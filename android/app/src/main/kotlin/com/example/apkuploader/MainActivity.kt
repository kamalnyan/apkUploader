package com.example.apkuploader

import androidx.annotation.NonNull
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.content.pm.PackageManager
import android.util.Log
import java.io.File
import android.content.Context
import android.os.Environment

class MainActivity : FlutterActivity() {
    private val PERMISSIONS_CHANNEL = "com.apkuploader/permissions"
    private val INSTALL_CHANNEL = "com.apkuploader/install"
    private val TAG = "APKInstaller"
    
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Setup permissions channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERMISSIONS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openAllFilesAccessSettings" -> {
                    val opened = openAllFilesAccessSettings()
                    result.success(opened)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Setup install channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, INSTALL_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "installAPK" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath != null) {
                        val success = installAPK(filePath)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGUMENT", "File path cannot be null", null)
                    }
                }
                "installAPKWithSession" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath != null) {
                        // Use the same installAPK method for both regular and session-based installation
                        // This avoids the PendingIntent issue completely
                        val success = installAPK(filePath)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGUMENT", "File path cannot be null", null)
                    }
                }
                "hasInstallPermission" -> {
                    result.success(hasInstallPermission())
                }
                "requestInstallPermission" -> {
                    requestInstallPermission()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun installAPK(filePath: String): Boolean {
        try {
            val file = File(filePath)
            if (!file.exists()) {
                Log.e(TAG, "APK file does not exist: $filePath")
                return false
            }
            
            // Check if we have permission to install unknown apps
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && !hasInstallPermission()) {
                Log.e(TAG, "No permission to install APKs")
                requestInstallPermission()
                return false
            }
            
            if (Build.VERSION.SDK_INT >= 34) { // Android 14+ (UPSIDE_DOWN_CAKE)
                return installApkAndroid14Plus(file)
            } else {
                return installApkLegacy(file)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error installing APK: ${e.message}")
            e.printStackTrace()
            return false
        }
    }
    
    // For Android 14+ (API level 34+)
    private fun installApkAndroid14Plus(apkFile: File): Boolean {
        try {
            val apkUri = FileProvider.getUriForFile(
                context,
                "${context.packageName}.fileprovider",
                apkFile
            )
            
            var intent = Intent(Intent.ACTION_VIEW)
            intent.setDataAndType(apkUri, "application/vnd.android.package-archive")
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            
            // For Android 14+, try to use an explicit intent
            intent.setPackage("com.android.packageinstaller")
            
            if (intent.resolveActivity(context.packageManager) != null) {
                context.startActivity(intent)
                return true
            } else {
                // Fall back to the system package installer if default not found
                intent.setPackage(null) // Clear the package to make it implicit
                
                // Use ACTION_INSTALL_PACKAGE which is safer for newer Android versions
                intent = Intent(Intent.ACTION_INSTALL_PACKAGE)
                intent.data = apkUri
                intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                
                // Avoid PendingIntent security issues
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    // This constant doesn't exist - replace with proper handling
                    // intent.putExtra(android.content.pm.PackageInstaller.EXTRA_STATUS_PENDING_USER_ACTION, true)
                    
                    // For Android 12+ we don't need any special extras as the system handles the installation flow
                }
                
                context.startActivity(intent)
                return true
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error installing APK on Android 14+: ${e.message}")
            e.printStackTrace()
            return false
        }
    }
    
    // For Android 13 and below
    private fun installApkLegacy(apkFile: File): Boolean {
        try {
            val apkUri: Uri
            
            // For devices running Android N (API 24) and above, use FileProvider
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                apkUri = FileProvider.getUriForFile(
                    context,
                    "${context.packageName}.fileprovider",
                    apkFile
                )
                
                val intent = Intent(Intent.ACTION_VIEW)
                intent.setDataAndType(apkUri, "application/vnd.android.package-archive")
                intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                
                // For Android 12 (S) and newer, add proper flags
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TASK)
                    // Add extra to avoid security issues
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        intent.putExtra(Intent.EXTRA_NOT_UNKNOWN_SOURCE, true)
                    }
                }
                
                context.startActivity(intent)
            } else {
                // For older devices
                apkUri = Uri.fromFile(apkFile)
                val intent = Intent(Intent.ACTION_VIEW)
                intent.setDataAndType(apkUri, "application/vnd.android.package-archive")
                intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                context.startActivity(intent)
            }
            
            return true
        } catch (e: Exception) {
            Log.e(TAG, "Error in legacy APK installation: ${e.message}")
            e.printStackTrace()
            return false
        }
    }
    
    private fun hasInstallPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            packageManager.canRequestPackageInstalls()
        } else {
            true
        }
    }
    
    private fun requestInstallPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES)
            intent.data = Uri.parse("package:${context.packageName}")
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
        }
    }
    
    // Method to open All Files Access settings on Android 11+
    private fun openAllFilesAccessSettings(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                val intent = Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION)
                intent.addCategory("android.intent.category.DEFAULT")
                intent.data = Uri.parse("package:${applicationContext.packageName}")
                startActivity(intent)
                true
            } else {
                // For older versions, use app settings
                val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                intent.data = Uri.parse("package:${applicationContext.packageName}")
                startActivity(intent)
                true
            }
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }
}
