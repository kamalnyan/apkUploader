import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/models/apk_model.dart';
import '../../core/models/model_adapter.dart';
import '../../core/models/supabase_to_firebase_adapter.dart';
import '../../core/providers/apk_provider.dart';
import '../../core/providers/app_provider.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../utils/helpers.dart';
import '../../widgets/apk_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import '../user/user_home_screen.dart';
import '../editor/apk_edit_screen.dart';
import 'user_management_screen.dart';
import 'profile_screen.dart';
import 'enhanced_upload_form.dart';

/// Admin home screen with APK management
class AdminHomeScreen extends StatefulWidget {
  /// Constructor
  const AdminHomeScreen({Key? key}) : super(key: key);

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  
  String _searchQuery = '';
  bool _isPerformingAction = false;
  
  @override
  void initState() {
    super.initState();
    
    // Set up animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    // Start the animation after a small delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
    _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// Navigate to Enhanced APK upload screen
  void _navigateToUpload() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const EnhancedUploadForm(),
      ),
    );
  }

  /// Navigate to APK edit screen
  void _navigateToEdit(SupabaseAPK apk) {
    // Convert SupabaseAPK to APKModel
    final apkModel = apk.toAPKModel();
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => APKEditScreen(apk: apkModel),
      ),
    );
  }

  /// Toggle pin status of an APK
  Future<void> _togglePinStatus(SupabaseAPK apk) async {
    setState(() {
      _isPerformingAction = true;
    });

    try {
      final success = await context.read<APKProvider>().togglePinStatus(
        apk.id,
        !apk.isPinned,
      );

      if (!mounted) return;

      if (success) {
        final action = apk.isPinned ? 'unpinned' : 'pinned';
        AppHelpers.showSnackBar(
          context,
          'APK ${action} successfully.',
        );
      } else {
        AppHelpers.showSnackBar(
          context,
          'Failed to update pin status. Please try again.',
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppHelpers.showSnackBar(
        context,
        'Failed to update pin status. Please try again.',
        isError: true,
      );
      logger.e('Error toggling pin status: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isPerformingAction = false;
        });
      }
    }
  }

  /// Delete an APK
  Future<void> _deleteAPK(SupabaseAPK apk) async {
    // Show confirmation dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete APK'),
        content: Text('Are you sure you want to delete "${apk.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;

    setState(() {
      _isPerformingAction = true;
    });

    try {
      final success = await context.read<APKProvider>().deleteAPK(apk.id);

      if (!mounted) return;

      if (success) {
        AppHelpers.showSnackBar(
          context,
          AppConstants.deleteSuccessMessage,
        );
      } else {
        AppHelpers.showSnackBar(
          context,
          'Failed to delete APK. Please try again.',
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppHelpers.showSnackBar(
        context,
        'Failed to delete APK. Please try again.',
        isError: true,
      );
      logger.e('Error deleting APK: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isPerformingAction = false;
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

  /// Navigate to user management screen
  void _navigateToUserManagement() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const UserManagementScreen(),
      ),
    );
  }

  /// Navigate to profile screen
  void _navigateToProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ProfileScreen(),
      ),
    );
  }

  /// Sign out
  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      if (!mounted) return;
      
      await context.read<AppProvider>().setUserRole(UserRole.viewer);
      
      // Navigate to user home screen
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

  /// Build the app list section
  Widget _buildAppList(
    List<SupabaseAPK> allApps,
    bool isLoading,
  ) {
    if (isLoading || _isPerformingAction) {
      return const LoadingIndicator(message: 'Loading apps...');
    }

    final List<SupabaseAPK> filteredApps = _searchQuery.isEmpty
        ? allApps
        : SupabaseAPK.fromFirebaseAPKList(
            context.read<APKProvider>().apks.where((apk) => 
              apk.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (apk.description ?? '').toLowerCase().contains(_searchQuery.toLowerCase())
            ).toList()
          );

    // If no apps available
    if (filteredApps.isEmpty) {
      return EmptyState(
        title: _searchQuery.isEmpty ? 'No Apps Available' : 'No Results',
        message: _searchQuery.isEmpty
            ? 'You haven\'t uploaded any apps yet. Tap the button below to upload your first APK.'
            : 'No apps found matching "$_searchQuery"',
        actionLabel: _searchQuery.isEmpty ? 'Upload APK' : 'Clear Search',
        onAction: _searchQuery.isEmpty
            ? _navigateToUpload
            : () {
                _searchController.clear();
                _onSearch('');
              },
      );
    }

    // Regular list
    return ListView.builder(
      padding: const EdgeInsets.only(top: AppTheme.spacingMedium),
      itemCount: filteredApps.length,
      itemBuilder: (context, index) {
        final apk = filteredApps[index];
        
        // Convert SupabaseAPK to APKModel for UI components
        final apkModel = apk.toAPKModel();
        
        return APKCard(
          apk: apkModel,
          onTap: () => _navigateToEdit(apk),
          onEdit: () => _navigateToEdit(apk),
          onDelete: () => _deleteAPK(apk),
          onTogglePin: () => _togglePinStatus(apk),
          isAdmin: true,
          index: index,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Disable back button
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          automaticallyImplyLeading: false, // Remove back button
          actions: [
            // Profile button
            IconButton(
              icon: const Icon(Icons.account_circle),
              tooltip: 'Profile Settings',
              onPressed: _navigateToProfile,
            ),
          
            // User management button
            IconButton(
              icon: const Icon(Icons.people),
              tooltip: 'User Management',
              onPressed: _navigateToUserManagement,
            ),
            
            // Sign out button
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Sign Out',
              onPressed: _signOut,
            ),
          ],
        ),
        
        // Floating action button for upload
        floatingActionButton: FloatingActionButton(
          onPressed: _navigateToUpload,
          backgroundColor: Colors.green,
          tooltip: 'Upload New APK',
          child: const Icon(Icons.add),
        ).animate(controller: _animationController)
          .scaleXY(
            begin: 0, 
            end: 1,
            duration: AppTheme.mediumAnimationDuration,
          ),
        
        // Main content
        body: Consumer<APKProvider>(
          builder: (context, apkProvider, child) {
            final isLoading = apkProvider.isLoading;
            // Convert Firebase APKs to Supabase APKs for backward compatibility
            final allApps = SupabaseAPK.fromFirebaseAPKList(apkProvider.apks);

            return Column(
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
                
                // App list
                Expanded(
                  child: _buildAppList(
                    allApps,
                    isLoading,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
} 