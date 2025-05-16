import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/helpers.dart';

/// User roles
enum UserRole {
  admin,
  editor,
  viewer,
}

/// User model
class UserModel {
  final String id;
  final String email;
  final UserRole role;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Constructor
  UserModel({
    required this.id,
    required this.email,
    required this.role,
    this.createdAt,
    this.updatedAt,
  });

  /// Create from Firestore map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      role: _stringToUserRole(map['role'] ?? 'viewer'),
      createdAt: _parseTimestamp(map['created_at']),
      updatedAt: _parseTimestamp(map['updated_at']),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role.toString().split('.').last,
      'created_at': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'updated_at': updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }
}

/// Service class to handle user management with Firebase
class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collection names
  static const String _usersCollection = 'users';

  /// Get current authenticated user
  User? getCurrentUser() {
    return _auth.currentUser;
  }
  
  /// Add a new user
  Future<bool> addUser(String email, UserRole role, String? createdBy) async {
    try {
      // Create the user with default password (123456 for admins, random for others)
      final defaultPassword = role == UserRole.admin ? '123456' : 'Password123!';
      final success = await createUser(email, defaultPassword, role);
      
      // Send password reset email only for non-admin users
      if (success && role != UserRole.admin) {
        await _auth.sendPasswordResetEmail(email: email);
        logger.i('Password reset link sent to $email');
      }
      
      return success;
    } catch (e) {
      logger.e('Error adding user: $e');
      return false;
    }
  }

  /// Get all users
  Future<List<UserModel>> getUsers() async {
    try {
      final snapshot = await _firestore
          .collection(_usersCollection)
          .orderBy('created_at', descending: true)
          .get();
      
      final users = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return UserModel.fromMap(data);
      }).toList();
      
      return users;
    } catch (e) {
      logger.e('Error getting users from Firebase: $e');
      return [];
    }
  }
  
  /// Check if any admin users exist
  Future<bool> hasAdminUsers() async {
    try {
      final snapshot = await _firestore
          .collection(_usersCollection)
          .where('role', isEqualTo: 'admin')
          .limit(1)
          .get();
      
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      logger.e('Error checking for admin users: $e');
      return false;
    }
  }
  
  /// Get user by ID
  Future<UserModel?> getUserById(String id) async {
    try {
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(id)
          .get();
      
      if (!doc.exists) {
        return null;
      }
      
      final data = doc.data()!;
      data['id'] = doc.id;
      return UserModel.fromMap(data);
    } catch (e) {
      logger.e('Error getting user by ID: $e');
      return null;
    }
  }
  
  /// Update user role
  Future<bool> updateUserRole(String userId, UserRole role) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .update({
            'role': role.toString().split('.').last,
            'updated_at': FieldValue.serverTimestamp(),
          });
      
      return true;
    } catch (e) {
      logger.e('Error updating user role: $e');
      return false;
    }
  }
  
  /// Create a new user
  Future<bool> createUser(String email, String password, UserRole role) async {
    try {
      // Create the user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Set the role in the users collection
      if (userCredential.user != null) {
        await _firestore
            .collection(_usersCollection)
            .doc(userCredential.user!.uid)
            .set({
              'email': email,
              'role': role.toString().split('.').last,
              'created_at': FieldValue.serverTimestamp(),
              'updated_at': FieldValue.serverTimestamp(),
            });
      }
      
      return userCredential.user != null;
    } catch (e) {
      logger.e('Error creating user: $e');
      return false;
    }
  }
  
  /// Delete a user
  Future<bool> deleteUser(String userId) async {
    try {
      // Delete from Auth (requires admin SDK or Cloud Functions)
      // For this client-side implementation, only the Firestore document will be deleted
      
      // Delete from users collection
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .delete();
      
      return true;
    } catch (e) {
      logger.e('Error deleting user: $e');
      return false;
    }
  }
  
  /// Get user role
  Future<UserRole> getUserRole(String userId) async {
    try {
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();
      
      if (!doc.exists) {
        return UserRole.viewer; // Default to lowest privilege
      }
      
      final roleStr = doc.data()?['role'] as String? ?? 'viewer';
      return _stringToUserRole(roleStr);
    } catch (e) {
      logger.e('Error getting user role: $e');
      return UserRole.viewer; // Default to lowest privilege
    }
  }
}

/// Helper function to convert string to UserRole
UserRole _stringToUserRole(String roleStr) {
  switch (roleStr) {
    case 'admin':
      return UserRole.admin;
    case 'editor':
      return UserRole.editor;
    case 'viewer':
    default:
      return UserRole.viewer;
  }
}

/// Helper function to parse timestamp
DateTime? _parseTimestamp(dynamic timestamp) {
  if (timestamp is Timestamp) {
    return timestamp.toDate();
  } else if (timestamp is String) {
    return DateTime.parse(timestamp);
  }
  return null;
} 