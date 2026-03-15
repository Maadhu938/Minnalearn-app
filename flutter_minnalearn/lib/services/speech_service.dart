import 'package:flutter/services.dart';

class SpeechService {
  SpeechService._internal();

  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;

  static const MethodChannel _channel = MethodChannel('minnalearn/tts');

  Future<bool> speakJapanese(String text) async {
    final value = text.trim();
    if (value.isEmpty) {
      return false;
    }

    try {
      final result = await _channel.invokeMethod<bool>('speak', {'text': value});
      return result ?? false;
    } catch (_) {
      // Keep the UI responsive even if the platform channel is unavailable.
      return false;
    }
  }

  Future<void> stop() async {
    try {
      await _channel.invokeMethod('stop');
    } catch (_) {
      // Ignore channel errors on unsupported platforms.
    }
  }

  Future<void> playWrongAnswer() async {
    try {
      await _channel.invokeMethod('playWrongTone');
    } catch (_) {
      SystemSound.play(SystemSoundType.alert);
    }
  }

  Future<void> playCorrectAnswer() async {
    try {
      await _channel.invokeMethod('playCorrectTone');
    } catch (_) {
      SystemSound.play(SystemSoundType.click);
    }
  }
}
