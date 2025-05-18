import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../core/theme.dart';
import 'helpers.dart';
import 'package:flutter/services.dart';

/// Dedicated class for handling storage permissions across Android versions
class StoragePermissionHandler {
  // Check if the device is running Android 11 (API 30) or higher
  static Future<bool> _isAndroid11OrHigher() async {
    if (!Platform.isAndroid) return false;
    
    try {
      final deviceInfoPlugin = DeviceInfoPlugin();
      final androidInfo = await deviceInfoPlugin.androidInfo;
      return androidInfo.version.sdkInt >= 30;
    } catch (e) {
      logger.e('Error determining Android version: $e');
      return false;
    }
  }
  
  /// Check storage permission status based on Android version
  static Future<bool> checkStoragePermission() async {
    if (!Platform.isAndroid) return true;
    
    try {
      final deviceInfoPlugin = DeviceInfoPlugin();
      final androidInfo = await deviceInfoPlugin.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;
      
      // MANAGE_EXTERNAL_STORAGE is sufficient for all Android versions
      // Check this first since it has the highest privileges
      if (await Permission.manageExternalStorage.isGranted) {
        logger.i('MANAGE_EXTERNAL_STORAGE permission is granted - sufficient for all Android versions');
        return true;
      }
      
      // Android 13+ (API 33+)
      if (sdkInt >= 33) {
        logger.i('Checking media permissions for Android 13+');
        return await Permission.photos.isGranted || 
               await Permission.videos.isGranted;
      }
      // For Android 10 and below, check regular storage permission
      else if (sdkInt < 30) {
        // For older Android versions, check storage permission
        logger.i('Checking storage permission for older Android');
        return await Permission.storage.isGranted;
      }
      
      // For Android 11-12 without MANAGE_EXTERNAL_STORAGE, we don't have proper permissions
      logger.i('Android 11-12 requires MANAGE_EXTERNAL_STORAGE permission which is not granted');
      return false;
    } catch (e) {
      logger.e('Error checking storage permission: $e');
      return false;
    }
  }
  
  /// Alias method for checkStoragePermission for backward compatibility
  @deprecated
  static Future<bool> hasStoragePermission() => checkStoragePermission();
  
  /// Request appropriate storage permissions based on Android version
  static Future<bool> requestStoragePermission(BuildContext context) async {
    if (!Platform.isAndroid) return true;
    
    try {
      logger.i('Requesting storage permissions for all Android versions');

      // Check if MANAGE_EXTERNAL_STORAGE is already granted (this is sufficient for all versions)
      if (await Permission.manageExternalStorage.isGranted) {
        logger.i('MANAGE_EXTERNAL_STORAGE already granted - no further permissions needed');
        return true;
      }
      
      // Get Android version for version-specific handling
      final deviceInfoPlugin = DeviceInfoPlugin();
      final androidInfo = await deviceInfoPlugin.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      // First show unified explanation dialog
      if (context.mounted) {
        final shouldProceed = await showExplanationDialog(context);
        if (!shouldProceed) {
          return false;
        }
      }
      
      // Check if we already have permissions
      final basicStorageGranted = await Permission.storage.isGranted;
      
      if (basicStorageGranted && sdkInt < 30) {
        logger.i('Basic storage permission already granted (sufficient for Android < 11)');
        return true;
      }
      
      // For Android 11+ (API 30+), we need MANAGE_EXTERNAL_STORAGE
      if (sdkInt >= 30) {
        logger.i('Detected Android 11+ (API $sdkInt), handling MANAGE_EXTERNAL_STORAGE specially');
        
        // Request the permission - might not directly grant but open settings
        logger.i('Requesting MANAGE_EXTERNAL_STORAGE permission');
        final status = await Permission.manageExternalStorage.request();
        logger.i('MANAGE_EXTERNAL_STORAGE permission status: $status');
        
        if (status.isGranted) {
          return true;
        }
        
        // If not granted, direct user to special storage settings
        if (context.mounted) {
          final openedSettings = await openAllFilesAccessSettings();
          if (!openedSettings && context.mounted) {
            // If we couldn't open settings directly, show manual instructions
            await showAllFilesAccessInstructions(context);
          }
          
          // Wait for user to potentially grant permission in settings
          await Future.delayed(const Duration(seconds: 3));
          
          // Check again if permission was granted
          final isGrantedAfterSettings = await Permission.manageExternalStorage.isGranted;
          logger.i('MANAGE_EXTERNAL_STORAGE after settings: $isGrantedAfterSettings');
          
          if (isGrantedAfterSettings) {
            return true;
          }
        }
        
        // Fall back to media permissions for Android 13+
        if (sdkInt >= 33) {
          logger.i('Falling back to media permissions for Android 13+');
          final photosStatus = await Permission.photos.request();
          final videosStatus = await Permission.videos.request();
          
          logger.i('Photos permission status: $photosStatus');
          logger.i('Videos permission status: $videosStatus');
          
          if (photosStatus.isGranted || videosStatus.isGranted) {
            return true;
          }
        }
        
        // If all else fails, show settings dialog
        if (context.mounted) {
          await showUnifiedPermissionSettingsDialog(context);
        }
        
        return false;
      }
      // For Android 10 and below
      else {
        // Try standard storage permission
        logger.i('Requesting basic storage permission for Android 10 and below');
        final storageStatus = await Permission.storage.request();
        logger.i('Storage permission status: $storageStatus');
        
        if (storageStatus.isGranted) {
          return true;
        }
        
        // If denied, show settings dialog
        if (context.mounted) {
          await showUnifiedPermissionSettingsDialog(context);
        }
        
        return false;
      }
    } catch (e) {
      logger.e('Error requesting storage permission: $e');
      return false;
    }
  }
  
  /// Try to open the special all files access settings page directly
  static Future<bool> openAllFilesAccessSettings() async {
    try {
      const methodChannel = MethodChannel('com.apkuploader/permissions');
      final opened = await methodChannel.invokeMethod<bool>('openAllFilesAccessSettings') ?? false;
      return opened;
    } catch (e) {
      logger.e('Error opening all files access settings: $e');
      return false;
    }
  }
  
  /// Show detailed instructions for enabling all files access for Android 11+
  static Future<void> showAllFilesAccessInstructions(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('All Files Access Required'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.folder_open,
                size: 48,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 16),
              const Text(
                'For Android 11 and above, APK Uploader needs "All files access" permission.',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Please follow these steps:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildInstructionStep(1, 'Tap "Open Settings" below'),
              _buildInstructionStep(2, 'Select "Files and media" or "Special app access"'),
              _buildInstructionStep(3, 'Find and tap "All files access" or "Files and media"'),
              _buildInstructionStep(4, 'Find "APK Uploader" and enable the toggle'),
              _buildInstructionStep(5, 'Return to the app'),
              const SizedBox(height: 16),
              Text(
                'This permission is required to download and manage APK files.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[700],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: <Widget>[
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
  
  /// Build an instruction step with number and text
  static Widget _buildInstructionStep(int stepNumber, String instruction) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$stepNumber',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              instruction,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Show unified explanation dialog for all Android versions
  static Future<bool> showExplanationDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Permission Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'APK Uploader needs storage permission to:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildPermissionReason(Icons.download_rounded, 'Download APK files'),
            _buildPermissionReason(Icons.install_mobile_rounded, 'Install applications'),
            _buildPermissionReason(Icons.folder, 'Store files temporarily'),
            const SizedBox(height: 16),
            Text(
              'Please grant all requested permissions in the following screens. You may need to enable additional permissions in Settings depending on your Android version.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }
  
  /// Build a permission reason row with icon and text
  static Widget _buildPermissionReason(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
  
  /// Show unified settings dialog for all Android versions
  static Future<void> showUnifiedPermissionSettingsDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Storage Permission Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.folder_open,
              size: 48,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 16),
            const Text(
              'Storage permission was denied.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'APK Uploader needs storage access to function properly. Please open settings and:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              '• On Android 11+: Enable "Allow access to manage all files"\n'
              '• On Android 13+: Grant photos and videos access\n'
              '• On older Android: Enable storage permission',
              textAlign: TextAlign.left,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: <Widget>[
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
  
  /// Request all app permissions at once
  static Future<bool> requestAllPermissions(
    BuildContext context, {
    bool forceRequest = false,
  }) async {
    if (!Platform.isAndroid) return true;
    
    // Request storage permissions
    bool storagePermissionGranted = false;
    if (forceRequest) {
      storagePermissionGranted = await requestStoragePermission(context);
    } else {
      final hasPermission = await checkStoragePermission();
      if (hasPermission) {
        logger.i('All permissions granted successfully');
        storagePermissionGranted = true;
      } else {
        storagePermissionGranted = await requestStoragePermission(context);
      }
    }
    
    // If storage permission was denied, stop here
    if (!storagePermissionGranted) {
      return false;
    }
    
    // Android 8.0+ requires a special permission for package installation
    if (Platform.isAndroid) {
      try {
        // Use method channel to check and request install permission
        const channel = MethodChannel('com.apkuploader/install');
        final hasInstallPermission = await channel.invokeMethod<bool>('hasInstallPermission') ?? false;
        
        if (!hasInstallPermission) {
          // Show a dialog explaining why this permission is needed
          if (context.mounted) {
            final shouldProceed = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) => AlertDialog(
                title: const Text('Installation Permission Required'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'APK Uploader needs permission to install packages:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildPermissionReason(Icons.android, 'Install Android applications'),
                    const SizedBox(height: 16),
                    Text(
                      'You will need to enable "Install unknown apps" in the next screen.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                actions: <Widget>[
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                    child: const Text('Not Now'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Continue'),
                  ),
                ],
              ),
            );
            
            if (shouldProceed != true) {
              return false;
            }
            
            // Request the permission
            await channel.invokeMethod<bool>('requestInstallPermission');
            
            // This will likely open settings, so we won't know immediately if permission was granted
            // We'll assume it's in progress and check when action is complete
            return true;
          }
          return false;
        }
      } catch (e) {
        logger.e('Error checking install permission: $e');
      }
    }
    
    return storagePermissionGranted;
  }
}