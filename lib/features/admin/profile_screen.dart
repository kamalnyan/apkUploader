import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/providers/app_provider.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../utils/helpers.dart';
import '../../widgets/animated_app_bar.dart';
import '../../widgets/loading_indicator.dart';

/// Profile screen for admin users to manage their account settings
class ProfileScreen extends StatefulWidget {
  /// Constructor
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  
  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  /// Change password
  Future<void> _changePassword() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Check if passwords match
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'New passwords do not match';
      });
      return;
    }
    
    // Start loading
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Get current and new passwords
      final currentPassword = _currentPasswordController.text;
      final newPassword = _newPasswordController.text;
      
      // Change password
      await _authService.changePassword(currentPassword, newPassword);
      
      if (!mounted) return;
      
      // Clear form
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changed successfully'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      
      // Reset loading state
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      // Show error message
      setState(() {
        _errorMessage = e.toString().split('Exception: ').last;
        _isLoading = false;
      });
      
      logger.e('Error changing password: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final user = _authService.getCurrentUser();
    final email = user?.email ?? 'Unknown';
    
    return Scaffold(
      appBar: AnimatedAppBar(
        title: 'Profile Settings',
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Updating password...')
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Admin info card
                    Card(
                      elevation: AppTheme.elevationSmall,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingMedium),
                        child: Row(
                          children: [
                            // Admin icon
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              child: const Icon(
                                Icons.admin_panel_settings,
                                size: 30,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingMedium),
                            // Admin info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Administrator',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    email,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(duration: AppTheme.shortAnimationDuration)
                    .slideY(
                      begin: -0.1,
                      end: 0,
                      duration: AppTheme.shortAnimationDuration,
                    ),
                    
                    const SizedBox(height: AppTheme.spacingLarge),
                    
                    // Change Password Section
                    Text(
                      'Change Password',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    )
                    .animate()
                    .fadeIn(
                      duration: AppTheme.shortAnimationDuration,
                      delay: const Duration(milliseconds: 100),
                    )
                    .slideX(
                      begin: -0.1,
                      end: 0,
                      duration: AppTheme.shortAnimationDuration,
                      delay: const Duration(milliseconds: 100),
                    ),
                    
                    const SizedBox(height: AppTheme.spacingMedium),
                    
                    // Error message
                    if (_errorMessage != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppTheme.spacingSmall),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            AppTheme.borderRadiusMedium,
                          ),
                          border: Border.all(
                            color: AppTheme.errorColor.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.errorColor,
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(duration: AppTheme.shortAnimationDuration)
                      .scale(
                        begin: const Offset(0.95, 0.95),
                        end: const Offset(1, 1),
                        duration: AppTheme.shortAnimationDuration,
                      ),
                      
                      const SizedBox(height: AppTheme.spacingMedium),
                    ],
                    
                    // Password change form
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Current password field
                          TextFormField(
                            controller: _currentPasswordController,
                            decoration: InputDecoration(
                              labelText: 'Current Password',
                              hintText: 'Enter your current password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureCurrentPassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureCurrentPassword = !_obscureCurrentPassword;
                                  });
                                },
                              ),
                            ),
                            obscureText: _obscureCurrentPassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your current password';
                              }
                              return null;
                            },
                          )
                          .animate()
                          .fadeIn(
                            duration: AppTheme.shortAnimationDuration,
                            delay: const Duration(milliseconds: 200),
                          )
                          .slideX(
                            begin: 0.1,
                            end: 0,
                            duration: AppTheme.shortAnimationDuration,
                            delay: const Duration(milliseconds: 200),
                          ),
                          
                          const SizedBox(height: AppTheme.spacingMedium),
                          
                          // New password field
                          TextFormField(
                            controller: _newPasswordController,
                            decoration: InputDecoration(
                              labelText: 'New Password',
                              hintText: 'Enter new password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureNewPassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureNewPassword = !_obscureNewPassword;
                                  });
                                },
                              ),
                            ),
                            obscureText: _obscureNewPassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a new password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          )
                          .animate()
                          .fadeIn(
                            duration: AppTheme.shortAnimationDuration,
                            delay: const Duration(milliseconds: 300),
                          )
                          .slideX(
                            begin: 0.1,
                            end: 0,
                            duration: AppTheme.shortAnimationDuration,
                            delay: const Duration(milliseconds: 300),
                          ),
                          
                          const SizedBox(height: AppTheme.spacingMedium),
                          
                          // Confirm password field
                          TextFormField(
                            controller: _confirmPasswordController,
                            decoration: InputDecoration(
                              labelText: 'Confirm New Password',
                              hintText: 'Confirm your new password',
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
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your new password';
                              }
                              if (value != _newPasswordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          )
                          .animate()
                          .fadeIn(
                            duration: AppTheme.shortAnimationDuration,
                            delay: const Duration(milliseconds: 400),
                          )
                          .slideX(
                            begin: 0.1,
                            end: 0,
                            duration: AppTheme.shortAnimationDuration,
                            delay: const Duration(milliseconds: 400),
                          ),
                          
                          const SizedBox(height: AppTheme.spacingLarge),
                          
                          // Change password button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: _changePassword,
                              icon: const Icon(Icons.vpn_key),
                              label: const Text('Change Password'),
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.borderRadiusMedium,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .animate()
                          .fadeIn(
                            duration: AppTheme.shortAnimationDuration,
                            delay: const Duration(milliseconds: 500),
                          )
                          .slideY(
                            begin: 0.2,
                            end: 0,
                            duration: AppTheme.shortAnimationDuration,
                            delay: const Duration(milliseconds: 500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 