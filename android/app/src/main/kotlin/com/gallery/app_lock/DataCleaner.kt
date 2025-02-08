package com.gallery.app_lock

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import android.os.Environment

class DataCleanerPlugin: FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "target_app_data_cleaner")
        channel.setMethodCallHandler(this)
        context = binding.applicationContext
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "clearTargetAppData" -> {
                val targetPackage = call.argument<String>("packageName")
                if (targetPackage != null && targetPackage != context.packageName) {
                    try {
                        // Clear app data
                        Runtime.getRuntime().exec("pm clear $targetPackage")
                        
                        // Clear media folders
                        val externalDir = Environment.getExternalStorageDirectory()
                        val mediaDir = File(externalDir, "Android/media/$targetPackage")
                        val dataDir = File(externalDir, "Android/data/$targetPackage")
                        
                        if (mediaDir.exists()) deleteRecursive(mediaDir)
                        if (dataDir.exists()) deleteRecursive(dataDir)
                        
                        // For specific apps, clear their media folders
                        when (targetPackage) {
                            "com.whatsapp" -> deleteRecursive(File(externalDir, "WhatsApp"))
                            "org.telegram.messenger" -> deleteRecursive(File(externalDir, "Telegram"))
                              "com.instagram.android" -> deleteRecursive(File(externalDir, "Instagram"))
                            
                            // Add other apps as needed
                        }
                        
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                } else {
                    result.error("INVALID_PACKAGE", "Invalid package name or attempted to clear launcher app", null)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun deleteRecursive(fileOrDirectory: File) {
        if (fileOrDirectory.isDirectory) {
            fileOrDirectory.listFiles()?.forEach { child ->
                deleteRecursive(child)
            }
        }
        fileOrDirectory.delete()
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
