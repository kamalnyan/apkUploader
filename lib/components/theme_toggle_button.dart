import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/providers/app_provider.dart';

/// A button that toggles between dark and light mode
class ThemeToggleButton extends StatelessWidget {
  /// Whether to show as a switch (true) or icon button (false)
  final bool asSwitch;
  
  /// Size of the icon button (ignored if asSwitch is true)
  final double? size;
  
  /// Callback that will be called after theme change
  final VoidCallback? onChanged;

  /// Creates a theme toggle button
  const ThemeToggleButton({
    super.key,
    this.asSwitch = false,
    this.size,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final isDarkMode = appProvider.isDarkMode;
        final colorScheme = Theme.of(context).colorScheme;
        
        if (asSwitch) {
          return SwitchListTile(
            title: const Text('Dark Mode'),
            secondary: Icon(
              isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: isDarkMode ? Colors.amber : colorScheme.primary,
            ),
            value: isDarkMode,
            onChanged: (value) {
              appProvider.toggleTheme();
              onChanged?.call();
            },
          );
        }
        
        return IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              isDarkMode ? Icons.dark_mode : Icons.light_mode,
              key: ValueKey<bool>(isDarkMode),
              color: isDarkMode ? Colors.amber : colorScheme.primary,
              size: size,
            ),
          ),
          tooltip: isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
          onPressed: () {
            appProvider.toggleTheme();
            onChanged?.call();
          },
        );
      },
    );
  }
}

/// A floating action button that toggles between dark and light mode
class ThemeToggleFAB extends StatelessWidget {
  /// Callback that will be called after theme change
  final VoidCallback? onChanged;

  /// Creates a theme toggle floating action button
  const ThemeToggleFAB({
    super.key,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final isDarkMode = appProvider.isDarkMode;
        final colorScheme = Theme.of(context).colorScheme;
        
        return FloatingActionButton(
          heroTag: 'theme_toggle_fab',
          onPressed: () {
            appProvider.toggleTheme();
            onChanged?.call();
          },
          tooltip: isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
          child: Icon(
            isDarkMode ? Icons.light_mode : Icons.dark_mode,
            color: isDarkMode 
                ? Colors.black 
                : colorScheme.onPrimaryContainer,
          ),
          backgroundColor: isDarkMode 
              ? Colors.amber 
              : colorScheme.primaryContainer,
        );
      },
    );
  }
} 