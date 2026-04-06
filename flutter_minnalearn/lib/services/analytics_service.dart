import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalytics get analytics => _analytics;
  FirebaseAnalyticsObserver get observer => FirebaseAnalyticsObserver(analytics: _analytics);

  Future<void> logTabView(String tabName) async {
    await _analytics.logEvent(name: 'tab_view', parameters: {'tab': tabName});
  }

  Future<void> logPasswordResetRequested() async {
    await _analytics.logEvent(name: 'password_reset_requested');
  }

  // ─── SCREEN TRACKING ─────────────────────────────────────────────
  Future<void> logScreen(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  // ─── LESSON EVENTS ───────────────────────────────────────────────
  Future<void> logLessonStarted(int lessonId) async {
    await _analytics.logEvent(
      name: 'lesson_started',
      parameters: {'lesson_id': lessonId},
    );
  }

  Future<void> logLessonCompleted(int lessonId) async {
    await _analytics.logEvent(
      name: 'lesson_completed',
      parameters: {'lesson_id': lessonId},
    );
  }

  // ─── VOCABULARY EVENTS ───────────────────────────────────────────
  Future<void> logVocabLearned(int lessonId, int count) async {
    await _analytics.logEvent(
      name: 'vocab_learned',
      parameters: {
        'lesson_id': lessonId,
        'vocab_count': count,
      },
    );
  }

  Future<void> logVocabBookmarked(String vocabId) async {
    await _analytics.logEvent(
      name: 'vocab_bookmarked',
      parameters: {'vocab_id': vocabId},
    );
  }

  // ─── KANJI EVENTS ────────────────────────────────────────────────
  Future<void> logKanjiLearned(String kanji) async {
    await _analytics.logEvent(
      name: 'kanji_learned',
      parameters: {'kanji': kanji},
    );
  }

  // ─── QUIZ EVENTS ─────────────────────────────────────────────────
  Future<void> logQuizStarted(int lessonId) async {
    await _analytics.logEvent(
      name: 'quiz_started',
      parameters: {'lesson_id': lessonId},
    );
  }

  Future<void> logQuizCompleted(int lessonId, int score, int total) async {
    await _analytics.logEvent(
      name: 'quiz_completed',
      parameters: {
        'lesson_id': lessonId,
        'score': score,
        'total': total,
        'percentage': ((score / total) * 100).round(),
      },
    );
  }

  // ─── GAME EVENTS ─────────────────────────────────────────────────
  Future<void> logGamePlayed(String gameName, int score) async {
    await _analytics.logEvent(
      name: 'game_played',
      parameters: {
        'game_name': gameName,
        'score': score,
      },
    );
  }

  // ─── STREAK EVENTS ───────────────────────────────────────────────
  Future<void> logStreakUpdated(int streakDays) async {
    await _analytics.logEvent(
      name: 'streak_updated',
      parameters: {'streak_days': streakDays},
    );
  }

  // ─── ACHIEVEMENT EVENTS ──────────────────────────────────────────
  Future<void> logAchievementUnlocked(String achievementId) async {
    await _analytics.logEvent(
      name: 'achievement_unlocked',
      parameters: {'achievement_id': achievementId},
    );
  }

  // ─── AUTH EVENTS ─────────────────────────────────────────────────
  Future<void> logSignUp(String method) async {
    await _analytics.logSignUp(signUpMethod: method);
  }

  Future<void> logLogin(String method) async {
    await _analytics.logLogin(loginMethod: method);
  }

  // ─── STUDY TIME ──────────────────────────────────────────────────
  Future<void> logStudySession(int durationSeconds) async {
    await _analytics.logEvent(
      name: 'study_session',
      parameters: {
        'duration_seconds': durationSeconds,
        'duration_minutes': (durationSeconds / 60).round(),
      },
    );
  }
}
