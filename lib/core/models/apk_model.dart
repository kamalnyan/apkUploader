import 'package:flutter/foundation.dart';

/// Model class for APK information
class APKModel {
  final String id;
  final String name;
  final String packageName;
  final String versionName;
  final int versionCode;
  final int minSdk;
  final int targetSdk;
  final String description;
  final String apkUrl;
  final String? iconUrl;
  final List<String> screenshots;
  final int sizeBytes;
  final bool isPinned;
  final int downloads;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? changelog;
  final String? developer;
  final String? minRequirements;
  final String? playStoreUrl;
  final List<String> permissions;
  // Additional fields
  final String? category;
  final String? releaseDate;
  final String? languages;
  final String? installInstructions;
  final String? supportEmail;
  final String? privacyPolicyUrl;
  final bool isRestricted;
  final String? downloadPassword;

  /// Constructor
  const APKModel({
    required this.id,
    required this.name,
    required this.packageName,
    required this.versionName,
    required this.versionCode,
    required this.minSdk,
    required this.targetSdk,
    required this.description,
    required this.apkUrl,
    this.iconUrl,
    required this.screenshots,
    required this.sizeBytes,
    required this.isPinned,
    required this.downloads,
    required this.createdAt,
    required this.updatedAt,
    this.changelog,
    this.developer,
    this.minRequirements,
    this.playStoreUrl,
    this.permissions = const [],
    // Additional fields
    this.category,
    this.releaseDate,
    this.languages,
    this.installInstructions,
    this.supportEmail,
    this.privacyPolicyUrl,
    this.isRestricted = false,
    this.downloadPassword,
  });

  /// For backward compatibility with old code
  DateTime get uploadedAt => createdAt;
  
  /// For backward compatibility - version getter maps to versionName
  String get version => versionName;
  
  /// For backward compatibility - downloadUrl getter maps to apkUrl
  String get downloadUrl => apkUrl;
  
  /// For backward compatibility - imageUrl getter maps to iconUrl
  String? get imageUrl => iconUrl;
  
  /// For backward compatibility - downloadCount getter maps to downloads
  int get downloadCount => downloads;

  /// Create a copy of this APK with some fields replaced
  APKModel copyWith({
    String? id,
    String? name,
    String? packageName,
    String? versionName,
    int? versionCode,
    int? minSdk,
    int? targetSdk,
    String? description,
    String? apkUrl,
    String? iconUrl,
    List<String>? screenshots,
    int? sizeBytes,
    bool? isPinned,
    int? downloads,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? changelog,
    String? developer,
    String? minRequirements,
    String? playStoreUrl,
    List<String>? permissions,
    // Additional fields
    String? category,
    String? releaseDate,
    String? languages,
    String? installInstructions,
    String? supportEmail,
    String? privacyPolicyUrl,
    bool? isRestricted,
    String? downloadPassword,
  }) {
    return APKModel(
      id: id ?? this.id,
      name: name ?? this.name,
      packageName: packageName ?? this.packageName,
      versionName: versionName ?? this.versionName,
      versionCode: versionCode ?? this.versionCode,
      minSdk: minSdk ?? this.minSdk,
      targetSdk: targetSdk ?? this.targetSdk,
      description: description ?? this.description,
      apkUrl: apkUrl ?? this.apkUrl,
      iconUrl: iconUrl ?? this.iconUrl,
      screenshots: screenshots ?? this.screenshots,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      isPinned: isPinned ?? this.isPinned,
      downloads: downloads ?? this.downloads,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      changelog: changelog ?? this.changelog,
      developer: developer ?? this.developer,
      minRequirements: minRequirements ?? this.minRequirements,
      playStoreUrl: playStoreUrl ?? this.playStoreUrl,
      permissions: permissions ?? this.permissions,
      // Additional fields
      category: category ?? this.category,
      releaseDate: releaseDate ?? this.releaseDate,
      languages: languages ?? this.languages,
      installInstructions: installInstructions ?? this.installInstructions,
      supportEmail: supportEmail ?? this.supportEmail,
      privacyPolicyUrl: privacyPolicyUrl ?? this.privacyPolicyUrl,
      isRestricted: isRestricted ?? this.isRestricted,
      downloadPassword: downloadPassword ?? this.downloadPassword,
    );
  }

  /// Create from a map
  factory APKModel.fromMap(Map<String, dynamic> map) {
    return APKModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      packageName: map['package_name'] ?? '',
      versionName: map['version_name'] ?? '',
      versionCode: _parseIntSafely(map['version_code']),
      minSdk: _parseIntSafely(map['min_sdk']),
      targetSdk: _parseIntSafely(map['target_sdk']),
      description: map['description'] ?? '',
      apkUrl: map['apk_url'] ?? '',
      iconUrl: map['icon_url'],
      screenshots: List<String>.from(map['screenshots'] ?? []),
      sizeBytes: _parseIntSafely(map['size_bytes']),
      isPinned: map['is_pinned'] ?? false,
      downloads: _parseIntSafely(map['downloads']),
      createdAt: map['created_at'] is DateTime 
          ? map['created_at']
          : DateTime.parse(map['created_at'].toString()),
      updatedAt: map['updated_at'] is DateTime 
          ? map['updated_at']
          : DateTime.parse(map['updated_at'].toString()),
      changelog: map['changelog'],
      developer: map['developer'],
      minRequirements: map['min_requirements'],
      playStoreUrl: map['play_store_url'],
      permissions: map['permissions'] != null 
        ? List<String>.from(map['permissions']) 
        : [],
      // Additional fields
      category: map['category'],
      releaseDate: map['release_date'],
      languages: map['languages'],
      installInstructions: map['install_instructions'],
      supportEmail: map['support_email'],
      privacyPolicyUrl: map['privacy_policy_url'],
      isRestricted: map['is_restricted'] ?? false,
      downloadPassword: map['download_password'],
    );
  }

  /// Convert to a map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'package_name': packageName,
      'version_name': versionName,
      'version_code': versionCode,
      'min_sdk': minSdk,
      'target_sdk': targetSdk,
      'description': description,
      'apk_url': apkUrl,
      'icon_url': iconUrl,
      'screenshots': screenshots,
      'size_bytes': sizeBytes,
      'is_pinned': isPinned,
      'downloads': downloads,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'changelog': changelog,
      'developer': developer,
      'min_requirements': minRequirements,
      'play_store_url': playStoreUrl,
      'permissions': permissions,
      // Additional fields
      'category': category,
      'release_date': releaseDate,
      'languages': languages,
      'install_instructions': installInstructions,
      'support_email': supportEmail,
      'privacy_policy_url': privacyPolicyUrl,
      'is_restricted': isRestricted,
      'download_password': downloadPassword,
    };
  }

  @override
  String toString() {
    return 'APKModel(id: $id, name: $name, packageName: $packageName, '
        'versionName: $versionName, versionCode: $versionCode, '
        'minSdk: $minSdk, targetSdk: $targetSdk, '
        'description: $description, apkUrl: $apkUrl, '
        'iconUrl: $iconUrl, screenshots: $screenshots, '
        'sizeBytes: $sizeBytes, isPinned: $isPinned, '
        'downloads: $downloads, createdAt: $createdAt, updatedAt: $updatedAt, '
        'developer: $developer, minRequirements: $minRequirements)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is APKModel &&
      other.id == id &&
      other.name == name &&
      other.packageName == packageName &&
      other.versionName == versionName &&
      other.versionCode == versionCode &&
      other.minSdk == minSdk &&
      other.targetSdk == targetSdk &&
      other.description == description &&
      other.apkUrl == apkUrl &&
      other.iconUrl == iconUrl &&
      listEquals(other.screenshots, screenshots) &&
      other.sizeBytes == sizeBytes &&
      other.isPinned == isPinned &&
      other.downloads == downloads &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt &&
      other.changelog == changelog &&
      other.developer == developer &&
      other.minRequirements == minRequirements &&
      other.playStoreUrl == playStoreUrl &&
      listEquals(other.permissions, permissions) &&
      other.category == category &&
      other.releaseDate == releaseDate &&
      other.languages == languages &&
      other.installInstructions == installInstructions &&
      other.supportEmail == supportEmail &&
      other.privacyPolicyUrl == privacyPolicyUrl &&
      other.isRestricted == isRestricted &&
      other.downloadPassword == downloadPassword;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      name.hashCode ^
      packageName.hashCode ^
      versionName.hashCode ^
      versionCode.hashCode ^
      minSdk.hashCode ^
      targetSdk.hashCode ^
      description.hashCode ^
      apkUrl.hashCode ^
      iconUrl.hashCode ^
      screenshots.hashCode ^
      sizeBytes.hashCode ^
      isPinned.hashCode ^
      downloads.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      changelog.hashCode ^
      developer.hashCode ^
      minRequirements.hashCode ^
      playStoreUrl.hashCode ^
      permissions.hashCode ^
      category.hashCode ^
      releaseDate.hashCode ^
      languages.hashCode ^
      installInstructions.hashCode ^
      supportEmail.hashCode ^
      privacyPolicyUrl.hashCode ^
      isRestricted.hashCode ^
      downloadPassword.hashCode;
  }
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