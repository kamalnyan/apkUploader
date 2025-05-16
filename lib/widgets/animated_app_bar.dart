import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/theme.dart';

/// An animated AppBar with hero animations and transitions
class AnimatedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final bool showElevation;
  final Color? backgroundColor;
  
  /// Constructor
  const AnimatedAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.showElevation = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    
    return AppBar(
      title: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      )
        .animate()
        .fadeIn(duration: AppTheme.shortAnimationDuration)
        .slideX(begin: -0.1, end: 0, duration: AppTheme.shortAnimationDuration),
      centerTitle: centerTitle,
      leading: leading != null 
        ? leading!
            .animate()
            .fadeIn(duration: AppTheme.shortAnimationDuration)
            .scale(begin: const Offset(0.8, 0.8), alignment: Alignment.center)
        : null,
      actions: actions != null 
        ? List.generate(
            actions!.length,
            (index) => actions![index]
              .animate()
              .fadeIn(duration: AppTheme.shortAnimationDuration)
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
                duration: AppTheme.shortAnimationDuration,
              ),
          )
        : null,
      backgroundColor: backgroundColor ?? (isDarkMode ? const Color(0xFF1E1E1E) : AppTheme.cardColor),
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      shadowColor: Colors.transparent,
      foregroundColor: isDarkMode ? Colors.white : AppTheme.textDarkColor,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
} 