import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:app_settings/app_settings.dart';

import '../../core/constants.dart';
import '../../core/models/apk_model.dart';
import '../../core/models/model_adapter.dart';
import '../../core/providers/apk_provider.dart';
import '../../core/providers/app_provider.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../services/download_service.dart';
import '../../services/user_service.dart';
import '../../utils/helpers.dart';
import '../../utils/storage_permission_handler.dart';
import '../../widgets/animated_app_bar.dart';
import '../../widgets/apk_card.dart';
import '../../widgets/download_progress_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import '../user/user_home_screen.dart';
import 'apk_details_screen.dart';

/// Home screen for viewer users
class ViewerHomeScreen extends StatefulWidget {
  /// Constructor
  const ViewerHomeScreen({super.key});

  @override
  State<ViewerHomeScreen> createState() => _ViewerHomeScreenState();
}

class _ViewerHomeScreenState extends State<ViewerHomeScreen> with SingleTickerProviderStateMixin {
  final DownloadService _downloadService = DownloadService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  late final AnimationController _animationController;
  String _searchQuery = '';
  bool _isDownloading = false;
  String? _downloadMessage;

  @override
  void initState() {
    super.initState();
    _initProviders();
    _animationController = AnimationController(
      vsync: this,
      duration: AppTheme.mediumAnimationDuration,
    );
    _animationController.forward();
    
    // Check for storage permissions when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkStoragePermission();
      
      // Also check for any pending installations
      _checkPendingInstallations();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// Initialize providers
  void _initProviders() {
    // Initialize APK provider to start loading data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<APKProvider>().init();
    });
  }

  /// Check for storage permissions
  Future<void> _checkStoragePermission() async {
    // Only check on Android
    if (!AppHelpers.isAndroid()) {
      return;
    }
    
    // Use the enhanced permission handler
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final hasPermission = await StoragePermissionHandler.requestAllPermissions(context);
      if (hasPermission) {
        logger.i('All permissions granted successfully');
      } else {
        logger.w('Some permissions were denied');
        // We don't show an error message here since the StoragePermissionHandler
        // already shows appropriate dialogs to the user
      }
    });
  }

  /// Check for any pending installations
  Future<void> _checkPendingInstallations() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final installationResult = await _downloadService.resumeAnyPendingInstallation();
      
      if (installationResult.hasAction && mounted) {
        if (installationResult.error != null) {
          // Show error message
          AppHelpers.showSnackBar(
            context, 
            installationResult.error!, 
            isError: true,
            action: installationResult.actionLabel != null 
              ? SnackBarAction(
                  label: installationResult.actionLabel!,
                  onPressed: () {
                    // Open settings if needed
                    if (installationResult.needsSettings) {
                      AppSettings.openAppSettings();
                    }
                  },
                )
              : null,
          );
        } else if (installationResult.success) {
          AppHelpers.showSnackBar(
            context, 
            'APK installation completed successfully.'
          );
        }
      }
    });
  }

  /// Navigate to APK details
  void _navigateToDetails(APKModel apk) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => APKDetailsScreen(apk: apk),
      ),
    );
  }

  /// Download and install APK
  Future<void> _downloadAPK(APKModel apk) async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
      _downloadMessage = 'Preparing download...';
    });

    try {
      // Check and request permissions
      final hasPermission = await StoragePermissionHandler.requestAllPermissions(
        context,
        forceRequest: true,
      );
      
      if (!hasPermission) {
        if (mounted) {
          setState(() {
            _isDownloading = false;
            _downloadMessage = null;
          });
          
          AppHelpers.showSnackBar(
            context,
            'Storage permission required to download APKs.',
            isError: true,
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () {
                AppSettings.openAppSettings();
              },
            ),
          );
        }
        return;
      }

      if (!mounted) return;
      
      // Show download progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => DownloadProgressDialog(
          fileName: apk.name,
          progress: 0,
          status: DownloadStatus.downloading,
          message: 'Starting installing...',
        ),
      );

      // Increment download count
      await context.read<APKProvider>().incrementDownloadCount(apk.id);
      
      // Download the APK
      final result = await _downloadService.downloadAndInstallAPK(
        context,
        apk.downloadUrl,
        apk.name,
      );

      if (!mounted) return;
      
      // Close progress dialog
      Navigator.of(context).pop();

      if (result.success) {
        if (result.installStarted) {
          // Installation has started
          AppHelpers.showSnackBar(
            context,
            'APK download completed. Installation started.',
          );
        } else {
          // Installation not started (maybe just downloaded)
          AppHelpers.showSnackBar(
            context,
            'APK downloaded successfully.',
          );
        }
      } else {
        // Error occurred
        AppHelpers.showSnackBar(
          context,
          result.error ?? 'Failed to download APK.',
          isError: true,
          action: result.needsSettings 
              ? SnackBarAction(
                  label: 'Settings',
                  onPressed: () {
                    AppSettings.openAppSettings();
                  },
                )
              : null,
        );
      }
    } catch (e) {
      logger.e('Error downloading APK: $e');
      
      if (mounted) {
        AppHelpers.showSnackBar(
          context,
          'Failed to download APK: ${e.toString()}',
          isError: true,
        );
        
        // Close progress dialog if open
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadMessage = null;
        });
      }
    }
  }

  /// Handle search
  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  /// Sign out
  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      if (!mounted) return;
      
      await context.read<AppProvider>().setUserRole(UserRole.viewer);
      
      // Navigate to UserHomeScreen
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const UserHomeScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      AppHelpers.showSnackBar(
        context,
        'Failed to sign out. Please try again.',
        isError: true,
      );
      logger.e('Error signing out: $e');
    }
  }

  /// Build app list widget
  Widget _buildAppList(
    List<APKModel> pinnedApps,
    List<APKModel> unpinnedApps,
    bool isLoading,
  ) {
    // Show loading indicator
    if (isLoading) {
      return const Expanded(
        child: LoadingIndicator(message: 'Loading apps...'),
      );
    }

    // If no apps available
    if (pinnedApps.isEmpty && unpinnedApps.isEmpty) {
      if (_searchQuery.isNotEmpty) {
        return Expanded(
          child: EmptyState(
            title: 'No Results',
            message: 'No apps found matching "$_searchQuery"',
            actionLabel: 'Clear Search',
            onAction: () {
              _searchController.clear();
              _onSearch('');
            },
          ),
        );
      } else {
        return const Expanded(
          child: EmptyState(
            title: 'No Apps Available',
            message: 'No apps have been uploaded yet.',
          ),
        );
      }
    }

    // Filter apps based on search query
    final List<APKModel> filteredPinnedApps = _searchQuery.isEmpty
        ? pinnedApps
        : pinnedApps
            .where((apk) =>
                apk.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (apk.description ?? '')
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()))
            .toList();

    final List<APKModel> filteredUnpinnedApps = _searchQuery.isEmpty
        ? unpinnedApps
        : unpinnedApps
            .where((apk) =>
                apk.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (apk.description ?? '')
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()))
            .toList();

    // Show no results if all filtered lists are empty
    if (filteredPinnedApps.isEmpty && filteredUnpinnedApps.isEmpty) {
      return Expanded(
        child: EmptyState(
          title: 'No Results',
          message: 'No apps found matching "$_searchQuery"',
          actionLabel: 'Clear Search',
          onAction: () {
            _searchController.clear();
            _onSearch('');
          },
        ),
      );
    }

    // List of apps
    return Expanded(
      child: ListView(
        padding: const EdgeInsets.only(top: AppTheme.spacingMedium),
        children: [
          // Pinned apps section
          if (filteredPinnedApps.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMedium,
                vertical: AppTheme.spacingSmall,
              ),
              child: Row(
                children: [
                  const Icon(Icons.push_pin, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Pinned Apps',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ...filteredPinnedApps.asMap().entries.map((entry) {
              final index = entry.key;
              final apk = entry.value;
              return APKCard(
                apk: apk,
                onTap: () => _navigateToDetails(apk),
                onDownload: () => _downloadAPK(apk),
                isAdmin: false,
                isViewer: true,
                index: index,
              );
            }),
            
            const Divider(
              height: AppTheme.spacingLarge * 2,
              indent: AppTheme.spacingMedium,
              endIndent: AppTheme.spacingMedium,
            ),
          ],

          // Unpinned apps section
          if (filteredUnpinnedApps.isNotEmpty) ...[
            if (filteredPinnedApps.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMedium,
                  vertical: AppTheme.spacingSmall,
                ),
                child: Text(
                  'All Apps',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ...filteredUnpinnedApps.asMap().entries.map((entry) {
              final index = entry.key;
              final apk = entry.value;
              return APKCard(
                apk: apk,
                onTap: () => _navigateToDetails(apk),
                onDownload: () => _downloadAPK(apk),
                isAdmin: false,
                isViewer: true,
                index: index + filteredPinnedApps.length,
              );
            }),
          ],
          
          // Bottom padding
          const SizedBox(height: AppTheme.spacingLarge),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Disable back button
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AnimatedAppBar(
          title: 'APK Viewer',
          actions: [
            // Theme toggle button
            IconButton(
              icon: Icon(
                context.watch<AppProvider>().isDarkMode
                    ? Icons.light_mode
                    : Icons.dark_mode,
              ),
              tooltip: 'Toggle Theme',
              onPressed: () {
                context.read<AppProvider>().toggleTheme();
              },
            ),
            
            // Sign out button
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Sign Out',
              onPressed: _signOut,
            ),
          ],
        ),
        body: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search apps...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _onSearch('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppTheme.borderRadiusMedium,
                    ),
                  ),
                ),
                onChanged: _onSearch,
              )
              .animate(controller: _animationController)
              .fadeIn(duration: AppTheme.mediumAnimationDuration)
              .slideY(
                begin: -0.1,
                end: 0,
                duration: AppTheme.mediumAnimationDuration,
              ),
            ),
            
            // Main content
            Consumer<APKProvider>(
              builder: (context, apkProvider, child) {
                final isLoading = apkProvider.isLoading;
                
                // Convert SupabaseAPK lists to APKModel lists
                final List<APKModel> pinnedApps = ModelAdapter.toAPKModelList(apkProvider.pinnedApks);
                final List<APKModel> unpinnedApps = ModelAdapter.toAPKModelList(apkProvider.unpinnedApks);
                
                return _buildAppList(
                  pinnedApps,
                  unpinnedApps,
                  isLoading,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
} 