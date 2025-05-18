import 'dart:io';
import 'dart:math';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import '../utils/helpers.dart';
import '../utils/storage_permission_handler.dart';
import '../utils/notification_helper.dart';
import '../components/installation_progress.dart';

/// Result class for download operations
class DownloadResult {
  final bool success;
  final bool installStarted;
  final String? error;
  final bool needsSettings;
  final bool hasAction;
  final String? actionLabel;
  
  DownloadResult({
    required this.success,
    required this.installStarted,
    this.error,
    required this.needsSettings,
    this.hasAction = false,
    this.actionLabel,
  });
}

/// Platform channel for native Android installation
const _channel = MethodChannel('com.apkuploader/install');

/// Keys for shared preferences
const String _pendingInstallKey = 'pending_install_path';

/// Service for handling APK downloads and installation
class DownloadService {
  /// Download an APK file from a URL
  /// 
  /// Returns the local file path if successful
  Future<String?> downloadAPK(
    String url, 
    String fileName, {
    Function(double)? onProgress,
    bool showNotification = true,
  }) async {
    final int downloadId = Random().nextInt(1000);
    
    try {
      // Request storage permission on Android
      if (Platform.isAndroid) {
        // Use the new StoragePermissionHandler
        bool hasPermission = await StoragePermissionHandler.checkStoragePermission();
        if (!hasPermission) {
          logger.e('Storage permission denied');
          return null;
        }
      }

      // Enhanced URL validation
      if (url.isEmpty) {
        logger.e('Empty URL provided');
        if (showNotification) {
          await NotificationHelper.showDownloadNotification(
            id: downloadId,
            title: 'Download Failed',
            body: 'No URL provided',
            progress: 0,
          );
        }
        return null;
      }

      // Try to fix Firebase Storage URL if needed
      String finalUrl = url;
      if (!Uri.parse(url).isAbsolute || !AppHelpers.isValidUrl(url)) {
        final fixedUrl = AppHelpers.fixFirebaseStorageUrl(url);
        if (fixedUrl.isNotEmpty) {
          finalUrl = fixedUrl;
          logger.i('Fixed Firebase Storage URL: $finalUrl');
        } else {
          logger.e('Invalid URL format: $url');
          if (showNotification) {
            await NotificationHelper.showDownloadNotification(
              id: downloadId,
              title: 'Download Failed',
              body: 'Invalid URL format',
              progress: 0,
            );
          }
          return null;
        }
      }

      // Validate the final URL
      try {
        final uri = Uri.parse(finalUrl);
        if (!uri.isAbsolute) {
          throw FormatException('URL is not absolute');
        }
      } catch (e) {
        logger.e('Invalid URL format: $e');
        if (showNotification) {
          await NotificationHelper.showDownloadNotification(
            id: downloadId,
            title: 'Download Failed',
            body: 'Invalid URL format: ${e.toString()}',
            progress: 0,
          );
        }
        return null;
      }

      // Get the download directory
      final downloadPath = await AppHelpers.getDownloadsDirectoryPath();
      final saveDir = Directory(downloadPath);
      
      if (!saveDir.existsSync()) {
        saveDir.createSync(recursive: true);
      }
      
      // Create a unique filename
      final uniqueFileName = AppHelpers.generateUniqueFileName(fileName);
      final filePath = path.join(downloadPath, uniqueFileName);
      
      // Create the file
      final file = File(filePath);
      
      // Show initial notification
      if (showNotification) {
        await NotificationHelper.showDownloadNotification(
          id: downloadId,
          title: 'Downloading APK',
          body: 'Starting download for $fileName',
          progress: 0,
        );
      }
      
      // First try to get HEAD info to determine file size
      int totalBytes = 0;
      try {
        final headResponse = await http.head(Uri.parse(finalUrl));
        if (headResponse.statusCode == 200) {
          final contentLength = headResponse.headers['content-length'];
          if (contentLength != null && contentLength.isNotEmpty) {
            totalBytes = int.tryParse(contentLength) ?? 0;
            if (totalBytes == 0) {
              logger.w('Invalid content-length header: $contentLength');
            }
          }
        }
      } catch (e) {
        logger.w('Could not determine file size: ${e.toString()}');
      }
      
      // Download with progress tracking
      try {
        final uri = Uri.parse(finalUrl);
        final request = http.Request('GET', uri);
        final response = await http.Client().send(request);
        
        if (response.statusCode == 200) {
          final fileStream = file.openWrite();
          int downloadedBytes = 0;
          
          await for (final chunk in response.stream) {
            fileStream.add(chunk);
            downloadedBytes += chunk.length;
            
            // Calculate progress (handle division by zero)
            final progress = totalBytes > 0 
              ? (downloadedBytes / totalBytes * 100).round() 
              : 0;
            
            // Update progress
            onProgress?.call(progress.toDouble());
            
            // Update notification
            if (showNotification && progress % 10 == 0 && totalBytes > 0) {
              await NotificationHelper.showDownloadNotification(
                id: downloadId,
                title: 'Downloading $fileName',
                body: '${progress.round()}% complete',
                progress: progress.round(),
              );
            } else if (showNotification && downloadedBytes % (1024 * 100) == 0) {
              await NotificationHelper.showDownloadNotification(
                id: downloadId,
                title: 'Downloading $fileName',
                body: '${(downloadedBytes / 1024).round()} KB downloaded',
                progress: 50,
              );
            }
          }
          
          await fileStream.close();
          
          // Verify APK file integrity
          if (file.lengthSync() < 1000) {
            logger.e('Downloaded file is too small to be a valid APK');
            if (showNotification) {
              await NotificationHelper.showDownloadNotification(
                id: downloadId,
                title: 'Download Failed',
                body: 'Invalid APK file received',
                progress: 0,
              );
            }
            file.deleteSync();
            return null;
          }
          
          // Show completion notification
          if (showNotification) {
            await NotificationHelper.showDownloadNotification(
              id: downloadId,
              title: 'Download Complete',
              body: '$fileName is ready to install',
              progress: 100,
            );
          }
          
          return filePath;
        } else {
          if (showNotification) {
            await NotificationHelper.showDownloadNotification(
              id: downloadId,
              title: 'Download Failed',
              body: 'Server returned error code: ${response.statusCode}',
              progress: 0,
            );
          }
          throw Exception('Failed to download APK: ${response.statusCode}');
        }
      } catch (e) {
        logger.e('Error downloading APK content: $e');
        if (file.existsSync()) {
          file.deleteSync();
        }
        rethrow;
      }
    } catch (e) {
      logger.e('Error downloading APK: $e');
      
      if (showNotification) {
        await NotificationHelper.showDownloadNotification(
          id: downloadId,
          title: 'Download Failed',
          body: 'Error: ${e.toString().substring(0, min(50, e.toString().length))}',
          progress: 0,
        );
      }
      
      return null;
    }
  }

  /// Install an APK on Android devices
  /// 
  /// Returns true if installation was initiated successfully
  Future<bool> installAPK(String filePath, {bool showNotification = true}) async {
    final int installId = Random().nextInt(1000) + 1000; // Different range from download IDs
    
    try {
      if (Platform.isAndroid) {
        // Save the file path for resuming installation if permissions are needed
        await _savePendingInstallPath(filePath);
        
        // Show notification
        if (showNotification) {
          await NotificationHelper.showInstallationNotification(
            id: installId,
            title: 'Installing APK',
            body: 'Preparing to install application',
          );
        }
        
        // Check if we have permission to install packages
        final hasPermission = await _channel.invokeMethod<bool>(
          'hasInstallPermission',
        ) ?? false;
        
        if (!hasPermission) {
          // Request permission to install packages
          if (showNotification) {
            await NotificationHelper.showInstallationNotification(
              id: installId,
              title: 'Permission Required',
              body: 'Please grant permission to install applications',
            );
          }
          
          // Ask user to grant permission - this will open system settings
          await _channel.invokeMethod<bool>('requestInstallPermission');
          
          // We need to return false here because the user needs to grant permission first
          // When the app resumes, we'll check for pending installations
          return false;
        }
        
        // We have permission, proceed with installation
        final result = await _channel.invokeMethod<bool>(
          'installAPK',
          {'filePath': filePath},
        );
        
        // If successful, clear the pending installation
        if (result == true) {
          await _clearPendingInstallPath();
        }
        
        // Show notification based on result
        if (showNotification) {
          if (result == true) {
            await NotificationHelper.showInstallationNotification(
              id: installId,
              title: 'Installation Started',
              body: 'Follow the on-screen instructions to complete installation',
              isComplete: true,
            );
          } else {
            await NotificationHelper.showInstallationNotification(
              id: installId,
              title: 'Installation Failed',
              body: 'Could not start installation',
              isComplete: true,
            );
          }
        }
        
        return result ?? false;
      } else {
        // Not supported on iOS
        return false;
      }
    } catch (e) {
      logger.e('Error installing APK: $e');
      
      if (showNotification) {
        await NotificationHelper.showInstallationNotification(
          id: installId,
          title: 'Installation Error',
          body: 'Failed to install application',
          isComplete: true,
        );
      }
      
      return false;
    }
  }
  
  /// Install an APK using a session-based approach (better user experience)
  /// 
  /// Returns true if installation was initiated successfully
  Future<bool> installAPKWithSession(String filePath, {bool showNotification = true}) async {
    final int installId = Random().nextInt(1000) + 2000; // Different range from other IDs
    
    try {
      if (Platform.isAndroid) {
        // Save the file path for resuming installation if permissions are needed
        await _savePendingInstallPath(filePath);
        
        // Show notification
        if (showNotification) {
          await NotificationHelper.showInstallationNotification(
            id: installId,
            title: 'Installing APK',
            body: 'Preparing session-based installation',
          );
        }
        
        // Check if we have permission to install packages
        final hasPermission = await _channel.invokeMethod<bool>(
          'hasInstallPermission',
        ) ?? false;
        
        if (!hasPermission) {
          // Request permission to install packages
          if (showNotification) {
            await NotificationHelper.showInstallationNotification(
              id: installId,
              title: 'Permission Required',
              body: 'Please grant permission to install applications',
            );
          }
          
          // Ask user to grant permission - this will open system settings
          await _channel.invokeMethod<bool>('requestInstallPermission');
          
          // We need to return false here because the user needs to grant permission first
          // When the app resumes, we'll check for pending installations
          return false;
        }
        
        // We have permission, proceed with installation
        // Show in-progress notification
        if (showNotification) {
          await NotificationHelper.showInstallationNotification(
            id: installId,
            title: 'Installing APK',
            body: 'Setting up installation session',
          );
        }
        
        final result = await _channel.invokeMethod<bool>(
          'installAPKWithSession',
          {'filePath': filePath},
        );
        
        // If successful, clear the pending installation
        if (result == true) {
          await _clearPendingInstallPath();
        }
        
        // Show notification based on result
        if (showNotification) {
          if (result == true) {
            await NotificationHelper.showInstallationNotification(
              id: installId,
              title: 'Installation Started',
              body: 'Follow the on-screen instructions to complete installation',
              isComplete: true,
            );
          } else {
            await NotificationHelper.showInstallationNotification(
              id: installId,
              title: 'Installation Failed',
              body: 'Could not start installation session',
              isComplete: true,
            );
          }
        }
        
        return result ?? false;
      } else {
        // Not supported on iOS
        return false;
      }
    } catch (e) {
      logger.e('Error installing APK with session: $e');
      
      if (showNotification) {
        await NotificationHelper.showInstallationNotification(
          id: installId,
          title: 'Installation Error',
          body: 'Failed to install application: ${e.toString().substring(0, min(50, e.toString().length))}',
          isComplete: true,
        );
      }
      
      return false;
    }
  }
  
  /// Check and resume any pending APK installation
  /// Call this when the app resumes
  Future<bool> checkAndResumeInstallation(BuildContext? context) async {
    if (!Platform.isAndroid) return false;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingPath = prefs.getString(_pendingInstallKey);
      
      if (pendingPath == null || pendingPath.isEmpty) {
        return false; // No pending installation
      }
      
      // Check if file still exists
      final file = File(pendingPath);
      if (!await file.exists()) {
        await _clearPendingInstallPath();
        return false;
      }
      
      // Check if we now have permission to install packages
      final hasPermission = await _channel.invokeMethod<bool>(
        'hasInstallPermission',
      ) ?? false;
      
      if (!hasPermission) {
        // Still don't have permission, show a message
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please grant permission to install APKs'),
              duration: Duration(seconds: 5),
            ),
          );
        }
        return false;
      }
      
      // We have permission now, resume installation
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Resuming installation...'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      // Use the session-based installation for better user experience
      final result = await installAPKWithSession(pendingPath);
      
      // Clear pending installation regardless of result
      await _clearPendingInstallPath();
      
      return result;
    } catch (e) {
      logger.e('Error resuming installation: $e');
      await _clearPendingInstallPath();
      return false;
    }
  }
  
  /// Save the file path of a pending installation
  Future<void> _savePendingInstallPath(String filePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pendingInstallKey, filePath);
    } catch (e) {
      logger.e('Error saving pending install path: $e');
    }
  }
  
  /// Clear the pending installation path
  Future<void> _clearPendingInstallPath() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingInstallKey);
    } catch (e) {
      logger.e('Error clearing pending install path: $e');
    }
  }

  /// Download and automatically install an APK
  /// 
  /// Returns a DownloadResult with status information
  Future<DownloadResult> downloadAndInstallAPK(
    BuildContext context,
    String url, 
    String fileName, {
    Function(double)? onProgress,
    bool useSession = true,
    bool showNotifications = true,
    bool showModernUI = true,
  }) async {
    // Cancellation token
    final cancelToken = CancellationToken();
    double downloadProgress = 0;
    
    // Show modern installation UI if requested
    if (showModernUI) {
      // Show dialog with progress
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setState) {
            return InstallationProgressDialog(
              progress: downloadProgress,
              status: downloadProgress == 0 
                ? 'Preparing to download...'
                : (downloadProgress < 100 
                    ? 'Downloading $fileName...' 
                    : 'Preparing to install...'),
              onCancel: cancelToken.isCancelled ? null : () {
                cancelToken.cancel();
                Navigator.of(dialogContext).pop();
              },
              isComplete: false,
            );
          }
        ),
      );
    } else {
      // Show downloading message with classic UI
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Downloading APK...'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
    
    try {
      // Download the APK
      final filePath = await downloadAPK(
        url, 
        fileName, 
        onProgress: (progress) {
          downloadProgress = progress;
          onProgress?.call(progress);
          
          // Update UI if showing modern dialog
          if (showModernUI && context.mounted) {
            // Trigger rebuild of the dialog
            (context as Element).markNeedsBuild();
          }
        },
        showNotification: showNotifications,
      );
      
      // Close download dialog if shown
      if (showModernUI && context.mounted) {
        Navigator.of(context).pop();
      }
      
      if (filePath == null) {
        if (context.mounted) {
          if (showModernUI) {
            // Show error dialog
            showDialog(
              context: context,
              builder: (context) => InstallationProgressDialog(
                progress: 0,
                status: 'Failed to download APK. Please check permissions and try again.',
                isComplete: true,
                isError: true,
                onDone: () => Navigator.of(context).pop(),
              ),
            );
          } else {
            // Show classic error
            AppHelpers.showSnackBar(
              context, 
              'Failed to download APK. Please check permissions and try again.', 
              isError: true,
            );
          }
        }
        return DownloadResult(
          success: false,
          installStarted: false,
          error: 'Failed to download APK file',
          needsSettings: true,
          hasAction: false,
        );
      }
      
      // Show installation progress
      if (showModernUI && context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => InstallationProgressDialog(
            progress: 100,
            status: 'Installing $fileName...',
            isComplete: false,
          ),
        );
      } else if (context.mounted) {
        // Show classic installation message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Installing APK...'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      // Install the APK
      bool installed;
      if (useSession) {
        // Use session-based installation for better user experience
        installed = await installAPKWithSession(
          filePath,
          showNotification: showNotifications,
        );
      } else {
        // Use standard installation
        installed = await installAPK(
          filePath,
          showNotification: showNotifications,
        );
      }
      
      // Close installation dialog if shown
      if (showModernUI && context.mounted) {
        Navigator.of(context).pop();
      }
      
      if (!installed) {
        if (context.mounted) {
          if (showModernUI) {
            // Show permission required dialog
            showDialog(
              context: context,
              builder: (context) => InstallationProgressDialog(
                progress: 0,
                status: 'Please grant permission to install applications.',
                isComplete: true,
                isError: true,
                onDone: () => Navigator.of(context).pop(),
              ),
            );
          } else {
            // Show classic error
            AppHelpers.showSnackBar(
              context, 
              'Please grant installation permission and try again.', 
              isError: true,
            );
          }
        }
      } else if (showModernUI && context.mounted) {
        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => InstallationProgressDialog(
            progress: 100,
            status: 'Installation has started. Please follow the on-screen instructions to complete installation.',
            isComplete: true,
            isError: false,
            onDone: () => Navigator.of(context).pop(),
          ),
        );
      }
      
      return DownloadResult(
        success: installed,
        installStarted: installed,
        error: installed ? null : 'Installation permission denied',
        needsSettings: !installed,
        hasAction: false,
      );
    } catch (e) {
      logger.e('Error downloading and installing APK: $e');
      
      // Close any open dialogs
      if (showModernUI && context.mounted) {
        Navigator.of(context).pop();
        
        // Show error dialog
        showDialog(
          context: context,
          builder: (context) => InstallationProgressDialog(
            progress: 0,
            status: 'Error: ${e.toString()}',
            isComplete: true,
            isError: true,
            onDone: () => Navigator.of(context).pop(),
          ),
        );
      } else if (context.mounted) {
        AppHelpers.showSnackBar(
          context, 
          'Failed to install APK: ${e.toString()}', 
          isError: true,
        );
      }
      
      return DownloadResult(
        success: false,
        installStarted: false,
        error: e.toString(),
        needsSettings: false,
        hasAction: false,
      );
    }
  }

  /// Show installation message based on platform
  void showInstallMessage(BuildContext context) {
    if (Platform.isIOS) {
      // Show iOS specific message
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Not Supported'),
          content: const Text(AppConstants.iosInstallMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  /// Request storage permission on Android
  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      // Use StoragePermissionHandler without UI (dialog will be shown by caller if needed)
      return await StoragePermissionHandler.checkStoragePermission();
    }
    return true; // Non-Android platforms don't need this permission check
  }
  
  /// Alias method for checkAndResumeInstallation for backward compatibility
  Future<DownloadResult> resumeAnyPendingInstallation() async {
    final wasResumed = await checkAndResumeInstallation(null);
    return DownloadResult(
      success: wasResumed,
      installStarted: wasResumed,
      error: wasResumed ? null : "No pending installation found",
      needsSettings: false,
      hasAction: false,
    );
  }
}

/// Simple cancellation token for download operations
class CancellationToken {
  bool _isCancelled = false;
  
  bool get isCancelled => _isCancelled;
  
  void cancel() {
    _isCancelled = true;
  }
} 