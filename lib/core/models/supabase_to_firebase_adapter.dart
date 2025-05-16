import 'package:firebase_auth/firebase_auth.dart';
import '../models/firebase_models.dart';
import '../models/apk_model.dart';
import '../../services/user_service.dart';  // Added import for UserRole

/// Temporary class to represent the Supabase APK model during migration
/// This is a placeholder to help transition from Supabase to Firebase
class SupabaseAPK {
  final String id;
  final String name;
  final String description;
  final String apkUrl;
  final String iconUrl;
  final bool isPinned;
  final DateTime uploadedAt;
  final String? playStoreUrl;
  final List<String> screenshotUrls;
  final String? minimumRequirements;
  final String? version;
  final String? size;
  final int downloadCount;
  final String? developer;
  final List<String>? categories;

  /// Constructor
  SupabaseAPK({
    required this.id,
    required this.name,
    required this.description,
    required this.apkUrl,
    required this.iconUrl,
    required this.isPinned,
    required this.uploadedAt,
    this.playStoreUrl,
    required this.screenshotUrls,
    this.minimumRequirements,
    this.version,
    this.size,
    required this.downloadCount,
    this.developer,
    this.categories,
  });

  /// Convert from FirebaseAPK model during transition
  factory SupabaseAPK.fromFirebaseAPK(FirebaseAPK apk) {
    return SupabaseAPK(
      id: apk.id,
      name: apk.name,
      description: apk.description ?? '',
      apkUrl: apk.apkUrl,
      iconUrl: apk.iconUrl ?? '',
      isPinned: apk.isPinned,
      uploadedAt: apk.createdAt,
      screenshotUrls: apk.screenshots,
      downloadCount: apk.downloads,
      // Map additional fields with default values for backward compatibility
      version: apk.versionName,
      size: '${(apk.sizeBytes / 1024 / 1024).toStringAsFixed(2)} MB',
      minimumRequirements: 'Android ${apk.minSdk}+',
      developer: 'Unknown',
      categories: [],
    );
  }

  /// Convert list of FirebaseAPKs to SupabaseAPKs for backward compatibility
  static List<SupabaseAPK> fromFirebaseAPKList(List<FirebaseAPK> apks) {
    return apks.map((apk) => SupabaseAPK.fromFirebaseAPK(apk)).toList();
  }
  
  /// Convert to APKModel
  APKModel toAPKModel() {
    return APKModel(
      id: id,
      name: name,
      packageName: 'unknown.package.name',  // Default value for backward compatibility
      versionName: version ?? '1.0.0',      // Default value for backward compatibility
      versionCode: 1,                       // Default value for backward compatibility
      minSdk: 21,                           // Default value for backward compatibility
      targetSdk: 33,                        // Default value for backward compatibility
      description: description,
      apkUrl: apkUrl,
      iconUrl: iconUrl,
      screenshots: screenshotUrls,
      sizeBytes: 0,                         // Default value for backward compatibility
      isPinned: isPinned,
      downloads: downloadCount,
      createdAt: uploadedAt,
      updatedAt: uploadedAt,
    );
  }
}

/// Extension method to help with User id access
extension UserExt on User {
  String get id => uid;
} 