package com.gallery.app_lock

import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivityLaunchConfigs
import android.content.Intent
import android.content.pm.PackageManager
import io.flutter.embedding.engine.FlutterEngine
import android.provider.Settings

class MainActivity: FlutterActivity() {
    private val LAUNCHER_CHANNEL = "app_lock/launcher"
    private val NOTIFICATION_CHANNEL = "app_locker/notifications"

    override fun onCreate(savedInstanceState: Bundle?) {
        intent.putExtra("background_mode", FlutterActivityLaunchConfigs.BackgroundMode.transparent.toString())
        super.onCreate(savedInstanceState)
        // restartNotificationService(context)
        // Setup launcher channel
        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, LAUNCHER_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "isDefaultLauncher") {
                result.success(isDefaultLauncher())
            } else {
                result.notImplemented()
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

    // fun restartNotificationService(context: Context) {
    //     val componentName = ComponentName(context, NotificationService::class.java)
    //     context.packageManager.setComponentEnabledSetting(
    //         componentName,
    //         PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
    //         PackageManager.DONT_KILL_APP
    //     )
    //     context.packageManager.setComponentEnabledSetting(
    //         componentName,
    //         PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
    //         PackageManager.DONT_KILL_APP
    //     )
    // }

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