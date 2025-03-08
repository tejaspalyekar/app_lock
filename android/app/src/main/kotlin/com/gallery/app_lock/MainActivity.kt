package com.gallery.app_lock

import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivityLaunchConfigs
import android.content.Intent
import android.content.pm.PackageManager
import io.flutter.embedding.engine.FlutterEngine
import android.provider.Settings
import android.view.WindowManager

class MainActivity: FlutterActivity() {
    private val LAUNCHER_CHANNEL = "app_lock/launcher"
    private val NOTIFICATION_CHANNEL = "app_locker/notifications"
    private val SECURE_LAUNCH_CHANNEL = "app_lock/secure_launch"

    override fun onCreate(savedInstanceState: Bundle?) {
        intent.putExtra("background_mode", FlutterActivityLaunchConfigs.BackgroundMode.transparent.toString())
        super.onCreate(savedInstanceState)

        // Setup launcher channel
        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, LAUNCHER_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "isDefaultLauncher") {
                result.success(isDefaultLauncher())
            } else {
                result.notImplemented()
            }
        }

        // Setup secure launch channel
        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, SECURE_LAUNCH_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "launchSecureApp" -> {
                    val packageName = call.argument<String>("packageName")
                    val isLocked = call.argument<Boolean>("isLocked") ?: false
                    launchSecureApp(packageName, isLocked)
                    result.success(null)
                }
                "setSecureFlag" -> {
                    setSecureFlag()
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(DataCleanerPlugin())
        
        // Setup notification channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATION_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestNotificationAccess" -> {
                    requestNotificationAccess()
                    result.success(null)
                }
                "checkNotificationPermission" -> {
                    val hasPermission = checkNotificationPermission()
                    result.success(hasPermission)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun launchSecureApp(packageName: String?, isLocked: Boolean) {
        if (packageName == null) return

        val intent = packageManager.getLaunchIntentForPackage(packageName)
        intent?.apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            
            if (isLocked) {
                // Prevent app from appearing in recents
                addFlags(Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS)
                // Don't keep in history stack
                addFlags(Intent.FLAG_ACTIVITY_NO_HISTORY)
            }
        }
        
        startActivity(intent)
        
        if (isLocked) {
            setSecureFlag()
        }
    }

    private fun setSecureFlag() {
        runOnUiThread {
            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        }
    }

    private fun requestNotificationAccess() {
        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }

    private fun checkNotificationPermission(): Boolean {
        val packageName = context.packageName
        val flat = Settings.Secure.getString(context.contentResolver, "enabled_notification_listeners")
        return flat != null && flat.contains(packageName)
    }

    private fun isDefaultLauncher(): Boolean {
        val intent = Intent(Intent.ACTION_MAIN)
        intent.addCategory(Intent.CATEGORY_HOME)
        val resolveInfo = packageManager.resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY)
        return resolveInfo?.activityInfo?.packageName == packageName
    }
}