import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../../utils/helpers.dart';
import '../../services/user_service.dart';

/// Constants for SharedPreferences keys
const String isDarkModeKey = 'is_dark_mode';
const String userRoleKey = 'user_role';

/// Provider for app-wide state
class AppProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  UserRole _userRole = UserRole.viewer;
  bool _isLoading = false;
  String? _errorMessage;
  SharedPreferences? _prefs;

  // Getters
  bool get isDarkMode => _isDarkMode;
  UserRole get userRole => _userRole;
  bool get isAdmin => _userRole == UserRole.admin;
  bool get isEditor => _userRole == UserRole.editor;
  bool get isViewer => _userRole == UserRole.viewer;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Initialize the provider
  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      
      // Load theme preference
      _isDarkMode = _prefs?.getBool(isDarkModeKey) ?? false;
      
      // Load user role
      final roleString = _prefs?.getString(userRoleKey);
      if (roleString != null) {
        _userRole = _stringToUserRole(roleString);
      }
      
      notifyListeners();
    } catch (e) {
      logger.e('Error initializing AppProvider: $e');
    }
  }

  /// Toggle dark/light theme
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    
    try {
      await _prefs?.setBool(isDarkModeKey, _isDarkMode);
      notifyListeners();
    } catch (e) {
      logger.e('Error saving theme preference: $e');
    }
  }

  /// Set user role
  Future<void> setUserRole(UserRole role) async {
    _userRole = role;
    
    try {
      await _prefs?.setString(userRoleKey, role.toString().split('.').last);
      notifyListeners();
    } catch (e) {
      logger.e('Error saving user role: $e');
    }
  }

  /// Backward compatibility for admin status
  Future<void> setAdminStatus(bool isAdmin) async {
    return setUserRole(isAdmin ? UserRole.admin : UserRole.viewer);
  }

  /// Set loading state
  void setLoading(bool isLoading) {
    _isLoading = isLoading;
    notifyListeners();
  }

  /// Set error message
  void setErrorMessage(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Clear error message
  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }
  
  /// Convert string to UserRole
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
} 