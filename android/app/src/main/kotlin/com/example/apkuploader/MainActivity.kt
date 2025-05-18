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
import android.content.pm.PackageInstaller
import android.content.Context
import android.content.IntentSender
import android.content.BroadcastReceiver
import android.app.PendingIntent
import android.util.Log
import java.io.File
import java.io.FileInputStream
import java.io.IOException
import java.io.InputStream
import java.io.OutputStream
import android.content.pm.PackageInfo
import android.os.Environment

class MainActivity : FlutterActivity() {
    private val PERMISSIONS_CHANNEL = "com.apkuploader/permissions"
    private val INSTALL_CHANNEL = "com.apkuploader/install"
    private val APK_PARSER_CHANNEL = "com.apkuploader/apk_parser"
    private val TAG = "APKInstaller"
    private val PACKAGE_INSTALLED_ACTION by lazy { "${context.packageName}.PACKAGE_INSTALLED" }
    
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
                        val success = installAPKWithSession(filePath)
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
        
        // Set up APK parser channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APK_PARSER_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getApkInfo" -> {
                    val apkFilePath = call.argument<String>("apkFilePath")
                    if (apkFilePath != null) {
                        val apkInfo = getApkInfo(apkFilePath)
                        result.success(apkInfo)
                    } else {
                        result.error("INVALID_ARGUMENT", "APK file path is null", null)
                    }
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
    
    private fun installAPKWithSession(filePath: String): Boolean {
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

            // Use PackageInstaller for a session-based installation
            val packageInstaller = context.packageManager.packageInstaller
            
            // Create a new installation session
            val params = PackageInstaller.SessionParams(
                PackageInstaller.SessionParams.MODE_FULL_INSTALL
            )
            
            // Set the app info (for Android 12+)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                params.setRequireUserAction(PackageInstaller.SessionParams.USER_ACTION_NOT_REQUIRED)
            }
            
            // Create installation session
            val sessionId = packageInstaller.createSession(params)
            val session = packageInstaller.openSession(sessionId)

            // Write the APK file to the session
            session.use { activeSession ->
                val fileSize = file.length()
                
                var inputStream: InputStream? = null
                var outputStream: OutputStream? = null
                
                try {
                    inputStream = FileInputStream(file)
                    outputStream = activeSession.openWrite("package", 0, fileSize)
                    
                    val buffer = ByteArray(65536) // 64 KB buffer
                    var bytesRead: Int
                    var totalBytesWritten: Long = 0
                    
                    while (inputStream.read(buffer).also { bytesRead = it } != -1) {
                        outputStream.write(buffer, 0, bytesRead)
                        outputStream.flush()
                        totalBytesWritten += bytesRead.toLong()
                    }
                    
                    // Make sure to set the length to the actual size written
                    activeSession.fsync(outputStream)
                    
                    Log.d(TAG, "APK written to session: $totalBytesWritten bytes")
                } catch (e: IOException) {
                    Log.e(TAG, "Error writing APK to session: ${e.message}")
                    e.printStackTrace()
                    return false
                } finally {
                    inputStream?.close()
                    outputStream?.close()
                }
                
                // Create a broadcast intent for installation status
                val intent = Intent(PACKAGE_INSTALLED_ACTION)
                intent.setPackage(context.packageName)
                
                // Create PendingIntent for installation callback
                val pendingIntent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    PendingIntent.getBroadcast(
                        context,
                        sessionId,
                        intent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
                    )
                } else {
                    PendingIntent.getBroadcast(
                        context,
                        sessionId,
                        intent,
                        PendingIntent.FLAG_UPDATE_CURRENT
                    )
                }
                
                // Commit the session
                activeSession.commit(pendingIntent.intentSender)
                Log.d(TAG, "Installation session committed")
                return true
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error in session-based installation: ${e.message}")
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
    
    // Extract information from APK file
    private fun getApkInfo(apkFilePath: String): Map<String, Any?> {
        val result = HashMap<String, Any?>()
        
        try {
            val pm = context.packageManager
            val packageInfo = pm.getPackageArchiveInfo(apkFilePath, 
                PackageManager.GET_ACTIVITIES or
                PackageManager.GET_PERMISSIONS or
                PackageManager.GET_PROVIDERS or
                PackageManager.GET_RECEIVERS or
                PackageManager.GET_SERVICES or
                PackageManager.GET_META_DATA
            )
            
            if (packageInfo != null) {
                packageInfo.applicationInfo?.sourceDir = apkFilePath
                packageInfo.applicationInfo?.publicSourceDir = apkFilePath
                
                // Get app name
                val appName = packageInfo.applicationInfo?.loadLabel(pm)?.toString() ?: packageInfo.packageName
                result["appName"] = appName
                
                // Get package name
                result["packageName"] = packageInfo.packageName
                
                // Get version info
                result["versionName"] = packageInfo.versionName
                
                // Get version code based on Android version
                result["versionCode"] = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    packageInfo.longVersionCode.toInt()
                } else {
                    @Suppress("DEPRECATION")
                    packageInfo.versionCode
                }
                
                // Get SDK versions
                result["minSdkVersion"] = packageInfo.applicationInfo?.minSdkVersion
                result["targetSdkVersion"] = packageInfo.applicationInfo?.targetSdkVersion
                
                // Get installer name if available
                val installerPackageName = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    pm.getInstallSourceInfo(packageInfo.packageName)?.installingPackageName
                } else {
                    @Suppress("DEPRECATION")
                    pm.getInstallerPackageName(packageInfo.packageName)
                }
                result["installerName"] = installerPackageName ?: ""
                
                // Get developer name from application meta-data if available
                val applicationInfo = packageInfo.applicationInfo
                if (applicationInfo?.metaData != null) {
                    val developerName = applicationInfo.metaData?.getString("developer_name")
                    result["developer"] = developerName ?: ""
                }
                
                // Get permissions
                val permissions = packageInfo.requestedPermissions
                if (permissions != null) {
                    result["permissions"] = permissions.toList()
                } else {
                    result["permissions"] = listOf<String>()
                }
                
                // Extract other useful information
                try {
                    val file = File(apkFilePath)
                    result["fileSize"] = file.length()
                    result["lastModified"] = file.lastModified()
                } catch (e: Exception) {
                    Log.e(TAG, "Error getting file details: ${e.message}")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error extracting APK info: ${e.message}")
            e.printStackTrace()
        }
        
        return result
    }
}
