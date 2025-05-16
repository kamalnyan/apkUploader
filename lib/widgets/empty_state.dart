import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/theme.dart';

/// Widget to display when there is no data
class EmptyState extends StatelessWidget {
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final double animationSize;

  /// Constructor
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.animationSize = 200,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animation
            Animate(
              effects: [
                FadeEffect(duration: AppTheme.mediumAnimationDuration),
                ScaleEffect(
                  begin: const Offset(0.8, 0.8),
                  duration: AppTheme.mediumAnimationDuration,
                ),
              ],
              child: SizedBox(
                width: animationSize,
                height: animationSize,
                child: Icon(
                  Icons.inbox_outlined,
                  size: animationSize * 0.5,
                  color: AppTheme.primaryColor.withOpacity(0.5),
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
                SlideEffect(
                  begin: const Offset(0, 0.2),
                  end: const Offset(0, 0),
                  duration: AppTheme.mediumAnimationDuration,
                  delay: const Duration(milliseconds: 200),
                ),
              ],
              child: Text(
                title,
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingMedium),
            
            // Message
            Animate(
              effects: [
                FadeEffect(
                  duration: AppTheme.mediumAnimationDuration,
                  delay: const Duration(milliseconds: 300),
                ),
                SlideEffect(
                  begin: const Offset(0, 0.2),
                  end: const Offset(0, 0),
                  duration: AppTheme.mediumAnimationDuration,
                  delay: const Duration(milliseconds: 300),
                ),
              ],
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textLightColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            // Action button
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppTheme.spacingXl),
              
              Animate(
                effects: [
                  FadeEffect(
                    duration: AppTheme.mediumAnimationDuration,
                    delay: const Duration(milliseconds: 400),
                  ),
                  SlideEffect(
                    begin: const Offset(0, 0.2),
                    end: const Offset(0, 0),
                    duration: AppTheme.mediumAnimationDuration,
                    delay: const Duration(milliseconds: 400),
                  ),
                ],
                child: AppTheme.primaryButton(
                  text: actionLabel!,
                  onPressed: onAction!,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 