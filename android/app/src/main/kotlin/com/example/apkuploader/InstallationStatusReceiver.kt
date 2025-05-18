package com.example.apkuploader

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageInstaller
import android.util.Log

/**
 * BroadcastReceiver to handle PackageInstaller session results
 */
class InstallationStatusReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "InstallationReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val sessionId = intent.getIntExtra(PackageInstaller.EXTRA_SESSION_ID, -1)
        if (sessionId == -1) {
            Log.e(TAG, "Invalid session ID")
            return
        }

        val status = intent.getIntExtra(PackageInstaller.EXTRA_STATUS, PackageInstaller.STATUS_FAILURE)
        val packageName = intent.getStringExtra(PackageInstaller.EXTRA_PACKAGE_NAME)
        val message = intent.getStringExtra(PackageInstaller.EXTRA_STATUS_MESSAGE)

        when (status) {
            PackageInstaller.STATUS_PENDING_USER_ACTION -> {
                // This status means that the user needs to confirm the installation
                // We need to start the intent that allows the user to confirm
                val confirmIntent = intent.getParcelableExtra<Intent>(Intent.EXTRA_INTENT)
                if (confirmIntent != null) {
                    confirmIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    try {
                        context.startActivity(confirmIntent)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error starting install confirmation activity", e)
                    }
                } else {
                    Log.e(TAG, "Missing confirmation intent")
                }
            }
            PackageInstaller.STATUS_SUCCESS -> {
                Log.d(TAG, "Installation succeeded: $packageName")
                // You can send this status back to Flutter via a method channel if needed
            }
            PackageInstaller.STATUS_FAILURE,
            PackageInstaller.STATUS_FAILURE_ABORTED,
            PackageInstaller.STATUS_FAILURE_BLOCKED,
            PackageInstaller.STATUS_FAILURE_CONFLICT,
            PackageInstaller.STATUS_FAILURE_INCOMPATIBLE,
            PackageInstaller.STATUS_FAILURE_INVALID,
            PackageInstaller.STATUS_FAILURE_STORAGE -> {
                Log.e(TAG, "Installation failed with status $status: $message")
                // You can send this status back to Flutter via a method channel if needed
            }
            else -> {
                Log.w(TAG, "Unhandled installation status: $status")
            }
        }
    }
} 