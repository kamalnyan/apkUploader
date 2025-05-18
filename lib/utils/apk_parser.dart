import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'helpers.dart';

/// Model class to hold APK information
class APKInfo {
  final String? appName;
  final String? packageName;
  final String? versionName;
  final int? versionCode;
  final int? minSdkVersion;
  final int? targetSdkVersion;
  final int sizeBytes;
  final String? installerName;
  final String? developer;
  final List<String>? permissions;
  final String? sdkVersionString;

  APKInfo({
    this.appName,
    this.packageName,
    this.versionName,
    this.versionCode,
    this.minSdkVersion,
    this.targetSdkVersion,
    this.sizeBytes = 0,
    this.installerName,
    this.developer,
    this.permissions,
    this.sdkVersionString,
  });
}

/// Utility class to parse APK files and extract metadata
class APKParser {
  static const _methodChannel = MethodChannel('com.apkuploader/apk_parser');

  /// Get information from an APK file
  static Future<APKInfo?> getAPKInfo(String apkFilePath) async {
    try {
      // Get file size regardless of method channel
      final file = File(apkFilePath);
      final fileSize = await file.length();
      final fileName = path.basename(file.path);
      
      try {
        // Call native method to extract APK info
        final result = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>(
          'getApkInfo',
          {'apkFilePath': apkFilePath},
        );
        
        if (result == null) {
          return _fallbackGetApkInfo(apkFilePath);
        }
        
        // Parse permissions list
        List<String> permissions = [];
        final permissionsList = result['permissions'] as List<dynamic>?;
        if (permissionsList != null) {
          permissions = permissionsList.map((p) => p.toString()).toList();
        }
        
        // Format SDK version string
        String? sdkVersionString;
        final minSdk = result['minSdkVersion'] as int?;
        if (minSdk != null) {
          sdkVersionString = _getSdkVersionString(minSdk);
        }
        
        return APKInfo(
          appName: result['appName'] as String?,
          packageName: result['packageName'] as String?,
          versionName: result['versionName'] as String?,
          versionCode: result['versionCode'] as int?,
          minSdkVersion: minSdk,
          targetSdkVersion: result['targetSdkVersion'] as int?,
          sizeBytes: fileSize,
          installerName: result['installerName'] as String?,
          developer: result['developer'] as String?,
          permissions: permissions,
          sdkVersionString: sdkVersionString,
        );
      } catch (e) {
        logger.e('Error in native APK parsing: $e');
        return _fallbackGetApkInfo(apkFilePath);
      }
    } catch (e) {
      logger.e('Error parsing APK: $e');
      return null;
    }
  }
  
  /// Fallback method to extract basic information from APK
  /// This won't work for all properties, but it's better than nothing
  static Future<APKInfo?> _fallbackGetApkInfo(String apkFilePath) async {
    try {
      final file = File(apkFilePath);
      final fileName = path.basename(file.path);
      
      // Use filename as a fallback for app name (removing extension)
      final appName = path.basenameWithoutExtension(fileName);
      
      // Try to get file size
      final fileSize = await file.length();
      
      // Get version from filename if it contains version pattern
      String? versionName;
      final versionRegex = RegExp(r'[vV]?(\d+\.\d+\.\d+|\d+\.\d+)');
      final versionMatch = versionRegex.firstMatch(fileName);
      if (versionMatch != null) {
        versionName = versionMatch.group(1);
      }
      
      // Try to infer a package name from the filename
      String? packageName;
      String nameWithoutExt = path.basenameWithoutExtension(fileName);
      if (nameWithoutExt.isNotEmpty) {
        // Remove version pattern if present
        nameWithoutExt = nameWithoutExt.replaceAll(versionRegex, '');
        
        // Create a package-like name
        packageName = nameWithoutExt
            .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '.')
            .replaceAll(RegExp(r'\.+'), '.')
            .toLowerCase();
        
        // Remove leading/trailing dots
        packageName = packageName.replaceAll(RegExp(r'^\.+|\.+$'), '');
        
        // Add domain if missing
        if (!packageName.contains('.')) {
          packageName = 'com.example.$packageName';
        }
      }
      
      // Unfortunately we can't get other metadata without native code
      return APKInfo(
        appName: appName,
        packageName: packageName,
        versionName: versionName,
        versionCode: null,
        minSdkVersion: null,
        targetSdkVersion: null,
        sizeBytes: fileSize,
      );
    } catch (e) {
      logger.e('Error in fallback APK parsing: $e');
      return null;
    }
  }
  
  /// Map SDK version number to Android version name
  static String _getSdkVersionString(int sdkVersion) {
    final sdkVersionMap = {
      21: 'Android 5.0 (Lollipop)',
      22: 'Android 5.1 (Lollipop)',
      23: 'Android 6.0 (Marshmallow)',
      24: 'Android 7.0 (Nougat)',
      25: 'Android 7.1 (Nougat)',
      26: 'Android 8.0 (Oreo)',
      27: 'Android 8.1 (Oreo)',
      28: 'Android 9.0 (Pie)',
      29: 'Android 10',
      30: 'Android 11',
      31: 'Android 12',
      32: 'Android 12L',
      33: 'Android 13',
      34: 'Android 14',
      35: 'Android 15',
    };
    
    return sdkVersionMap[sdkVersion] ?? 'Android $sdkVersion+';
  }
} 