package com.kekexiaoai.wordquest

import android.speech.tts.TextToSpeech
import java.util.Locale
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity(), TextToSpeech.OnInitListener {
    private var textToSpeech: TextToSpeech? = null
    private var isTextToSpeechReady = false
    private var pendingText: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        textToSpeech = TextToSpeech(this, this)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            PRONUNCIATION_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "speak" -> {
                    val text = call.argument<String>("text").orEmpty().trim()
                    if (text.isNotEmpty()) {
                        speak(text)
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            val languageResult = textToSpeech?.setLanguage(Locale.US)
            isTextToSpeechReady = languageResult != TextToSpeech.LANG_MISSING_DATA &&
                languageResult != TextToSpeech.LANG_NOT_SUPPORTED
            pendingText?.let { text ->
                pendingText = null
                speak(text)
            }
        }
    }

    override fun onDestroy() {
        textToSpeech?.stop()
        textToSpeech?.shutdown()
        textToSpeech = null
        super.onDestroy()
    }

    private fun speak(text: String) {
        val tts = textToSpeech ?: return
        if (!isTextToSpeechReady) {
            pendingText = text
            return
        }
        tts.speak(text, TextToSpeech.QUEUE_FLUSH, null, "word-quest-pronunciation")
    }

    companion object {
        private const val PRONUNCIATION_CHANNEL = "word_quest/pronunciation"
    }
}
