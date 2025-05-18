import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/providers/app_provider.dart';
import '../../core/providers/apk_provider.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../utils/helpers.dart';
import '../admin/admin_home_screen.dart';
import '../editor/editor_home_screen.dart';
import '../viewer/viewer_home_screen.dart';
import '../auth/initial_admin_setup_screen.dart';
import '../auth/login_screen.dart';
import '../user/user_home_screen.dart';

/// Splash screen with app initialization
class SplashScreen extends StatefulWidget {
  /// Constructor
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  bool _isInitialized = false;
  String? _errorMessage;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animationController.repeat();
    _initializeApp();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Initialize app data and check auth status
  Future<void> _initializeApp() async {
    try {
      // Simulate loading delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Initialize providers
      if (!mounted) return;
      context.read<APKProvider>().init();
      
      setState(() {
        _isInitialized = true;
      });
      
      // Check if any admin users exist
      final hasAdmins = await _userService.hasAdminUsers();
      
      if (!hasAdmins) {
        // If no admin users, navigate to initial setup
        _navigateToInitialSetup();
        return;
      }
      
      // Navigate based on authentication status
      _checkAuthStatus();
    } catch (e) {
      logger.e('Error initializing app: $e');
      setState(() {
        _errorMessage = 'Failed to initialize app. Please try again.';
      });
    }
  }

  /// Check authentication status and navigate accordingly
  /// This verifies if there's a persistent user session and routes accordingly
  Future<void> _checkAuthStatus() async {
    if (!mounted) return;
    
    try {
      final user = _authService.getCurrentUser();
      
      if (user != null) {
        // User session exists, verify role
        final userId = _authService.getCurrentUserId();
        if (userId == null) {
          // No valid user ID, go to user home screen
          _navigateToUserHome();
          return;
        }
        
        // Get user role
        final userRole = await _userService.getUserRole(userId);
        if (!mounted) return;
        
        // Set user role in provider
        await context.read<AppProvider>().setUserRole(userRole);
        
        if (!mounted) return;
        
        // Navigate based on user role - simplified flow
        if (userRole == UserRole.admin) {
          // Valid admin session found, go to admin home
          logger.i('Admin session restored for user: $userId');
          _navigateToAdminHome();
        } else if (userRole == UserRole.editor) {
          // Editor session found, go to editor home
          logger.i('Editor session restored for user: $userId');
          _navigateToEditorHome();
        } else {
          // Default to viewer for any other role
          logger.i('Viewer session restored for user: $userId');
          _navigateToViewerHome();
        }
      } else {
        // No user logged in, go directly to user home screen - no login required
        logger.i('No active session found, redirecting to user home screen');
        _navigateToUserHome();
      }
    } catch (e) {
      logger.e('Error checking auth status: $e');
      // In case of error, go to user home screen
      _navigateToUserHome();
    }
  }

  /// Navigate to the login screen
  void _navigateToLogin() {
    if (!mounted) return;
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });
  }

  /// Navigate to the admin home screen
  void _navigateToAdminHome() {
    if (!mounted) return;
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AdminHomeScreen()),
      );
    });
  }
  
  /// Navigate to the initial admin setup screen
  void _navigateToInitialSetup() {
    if (!mounted) return;
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const InitialAdminSetupScreen()),
      );
    });
  }

  /// Navigate to the editor home screen
  void _navigateToEditorHome() {
    if (!mounted) return;
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const EditorHomeScreen()),
      );
    });
  }
  
  /// Navigate to the viewer home screen
  void _navigateToViewerHome() {
    if (!mounted) return;
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const ViewerHomeScreen()),
      );
    });
  }

  /// Navigate to the user home screen
  void _navigateToUserHome() {
    if (!mounted) return;
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const UserHomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primaryContainer.withOpacity(0.6),
              colorScheme.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo/icon
                Hero(
                  tag: 'app-logo',
                  child: Animate(
                    effects: [
                      FadeEffect(duration: const Duration(milliseconds: 800)),
                      ScaleEffect(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1.0, 1.0),
                        duration: const Duration(milliseconds: 800),
                      ),
                    ],
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.android_rounded,
                        color: colorScheme.onPrimary,
                        size: 80,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // App name
                Animate(
                  effects: [
                    FadeEffect(
                      duration: const Duration(milliseconds: 800),
                      delay: const Duration(milliseconds: 300),
                    ),
                    SlideEffect(
                      begin: const Offset(0, 10),
                      end: const Offset(0, 0),
                      duration: const Duration(milliseconds: 800),
                      delay: const Duration(milliseconds: 300),
                    ),
                  ],
                  child: Text(
                    AppConstants.appName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // App description
                Animate(
                  effects: [
                    FadeEffect(
                      duration: const Duration(milliseconds: 800),
                      delay: const Duration(milliseconds: 400),
                    ),
                    SlideEffect(
                      begin: const Offset(0, 10),
                      end: const Offset(0, 0),
                      duration: const Duration(milliseconds: 800),
                      delay: const Duration(milliseconds: 400),
                    ),
                  ],
                  child: Text(
                    'APK Management Platform',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // Loading animation or error message
                if (_errorMessage != null)
                  Animate(
                    effects: [
                      FadeEffect(
                        duration: const Duration(milliseconds: 800),
                        delay: const Duration(milliseconds: 500),
                      ),
                    ],
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 32,
                      ),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Column(
                    children: [
                      // Loading animation
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return CircularProgressIndicator(
                              value: _animationController.value,
                              color: colorScheme.primary,
                              strokeWidth: 3,
                            );
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Loading text
                      Text(
                        _isInitialized 
                            ? 'Checking credentials...' 
                            : 'Initializing...',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 