import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Logger instance for application-wide logging
final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
    printTime: true,
  ),
);

/// Utility functions for the application
class AppHelpers {
  // Private constructor to prevent instantiation
  AppHelpers._();

  /// Format a DateTime object to a readable string
  static String formatDateTime(DateTime dateTime) {
    final formatter = DateFormat('MMM dd, yyyy - HH:mm');
    return formatter.format(dateTime);
  }

  /// Format file size in bytes to a human-readable format
  static String formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    
    const List<String> suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    int i = (math.log(bytes) / math.log(1024)).floor();
    
    return '${(bytes / math.pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
  }

  /// Check if the device is iOS
  static bool isIOS() => Platform.isIOS;

  /// Check if the device is Android
  static bool isAndroid() => Platform.isAndroid;

  /// Show a snackbar message
  static void showSnackBar(
    BuildContext context, 
    String message, 
    {
      bool isError = false,
      SnackBarAction? action,
      Duration? duration,
    }
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError 
            ? Theme.of(context).colorScheme.error 
            : Theme.of(context).primaryColor,
        behavior: SnackBarBehavior.floating,
        duration: duration ?? const Duration(seconds: 3),
        action: action,
      ),
    );
  }

  /// Get a temporary directory path for downloading files
  static Future<String> getTemporaryDirectoryPath() async {
    final directory = await getTemporaryDirectory();
    return directory.path;
  }

  /// Get a downloads directory path
  static Future<String> getDownloadsDirectoryPath() async {
    if (Platform.isAndroid) {
      final directory = await getExternalStorageDirectory();
      return directory?.path ?? (await getTemporaryDirectory()).path;
    } else if (Platform.isIOS) {
      final directory = await getApplicationDocumentsDirectory();
      return directory.path;
    }
    
    throw UnsupportedError('Unsupported platform');
  }

  /// Launch a URL
  static Future<bool> launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return true;
    }
    return false;
  }

  /// Check if a string is a valid URL
  static bool isValidUrl(String url) {
    final urlPattern = RegExp(
      r'^(https?:\/\/)?' // protocol
      r'((([a-z\d]([a-z\d-]*[a-z\d])*)\.)+[a-z]{2,}|' // domain name
      r'((\d{1,3}\.){3}\d{1,3}))' // OR ip (v4) address
      r'(\:\d+)?(\/[-a-z\d%_.~+]*)*' // port and path
      r'(\?[;&a-z\d%_.~+=-]*)?' // query string
      r'(\#[-a-z\d_]*)?$', // fragment locator
      caseSensitive: false,
    );
    return urlPattern.hasMatch(url);
  }

  /// Open app settings
  static Future<void> openAppSettings() async {
    await AppSettings.openAppSettings();
  }

  /// Generate a unique file name based on timestamp
  static String generateUniqueFileName(String originalName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = originalName.split('.').last;
    return 'file_$timestamp.$extension';
  }

  /// Capitalize the first letter of a string
  static String capitalizeFirstLetter(String text) {
    if (text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Validate and fix Firebase Storage URL
  static String fixFirebaseStorageUrl(String? url) {
    if (url == null || url.isEmpty) {
      return '';
    }

    // Firebase Storage bucket name from google-services.json
    const String firebaseBucket = 'apk-uploader-8feb8.appspot.com';

    try {
      // If the URL is already valid, return it
      if (Uri.parse(url).isAbsolute) {
        // Add alt=media parameter for Firebase Storage URLs if missing
        if (url.contains('firebasestorage.googleapis.com')) {
          final uri = Uri.parse(url);
          final queryParams = Map<String, String>.from(uri.queryParameters);
          queryParams['alt'] = 'media';
          return uri.replace(queryParameters: queryParams).toString();
        }
        return url;
      }

      // Check if it's a Firebase Storage path without the full URL
      if (url.startsWith('gs://')) {
        // Convert gs:// URL to HTTPS URL
        final pathWithoutPrefix = url.replaceAll('gs://$firebaseBucket/', '').replaceAll('gs://', '');
        return 'https://firebasestorage.googleapis.com/v0/b/$firebaseBucket/o/${Uri.encodeComponent(pathWithoutPrefix)}?alt=media';
      } else if (url.startsWith('/')) {
        // Handle path starting with slash
        final path = url.startsWith('/') ? url.substring(1) : url;
        return 'https://firebasestorage.googleapis.com/v0/b/$firebaseBucket/o/${Uri.encodeComponent(path)}?alt=media';
      }

      // If the URL appears to be a relative path in storage
      if (!url.contains('://') && !url.contains(' ')) {
        // Ensure the path is properly encoded
        final encodedPath = url.split('/').map(Uri.encodeComponent).join('/');
        return 'https://firebasestorage.googleapis.com/v0/b/$firebaseBucket/o/$encodedPath?alt=media';
      }

      // If we can't handle the URL format, return empty string
      logger.e('Unsupported URL format: $url');
      return '';
    } catch (e) {
      logger.e('Error fixing Firebase Storage URL: $e');
      return '';
    }
  }

  /// Check and request storage permission
  static Future<bool> checkAndRequestStoragePermission(BuildContext context) async {
    if (!Platform.isAndroid) {
      return true; // Only Android needs explicit storage permission
    }
    
    // Check Android version
    int androidVersion = 0;
    try {
      final versionString = Platform.operatingSystemVersion.split('.').first;
      androidVersion = int.tryParse(versionString.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
      logger.i('Android version detected: $androidVersion');
    } catch (e) {
      logger.e('Error parsing OS version: $e');
    }
    
    // For Android 11+ (API 30+), we need to handle "All files access" permission
    if (androidVersion >= 30) {
      logger.i('Android 11+ detected, checking for All files access permission');
      
      // Check if we have the manage external storage permission
      PermissionStatus allFilesStatus = await Permission.manageExternalStorage.status;
      
      if (allFilesStatus.isGranted) {
        logger.i('All files access permission already granted');
        return true;
      }
      
      // First try regular storage permission as it's less intrusive
      PermissionStatus storageStatus = await Permission.storage.status;
      if (storageStatus.isGranted) {
        logger.i('Standard storage permission granted, might be sufficient');
        return true;
      }
      
      // Request standard storage permission first
      logger.i('Requesting storage permission');
      storageStatus = await Permission.storage.request();
      
      if (storageStatus.isGranted) {
        logger.i('Storage permission granted');
        return true;
      }
      
      // If standard storage isn't enough, we need to request All files access
      logger.i('Standard storage permission denied or insufficient, requesting All files access');
      
      // Show an explanation dialog
      if (context.mounted) {
        bool shouldProceed = await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Storage Access Required'),
            content: const Text(
              'This app needs permission to access your storage to download and install APKs. '
              'On Android 11+, this requires "All files access" permission.\n\n'
              'You will be redirected to a settings page to enable this permission.'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Continue'),
              ),
            ],
          ),
        ) ?? false;
        
        if (!shouldProceed) {
          logger.w('User cancelled All files access permission request');
          return false;
        }
        
        // Request the All files access permission
        // This redirects to a special settings page
        allFilesStatus = await Permission.manageExternalStorage.request();
        
        // Check the result after returning from settings
        if (allFilesStatus.isGranted) {
          logger.i('All files access permission granted');
          return true;
        } else {
          logger.w('All files access permission not granted: $allFilesStatus');
          
          // Show additional guidance if permission is still not granted
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Storage permission is required to download APKs. Please enable "All files access".'
                ),
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Settings',
                  onPressed: () => openAppSettings(),
                ),
              ),
            );
          }
          return false;
        }
      }
      return false;
    }
    
    // For Android 10 and below, use the regular storage permission
    // Check if already granted
    PermissionStatus status = await Permission.storage.status;
    
    // If already granted, return true
    if (status.isGranted) {
      logger.i('Standard storage permission already granted');
      return true;
    }
    
    // Request standard storage permission
    logger.i('Requesting storage permission');
    status = await Permission.storage.request();
    
    if (status.isGranted) {
      logger.i('Storage permission granted');
      return true;
    }
    
    // If we reach here, permission wasn't granted
    logger.w('Storage permission not granted, status: $status');
    
    // Check if we should show a dialog
    if (status.isPermanentlyDenied) {
      // Show dialog to open settings
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Storage Permission Required'),
            content: const Text(
              'Storage permission is required to download APKs. Please enable it in app settings.'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
      }
    } else {
      // Show a prompt to try again
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Storage permission is required to download APKs'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Try Again',
              onPressed: () async {
                if (!context.mounted) return; // Check context before async gap
                // Try again
                final retryStatus = await Permission.storage.request();
                if (!context.mounted) return; // Check context after async gap

                if (!retryStatus.isGranted) {
                  // If still denied after trying again, offer to open settings
                  showDialog(
                    context: context, // Use the original context
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Permission Still Denied'),
                      content: const Text(
                        'Storage permission is crucial for downloading APKs. Please enable it in app settings to continue.'
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            openAppSettings(); // Function to open app settings
                          },
                          child: const Text('Open Settings'),
                        ),
                      ],
                    ),
                  );
                } else {
                  // Optional: show a success message or let the original flow continue
                  // This might be useful for immediate feedback if the user is waiting.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Storage permission granted! You can now try the action again.'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              },
            ),
          ),
        );
      }
    }
    
    return false;
  }

  /// Get the app version
  static Future<String> getAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    return '${info.version} (${info.buildNumber})';
  }
  
  /// Check if email is valid
  static bool isValidEmail(String email) {
    // Email regex pattern
    const pattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
    final regex = RegExp(pattern);
    return regex.hasMatch(email);
  }
}

/// Extension methods for BuildContext
extension BuildContextExtensions on BuildContext {
  /// Get the current theme
  ThemeData get theme => Theme.of(this);
  
  /// Get the current text theme
  TextTheme get textTheme => Theme.of(this).textTheme;
  
  /// Get the current color scheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  
  /// Get the screen size
  Size get screenSize => MediaQuery.of(this).size;
  
  /// Get the screen width
  double get screenWidth => MediaQuery.of(this).size.width;
  
  /// Get the screen height
  double get screenHeight => MediaQuery.of(this).size.height;
  
  /// Check if the device is in dark mode
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  
  /// Check if the device is in landscape orientation
  bool get isLandscape => MediaQuery.of(this).orientation == Orientation.landscape;
  
  /// Navigate to a named route
  Future<T?> pushNamed<T extends Object?>(String routeName, {Object? arguments}) {
    return Navigator.of(this).pushNamed<T>(routeName, arguments: arguments);
  }
  
  /// Replace the current route with a named route
  Future<T?> pushReplacementNamed<T extends Object?, TO extends Object?>(
    String routeName, {
    TO? result,
    Object? arguments,
  }) {
    return Navigator.of(this).pushReplacementNamed<T, TO>(
      routeName,
      result: result,
      arguments: arguments,
    );
  }
  
  /// Pop the current route
  void pop<T extends Object?>([T? result]) {
    Navigator.of(this).pop<T>(result);
  }
} 