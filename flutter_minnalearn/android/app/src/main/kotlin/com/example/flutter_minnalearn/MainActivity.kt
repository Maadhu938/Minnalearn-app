package com.example.flutter_minnalearn

import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.media.AudioManager
import android.media.ToneGenerator
import android.speech.tts.TextToSpeech
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class MainActivity : FlutterActivity(), TextToSpeech.OnInitListener {
    private val channelName = "minnalearn/tts"
    private val mainHandler = Handler(Looper.getMainLooper())
    private var textToSpeech: TextToSpeech? = null
    private var toneGenerator: ToneGenerator? = null
    private var ttsReady = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        textToSpeech = TextToSpeech(this, this)
        toneGenerator = ToneGenerator(AudioManager.STREAM_NOTIFICATION, 90)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "speak" -> {
                        val text = call.argument<String>("text").orEmpty()
                        if (text.isBlank()) {
                            result.success(false)
                            return@setMethodCallHandler
                        }

                        if (speakNow(text)) {
                            result.success(true)
                            return@setMethodCallHandler
                        }

                        if (textToSpeech != null) {
                            mainHandler.postDelayed({
                                speakNow(text)
                            }, 700)
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    }

                    "stop" -> {
                        textToSpeech?.stop()
                        result.success(true)
                    }

                    "playWrongTone" -> {
                        toneGenerator?.startTone(ToneGenerator.TONE_PROP_NACK, 180)
                        result.success(true)
                    }

                    "playCorrectTone" -> {
                        toneGenerator?.startTone(ToneGenerator.TONE_PROP_ACK, 140)
                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    override fun onInit(status: Int) {
        if (status != TextToSpeech.SUCCESS) {
            ttsReady = false
            return
        }

        ttsReady = true
        configureJapaneseVoice()

        textToSpeech?.setSpeechRate(0.42f)
        textToSpeech?.setPitch(1.0f)
    }

    private fun configureJapaneseVoice() {
        val engine = textToSpeech ?: return

        val japaneseVoice = engine.voices?.firstOrNull { voice ->
            voice.locale?.language == Locale.JAPANESE.language
        }
        if (japaneseVoice != null) {
            engine.voice = japaneseVoice
            return
        }

        val preferredLocales = listOf(
            Locale("ja", "JP"),
            Locale.JAPAN,
            Locale.JAPANESE,
        )
        for (locale in preferredLocales) {
            val setLanguageResult = engine.setLanguage(locale)
            if (setLanguageResult != TextToSpeech.LANG_MISSING_DATA &&
                setLanguageResult != TextToSpeech.LANG_NOT_SUPPORTED
            ) {
                return
            }
        }
    }

    private fun speakNow(text: String): Boolean {
        val engine = textToSpeech ?: return false
        if (!ttsReady) {
            return false
        }

        engine.stop()
        val speakResult = engine.speak(
            text,
            TextToSpeech.QUEUE_FLUSH,
            null,
            "minnalearn_tts"
        )
        return speakResult != TextToSpeech.ERROR
    }

    override fun onDestroy() {
        textToSpeech?.stop()
        textToSpeech?.shutdown()
        textToSpeech = null
        toneGenerator?.release()
        toneGenerator = null
        super.onDestroy()
    }
}
