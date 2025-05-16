/// Application-wide constants
class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  // App information
  static const String appName = 'APK Uploader';
  static const String appDescription = 'Upload, manage, and distribute APK files';

  // Animation paths
  static const String loadingAnimation = 'assets/animations/loading.json';
  static const String uploadAnimation = 'assets/animations/upload.json';
  static const String downloadAnimation = 'assets/animations/download.json';
  static const String emptyAnimation = 'assets/animations/empty.json';
  static const String successAnimation = 'assets/animations/success.json';
  static const String errorAnimation = 'assets/animations/error.json';
  static const String loginAnimation = 'assets/animations/login.json';

  // Firebase collection names
  static const String apksCollection = 'apks';
  static const String usersCollection = 'users';
  
  // Firebase storage paths
  static const String apkStoragePath = 'apks';
  static const String iconStoragePath = 'icons';
  
  // Firestore field names
  static const String nameField = 'name';
  static const String descriptionField = 'description';
  static const String apkUrlField = 'apkUrl';
  static const String iconUrlField = 'iconUrl';
  static const String isPinnedField = 'isPinned';
  static const String uploadedAtField = 'uploadedAt';
  static const String isAdminField = 'isAdmin';

  // Success messages
  static const String uploadSuccessMessage = 'APK uploaded successfully!';
  static const String updateSuccessMessage = 'APK updated successfully!';
  static const String deleteSuccessMessage = 'APK deleted successfully!';
  static const String downloadSuccessMessage = 'APK downloaded successfully!';
  static const String installSuccessMessage = 'APK installation started!';
  static const String pinSuccessMessage = 'APK pinned successfully!';
  static const String unpinSuccessMessage = 'APK unpinned successfully!';
  static const String loginSuccessMessage = 'Login successful!';
  static const String logoutSuccessMessage = 'Logged out successfully!';

  // Error messages
  static const String uploadErrorMessage = 'Failed to upload APK. Please try again.';
  static const String updateErrorMessage = 'Failed to update APK. Please try again.';
  static const String deleteErrorMessage = 'Failed to delete APK. Please try again.';
  static const String downloadErrorMessage = 'Failed to download APK. Please try again.';
  static const String installErrorMessage = 'Failed to install APK. Please try again.';
  static const String loginErrorMessage = 'Invalid email or password. Please try again.';
  static const String networkErrorMessage = 'Network error. Please check your connection.';
  static const String permissionErrorMessage = 'Storage permission required for this action.';
  static const String unknownErrorMessage = 'An unknown error occurred. Please try again.';

  // iOS installation message
  static const String iosInstallMessage = 'APK files cannot be installed on iOS devices. Please use an Android device to install this app.';
  
  // Demo mode messages
  static const String demoModeMessage = 'Running in demo mode. Firebase authentication is bypassed.';
  static const String demoLoginMessage = 'In demo mode, any username and password will work.';
  static const String demoUploadMessage = 'In demo mode, files are not actually uploaded.';
  static const String demoDownloadMessage = 'In demo mode, files are not actually downloaded.';
} 