import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../core/theme.dart';
import '../core/constants.dart';

/// A loading indicator widget with animation
class LoadingIndicator extends StatelessWidget {
  final String? message;
  final double size;
  final bool useScaffold;
  final double? progress;
  final bool showProgress;
  final bool isDownloading;
  final bool isUploading;
  final bool isCancelled;
  final String? actionName;

  /// Constructor
  const LoadingIndicator({
    super.key,
    this.message,
    this.size = 200,
    this.useScaffold = false,
    this.progress,
    this.showProgress = false,
    this.isDownloading = false,
    this.isUploading = false,
    this.isCancelled = false,
    this.actionName,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Loading animation
        if (isDownloading) ...[
          // Show download animation
          SizedBox(
            width: size,
            height: size,
            child: Lottie.asset(
              AppConstants.downloadAnimation,
              animate: !isCancelled,
            ),
          ),
        ] else if (isUploading) ...[
          // Show upload animation
          SizedBox(
            width: size,
            height: size,
            child: Lottie.asset(
              AppConstants.uploadAnimation,
              animate: !isCancelled,
            ),
          ),
        ] else ...[
          // Standard loading spinner
          SizedBox(
            width: size,
            height: size,
            child: Center(
              child: showProgress && progress != null
                  ? CircularProgressIndicator(
                      color: isCancelled ? AppTheme.errorColor : AppTheme.primaryColor,
                      value: progress! / 100,
                    )
                  : CircularProgressIndicator(
                      color: isCancelled ? AppTheme.errorColor : AppTheme.primaryColor,
                    ),
            ),
          ),
        ],
        
        // Optional message
        if (message != null) ...[
          const SizedBox(height: AppTheme.spacingMedium),
          Text(
            message!,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isCancelled ? AppTheme.errorColor : null,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        
        // Progress text with action name
        if (showProgress && progress != null) ...[
          const SizedBox(height: AppTheme.spacingSmall),
          Text(
            actionName != null 
                ? '$actionName: ${progress!.toInt()}%' 
                : '${progress!.toInt()}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isCancelled ? AppTheme.errorColor : null,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (useScaffold) {
      return Scaffold(
        body: Center(child: content),
      );
    }

    return Center(child: content);
  }
} 