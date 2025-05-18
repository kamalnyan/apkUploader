import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
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

/// Login screen for the app
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
      
      // Get user role from UserService
      final userId = response.user!.uid;
      final userRole = await _userService.getUserRole(userId);
      
      // Set user role in provider
      await context.read<AppProvider>().setUserRole(userRole);
      
      if (!mounted) return;

      // Navigate to appropriate screen based on role
      // If admin, show AdminHomeScreen
      // Otherwise, show ViewerHomeScreen by default
      if (userRole == UserRole.admin) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AdminHomeScreen()),
        );
      } else if (userRole == UserRole.editor) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const EditorHomeScreen()),
        );
      } else {
        // Default for all non-admin users (including unknown roles)
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ViewerHomeScreen()),
        );
      }
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().contains('Invalid')
            ? 'Invalid email or password'
            : AppConstants.loginErrorMessage;
      });
      logger.e('Error logging in: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const LoadingIndicator(
              message: 'Signing in...',
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
                        // App logo animation
                        Animate(
                          effects: [
                            FadeEffect(duration: AppTheme.mediumAnimationDuration),
                            ScaleEffect(
                              begin: const Offset(0.8, 0.8),
                              duration: AppTheme.mediumAnimationDuration,
                            ),
                          ],
                          child: Lottie.asset(
                            'assets/animations/login.json',
                            width: 200,
                            height: 200,
                            repeat: true,
                            frameRate: FrameRate.max,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.login_rounded,
                                size: 100,
                                color: AppTheme.primaryColor,
                              );
                            },
                          ),
                        ),
                        
                        const SizedBox(height: AppTheme.spacingLarge),
                        
                        // App title
                        Animate(
                          effects: [
                            FadeEffect(
                              duration: AppTheme.mediumAnimationDuration, 
                              delay: const Duration(milliseconds: 200),
                            ),
                          ],
                          child: Text(
                            AppConstants.appName,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: AppTheme.spacingMedium),
                        
                        Animate(
                          effects: [
                            FadeEffect(
                              duration: AppTheme.mediumAnimationDuration, 
                              delay: const Duration(milliseconds: 300),
                            ),
                          ],
                          child: Text(
                            'Sign in to continue',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                            SlideEffect(
                              begin: const Offset(0.1, 0),
                              end: const Offset(0, 0),
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
                            SlideEffect(
                              begin: const Offset(0.1, 0),
                              end: const Offset(0, 0),
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
                        
                        const SizedBox(height: AppTheme.spacingLarge),
                        
                        // Login button
                        Animate(
                          effects: [
                            FadeEffect(
                              duration: AppTheme.mediumAnimationDuration, 
                              delay: const Duration(milliseconds: 700),
                            ),
                            SlideEffect(
                              begin: const Offset(0, 0.2),
                              end: const Offset(0, 0),
                              duration: AppTheme.mediumAnimationDuration, 
                              delay: const Duration(milliseconds: 700),
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
                                backgroundColor: Colors.white,
                                foregroundColor: AppTheme.primaryColor,
                                elevation: 8,
                                side: const BorderSide(color: AppTheme.primaryColor, width: 2),
                                shadowColor: Colors.white.withOpacity(0.6),
                              ),
                              child: const Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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