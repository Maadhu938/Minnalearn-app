import 'dart:async';
import 'database_service.dart';

class StudyTimerService {
  static final StudyTimerService _instance = StudyTimerService._internal();
  factory StudyTimerService() => _instance;
  StudyTimerService._internal();

  Timer? _timer;
  int _activeSessions = 0;
  int _secondsElapsed = 0;
  final int _saveIntervalSeconds = 10; // Save to DB every 10 seconds for robustness

  void startTimer() {
    _activeSessions++;
    if (_timer != null && _timer!.isActive) {
      return;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _secondsElapsed++;

      if (_secondsElapsed % _saveIntervalSeconds == 0) {
        _saveToDatabase();
      }
    });
  }

  void stopTimer() {
    if (_activeSessions > 0) {
      _activeSessions--;
    }

    if (_activeSessions > 0) {
      return;
    }

    _timer?.cancel();
    _timer = null;
    _saveToDatabase();
  }

  Future<void> _saveToDatabase() async {
    if (_secondsElapsed > 0) {
      await DatabaseService().addStudyTime(_secondsElapsed);
      _secondsElapsed = 0;
    }
  }

  Future<String> getFormattedStudyTime() async {
    int totalSeconds = await DatabaseService().getTotalStudyTime();
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}
