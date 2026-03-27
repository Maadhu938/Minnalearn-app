import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:io';
import 'audio_service.dart';

class SpeechService {
  SpeechService._internal();

  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;

  static const MethodChannel _channel = MethodChannel('minnalearn/tts');
  FlutterTts? _flutterTts;
  Future<void>? _initFuture; // Guard: ensures only one init runs at a time
  bool _isLanguageAvailable = false;

  /// Lazy init — only runs once; subsequent calls reuse the same Future.
  Future<void> _ensureInitialized() {
    _initFuture ??= _doInit();
    return _initFuture!;
  }

  Future<void> _doInit() async {
    try {
      _flutterTts = FlutterTts();

      if (Platform.isAndroid) {
        try {
          final engines = await _flutterTts!.getEngines;
          if (engines is List && engines.contains("com.google.android.tts")) {
            await _flutterTts!.setEngine("com.google.android.tts");
          }
        } catch (_) {
          // Use default engine
        }
      }

      await _flutterTts!.setLanguage("ja-JP");
      await _flutterTts!.setSpeechRate(0.4);
      await _flutterTts!.setPitch(1.0);

      try {
        final result = await _flutterTts!.isLanguageAvailable("ja-JP");
        _isLanguageAvailable = result == true || result == 1;
      } catch (_) {
        _isLanguageAvailable = false;
      }
    } catch (_) {
      _flutterTts = null;
      _initFuture = null; // Allow retry on next call
    }
  }

  Future<void> openTtsSettings() async {
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('openTtsSettings');
      }
    } catch (_) {}
  }

  Future<bool> speakJapanese(String text) async {
    final value = text.trim();
    if (value.isEmpty) return false;

    try {
      await _ensureInitialized();
      if (_flutterTts == null) return false;

      // Re-check availability if it was previously unavailable
      if (!_isLanguageAvailable) {
        try {
          final result = await _flutterTts!.isLanguageAvailable("ja-JP");
          _isLanguageAvailable = result == true || result == 1;
        } catch (_) {
          return false;
        }
      }

      if (!_isLanguageAvailable) return false;

      await _flutterTts!.stop();
      await _flutterTts!.speak(value);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts?.stop();
    } catch (_) {}
  }

  Future<void> playWrongAnswer() async {
    await AudioService().playWrong();
  }

  Future<void> playCorrectAnswer() async {
    await AudioService().playCorrect();
  }
}
