import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../utils/helpers.dart';
import '../../widgets/loading_indicator.dart';
import '../admin/admin_home_screen.dart';

/// Screen for setting up the first admin account
class InitialAdminSetupScreen extends StatefulWidget {
  /// Constructor
  const InitialAdminSetupScreen({Key? key}) : super(key: key);

  @override
  State<InitialAdminSetupScreen> createState() => _InitialAdminSetupScreenState();
}

class _InitialAdminSetupScreenState extends State<InitialAdminSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Handle admin account creation
  Future<void> _createAdminAccount() async {
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
      
      // Create user with Firebase
      final credential = await _authService.createUser(email, password);
      
      if (credential.user != null) {
        // Set user role as admin
        await _userService.createUser(
          email,
          password,
          UserRole.admin,
        );
        
        // Set admin status in Firestore
        await _authService.setUserRole(credential.user!.uid, 'admin');
        
        if (!mounted) return;
        
        // Navigate to admin screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AdminHomeScreen()),
        );
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Admin account created successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().contains('email-already-in-use')
            ? 'Email is already in use'
            : e.toString().contains('weak-password')
                ? 'Password is too weak'
                : 'Failed to create admin account. Please try again.';
        _isLoading = false;
      });
      logger.e('Error creating admin account: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const LoadingIndicator(
              message: 'Creating admin account...',
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
                        // Admin setup icon
                        Animate(
                          effects: [
                            FadeEffect(duration: AppTheme.mediumAnimationDuration),
                            ScaleEffect(
                              begin: const Offset(0.8, 0.8),
                              duration: AppTheme.mediumAnimationDuration,
                            ),
                          ],
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.admin_panel_settings,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: AppTheme.spacingLarge),
                        
                        // Title
                        Animate(
                          effects: [
                            FadeEffect(
                              duration: AppTheme.mediumAnimationDuration, 
                              delay: const Duration(milliseconds: 200),
                            ),
                          ],
                          child: Text(
                            'Initial Setup',
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
                            'Create the first admin account',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.textLightColor,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: AppTheme.spacingXl),
                        
                        // Welcome box
                        Animate(
                          effects: [
                            FadeEffect(
                              duration: AppTheme.mediumAnimationDuration, 
                              delay: const Duration(milliseconds: 300),
                            ),
                          ],
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppTheme.spacingMedium),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                AppTheme.borderRadiusMedium,
                              ),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.blue,
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Welcome to APK Uploader',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'No admin accounts have been found. Please create the first admin account to get started with the application.',
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: AppTheme.spacingLarge),
                        
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
                              labelText: 'Admin Email',
                              hintText: 'Enter your admin email',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!value.contains('@') || !value.contains('.')) {
                                return 'Please enter a valid email address';
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
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                        ),
                        
                        const SizedBox(height: AppTheme.spacingLarge),
                        
                        // Confirm Password field
                        Animate(
                          effects: [
                            FadeEffect(
                              duration: AppTheme.mediumAnimationDuration, 
                              delay: const Duration(milliseconds: 600),
                            ),
                            SlideEffect(
                              begin: const Offset(0.1, 0),
                              end: const Offset(0, 0),
                              duration: AppTheme.mediumAnimationDuration, 
                              delay: const Duration(milliseconds: 600),
                            ),
                          ],
                          child: TextFormField(
                            controller: _confirmPasswordController,
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              hintText: 'Confirm your password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword = !_obscureConfirmPassword;
                                  });
                                },
                              ),
                            ),
                            obscureText: _obscureConfirmPassword,
                            textInputAction: TextInputAction.done,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                        ),
                        
                        const SizedBox(height: AppTheme.spacingXl),
                        
                        // Create account button
                        Animate(
                          effects: [
                            FadeEffect(
                              duration: AppTheme.mediumAnimationDuration, 
                              delay: const Duration(milliseconds: 700),
                            ),
                          ],
                          child: SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton.icon(
                              onPressed: _createAdminAccount,
                              icon: const Icon(Icons.admin_panel_settings),
                              label: const Text('Create Admin Account'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.borderRadiusMedium,
                                  ),
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