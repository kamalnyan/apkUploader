import 'package:flutter/material.dart';

/// A component that displays APK installation progress with a modern UI
class InstallationProgress extends StatelessWidget {
  final double progress;
  final String status;
  final VoidCallback? onCancel;
  final VoidCallback? onRetry;
  final bool showActions;
  final bool isComplete;
  final bool isError;

  const InstallationProgress({
    super.key,
    required this.progress,
    required this.status,
    this.onCancel,
    this.onRetry,
    this.showActions = true,
    this.isComplete = false,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isComplete 
                    ? (isError ? Icons.error : Icons.check_circle) 
                    : Icons.downloading,
                  color: isError 
                    ? Colors.red 
                    : (isComplete ? Colors.green : colorScheme.primary),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isError ? Colors.red : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!isComplete && !isError)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: progress / 100,
                    backgroundColor: colorScheme.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                    borderRadius: BorderRadius.circular(4),
                    minHeight: 8,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${progress.toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            if (showActions && (onCancel != null || onRetry != null))
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onCancel != null)
                      TextButton(
                        onPressed: onCancel,
                        style: TextButton.styleFrom(
                          foregroundColor: colorScheme.onSurfaceVariant,
                        ),
                        child: const Text('Cancel'),
                      ),
                    if (onRetry != null)
                      FilledButton.tonal(
                        onPressed: onRetry,
                        child: const Text('Retry'),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A component that displays the installation success UI
class InstallationSuccess extends StatelessWidget {
  final String appName;
  final String? iconUrl;
  final VoidCallback? onDone;

  const InstallationSuccess({
    super.key,
    required this.appName,
    this.iconUrl,
    this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Installation Complete!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$appName has been successfully installed.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (onDone != null)
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: FilledButton(
                  onPressed: onDone,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(120, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Done'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A dialog that shows the installation progress
class InstallationProgressDialog extends StatelessWidget {
  final double progress;
  final String status;
  final VoidCallback? onCancel;
  final bool isComplete;
  final bool isError;
  final VoidCallback? onDone;

  const InstallationProgressDialog({
    super.key,
    required this.progress,
    required this.status,
    this.onCancel,
    this.isComplete = false,
    this.isError = false,
    this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isComplete && !isError)
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 48,
              )
            else if (isError)
              const Icon(
                Icons.error,
                color: Colors.red,
                size: 48,
              )
            else
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(),
              ),
            const SizedBox(height: 24),
            Text(
              isComplete
                  ? (isError ? 'Installation Failed' : 'Installation Complete')
                  : 'Installing APK',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              status,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (!isComplete && !isError)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: LinearProgressIndicator(
                  value: progress > 0 ? progress / 100 : null,
                  borderRadius: BorderRadius.circular(4),
                  minHeight: 8,
                ),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isComplete && onCancel != null)
                  TextButton(
                    onPressed: onCancel,
                    child: const Text('Cancel'),
                  )
                else if (isComplete && onDone != null)
                  FilledButton(
                    onPressed: onDone,
                    child: const Text('Done'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 