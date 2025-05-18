import 'dart:io';

import 'package:flutter/material.dart';

import '../../services/firebase_service.dart';
import '../../utils/helpers.dart';
import '../models/firebase_models.dart';
import '../models/model_adapter.dart';
import '../models/apk_model.dart';

/// Provider class for managing APK data
class APKProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  
  List<FirebaseAPK> _apks = [];
  List<FirebaseAPK> _pinnedApks = [];
  List<FirebaseAPK> _unpinnedApks = [];
  FirebaseAPK? _selectedApk;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<FirebaseAPK> get apks => _apks;
  List<FirebaseAPK> get pinnedApks => _pinnedApks;
  List<FirebaseAPK> get unpinnedApks => _unpinnedApks;
  FirebaseAPK? get selectedApk => _selectedApk;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasActiveUploads => _firebaseService.hasActiveUploads;

  /// Initialize the provider and set up streams
  void init() {
    _loadApks();
  }

  /// Load all APKs from Firebase
  Future<void> _loadApks() async {
    _setLoading(true);
    
    try {
      final apks = await _firebaseService.getApks();
      _apks = apks;
      _filterPinnedApks();
      _setLoading(false);
      notifyListeners();
    } catch (error) {
      logger.e('Error loading APKs: $error');
      _setErrorMessage('Failed to load APKs. Please try again.');
      _setLoading(false);
    }
  }

  /// Filter pinned and unpinned APKs
  void _filterPinnedApks() {
    _pinnedApks = _apks.where((apk) => apk.isPinned).toList();
    _unpinnedApks = _apks.where((apk) => !apk.isPinned).toList();
  }

  /// Select an APK
  void selectAPK(FirebaseAPK apk) {
    _selectedApk = apk;
    notifyListeners();
  }

  /// Clear selected APK
  void clearSelectedAPK() {
    _selectedApk = null;
    notifyListeners();
  }

  /// Cancel all active uploads
  Future<void> cancelUploads() async {
    await _firebaseService.cancelUploads();
    _setLoading(false);
  }

  /// Add a new APK
  Future<bool> addAPK({
    required String name,
    required String packageName,
    required String versionName,
    required int versionCode,
    required int minSdk,
    required int targetSdk,
    required String description,
    String? developer,
    String? minRequirements,
    String? playStoreUrl,
    List<String>? permissions,
    required File apkFile,
    required File? iconFile,
    required String apkFileName,
    required String? iconFileName,
    List<File>? screenshotFiles,
    List<String>? screenshotFileNames,
    required int sizeBytes,
    bool isPinned = false,
    // Additional fields
    String? category,
    String? releaseDate,
    String? languages,
    String? installInstructions,
    String? changelog,
    String? supportEmail,
    String? privacyPolicyUrl,
    bool isRestricted = false,
    String? downloadPassword,
    Function(double)? onProgress,
  }) async {
    try {
      _setLoading(true);
      
      final userId = _firebaseService.getCurrentUserId();
      
      // Upload APK file to Firebase Storage
      final apkUrl = await _firebaseService.uploadAPK(
        apkFile, 
        apkFileName,
        onProgress: onProgress != null 
          ? (progress) => onProgress(progress.toDouble()) 
          : null,
      );
      
      // Upload icon file to Firebase Storage if provided
      String? iconUrl;
      if (iconFile != null && iconFileName != null) {
        iconUrl = await _firebaseService.uploadIcon(
          iconFile, 
          iconFileName,
          onProgress: onProgress != null 
            ? (progress) => onProgress(progress.toDouble()) 
            : null,
        );
      }
      
      // Upload screenshots if provided
      List<String> screenshotUrls = [];
      if (screenshotFiles != null && screenshotFileNames != null) {
        screenshotUrls = await _firebaseService.uploadScreenshots(
          screenshotFiles, 
          screenshotFileNames,
          onProgress: onProgress != null 
            ? (progress) => onProgress(progress.toDouble()) 
            : null,
        );
      }
      
      final now = DateTime.now();
      
      // Create a new APK model with all the extracted metadata
      final newApk = FirebaseAPK(
        id: '', // Will be set by Firestore
        name: name,
        packageName: packageName,
        versionName: versionName,
        versionCode: versionCode,
        minSdk: minSdk,
        targetSdk: targetSdk,
        description: description,
        developer: developer,
        minRequirements: minRequirements,
        playStoreUrl: playStoreUrl,
        permissions: permissions ?? [],
        apkUrl: apkUrl,
        iconUrl: iconUrl,
        screenshots: screenshotUrls,
        sizeBytes: sizeBytes,
        isPinned: isPinned,
        downloads: 0,
        createdBy: userId,
        updatedBy: userId,
        createdAt: now,
        updatedAt: now,
        // Additional fields
        category: category,
        releaseDate: releaseDate,
        languages: languages,
        installInstructions: installInstructions,
        changelog: changelog,
        supportEmail: supportEmail,
        privacyPolicyUrl: privacyPolicyUrl,
        isRestricted: isRestricted,
        downloadPassword: downloadPassword,
      );
      
      // Add to Firebase
      await _firebaseService.addApk(newApk);
      
      // Refresh the list
      await _loadApks();
      
      _setLoading(false);
      return true;
    } catch (e) {
      logger.e('Error adding APK: $e');
      _setErrorMessage('Failed to add APK. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  /// Update an existing APK
  Future<bool> updateAPK({
    required String id,
    required String name,
    required String packageName,
    required String versionName,
    required int versionCode,
    required int minSdk,
    required int targetSdk,
    required String description,
    String? developer,
    String? minRequirements,
    String? playStoreUrl,
    List<String>? permissions,
    File? apkFile,
    File? iconFile,
    String? apkFileName,
    String? iconFileName,
    List<File>? newScreenshotFiles,
    List<String>? newScreenshotFileNames,
    List<String>? screenshotsToKeep,
    required int sizeBytes,
    bool? isPinned,
    // Additional fields
    String? category,
    String? releaseDate,
    String? languages,
    String? installInstructions,
    String? changelog,
    String? supportEmail,
    String? privacyPolicyUrl,
    bool? isRestricted,
    String? downloadPassword,
  }) async {
    try {
      _setLoading(true);
      
      final userId = _firebaseService.getCurrentUserId();
      
      // Get existing APK
      final existingApk = await _firebaseService.getApkById(id);
      
      if (existingApk == null) {
        _setErrorMessage('APK not found.');
        _setLoading(false);
        return false;
      }
      
      // Update APK file if provided
      String apkUrl = existingApk.apkUrl;
      if (apkFile != null && apkFileName != null) {
        // Delete existing APK file
        await _firebaseService.deleteFile(existingApk.apkUrl);
        
        // Upload new APK file
        apkUrl = await _firebaseService.uploadAPK(
          apkFile, 
          apkFileName,
        );
      }
      
      // Update icon file if provided
      String? iconUrl = existingApk.iconUrl;
      if (iconFile != null && iconFileName != null) {
        // Delete existing icon file if exists
        if (existingApk.iconUrl != null) {
          await _firebaseService.deleteFile(existingApk.iconUrl!);
        }
        
        // Upload new icon file
        iconUrl = await _firebaseService.uploadIcon(
          iconFile, 
          iconFileName,
        );
      }
      
      // Update screenshots if provided
      List<String> updatedScreenshots = [];
      
      // Add existing screenshots that should be kept
      if (screenshotsToKeep != null) {
        updatedScreenshots.addAll(screenshotsToKeep);
      }
      
      // Add new screenshots
      if (newScreenshotFiles != null && newScreenshotFileNames != null) {
        final newUrls = await _firebaseService.uploadScreenshots(
          newScreenshotFiles, 
          newScreenshotFileNames,
        );
        
        updatedScreenshots.addAll(newUrls);
      }
      
      // Delete screenshots that should not be kept
      final screenshotsToDelete = existingApk.screenshots
          .where((url) => screenshotsToKeep == null || !screenshotsToKeep.contains(url))
          .toList();
      
      for (final url in screenshotsToDelete) {
        await _firebaseService.deleteFile(url);
      }
      
      // Create the updated APK
      final updatedApk = existingApk.copyWith(
        name: name,
        packageName: packageName,
        versionName: versionName,
        versionCode: versionCode,
        minSdk: minSdk,
        targetSdk: targetSdk,
        description: description,
        developer: developer ?? existingApk.developer,
        minRequirements: minRequirements ?? existingApk.minRequirements,
        playStoreUrl: playStoreUrl ?? existingApk.playStoreUrl,
        permissions: permissions ?? existingApk.permissions,
        apkUrl: apkUrl,
        iconUrl: iconUrl,
        screenshots: updatedScreenshots,
        sizeBytes: sizeBytes,
        isPinned: isPinned,
        updatedBy: userId,
        updatedAt: DateTime.now(),
        // Additional fields
        category: category,
        releaseDate: releaseDate,
        languages: languages,
        installInstructions: installInstructions,
        changelog: changelog,
        supportEmail: supportEmail,
        privacyPolicyUrl: privacyPolicyUrl,
        isRestricted: isRestricted,
        downloadPassword: downloadPassword,
      );
      
      // Update in Firebase
      await _firebaseService.updateApk(updatedApk);
      
      // Refresh the list
      await _loadApks();
      
      _setLoading(false);
      return true;
    } catch (e) {
      logger.e('Error updating APK: $e');
      _setErrorMessage('Failed to update APK. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  /// Toggle pin status
  Future<bool> togglePinStatus(String id, bool isPinned) async {
    try {
      _setLoading(true);
      
      // Get existing APK first
      final existingApk = await _firebaseService.getApkById(id);
      
      if (existingApk == null) {
        _setErrorMessage('APK not found.');
        _setLoading(false);
        return false;
      }
      
      // Update pin status in Firestore
      await _firebaseService.togglePinStatus(id, isPinned);
      
      // Update local copy and notify listeners
      final index = _apks.indexWhere((apk) => apk.id == id);
      if (index != -1) {
        _apks[index] = _apks[index].copyWith(isPinned: isPinned);
        _filterPinnedApks(); // Re-filter pinned/unpinned lists
      }
      
      // Refresh the list to ensure consistency
      await _loadApks();
      _setLoading(false);
      
      // Return success
      return true;
    } catch (e) {
      logger.e('Error toggling pin status: $e');
      _setErrorMessage('Failed to update pin status. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  /// Delete APK
  Future<bool> deleteAPK(String id) async {
    try {
      _setLoading(true);
      
      // Get APK data first to get URLs for Firebase
      final apk = await _firebaseService.getApkById(id);
      
      if (apk == null) {
        _setErrorMessage('APK not found.');
        _setLoading(false);
        return false;
      }
      
      // Delete the APK from Firebase database
      await _firebaseService.deleteApk(id);
      
      // Delete the files from Firebase storage
      await _firebaseService.deleteFile(apk.apkUrl);
      
      if (apk.iconUrl != null) {
        await _firebaseService.deleteFile(apk.iconUrl!);
      }
      
      for (final url in apk.screenshots) {
        await _firebaseService.deleteFile(url);
      }
      
      // Refresh the list
      await _loadApks();
      
      _setLoading(false);
      return true;
    } catch (e) {
      logger.e('Error deleting APK: $e');
      _setErrorMessage('Failed to delete APK. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  /// Increment download count
  Future<void> incrementDownloadCount(String id) async {
    try {
      await _firebaseService.incrementDownloadCount(id);
      await _loadApks();
    } catch (e) {
      logger.e('Error incrementing download count: $e');
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) {
      _errorMessage = null;
    }
    notifyListeners();
  }

  void _setErrorMessage(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Convert to generic APK model list
  List<APKModel> getAPKModels() {
    return ModelAdapter.toAPKModelList(_apks);
  }

  /// Convert to generic APK model list (pinned only)
  List<APKModel> getPinnedAPKModels() {
    return ModelAdapter.toAPKModelList(_pinnedApks);
  }

  /// Convert to generic APK model list (unpinned only)
  List<APKModel> getUnpinnedAPKModels() {
    return ModelAdapter.toAPKModelList(_unpinnedApks);
  }
  
  /// Search APKs
  Future<List<APKModel>> searchAPKs(String query) async {
    try {
      if (query.isEmpty) {
        return ModelAdapter.toAPKModelList(_apks);
      }
      
      final results = await _firebaseService.searchAPKs(query);
      return ModelAdapter.toAPKModelList(results);
    } catch (e) {
      logger.e('Error searching APKs: $e');
      return [];
    }
  }
  
  /// Upload a new APK (compatibility method for older code)
  Future<bool> uploadAPK({
    required String name,
    required String packageName,
    required String version,
    required String? changelog,
    required String description,
    String? developer,
    String? minRequirements,
    String? playStoreUrl,
    List<String>? permissions,
    required File apkFile,
    required File? iconFile,
    required int sizeBytes,
    bool isPinned = false,
    List<File>? screenshotFiles,
    Function(double)? onProgress,
  }) async {
    final apkFileName = '${name.replaceAll(' ', '_')}_v${version}.apk';
    final iconFileName = iconFile != null ? '${name.replaceAll(' ', '_')}_icon.png' : null;
    
    List<String>? screenshotFileNames;
    if (screenshotFiles != null) {
      screenshotFileNames = [];
      for (int i = 0; i < screenshotFiles.length; i++) {
        screenshotFileNames.add('${name.replaceAll(' ', '_')}_screenshot_$i.png');
      }
    }
    
    // Parse version numbers
    int versionCode = 1;
    try {
      final parts = version.split('.');
      if (parts.length >= 2) {
        versionCode = int.parse(parts[0]) * 10000;
        versionCode += int.parse(parts[1]) * 100;
        if (parts.length >= 3) {
          versionCode += int.parse(parts[2]);
        }
      }
    } catch (e) {
      logger.e('Error parsing version: $e');
    }
    
    return addAPK(
      name: name,
      packageName: packageName,
      versionName: version,
      versionCode: versionCode,
      minSdk: 21, // Android 5.0
      targetSdk: 33, // Android 13
      description: description,
      developer: developer,
      minRequirements: minRequirements,
      playStoreUrl: playStoreUrl,
      permissions: permissions,
      apkFile: apkFile,
      iconFile: iconFile,
      apkFileName: apkFileName,
      iconFileName: iconFileName,
      screenshotFiles: screenshotFiles,
      screenshotFileNames: screenshotFileNames,
      sizeBytes: sizeBytes,
      isPinned: isPinned,
      onProgress: onProgress,
    );
  }
}