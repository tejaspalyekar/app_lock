package com.gallery.app_lock
import android.app.Notification
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import org.json.JSONArray
import java.util.Base64
import android.app.NotificationChannel
class NotificationService : NotificationListenerService() {
    companion object {
        private const val TAG = "NotificationService"
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val LOCKED_APPS_KEY = "flutter.LOCKED_APP_LIST"
    }

    private var audioManager: AudioManager? = null
    private lateinit var notificationManager: NotificationManager

    override fun onCreate() {
        super.onCreate()
        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && 
            !notificationManager.isNotificationPolicyAccessGranted) {
            val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            startActivity(intent)
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        super.onNotificationRemoved(sbn)
        val packageName = sbn?.packageName
        Log.d(TAG, "Notification removed from: $packageName")

        if (packageName?.let { isAppLocked(it) } == true) {
            if (isCallNotification(sbn)) {
                Log.d(TAG, "Removing call notification detected from: $packageName")
                restoreAudioSettings()
            }
        }
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val packageName = sbn.packageName
        Log.d(TAG, "Notification received from: $packageName")

        if (isAppLocked(packageName)) {
            cancelNotification(sbn.key)

            if (isCallNotification(sbn)) {
                Log.d(TAG, "Call notification detected from: $packageName")
                handleIncomingCall(sbn)
                cancelNotification(sbn.key)
                disableWhatsAppCallNotifications()
            }

            scheduleNotificationCancellation(sbn.key)
        }
    }

    private fun disableWhatsAppCallNotifications() {
        val channels = notificationManager.notificationChannels

        for (channel in channels) {
            Log.d("WhatsAppChannels", "ID: ${channel.id}, Name: ${channel.name}, Importance: ${channel.importance}")
            if (channel.id.contains("call", ignoreCase = true) || channel.id.contains("ringing", ignoreCase = true)) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    val updatedChannel = NotificationChannel(channel.id, channel.name, NotificationManager.IMPORTANCE_NONE)
                    notificationManager.createNotificationChannel(updatedChannel)
                }
            }
        }
    }

    private fun scheduleNotificationCancellation(key: String) {
        val delays = longArrayOf(0, 50, 100, 200, 500, 1000)
        delays.forEach { delay ->
            Handler(Looper.getMainLooper()).postDelayed({
                try {
                    cancelNotification(key)
                } catch (e: Exception) {
                    Log.e(TAG, "Error in scheduled cancellation: ${e.message}")
                }
            }, delay)
        }
    }

    private fun isCallNotification(sbn: StatusBarNotification): Boolean {
        val extras = sbn.notification.extras
        val flags = sbn.notification.flags

        if ((flags and Notification.FLAG_HIGH_PRIORITY) != 0 ||
            (flags and Notification.FLAG_FOREGROUND_SERVICE) != 0 ||
            (flags and Notification.FLAG_NO_CLEAR) != 0 ||
            sbn.notification.priority == Notification.PRIORITY_HIGH ||
            sbn.notification.priority == Notification.PRIORITY_MAX) {

            return when {
                sbn.notification.category == Notification.CATEGORY_CALL -> true
                sbn.notification.category == "call" -> true
                sbn.notification.category == "incoming_call" -> true
                extras.getString(Notification.EXTRA_TEMPLATE)?.contains("call", ignoreCase = true) == true -> true
                extras.getString("android.title")?.let {
                    it.contains("calling", ignoreCase = true) ||
                    it.contains("incoming", ignoreCase = true) ||
                    it.contains("video call", ignoreCase = true) ||
                    it.contains("voice call", ignoreCase = true)
                } == true -> true
                extras.getString("android.text")?.let {
                    it.contains("calling", ignoreCase = true) ||
                    it.contains("incoming", ignoreCase = true) ||
                    it.contains("video call", ignoreCase = true) ||
                    it.contains("voice call", ignoreCase = true)
                } == true -> true
                else -> false
            }
        }
        return false
    }

    private fun handleIncomingCall(sbn: StatusBarNotification) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                if (notificationManager.isNotificationPolicyAccessGranted) {
                    cancelNotification(sbn.key)
                    enableDNDAndMute()
                    scheduleNotificationCancellation(sbn.key)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error handling call: ${e.message}")
            }
        }
    }

    private fun enableDNDAndMute() {
        try {
            notificationManager.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_NONE)
            audioManager?.let { audio ->
                audio.ringerMode = AudioManager.RINGER_MODE_SILENT
                val streamsToMute = arrayOf(
                    AudioManager.STREAM_RING,
                    AudioManager.STREAM_NOTIFICATION,
                    AudioManager.STREAM_MUSIC,
                    AudioManager.STREAM_VOICE_CALL,
                    AudioManager.STREAM_SYSTEM,
                    AudioManager.STREAM_ALARM
                )

                streamsToMute.forEach { streamType ->
                    try {
                        audio.adjustStreamVolume(streamType, AudioManager.ADJUST_MUTE, 0)
                        audio.setStreamVolume(streamType, 0, 0)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error muting stream $streamType: ${e.message}")
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error in enableDNDAndMute: ${e.message}")
        }
    }

    private fun restoreAudioSettings() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                if (notificationManager.isNotificationPolicyAccessGranted) {
                    notificationManager.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALL)
                    audioManager?.let { audio ->
                        audio.ringerMode = AudioManager.RINGER_MODE_NORMAL
                        val streamsToUnmute = arrayOf(
                            AudioManager.STREAM_RING,
                            AudioManager.STREAM_NOTIFICATION,
                            AudioManager.STREAM_MUSIC,
                            AudioManager.STREAM_VOICE_CALL,
                            AudioManager.STREAM_SYSTEM,
                            AudioManager.STREAM_ALARM
                        )

                        streamsToUnmute.forEach { streamType ->
                            audio.adjustStreamVolume(streamType, AudioManager.ADJUST_UNMUTE, 0)
                        }
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error restoring audio: ${e.message}")
            }
        }
    }

    private fun isAppLocked(packageName: String): Boolean {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val lockedAppsString = prefs.getString(LOCKED_APPS_KEY, null) ?: return false

        return try {
            val jsonStr = if (lockedAppsString.startsWith("[")) lockedAppsString else String(Base64.getDecoder().decode(lockedAppsString))
            val jsonArray = JSONArray(jsonStr)
            List(jsonArray.length()) { i -> jsonArray.getString(i) }.contains(packageName)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to parse locked apps: ${e.message}")
            false
        }
    }

    // override fun onDestroy() {
    //     super.onDestroy()
    //     restoreAudioSettings()
    // }
}

