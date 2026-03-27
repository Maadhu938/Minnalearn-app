import 'package:audioplayers/audioplayers.dart';

class AudioService {
  AudioService._internal();
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;

  final AudioPlayer _player = AudioPlayer();

  Future<void> playCorrect() async {
    try {
      await _player.play(AssetSource('audio/correct.mp3'));
    } catch (e) {
      print('Audio error: $e');
    }
  }

  Future<void> playWrong() async {
    try {
      await _player.play(AssetSource('audio/wrong.mp3'));
    } catch (e) {
      print('Audio error: $e');
    }
  }

  Future<void> playClick() async {
    try {
      await _player.play(AssetSource('audio/click.mp3'));
    } catch (e) {
      print('Audio error: $e');
    }
  }

  Future<void> playLevelComplete() async {
    try {
      await _player.play(AssetSource('audio/success.mp3'));
    } catch (e) {
      print('Audio error: $e');
    }
  }
}
