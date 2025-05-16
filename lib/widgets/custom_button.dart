import 'package:flutter/material.dart';
import '../core/theme.dart';

/// A customized button widget with built-in loading state
class CustomButton extends StatelessWidget {
  /// The callback when the button is pressed
  final VoidCallback? onPressed;
  
  /// The icon to display
  final IconData? icon;
  
  /// The label text
  final String label;
  
  /// Whether the button is in loading state
  final bool isLoading;
  
  /// Optional color override
  final Color? color;
  
  /// Constructor
  const CustomButton({
    super.key,
    required this.onPressed,
    this.icon,
    required this.label,
    this.isLoading = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Use AppTheme.primaryButton with customizations
    return AppTheme.primaryButton(
      text: label,
      onPressed: onPressed,
      isLoading: isLoading,
      leadingIcon: icon,
      // Use custom style if color is provided
      // The AppTheme.primaryButton already handles disabled and loading states
    );
  }
} 