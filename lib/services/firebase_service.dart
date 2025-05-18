import 'dart:io';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as path;

import '../utils/helpers.dart';
import '../core/models/firebase_models.dart';

/// Service class to handle Firebase operations
class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Track active uploads to allow cancellation
  final Map<String, UploadTask> _activeUploads = {};
  final Map<String, StreamSubscription> _activeListeners = {};
  bool _uploadCancelled = false;
  
  // Storage paths
  static const String _apksPath = 'apks';
  static const String _screenshotsPath = 'screenshots';
  static const String _iconsPath = 'icons';
  
  // Collection names
  static const String _apksCollection = 'apk_uploads';
  static const String _usersCollection = 'users';

  /// Check if there are active uploads
  bool get hasActiveUploads => _activeUploads.isNotEmpty;
  
  /// Cancel all active uploads
  Future<void> cancelUploads() async {
    _uploadCancelled = true;
    
    // Cancel all listeners first
    for (final subscription in _activeListeners.values) {
      await subscription.cancel();
    }
    _activeListeners.clear();
    
    // Then cancel all tasks
    for (final task in _activeUploads.values) {
      try {
        task.cancel();
      } catch (e) {
        logger.e('Error cancelling upload: $e');
      }
    }
    _activeUploads.clear();
  }

  /// Get all APKs from the database
  Future<List<FirebaseAPK>> getApks() async {
    try {
      final snapshot = await _firestore
          .collection(_apksCollection)
          .orderBy('created_at', descending: true)
          .get();
      
      final apks = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Add document ID to the data
        return FirebaseAPK.fromMap(data);
      }).toList();
      
      return apks;
    } catch (e) {
      logger.e('Error getting APKs from Firebase: $e');
      rethrow;
    }
  }
  
  /// Get pinned APKs
  Future<List<FirebaseAPK>> getPinnedApks() async {
    try {
      final snapshot = await _firestore
          .collection(_apksCollection)
          .where('is_pinned', isEqualTo: true)
          .orderBy('created_at', descending: true)
          .get();
      
      final apks = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return FirebaseAPK.fromMap(data);
      }).toList();
      
      return apks;
    } catch (e) {
      logger.e('Error getting pinned APKs from Firebase: $e');
      rethrow;
    }
  }
  
  /// Get unpinned APKs
  Future<List<FirebaseAPK>> getUnpinnedApks() async {
    try {
      final snapshot = await _firestore
          .collection(_apksCollection)
          .where('is_pinned', isEqualTo: false)
          .orderBy('created_at', descending: true)
          .get();
      
      final apks = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return FirebaseAPK.fromMap(data);
      }).toList();
      
      return apks;
    } catch (e) {
      logger.e('Error getting unpinned APKs from Firebase: $e');
      rethrow;
    }
  }
  
  /// Search APKs by name or package name
  Future<List<FirebaseAPK>> searchAPKs(String query) async {
    try {
      // Firestore doesn't support direct text search, so we'll get all APKs
      // and filter them on the client side
      final snapshot = await _firestore
          .collection(_apksCollection)
          .orderBy('created_at', descending: true)
          .get();
      
      final apks = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return FirebaseAPK.fromMap(data);
      }).where((apk) {
        final name = apk.name.toLowerCase();
        final packageName = apk.packageName.toLowerCase();
        final description = apk.description?.toLowerCase() ?? '';
        final searchQuery = query.toLowerCase();
        
        return name.contains(searchQuery) || 
               packageName.contains(searchQuery) ||
               description.contains(searchQuery);
      }).toList();
      
      return apks;
    } catch (e) {
      logger.e('Error searching APKs in Firebase: $e');
      rethrow;
    }
  }
  
  /// Get an APK by ID
  Future<FirebaseAPK?> getApkById(String id) async {
    try {
      final doc = await _firestore
          .collection(_apksCollection)
          .doc(id)
          .get();
      
      if (!doc.exists) {
        return null;
      }
      
      final data = doc.data()!;
      data['id'] = doc.id;
      return FirebaseAPK.fromMap(data);
    } catch (e) {
      logger.e('Error getting APK by ID from Firebase: $e');
      return null;
    }
  }
  
  /// Add a new APK to the database
  Future<String> addApk(FirebaseAPK apk) async {
    try {
      final docRef = await _firestore
          .collection(_apksCollection)
          .add(apk.toMap());
      
      return docRef.id;
    } catch (e) {
      logger.e('Error adding APK to Firebase: $e');
      rethrow;
    }
  }
  
  /// Update an existing APK
  Future<void> updateApk(FirebaseAPK apk) async {
    try {
      await _firestore
          .collection(_apksCollection)
          .doc(apk.id)
          .update(apk.toMap());
    } catch (e) {
      logger.e('Error updating APK in Firebase: $e');
      rethrow;
    }
  }
  
  /// Delete an APK from the database
  Future<void> deleteApk(String id) async {
    try {
      await _firestore
          .collection(_apksCollection)
          .doc(id)
          .delete();
    } catch (e) {
      logger.e('Error deleting APK from Firebase: $e');
      rethrow;
    }
  }
  
  /// Toggle the pin status of an APK
  Future<void> togglePinStatus(String id, bool isPinned) async {
    try {
      await _firestore
          .collection(_apksCollection)
          .doc(id)
          .update({'is_pinned': isPinned});
    } catch (e) {
      logger.e('Error toggling pin status in Firebase: $e');
      rethrow;
    }
  }
  
  /// Increment the download count for an APK
  Future<void> incrementDownloadCount(String id) async {
    try {
      // Use transaction to safely increment the counter
      await _firestore.runTransaction((transaction) async {
        final docRef = _firestore.collection(_apksCollection).doc(id);
        final snapshot = await transaction.get(docRef);
        
        if (!snapshot.exists) {
          throw Exception('APK document does not exist!');
        }
        
        final currentCount = snapshot.data()?['downloads'] as int? ?? 0;
        transaction.update(docRef, {'downloads': currentCount + 1});
      });
    } catch (e) {
      logger.e('Error incrementing download count in Firebase: $e');
      rethrow;
    }
  }

  /// Upload an APK file to Firebase storage
  Future<String> uploadAPK(File file, String fileName, {Function(int)? onProgress}) async {
    try {
      _uploadCancelled = false;
      
      final extension = path.extension(fileName);
      final uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}$extension';
      final storageRef = _storage.ref().child('$_apksPath/$uniqueFileName');
      
      final uploadTask = storageRef.putFile(file);
      final uploadId = 'apk_$uniqueFileName';
      _activeUploads[uploadId] = uploadTask;
      
      // Track upload progress if callback is provided
      if (onProgress != null) {
        int lastProgress = 0;
        
        // Use a single listener to avoid multiple progress callbacks
        final listener = uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          // Calculate progress percentage
          final progress = (snapshot.bytesTransferred / snapshot.totalBytes * 100).round();
          
          // Only notify if the progress has changed and is not decreasing
          if (progress > lastProgress && !_uploadCancelled) {
            lastProgress = progress;
            onProgress(progress);
          }
          
          // Handle upload completion
          if (snapshot.state == TaskState.success) {
            _activeUploads.remove(uploadId);
            if (_activeListeners.containsKey(uploadId)) {
              _activeListeners[uploadId]?.cancel();
              _activeListeners.remove(uploadId);
            }
          }
        }, onError: (e) {
          logger.e('Error during APK upload: $e');
          _activeUploads.remove(uploadId);
        }, onDone: () {
          _activeUploads.remove(uploadId);
        });
        
        _activeListeners[uploadId] = listener;
      }
      
      // Wait for upload to complete
      final snapshot = await uploadTask;
      
      // Clean up
      _activeUploads.remove(uploadId);
      if (_activeListeners.containsKey(uploadId)) {
        await _activeListeners[uploadId]?.cancel();
        _activeListeners.remove(uploadId);
      }
      
      // If upload was cancelled, throw an exception
      if (_uploadCancelled) {
        throw Exception('Upload cancelled');
      }
      
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      logger.e('Error uploading APK to Firebase: $e');
      rethrow;
    }
  }

  /// Upload an icon file to Firebase storage
  Future<String> uploadIcon(File file, String fileName, {Function(int)? onProgress}) async {
    try {
      final extension = path.extension(fileName);
      final uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}$extension';
      final storageRef = _storage.ref().child('$_iconsPath/$uniqueFileName');
      
      final uploadTask = storageRef.putFile(file);
      final uploadId = 'icon_$uniqueFileName';
      _activeUploads[uploadId] = uploadTask;
      
      // Track upload progress if callback is provided
      if (onProgress != null) {
        int lastProgress = 0;
        
        // Use a single listener to avoid multiple progress callbacks
        final listener = uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          // Calculate progress percentage
          final progress = (snapshot.bytesTransferred / snapshot.totalBytes * 100).round();
          
          // Only notify if the progress has changed and is not decreasing
          if (progress > lastProgress && !_uploadCancelled) {
            lastProgress = progress;
            onProgress(progress);
          }
          
          // Handle upload completion
          if (snapshot.state == TaskState.success) {
            _activeUploads.remove(uploadId);
            if (_activeListeners.containsKey(uploadId)) {
              _activeListeners[uploadId]?.cancel();
              _activeListeners.remove(uploadId);
            }
          }
        }, onError: (e) {
          logger.e('Error during icon upload: $e');
          _activeUploads.remove(uploadId);
        }, onDone: () {
          _activeUploads.remove(uploadId);
        });
        
        _activeListeners[uploadId] = listener;
      }
      
      // Wait for upload to complete
      final snapshot = await uploadTask;
      
      // Clean up
      _activeUploads.remove(uploadId);
      if (_activeListeners.containsKey(uploadId)) {
        await _activeListeners[uploadId]?.cancel();
        _activeListeners.remove(uploadId);
      }
      
      // If upload was cancelled, throw an exception
      if (_uploadCancelled) {
        throw Exception('Upload cancelled');
      }
      
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      logger.e('Error uploading icon to Firebase: $e');
      rethrow;
    }
  }

  /// Upload a screenshot to Firebase storage
  Future<String> uploadScreenshot(File file, String fileName, {Function(int)? onProgress}) async {
    try {
      final extension = path.extension(fileName);
      final uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}$extension';
      final storageRef = _storage.ref().child('$_screenshotsPath/$uniqueFileName');
      
      final uploadTask = storageRef.putFile(file);
      final uploadId = 'screenshot_$uniqueFileName';
      _activeUploads[uploadId] = uploadTask;
      
      // Track upload progress if callback is provided
      if (onProgress != null) {
        int lastProgress = 0;
        
        // Use a single listener to avoid multiple progress callbacks
        final listener = uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          // Calculate progress percentage
          final progress = (snapshot.bytesTransferred / snapshot.totalBytes * 100).round();
          
          // Only notify if the progress has changed and is not decreasing
          if (progress > lastProgress && !_uploadCancelled) {
            lastProgress = progress;
            onProgress(progress);
          }
          
          // Handle upload completion
          if (snapshot.state == TaskState.success) {
            _activeUploads.remove(uploadId);
            if (_activeListeners.containsKey(uploadId)) {
              _activeListeners[uploadId]?.cancel();
              _activeListeners.remove(uploadId);
            }
          }
        }, onError: (e) {
          logger.e('Error during screenshot upload: $e');
          _activeUploads.remove(uploadId);
        }, onDone: () {
          _activeUploads.remove(uploadId);
        });
        
        _activeListeners[uploadId] = listener;
      }
      
      // Wait for upload to complete
      final snapshot = await uploadTask;
      
      // Clean up
      _activeUploads.remove(uploadId);
      if (_activeListeners.containsKey(uploadId)) {
        await _activeListeners[uploadId]?.cancel();
        _activeListeners.remove(uploadId);
      }
      
      // If upload was cancelled, throw an exception
      if (_uploadCancelled) {
        throw Exception('Upload cancelled');
      }
      
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      logger.e('Error uploading screenshot to Firebase: $e');
      rethrow;
    }
  }

  /// Upload multiple screenshots to Firebase storage
  Future<List<String>> uploadScreenshots(List<File> files, List<String> fileNames, {Function(int)? onProgress}) async {
    try {
      final urls = <String>[];
      final totalFiles = files.length;
      int overallProgress = 0;
      
      for (int i = 0; i < files.length; i++) {
        if (_uploadCancelled) {
          throw Exception('Upload cancelled');
        }
        
        final url = await uploadScreenshot(
          files[i], 
          fileNames[i],
          onProgress: onProgress != null 
            ? (progress) {
                // Calculate overall progress based on current file and its progress
                // Ensure progress never decreases
                final fileContribution = (progress / totalFiles).round();
                final baseProgress = ((i / totalFiles) * 100).round();
                final newOverallProgress = baseProgress + fileContribution;
                
                if (newOverallProgress > overallProgress && !_uploadCancelled) {
                  overallProgress = newOverallProgress;
                  onProgress(overallProgress);
                }
              }
            : null
        );
        urls.add(url);
      }
      
      return urls;
    } catch (e) {
      logger.e('Error uploading multiple screenshots to Firebase: $e');
      rethrow;
    }
  }

  /// Delete a file from Firebase storage
  Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      logger.e('Error deleting file from Firebase: $e');
      rethrow;
    }
  }

  /// Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }
  
  /// Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }
  
  /// Check if user is admin
  Future<bool> isUserAdmin(String userId) async {
    try {
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();
      
      if (!doc.exists) {
        return false;
      }
      
      final role = doc.data()?['role'] as String?;
      return role == 'admin';
    } catch (e) {
      logger.e('Error checking admin status: $e');
      return false;
    }
  }
  
  /// Create a new user profile
  Future<void> createUserProfile(String userId, String email, String role) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .set({
            'email': email,
            'role': role,
            'created_at': FieldValue.serverTimestamp(),
            'updated_at': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      logger.e('Error creating user profile: $e');
      rethrow;
    }
  }
} 