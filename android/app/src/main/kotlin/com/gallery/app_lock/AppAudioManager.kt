package com.gallery.app_lock

import android.content.Context
import android.media.AudioManager
import android.util.Log

class AppAudioManager(private val context: Context) {
    private val audioManager: AudioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    private var originalRingerMode: Int = AudioManager.RINGER_MODE_NORMAL

    fun muteRingtoneForApp(packageName: String) {
        try {
            // Store the original ringer mode
            originalRingerMode = audioManager.ringerMode
            
            // Set to silent
            audioManager.ringerMode = AudioManager.RINGER_MODE_SILENT
            
            // You might want to restore the ringer mode after a delay
            android.os.Handler().postDelayed({
                restoreRingerMode()
            }, 5000) // Restore after 5 seconds
        } catch (e: Exception) {
            Log.e("AppAudioManager", "Error muting ringtone: ${e.message}")
        }
    }

    private fun restoreRingerMode() {
        try {
            audioManager.ringerMode = originalRingerMode
        } catch (e: Exception) {
            Log.e("AppAudioManager", "Error restoring ringer mode: ${e.message}")
        }
    }

    fun cleanup() {
        // Ensure ringer mode is restored
        restoreRingerMode()
    }
}