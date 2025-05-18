import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;

import '../utils/helpers.dart';

/// Service to analyze APK files and extract information
class APKAnalyzerService {
  /// Extract metadata from an APK file
  Future<Map<String, dynamic>> extractApkMetadata(File apkFile) async {
    try {
      final Map<String, dynamic> metadata = {
        'fileName': path.basename(apkFile.path),
        'sizeBytes': apkFile.lengthSync(),
        'fileSizeReadable': _formatFileSize(apkFile.lengthSync()),
        'lastModified': apkFile.lastModifiedSync(),
      };

      // Read APK as ZIP file (APK files are ZIP archives)
      final bytes = await apkFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // Find and parse the AndroidManifest.xml
      final manifestFile = archive.findFile('AndroidManifest.xml');
      if (manifestFile != null) {
        // Parse binary XML (this is simplified; real parsing needs a binary XML parser)
        // Here we're looking for text fragments that might contain the package info
        final manifestBytes = manifestFile.content as List<int>;
        final manifestString = String.fromCharCodes(manifestBytes);
        
        // Extract package name using regex patterns (very simplified)
        metadata['packageName'] = _safeExtractRegexMatch(manifestString, r'package="([^"]+)"') ?? '';
        metadata['versionName'] = _safeExtractRegexMatch(manifestString, r'versionName="([^"]+)"') ?? '';
        metadata['versionCode'] = int.tryParse(_safeExtractRegexMatch(manifestString, r'versionCode="([^"]+)"') ?? '0') ?? 0;
        metadata['minSdk'] = int.tryParse(_safeExtractRegexMatch(manifestString, r'minSdkVersion="([^"]+)"') ?? '0') ?? 0;
        metadata['targetSdk'] = int.tryParse(_safeExtractRegexMatch(manifestString, r'targetSdkVersion="([^"]+)"') ?? '0') ?? 0;
      }

      // Check for resources and other assets
      metadata['hasAssets'] = archive.findFile('assets/') != null;
      metadata['hasResources'] = archive.findFile('res/') != null;
      
      // Count resource types
      final drawables = archive.files.where((file) => 
        file.name.startsWith('res/drawable') || 
        file.name.startsWith('res/mipmap')).length;
      metadata['drawableCount'] = drawables;
      
      // Check for native libraries
      final hasNativeLibs = archive.files.any((file) => file.name.startsWith('lib/'));
      metadata['hasNativeLibraries'] = hasNativeLibs;
      
      // Check for common architectures
      metadata['architectures'] = [];
      if (hasNativeLibs) {
        if (archive.files.any((file) => file.name.startsWith('lib/armeabi-v7a/'))) {
          metadata['architectures'].add('armeabi-v7a');
        }
        if (archive.files.any((file) => file.name.startsWith('lib/arm64-v8a/'))) {
          metadata['architectures'].add('arm64-v8a');
        }
        if (archive.files.any((file) => file.name.startsWith('lib/x86/'))) {
          metadata['architectures'].add('x86');
        }
        if (archive.files.any((file) => file.name.startsWith('lib/x86_64/'))) {
          metadata['architectures'].add('x86_64');
        }
      }

      // Detect common libraries/frameworks
      metadata['detectedLibraries'] = [];
      
      // Check for Firebase
      if (archive.files.any((file) => 
          file.name.contains('firebase') || 
          file.name.contains('com/google/firebase'))) {
        metadata['detectedLibraries'].add('Firebase');
      }
      
      // Check for ads
      if (archive.files.any((file) => 
          file.name.contains('admob') || 
          file.name.contains('com/google/android/gms/ads'))) {
        metadata['detectedLibraries'].add('AdMob');
      }
      
      // Check for analytics
      if (archive.files.any((file) => 
          file.name.contains('analytics') || 
          file.name.contains('com/google/android/gms/analytics'))) {
        metadata['detectedLibraries'].add('Analytics');
      }
      
      // Check for Flutter
      if (archive.files.any((file) => 
          file.name.contains('flutter') || 
          file.name.contains('io/flutter'))) {
        metadata['detectedLibraries'].add('Flutter');
      }
      
      // Check for React Native
      if (archive.files.any((file) => 
          file.name.contains('reactnative') || 
          file.name.contains('com/facebook/react'))) {
        metadata['detectedLibraries'].add('React Native');
      }

      return metadata;
    } catch (e) {
      logger.e('Error analyzing APK: $e');
      return {
        'error': 'Failed to analyze APK file: ${e.toString()}',
        'sizeBytes': apkFile.lengthSync(),
        'fileName': path.basename(apkFile.path),
      };
    }
  }

  /// Safely extract a regex match from a string
  String? _safeExtractRegexMatch(String input, String pattern) {
    try {
      final match = RegExp(pattern).firstMatch(input);
      if (match != null && match.groupCount >= 1) {
        return match.group(1);
      }
    } catch (e) {
      logger.e('Error extracting regex match: $e');
    }
    return null;
  }

  /// Format file size for display
  String _formatFileSize(int bytes) {
    return AppHelpers.formatFileSize(bytes);
  }
} 