import 'firebase_models.dart';
import 'apk_model.dart';

/// Adapter class to convert between different model types
class ModelAdapter {
  /// Convert FirebaseAPK to generic APKModel
  static APKModel toAPKModel(FirebaseAPK firebaseAPK) {
    return APKModel(
      id: firebaseAPK.id,
      name: firebaseAPK.name,
      packageName: firebaseAPK.packageName,
      versionName: firebaseAPK.versionName,
      versionCode: firebaseAPK.versionCode,
      minSdk: firebaseAPK.minSdk,
      targetSdk: firebaseAPK.targetSdk,
      description: firebaseAPK.description ?? '',
      apkUrl: firebaseAPK.apkUrl,
      iconUrl: firebaseAPK.iconUrl,
      screenshots: firebaseAPK.screenshots,
      sizeBytes: firebaseAPK.sizeBytes,
      isPinned: firebaseAPK.isPinned,
      downloads: firebaseAPK.downloads,
      createdAt: firebaseAPK.createdAt,
      updatedAt: firebaseAPK.updatedAt,
      developer: firebaseAPK.developer,
      minRequirements: firebaseAPK.minRequirements,
      playStoreUrl: firebaseAPK.playStoreUrl,
      permissions: firebaseAPK.permissions,
      category: firebaseAPK.category,
      releaseDate: firebaseAPK.releaseDate,
      languages: firebaseAPK.languages,
      installInstructions: firebaseAPK.installInstructions,
      changelog: firebaseAPK.changelog,
      supportEmail: firebaseAPK.supportEmail,
      privacyPolicyUrl: firebaseAPK.privacyPolicyUrl,
      isRestricted: firebaseAPK.isRestricted,
      downloadPassword: firebaseAPK.downloadPassword,
    );
  }

  /// Convert generic APKModel to FirebaseAPK
  static FirebaseAPK toFirebaseAPK(APKModel apkModel, {String? createdBy, String? updatedBy}) {
    return FirebaseAPK(
      id: apkModel.id,
      name: apkModel.name,
      packageName: apkModel.packageName,
      versionName: apkModel.versionName,
      versionCode: apkModel.versionCode,
      minSdk: apkModel.minSdk,
      targetSdk: apkModel.targetSdk,
      description: apkModel.description,
      apkUrl: apkModel.apkUrl,
      iconUrl: apkModel.iconUrl,
      screenshots: apkModel.screenshots,
      sizeBytes: apkModel.sizeBytes,
      isPinned: apkModel.isPinned,
      downloads: apkModel.downloads,
      createdBy: createdBy,
      updatedBy: updatedBy,
      createdAt: apkModel.createdAt,
      updatedAt: apkModel.updatedAt,
      developer: apkModel.developer,
      minRequirements: apkModel.minRequirements,
      playStoreUrl: apkModel.playStoreUrl,
      permissions: apkModel.permissions,
      category: apkModel.category,
      releaseDate: apkModel.releaseDate,
      languages: apkModel.languages,
      installInstructions: apkModel.installInstructions,
      changelog: apkModel.changelog,
      supportEmail: apkModel.supportEmail,
      privacyPolicyUrl: apkModel.privacyPolicyUrl,
      isRestricted: apkModel.isRestricted,
      downloadPassword: apkModel.downloadPassword,
    );
  }

  /// Convert list of FirebaseAPK to list of APKModel
  static List<APKModel> toAPKModelList(List<FirebaseAPK> firebaseAPKs) {
    return firebaseAPKs.map((firebaseAPK) => toAPKModel(firebaseAPK)).toList();
  }

  /// Convert list of APKModel to list of FirebaseAPK
  static List<FirebaseAPK> toFirebaseAPKList(List<APKModel> apkModels, {String? createdBy, String? updatedBy}) {
    return apkModels.map((apkModel) => toFirebaseAPK(apkModel, createdBy: createdBy, updatedBy: updatedBy)).toList();
  }
} 