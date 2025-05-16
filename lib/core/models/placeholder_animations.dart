import 'package:flutter/material.dart';

/// Class that provides placeholder animations for use in places where Lottie animations would normally be used
class PlaceholderAnimations {
  // Private constructor to prevent instantiation
  PlaceholderAnimations._();

  /// Placeholder for upload animation
  static Widget uploadAnimation({
    double? width,
    double? height,
    Color? color,
  }) {
    return _buildAnimatedIcon(
      icon: Icons.cloud_upload_rounded,
      width: width,
      height: height,
      color: color,
    );
  }

  /// Placeholder for download animation
  static Widget downloadAnimation({
    double? width,
    double? height,
    Color? color,
  }) {
    return _buildAnimatedIcon(
      icon: Icons.cloud_download_rounded,
      width: width,
      height: height,
      color: color,
    );
  }

  /// Placeholder for empty state animation
  static Widget emptyAnimation({
    double? width,
    double? height,
    Color? color,
  }) {
    return _buildAnimatedIcon(
      icon: Icons.inbox_rounded,
      width: width,
      height: height,
      color: color,
    );
  }

  /// Placeholder for error animation
  static Widget errorAnimation({
    double? width,
    double? height,
    Color? color,
  }) {
    return _buildAnimatedIcon(
      icon: Icons.error_outline_rounded,
      width: width,
      height: height,
      color: color ?? Colors.red,
    );
  }

  /// Placeholder for success animation
  static Widget successAnimation({
    double? width,
    double? height,
    Color? color,
  }) {
    return _buildAnimatedIcon(
      icon: Icons.check_circle_outline_rounded,
      width: width,
      height: height,
      color: color ?? Colors.green,
    );
  }

  /// Placeholder for loading animation
  static Widget loadingAnimation({
    double? width,
    double? height,
    Color? color,
  }) {
    return _buildLoadingAnimation(
      width: width,
      height: height,
      color: color,
    );
  }

  /// Placeholder for login animation
  static Widget loginAnimation({
    double? width,
    double? height,
    Color? color,
  }) {
    return _buildAnimatedIcon(
      icon: Icons.login_rounded,
      width: width,
      height: height,
      color: color,
    );
  }

  /// Build an animated icon
  static Widget _buildAnimatedIcon({
    required IconData icon,
    double? width,
    double? height,
    Color? color,
  }) {
    final iconSize = (width ?? 150) * 0.6;
    
    return SizedBox(
      width: width,
      height: height,
      child: Center(
        child: TweenAnimationBuilder(
          tween: Tween<double>(begin: 0.8, end: 1.0),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOut,
          builder: (_, double value, child) {
            return Transform.scale(
              scale: value,
              child: Icon(
                icon,
                size: iconSize,
                color: color,
              ),
            );
          },
        ),
      ),
    );
  }

  /// Build a loading animation
  static Widget _buildLoadingAnimation({
    double? width,
    double? height,
    Color? color,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: Center(
        child: CircularProgressIndicator(
          color: color,
          strokeWidth: 4.0,
        ),
      ),
    );
  }
} 