import 'package:flutter/material.dart';

import '../core/theme.dart';

/// A loading indicator widget with animation
class LoadingIndicator extends StatelessWidget {
  final String? message;
  final double size;
  final bool useScaffold;
  final double? progress;
  final bool showProgress;

  /// Constructor
  const LoadingIndicator({
    super.key,
    this.message,
    this.size = 200,
    this.useScaffold = false,
    this.progress,
    this.showProgress = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Loading animation
        SizedBox(
          width: size,
          height: size,
          child: Center(
            child: showProgress && progress != null
                ? CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                    value: progress! / 100,
                  )
                : CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                  ),
          ),
        ),
        
        // Optional message
        if (message != null) ...[
          const SizedBox(height: AppTheme.spacingMedium),
          Text(
            message!,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ],
        
        // Progress text
        if (showProgress && progress != null) ...[
          const SizedBox(height: AppTheme.spacingSmall),
          Text(
            '${progress!.toInt()}%',
            style: Theme.of(context).textTheme.bodySmall,
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