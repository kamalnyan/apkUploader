import 'package:cloud_firestore/cloud_firestore.dart';

/// Firebase APK model
class FirebaseAPK {
  final String id;
  final String name;
  final String packageName;
  final String versionName;
  final int versionCode;
  final int minSdk;
  final int targetSdk;
  final String? description;
  final String? developer;
  final String? minRequirements;
  final String? playStoreUrl;
  final List<String> permissions;
  final String apkUrl;
  final String? iconUrl;
  final List<String> screenshots;
  final int sizeBytes;
  final bool isPinned;
  final int downloads;
  final String? createdBy;
  final String? updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Additional fields
  final String? category;
  final String? releaseDate;
  final String? languages;
  final String? installInstructions;
  final String? changelog;
  final String? supportEmail;
  final String? privacyPolicyUrl;
  final bool isRestricted;
  final String? downloadPassword;

  /// Constructor
  FirebaseAPK({
    required this.id,
    required this.name,
    required this.packageName,
    required this.versionName,
    required this.versionCode,
    required this.minSdk,
    required this.targetSdk,
    this.description,
    this.developer,
    this.minRequirements,
    this.playStoreUrl,
    this.permissions = const [],
    required this.apkUrl,
    this.iconUrl,
    required this.screenshots,
    required this.sizeBytes,
    required this.isPinned,
    required this.downloads,
    this.createdBy,
    this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
    // Additional fields
    this.category,
    this.releaseDate,
    this.languages,
    this.installInstructions,
    this.changelog,
    this.supportEmail,
    this.privacyPolicyUrl,
    this.isRestricted = false,
    this.downloadPassword,
  });

  /// Create from Firestore map
  factory FirebaseAPK.fromMap(Map<String, dynamic> map) {
    return FirebaseAPK(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      packageName: map['package_name'] ?? '',
      versionName: map['version_name'] ?? '',
      versionCode: _parseIntSafely(map['version_code']),
      minSdk: _parseIntSafely(map['min_sdk']),
      targetSdk: _parseIntSafely(map['target_sdk']),
      description: map['description'],
      developer: map['developer'],
      minRequirements: map['min_requirements'],
      playStoreUrl: map['play_store_url'],
      permissions: List<String>.from(map['permissions'] ?? []),
      apkUrl: map['apk_url'] ?? '',
      iconUrl: map['icon_url'],
      screenshots: List<String>.from(map['screenshots'] ?? []),
      sizeBytes: _parseIntSafely(map['size_bytes']),
      isPinned: map['is_pinned'] ?? false,
      downloads: _parseIntSafely(map['downloads']),
      createdBy: map['created_by'],
      updatedBy: map['updated_by'],
      createdAt: _parseTimestamp(map['created_at']),
      updatedAt: _parseTimestamp(map['updated_at']),
      // Additional fields
      category: map['category'],
      releaseDate: map['release_date'],
      languages: map['languages'],
      installInstructions: map['install_instructions'],
      changelog: map['changelog'],
      supportEmail: map['support_email'],
      privacyPolicyUrl: map['privacy_policy_url'],
      isRestricted: map['is_restricted'] ?? false,
      downloadPassword: map['download_password'],
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'package_name': packageName,
      'version_name': versionName,
      'version_code': versionCode,
      'min_sdk': minSdk,
      'target_sdk': targetSdk,
      'description': description,
      'developer': developer,
      'min_requirements': minRequirements,
      'play_store_url': playStoreUrl,
      'permissions': permissions,
      'apk_url': apkUrl,
      'icon_url': iconUrl,
      'screenshots': screenshots,
      'size_bytes': sizeBytes,
      'is_pinned': isPinned,
      'downloads': downloads,
      'created_by': createdBy,
      'updated_by': updatedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      // Additional fields
      'category': category,
      'release_date': releaseDate,
      'languages': languages,
      'install_instructions': installInstructions,
      'changelog': changelog,
      'support_email': supportEmail,
      'privacy_policy_url': privacyPolicyUrl, 
      'is_restricted': isRestricted,
      'download_password': downloadPassword,
    };
  }

  /// Create a copy with updated fields
  FirebaseAPK copyWith({
    String? id,
    String? name,
    String? packageName,
    String? versionName,
    int? versionCode,
    int? minSdk,
    int? targetSdk,
    String? description,
    String? developer,
    String? minRequirements,
    String? playStoreUrl,
    List<String>? permissions,
    String? apkUrl,
    String? iconUrl,
    List<String>? screenshots,
    int? sizeBytes,
    bool? isPinned,
    int? downloads,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
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
  }) {
    return FirebaseAPK(
      id: id ?? this.id,
      name: name ?? this.name,
      packageName: packageName ?? this.packageName,
      versionName: versionName ?? this.versionName,
      versionCode: versionCode ?? this.versionCode,
      minSdk: minSdk ?? this.minSdk,
      targetSdk: targetSdk ?? this.targetSdk,
      description: description ?? this.description,
      developer: developer ?? this.developer,
      minRequirements: minRequirements ?? this.minRequirements,
      playStoreUrl: playStoreUrl ?? this.playStoreUrl,
      permissions: permissions ?? this.permissions,
      apkUrl: apkUrl ?? this.apkUrl,
      iconUrl: iconUrl ?? this.iconUrl,
      screenshots: screenshots ?? this.screenshots,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      isPinned: isPinned ?? this.isPinned,
      downloads: downloads ?? this.downloads,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      // Additional fields
      category: category ?? this.category,
      releaseDate: releaseDate ?? this.releaseDate,
      languages: languages ?? this.languages,
      installInstructions: installInstructions ?? this.installInstructions,
      changelog: changelog ?? this.changelog,
      supportEmail: supportEmail ?? this.supportEmail,
      privacyPolicyUrl: privacyPolicyUrl ?? this.privacyPolicyUrl,
      isRestricted: isRestricted ?? this.isRestricted,
      downloadPassword: downloadPassword ?? this.downloadPassword,
    );
  }
}

/// Firebase user model
class FirebaseUser {
  final String id;
  final String email;
  final String role;
  final String? displayName;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Constructor
  FirebaseUser({
    required this.id,
    required this.email,
    required this.role,
    this.displayName,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Firestore map
  factory FirebaseUser.fromMap(Map<String, dynamic> map) {
    return FirebaseUser(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'user',
      displayName: map['display_name'],
      avatarUrl: map['avatar_url'],
      createdAt: _parseTimestamp(map['created_at']),
      updatedAt: _parseTimestamp(map['updated_at']),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  FirebaseUser copyWith({
    String? id,
    String? email,
    String? role,
    String? displayName,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FirebaseUser(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Helper function to parse Firestore timestamp
DateTime _parseTimestamp(dynamic timestamp) {
  if (timestamp is Timestamp) {
    return timestamp.toDate();
  } else if (timestamp is String) {
    return DateTime.parse(timestamp);
  }
  return DateTime.now();
}

/// Helper function to safely parse integer values
int _parseIntSafely(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) {
    try {
      return int.parse(value);
    } catch (e) {
      // If the string contains non-numeric values or has a non-numeric prefix
      return 0;
    }
  }
  return 0;
} 