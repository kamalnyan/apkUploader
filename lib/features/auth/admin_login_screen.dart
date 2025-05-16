import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/providers/app_provider.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../utils/helpers.dart';
import '../../widgets/loading_indicator.dart';
import '../admin/admin_home_screen.dart';
import '../editor/editor_home_screen.dart';
import '../viewer/viewer_home_screen.dart';

/// App login screen for admin users only
class AdminLoginScreen extends StatefulWidget {
  /// Constructor
  const AdminLoginScreen({Key? key}) : super(key: key);

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Handle login
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get email and password
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      
      // Sign in with Firebase
      final response = await _authService.signInWithEmailAndPassword(
        email,
        password,
      );
      
      if (!mounted) return;
      
      // Check if user is admin
      final userId = response.user!.uid;
      final userRole = await _userService.getUserRole(userId);
      
      if (userRole != UserRole.admin) {
        setState(() {
          _errorMessage = 'You do not have admin privileges';
          _isLoading = false;
        });
        return;
      }
      
      // Set user role in provider
      await context.read<AppProvider>().setUserRole(userRole);
      
      if (!mounted) return;

      // Navigate to admin home screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AdminHomeScreen()),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().contains('Invalid')
            ? 'Invalid email or password'
            : AppConstants.loginErrorMessage;
        _isLoading = false;
      });
      logger.e('Error logging in: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const LoadingIndicator(
              message: 'Authenticating Admin...',
              useScaffold: true,
            )
          : SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.spacingLarge),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // App icon
                        Animate(
                          effects: [
                            FadeEffect(duration: AppTheme.mediumAnimationDuration),
                            ScaleEffect(
                              begin: const Offset(0.8, 0.8),
                              duration: AppTheme.mediumAnimationDuration,
                            ),
                          ],
                          child: Icon(
                            Icons.admin_panel_settings,
                            size: 80,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        
                        const SizedBox(height: AppTheme.spacingLarge),
                        
                        // Title - Admin Login
                        Animate(
                          effects: [
                            FadeEffect(
                              duration: AppTheme.mediumAnimationDuration, 
                              delay: const Duration(milliseconds: 200),
                            ),
                          ],
                          child: Text(
                            'Admin Login',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: AppTheme.spacingLarge),
                        
                        // Error message
                        if (_errorMessage != null) ...[
                          Animate(
                            effects: const [FadeEffect(duration: Duration(milliseconds: 300))],
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppTheme.spacingMedium),
                              decoration: BoxDecoration(
                                color: AppTheme.errorColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                                border: Border.all(color: AppTheme.errorColor),
                              ),
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: AppTheme.errorColor),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingLarge),
                        ],
                        
                        // Email field
                        Animate(
                          effects: [
                            FadeEffect(
                              duration: AppTheme.mediumAnimationDuration, 
                              delay: const Duration(milliseconds: 400),
                            ),
                          ],
                          child: TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              hintText: 'Enter your admin email',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!AppHelpers.isValidEmail(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                        ),
                        
                        const SizedBox(height: AppTheme.spacingLarge),
                        
                        // Password field
                        Animate(
                          effects: [
                            FadeEffect(
                              duration: AppTheme.mediumAnimationDuration, 
                              delay: const Duration(milliseconds: 500),
                            ),
                          ],
                          child: TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: 'Enter your password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            obscureText: _obscurePassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),
                        ),
                        
                        const SizedBox(height: AppTheme.spacingXl),
                        
                        // Login button
                        Animate(
                          effects: [
                            FadeEffect(
                              duration: AppTheme.mediumAnimationDuration, 
                              delay: const Duration(milliseconds: 600),
                            ),
                          ],
                          child: SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.borderRadiusMedium,
                                  ),
                                ),
                              ),
                              child: const Text('Admin Login'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

/// Regular login screen for all user roles
class LoginScreen extends StatefulWidget {
  /// Constructor
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Handle login
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get email and password
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      
      // Sign in with Firebase
      final response = await _authService.signInWithEmailAndPassword(
        email,
        password,
      );
      
      if (!mounted) return;
      
      // Check user role
      final userId = response.user!.uid;
      final userRole = await _userService.getUserRole(userId);
      
      // Set user role in provider
      await context.read<AppProvider>().setUserRole(userRole);
      
      if (!mounted) return;

      // Navigate to appropriate screen based on role
      _navigateToHomeScreen(userRole);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().contains('Invalid')
            ? 'Invalid email or password'
            : AppConstants.loginErrorMessage;
        _isLoading = false;
      });
      logger.e('Error logging in: $e');
    }
  }
  
  /// Navigate to the correct home screen based on user role
  void _navigateToHomeScreen(UserRole role) {
    if (!mounted) return;
    
    Widget homeScreen;
    switch (role) {
      case UserRole.admin:
        homeScreen = const AdminHomeScreen();
        break;
      case UserRole.editor:
        homeScreen = const EditorHomeScreen();
        break;
      case UserRole.viewer:
      default:
        homeScreen = const ViewerHomeScreen();
        break;
    }
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => homeScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const LoadingIndicator(
              message: 'Authenticating...',
              useScaffold: true,
            )
          : SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.spacingLarge),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // App icon
                        Animate(
                          effects: [
                            FadeEffect(duration: AppTheme.mediumAnimationDuration),
                            ScaleEffect(
                              begin: const Offset(0.8, 0.8),
                              duration: AppTheme.mediumAnimationDuration,
                            ),
                          ],
                          child: Icon(
                            Icons.android_rounded,
                            size: 80,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        
                        const SizedBox(height: AppTheme.spacingLarge),
                        
                        // Title - APK Uploader
                        Animate(
                          effects: [
                            FadeEffect(
                              duration: AppTheme.mediumAnimationDuration, 
                              delay: const Duration(milliseconds: 200),
                            ),
                          ],
                          child: Text(
                            'APK Uploader',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: AppTheme.spacingSmall),
                        
                        Animate(
                          effects: [
                            FadeEffect(
                              duration: AppTheme.mediumAnimationDuration, 
                              delay: const Duration(milliseconds: 300),
                            ),
                          ],
                          child: Text(
                            'Management Portal',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textLightColor,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: AppTheme.spacingXl),
                        
                        // Error message
                        if (_errorMessage != null) ...[
                          Animate(
                            effects: [
                              FadeEffect(duration: AppTheme.shortAnimationDuration),
                              ShakeEffect(),
                            ],
                            child: Container(
                              padding: const EdgeInsets.all(AppTheme.spacingMedium),
                              decoration: BoxDecoration(
                                color: AppTheme.errorColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.borderRadiusMedium,
                                ),
                                border: Border.all(
                                  color: AppTheme.errorColor.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: AppTheme.errorColor,
                                  ),
                                  const SizedBox(width: AppTheme.spacingSmall),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppTheme.errorColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: AppTheme.spacingLarge),
                        ],
                        
                        // Email field
                        Animate(
                          effects: [
                            FadeEffect(
                              duration: AppTheme.mediumAnimationDuration, 
                              delay: const Duration(milliseconds: 400),
                            ),
                          ],
                          child: TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              hintText: 'Enter your email',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!value.contains('@') || !value.contains('.')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                        ),
                        
                        const SizedBox(height: AppTheme.spacingLarge),
                        
                        // Password field
                        Animate(
                          effects: [
                            FadeEffect(
                              duration: AppTheme.mediumAnimationDuration, 
                              delay: const Duration(milliseconds: 500),
                            ),
                          ],
                          child: TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: 'Enter your password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            obscureText: _obscurePassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),
                        ),
                        
                        const SizedBox(height: AppTheme.spacingXl),
                        
                        // Login button
                        Animate(
                          effects: [
                            FadeEffect(
                              duration: AppTheme.mediumAnimationDuration, 
                              delay: const Duration(milliseconds: 600),
                            ),
                          ],
                          child: SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.borderRadiusMedium,
                                  ),
                                ),
                              ),
                              child: const Text('Log In'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
} 