package com.example.turf_cross_platform

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.media.AudioAttributes
import android.media.SoundPool
import android.util.Log

class MainActivity : FlutterActivity() {
    private val CHANNEL = "turf.app/sfx"
    private var soundPool: SoundPool? = null
    private val soundMap = HashMap<String, Int>()
    private val loadedSounds = HashSet<Int>()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Initialize SoundPool for low-latency SFX playback
        val audioAttributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ASSISTANCE_SONIFICATION)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()

        soundPool = SoundPool.Builder()
            .setMaxStreams(5)
            .setAudioAttributes(audioAttributes)
            .build()

        soundPool?.setOnLoadCompleteListener { _, sampleId, status ->
            if (status == 0) {
                loadedSounds.add(sampleId)
            } else {
                Log.e("MainActivity", "Failed to load sound sample: $sampleId, status: $status")
            }
        }

        // List of all action sounds to pre-load
        val sounds = listOf(
            "button_click",
            "start_walk",
            "end_walk",
            "login",
            "logout",
            "recenter",
            "delete_history"
        )

        for (name in sounds) {
            try {
                // Flutter assets are compiled into the Android APK under flutter_assets/
                val afd = assets.openFd("flutter_assets/assets/sfx_$name.wav")
                val soundId = soundPool?.load(afd, 1) ?: 0
                if (soundId != 0) {
                    soundMap[name] = soundId
                }
            } catch (e: Exception) {
                Log.e("MainActivity", "Error loading sound file sfx_$name.wav: ${e.message}")
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "playSfx") {
                val name = call.argument<String>("name")
                if (name != null) {
                    playRetroBeep(name)
                    result.success(null)
                } else {
                    result.error("INVALID_ARGUMENTS", "Sound name was null", null)
                }
            } else if (call.method == "playRetroClick") {
                // For backwards compatibility
                playRetroBeep("button_click")
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun playRetroBeep(name: String) {
        val soundId = soundMap[name]
        if (soundId != null && loadedSounds.contains(soundId)) {
            soundPool?.play(soundId, 1.0f, 1.0f, 1, 0, 1.0f)
        } else {
            Log.w("MainActivity", "Sound sfx_$name.wav not loaded yet or load failed")
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        soundPool?.release()
        soundPool = null
    }
}
