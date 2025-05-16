import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/helpers.dart';

/// Service class to handle Firebase authentication
/// 
/// Firebase Auth automatically persists user sessions across app restarts,
/// so admins will remain logged in until they explicitly sign out.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collection names
  static const String _usersCollection = 'users';

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      logger.i('User signed in: ${credential.user?.uid}');
      return credential;
    } catch (e) {
      logger.e('Error signing in: $e');
      rethrow;
    }
  }

  /// Sign in as admin (only admins allowed)
  Future<UserCredential> signInAsAdmin(String email, String password) async {
    try {
      // First try to sign in
      final credential = await signInWithEmailAndPassword(email, password);
      
      if (credential.user == null) {
        throw Exception('Authentication failed');
      }
      
      // Check if user has admin role
      final isAdmin = await checkAdminStatus(credential.user!.uid);
      
      if (!isAdmin) {
        // Sign out and throw error if not admin
        await signOut();
        throw Exception('Access denied: Admin privileges required');
      }
      
      logger.i('Admin user signed in: ${credential.user?.uid}');
      return credential;
    } catch (e) {
      logger.e('Error signing in as admin: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      logger.i('User signed out');
    } catch (e) {
      logger.e('Error signing out: $e');
      rethrow;
    }
  }

  /// Check if user is signed in
  bool isSignedIn() {
    return _auth.currentUser != null;
  }

  /// Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Check if user has admin role
  Future<bool> checkAdminStatus(String userId) async {
    try {
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();
      
      if (!doc.exists) {
        return false;
      }
      
      return doc.data()?['role'] == 'admin';
    } catch (e) {
      logger.e('Error checking admin status: $e');
      return false;
    }
  }
  
  /// Create a new user
  Future<UserCredential> createUser(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      logger.i('User created: ${credential.user?.uid}');
      return credential;
    } catch (e) {
      logger.e('Error creating user: $e');
      rethrow;
    }
  }
  
  /// Set user role
  Future<void> setUserRole(String userId, String role) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .set({
            'role': role,
            'updated_at': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      
      logger.i('User role updated: $userId, $role');
    } catch (e) {
      logger.e('Error setting user role: $e');
      rethrow;
    }
  }
  
  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      logger.i('Password reset email sent to $email');
    } catch (e) {
      logger.e('Error sending password reset email: $e');
      rethrow;
    }
  }
  
  /// Update user profile
  Future<void> updateUserProfile({String? displayName, String? photoURL}) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName);
        await user.updatePhotoURL(photoURL);
        logger.i('User profile updated');
      }
    } catch (e) {
      logger.e('Error updating user profile: $e');
      rethrow;
    }
  }
  
  /// Change user password
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }
      
      // Verify current password by re-authenticating
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      
      await user.reauthenticateWithCredential(credential);
      
      // Change password
      await user.updatePassword(newPassword);
      
      logger.i('Password changed successfully');
    } catch (e) {
      logger.e('Error changing password: $e');
      
      if (e.toString().contains('wrong-password')) {
        throw Exception('Current password is incorrect');
      } else if (e.toString().contains('requires-recent-login')) {
        throw Exception('Please log in again before changing your password');
      } else if (e.toString().contains('weak-password')) {
        throw Exception('New password is too weak. It must be at least 6 characters');
      } else {
        throw Exception('Failed to change password: ${e.toString()}');
      }
    }
  }
} 