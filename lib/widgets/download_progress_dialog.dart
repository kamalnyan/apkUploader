import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../core/theme.dart';
import '../core/constants.dart';

enum DownloadStatus {
  downloading,
  installing,
  complete,
  error,
  permissionRequired
}

class DownloadProgressDialog extends StatelessWidget {
  final String fileName;
  final double progress;
  final DownloadStatus status;
  final String? message;
  final VoidCallback? onCancel;
  final VoidCallback? onRetry;
  final VoidCallback? onSettings;
  final Stream<double>? downloadStream;

  const DownloadProgressDialog({
    Key? key,
    required this.fileName,
    required this.progress,
    required this.status,
    this.message,
    this.onCancel,
    this.onRetry,
    this.onSettings,
    this.downloadStream,
    String? apkName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Auto-dismiss dialog if status is complete after a short delay
    if (status == DownloadStatus.complete) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      });
    }
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      ),
      elevation: AppTheme.elevationSmall,
      backgroundColor: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              _getTitle(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: _getTitleColor(context),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            // Animation
            Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                color: status == DownloadStatus.error || status == DownloadStatus.permissionRequired
                    ? AppTheme.errorColor.withOpacity(0.05)
                    : status == DownloadStatus.complete
                        ? AppTheme.successColor.withOpacity(0.05)
                        : AppTheme.primaryColor.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: _buildAnimation(context),
            ),
            
            const SizedBox(height: 24),
            
            // Progress indicator
            if (status == DownloadStatus.downloading || status == DownloadStatus.installing) ...[
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                      child: LinearProgressIndicator(
                        value: progress / 100,
                        minHeight: 8,
                        backgroundColor: AppTheme.surfaceColor,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          status == DownloadStatus.downloading 
                              ? AppTheme.primaryColor 
                              : AppTheme.successColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    "${progress.toInt()}%",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            
            // Message
            Text(
              message ?? _getDefaultMessage(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _buildButtons(context),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildButtons(BuildContext context) {
    switch (status) {
      case DownloadStatus.downloading:
      case DownloadStatus.installing:
        return [
          if (onCancel != null)
            AppTheme.textLinkButton(
              text: 'Cancel',
              onPressed: onCancel!,
            ),
        ];
      
      case DownloadStatus.complete:
        return [
          AppTheme.primaryButton(
            text: 'Done',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ];
        
      case DownloadStatus.error:
        return [
          if (onRetry != null) ...[
            AppTheme.secondaryButton(
              text: 'Retry',
              onPressed: () {
                Navigator.of(context).pop();
                onRetry?.call();
              },
            ),
            const SizedBox(width: 12),
          ],
          AppTheme.textLinkButton(
            text: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ];
        
      case DownloadStatus.permissionRequired:
        return [
          AppTheme.textLinkButton(
            text: 'Cancel',
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 12),
          AppTheme.primaryButton(
            text: 'Open Settings',
            onPressed: () {
              Navigator.of(context).pop();
              onSettings?.call();
            },
          ),
        ];
    }
  }

  Widget _buildAnimation(BuildContext context) {
    switch (status) {
      case DownloadStatus.downloading:
        return Lottie.asset(
          'assets/animations/download_animation.json',
          repeat: true,
          frameRate: FrameRate.max,
          errorBuilder: (context, error, stackTrace) {
            return CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              strokeWidth: 3,
            );
          },
        );
      case DownloadStatus.installing:
        return Lottie.asset(
          'assets/animations/installing_animation.json',
          repeat: true,
          frameRate: FrameRate.max,
          errorBuilder: (context, error, stackTrace) {
            return CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.successColor),
              strokeWidth: 3,
            );
          },
        );
      case DownloadStatus.complete:
        return Lottie.asset(
          'assets/animations/success_animation.json',
          repeat: false,
          frameRate: FrameRate.max,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.check_circle,
              size: 70,
              color: AppTheme.successColor,
            );
          },
        );
      case DownloadStatus.error:
      case DownloadStatus.permissionRequired:
        return Lottie.asset(
          'assets/animations/error_animation.json',
          repeat: false,
          frameRate: FrameRate.max,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.error,
              size: 70,
              color: AppTheme.errorColor,
            );
          },
        );
    }
  }

  String _getTitle() {
    switch (status) {
      case DownloadStatus.downloading:
        return 'Downloading $fileName';
      case DownloadStatus.installing:
        return 'Installing $fileName';
      case DownloadStatus.complete:
        return 'Installation Complete';
      case DownloadStatus.error:
        return 'Download Failed';
      case DownloadStatus.permissionRequired:
        return 'Permission Required';
    }
  }

  String _getDefaultMessage() {
    switch (status) {
      case DownloadStatus.downloading:
        return 'Please wait while we download the APK...';
      case DownloadStatus.installing:
        return 'Preparing to install the application...';
      case DownloadStatus.complete:
        return 'The APK was successfully downloaded and is being installed.';
      case DownloadStatus.error:
        return 'There was a problem downloading the APK. Please check your internet connection and try again.';
      case DownloadStatus.permissionRequired:
        return 'Storage permission is required to download and install APKs.';
    }
  }

  Color _getTitleColor(BuildContext context) {
    switch (status) {
      case DownloadStatus.downloading:
      case DownloadStatus.installing:
        return Theme.of(context).textTheme.titleLarge!.color!;
      case DownloadStatus.complete:
        return AppTheme.successColor;
      case DownloadStatus.error:
      case DownloadStatus.permissionRequired:
        return AppTheme.errorColor;
    }
  }
} 