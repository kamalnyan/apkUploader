import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/models/apk_model.dart';
import '../../core/theme.dart';
import '../../core/providers/apk_provider.dart';
import '../../core/providers/app_provider.dart';
import '../../core/models/model_adapter.dart';
import '../../services/auth_service.dart';
import '../../services/download_service.dart';
import '../../utils/helpers.dart';
import '../../utils/storage_permission_handler.dart';
import '../../widgets/animated_app_bar.dart';
import '../../widgets/apk_card.dart';
import '../../widgets/download_progress_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import '../../components/theme_toggle_button.dart';
import 'apk_details_screen.dart';
import '../admin/admin_home_screen.dart';
import '../auth/login_screen.dart';

/// Home screen for regular users
class UserHomeScreen extends StatefulWidget {
  /// Constructor
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> with SingleTickerProviderStateMixin {
  final DownloadService _downloadService = DownloadService();
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
    if (!AppHelpers.isAndroid()) return;
    
    try {
      final resumed = await _downloadService.checkAndResumeInstallation(context);
      if (resumed) {
        logger.i('Successfully resumed pending installation from UserHomeScreen');
      }
    } catch (e) {
      logger.e('Error checking pending installations in UserHomeScreen: $e');
    }
  }

  /// Show the download loading dialog
  void _showDownloadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              AppConstants.downloadAnimation,
              width: 100,
              height: 100,
              repeat: true,
              frameRate: FrameRate.max,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(),
                );
              },
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            Text(message),
          ],
        ),
      ),
    );
  }

  /// Handle APK download and installation
  Future<void> _downloadAndInstallAPK(APKModel apk) async {
    // First, check for storage permission
    if (AppHelpers.isAndroid()) {
      final hasPermission = await StoragePermissionHandler.requestStoragePermission(context);
      if (!hasPermission) {
        logger.e('Storage permission denied - cannot proceed with download');
        if (mounted) {
          AppHelpers.showSnackBar(
            context,
            'Storage permission required for downloading. Please grant permission.',
            isError: true,
          );
        }
        return;
      }
    }
    
    // Enhanced URL validation
    if (apk.apkUrl.isEmpty) {
      if (mounted) {
        AppHelpers.showSnackBar(
          context,
          'Invalid APK URL. Please contact the administrator.',
          isError: true,
        );
      }
      logger.e('Empty APK URL');
      return;
    }
    
    // Try to ensure the URL is valid
    String downloadUrl = apk.apkUrl;
    
    // Check if URL needs to be fixed (especially for Firebase Storage)
    try {
      if (!Uri.parse(downloadUrl).isAbsolute || !AppHelpers.isValidUrl(downloadUrl)) {
        // Try to fix Firebase Storage URL
        final fixedUrl = AppHelpers.fixFirebaseStorageUrl(downloadUrl);
        if (fixedUrl.isNotEmpty) {
          downloadUrl = fixedUrl;
          logger.i('Fixed Firebase Storage URL: $downloadUrl');
        } else {
          if (mounted) {
            AppHelpers.showSnackBar(
              context,
              'Invalid APK URL format. Please contact the administrator.',
              isError: true,
            );
          }
          logger.e('Invalid APK URL: $downloadUrl');
          return;
        }
      }
    } catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(
          context,
          'Invalid APK URL format. Please contact the administrator.',
          isError: true,
        );
      }
      logger.e('Error parsing APK URL: $e');
      return;
    }
    
    final String fileName = '${apk.name.replaceAll(' ', '_')}.apk';
    double progress = 0;
    bool isCancelled = false;
    
    // Reference to the dialog, so we can dismiss it if needed
    BuildContext? dialogContext;
    
    try {
      if (AppHelpers.isAndroid()) {
        // Show the progress dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            dialogContext = context;
            return StatefulBuilder(
              builder: (context, setState) {
                return DownloadProgressDialog(
                  fileName: apk.name,
                  progress: progress,
                  status: DownloadStatus.downloading,
                  message: 'Downloading ${apk.name} (${progress.toInt()}%)...',
                  onCancel: () {
                    setState(() {
                      isCancelled = true;
                    });
                    Navigator.of(context).pop();
                  },
                );
              }
            );
          },
        );
        
        if (!mounted) return;
        
        // Download the APK file
        final filePath = await _downloadService.downloadAPK(
          downloadUrl,
          fileName,
          onProgress: (downloadProgress) {
            if (dialogContext != null && !isCancelled) {
              (dialogContext! as Element).markNeedsBuild(); // Force dialog rebuild
              progress = downloadProgress;
            }
          },
          showNotification: false, // We'll show our own UI instead
        );
        
        // If cancelled or unmounted, stop here
        if (isCancelled || !mounted) return;
        
        if (filePath == null) {
          // If download failed, update dialog with error
          if (dialogContext != null) {
            Navigator.of(dialogContext!).pop();
            
            if (mounted) {
              // Use snackbar instead of error dialog
              AppHelpers.showSnackBar(
                context,
                'Failed to download APK. Please check your internet connection and try again.',
                isError: true,
              );
            }
          }
          return;
        }
        
        // Increment download count in the database
        context.read<APKProvider>().incrementDownloadCount(apk.id);
        
        // Update dialog to show installation progress
        if (dialogContext != null && mounted) {
          Navigator.of(dialogContext!).pop();
          
          // Show installation dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              dialogContext = context;
              return const DownloadProgressDialog(
                fileName: '',
                progress: 100,
                status: DownloadStatus.installing,
                message: 'APK downloaded successfully. Starting installation...',
              );
            },
          );
        }
        
        // Install the APK
        final installSuccess = await _downloadService.installAPK(
          filePath,
          showNotification: false, // We'll show our own UI instead
        );
        
        // If installation dialog is still showing, dismiss it
        if (dialogContext != null && mounted) {
          Navigator.of(dialogContext!).pop();
          
          // Don't show completion animation dialog, just show a brief message if successful
          if (installSuccess) {
            AppHelpers.showSnackBar(
              context,
              'APK installation started. Follow on-screen instructions to complete.',
            );
          } else {
            // For installation errors, use a snackbar with Settings action
            AppHelpers.showSnackBar(
              context,
              'Failed to install APK. Permission may be required.',
              isError: true,
              action: SnackBarAction(
                label: 'Settings',
                textColor: Colors.white,
                onPressed: () => AppHelpers.openAppSettings(),
              ),
            );
          }
        }
      } else if (AppHelpers.isIOS()) {
        // Show iOS message
        _downloadService.showInstallMessage(context);
      } else {
        // Show a message for other platforms
        AppHelpers.showSnackBar(
          context,
          'Download and installation not supported on this platform',
        );
      }
    } catch (e) {
      // If an error occurs and the dialog is still showing, dismiss it
      if (dialogContext != null && mounted) {
        Navigator.of(dialogContext!).pop();
        
        // Show error snackbar instead of dialog
        if (mounted) {
          AppHelpers.showSnackBar(
            context,
            'Error downloading APK: ${e.toString().split('\n').first}',
            isError: true,
          );
        }
      }
      
      logger.e('Error downloading APK: $e');
    }
  }

  /// Navigate to APK details screen
  void _navigateToDetails(APKModel apk) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => APKDetailsScreen(apk: apk),
      ),
    );
  }

  /// Handle search
  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  /// Go to login screen
  void _goToLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  /// Build the app list section
  Widget _buildAppList(
    List<APKModel> pinnedApps,
    List<APKModel> unpinnedApps,
    bool isLoading,
  ) {
    if (isLoading) {
      return const LoadingIndicator(message: 'Loading apps...');
    }

    // Filter by search query
    final List<APKModel> filteredPinnedApps = _searchQuery.isEmpty
        ? pinnedApps
        : pinnedApps.where((app) => 
            app.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            app.description.toLowerCase().contains(_searchQuery.toLowerCase())
          ).toList();
    
    final List<APKModel> filteredUnpinnedApps = _searchQuery.isEmpty
        ? unpinnedApps
        : unpinnedApps.where((app) => 
            app.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            app.description.toLowerCase().contains(_searchQuery.toLowerCase())
          ).toList();
    
    // If no apps available
    if (filteredPinnedApps.isEmpty && filteredUnpinnedApps.isEmpty) {
      return EmptyState(
        title: _searchQuery.isEmpty ? 'No Apps Available' : 'No Results',
        message: _searchQuery.isEmpty
            ? 'No apps have been uploaded yet. Please check back later.'
            : 'No apps found matching "$_searchQuery"',
        actionLabel: _searchQuery.isEmpty ? null : 'Clear Search',
        onAction: _searchQuery.isEmpty
            ? null
            : () {
                _searchController.clear();
                _onSearch('');
              },
      );
    }

    // Regular list with pinned and unpinned apps
    return ListView(
      padding: const EdgeInsets.only(top: AppTheme.spacingMedium),
      children: [
        // Pinned apps section
        if (filteredPinnedApps.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(
              left: AppTheme.spacingLarge,
              right: AppTheme.spacingLarge,
              bottom: AppTheme.spacingMedium,
            ),
            child: Text(
              'Featured Apps',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            )
            .animate(controller: _animationController)
            .fadeIn(duration: AppTheme.mediumAnimationDuration)
            .slideX(
              begin: -0.1,
              end: 0,
              duration: AppTheme.mediumAnimationDuration,
            ),
          ),
          
          ...List.generate(
            filteredPinnedApps.length,
            (index) => APKCard(
              apk: filteredPinnedApps[index],
              onTap: () => _navigateToDetails(filteredPinnedApps[index]),
              onDownload: () => _downloadAndInstallAPK(filteredPinnedApps[index]),
              index: index,
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingLarge),
        ],

        // Unpinned apps section
        if (filteredUnpinnedApps.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(
              left: AppTheme.spacingLarge,
              right: AppTheme.spacingLarge,
              bottom: AppTheme.spacingMedium,
            ),
            child: Text(
              'All Apps',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            )
            .animate(controller: _animationController)
            .fadeIn(
              duration: AppTheme.mediumAnimationDuration,
              delay: const Duration(milliseconds: 200),
            )
            .slideX(
              begin: -0.1,
              end: 0,
              duration: AppTheme.mediumAnimationDuration,
              delay: const Duration(milliseconds: 200),
            ),
          ),
          
          ...List.generate(
            filteredUnpinnedApps.length,
            (index) => APKCard(
              apk: filteredUnpinnedApps[index],
              onTap: () => _navigateToDetails(filteredUnpinnedApps[index]),
              onDownload: () => _downloadAndInstallAPK(filteredUnpinnedApps[index]),
              index: index + (filteredPinnedApps.isEmpty ? 0 : filteredPinnedApps.length),
            ),
          ),
        ],
        
        const SizedBox(height: AppTheme.spacingLarge),
      ],
    );
  }

  /// Build app drawer with admin login option
  Widget _buildDrawer() {
    final isDark = context.watch<AppProvider>().isDarkMode;
    final isAdmin = context.watch<AppProvider>().isAdmin;
    
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
            ),
            padding: const EdgeInsets.all(AppTheme.spacingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.android_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(width: AppTheme.spacingMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppConstants.appName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppConstants.appDescription,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Show admin option based on admin status
          if (isAdmin) 
            AppTheme.drawerListTile(
              icon: Icons.admin_panel_settings,
              title: 'Admin Dashboard',
              onTap: () {
                Navigator.of(context).pop(); // Close drawer
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AdminHomeScreen(),
                  ),
                );
              },
            )
          else
            Column(
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListTile(
                    leading: const Icon(
                      Icons.admin_panel_settings,
                      color: AppTheme.primaryColor,
                    ),
                    title: const Text(
                      'Admin Login', 
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).pop(); // Close drawer
                      _goToLogin();
                    },
                    dense: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                    ),
                  ),
                ),
              ],
            ),
          // Dark mode toggle
          const ThemeToggleButton(asSwitch: true),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get APK data from provider
    final apkProvider = context.watch<APKProvider>();
    final isLoading = apkProvider.isLoading;
    final allApps = apkProvider.apks;
    
    // Separate pinned and unpinned apps
    final pinnedApps = allApps.where((app) => app.isPinned).toList();
    final unpinnedApps = allApps.where((app) => !app.isPinned).toList();
    
    return Scaffold(
      drawer: _buildDrawer(),
      appBar: AnimatedAppBar(
        title: AppConstants.appName,
        actions: [
          // Theme toggle button
          const ThemeToggleButton(),
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
          Expanded(
            child: Consumer<APKProvider>(
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
          ),
        ],
      ),
      // Add floating action button for theme toggling
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read<AppProvider>().toggleTheme();
        },
        tooltip: 'Toggle Theme',
        child: Icon(
          context.watch<AppProvider>().isDarkMode 
              ? Icons.light_mode 
              : Icons.dark_mode,
        ),
      ),
    );
  }
} 