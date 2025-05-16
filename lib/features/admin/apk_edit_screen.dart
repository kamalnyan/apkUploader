// Existing imports and code above...

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:permission_handler/permission_handler.dart' as AppSettings;

class PermissionManager {
  static Future<bool> requestStoragePermission(BuildContext context) async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    final androidInfo = await deviceInfoPlugin.androidInfo;
    final sdkInt = androidInfo.version.sdkInt;
    
    // Android 13+ (API 33+)
    if (sdkInt >= 33) {
      // For Android 13+, we need to request more granular permissions
      // Request read media storage permission
      final readMedia = await Permission.photos.request();
      final readMediaImages = await Permission.photos.request();
      final readMediaVideo = await Permission.videos.request();
      
      if (readMedia.isGranted || readMediaImages.isGranted || readMediaVideo.isGranted) {
        return true;
      }
      
      // If permissions are denied, show explanation dialog
      if (context != null) {
        await _showPermissionExplanationDialog(context, sdkInt);
      }
      
      return false;
    }
    // Android 11-12 (API 30-32)
    else if (sdkInt >= 30) {
      // Request special storage access for Android 11-12
      final status = await Permission.manageExternalStorage.request();
      
      if (status.isGranted) {
        return true;
      }
      
      // If permission is denied, show explanation dialog
      if (context != null) {
        await _showPermissionExplanationDialog(context, sdkInt);
      }
      
      return false;
    }
    // Android 10 and below
    else {
      final status = await Permission.storage.request();
      
      if (status.isGranted) {
        return true;
      }
      
      // If permission is denied, show explanation dialog
      if (context != null && status.isPermanentlyDenied) {
        await _showPermissionExplanationDialog(context, sdkInt);
      }
      
      return status.isGranted;
    }
  }
  
  // Show dialog explaining permissions
  static void showPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Storage Permission Required'),
        content: Text('This app needs storage access to upload and manage APK files. Please grant the required permissions in the next screen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await requestStoragePermission(context);
            },
            child: Text('Continue'),
          ),
        ],
      ),
    );
  }
  
  // Show a detailed explanation dialog based on Android version
  static Future<void> _showPermissionExplanationDialog(BuildContext context, int sdkVersion) async {
    String title = 'Permission Required';
    String message = '';
    String settingsButtonText = 'Open Settings';
    
    if (sdkVersion >= 33) { // Android 13+
      message = 'For Android 13 and above, this app needs permission to access photos and media to upload APK files. Please grant the required permissions in the settings.';
    } else if (sdkVersion >= 30) { // Android 11-12
      message = 'For Android 11 and 12, this app needs "All files access" permission to upload and manage APK files. Please enable this permission in the settings.';
    } else { // Android 10 and below
      message = 'This app needs storage permission to upload and manage APK files. Please grant the permission in the settings.';
    }
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await AppSettings.openAppSettings();
            },
            child: Text(settingsButtonText),
          ),
        ],
      ),
    );
  }
}

// Rest of the existing code below...