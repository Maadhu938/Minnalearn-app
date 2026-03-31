import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'database_service.dart';

class CloudService {
  CloudService._internal();
  static final CloudService _instance = CloudService._internal();
  factory CloudService() => _instance;

  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      return null;
    }
  }
  
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get uid => _auth.currentUser?.uid;

  Future<void> syncAll() async {
    if (uid == null) return;
    try {
      // Initial pull to get remote progress
      await pullFromCloud();
      // Then push local state to ensure they match
      await pushAllLocalData();
    } catch (e) {
      debugPrint('Cloud sync skipped: database not configured ($e)');
    }
    DatabaseService().notifyDataChanged();
  }

  Future<void> pullFromCloud() async {
    final fs = _firestore;
    if (uid == null || fs == null) return;
    
    try {
      final userDoc = await fs.collection('users').doc(uid).get();
      if (!userDoc.exists) return;

      final data = userDoc.data()!;
      final db = DatabaseService();

      // 1. Sync User Stats
      if (data.containsKey('stats')) {
        final stats = data['stats'] as Map<String, dynamic>;
        if (stats.containsKey('current_streak')) {
          await db.updateStat('current_streak', stats['current_streak']);
        }
        if (stats.containsKey('total_study_time_seconds')) {
          await db.updateStat('total_study_time_seconds', stats['total_study_time_seconds']);
        }
        if (stats.containsKey('last_study_date')) {
          await db.updateStat('last_study_date', stats['last_study_date']);
        }
      }

      // 2. Sync Lesson Progress
      if (data.containsKey('lessons')) {
        final lessons = data['lessons'] as Map<String, dynamic>;
        for (var entry in lessons.entries) {
          final lessonId = int.tryParse(entry.key);
          if (lessonId != null) {
            final progress = (entry.value['progress'] as num?)?.toDouble() ?? 0.0;
            await db.updateLessonProgress(lessonId, progress);
          }
        }
      }

      // 3. Sync Learned Kanji
      if (data.containsKey('learned_kanji')) {
        final kanjiSet = Set<String>.from(data['learned_kanji']);
        for (var char in kanjiSet) {
          await db.markKanjiAsLearned(char);
        }
      }

      // 4. Sync Bookmarks
      if (data.containsKey('bookmarks')) {
        final bookmarks = List<String>.from(data['bookmarks']);
        for (var vocabId in bookmarks) {
          await db.setVocabularyBookmark(vocabId, true);
        }
      }

      // 5. Sync Achievements
      if (data.containsKey('achievements')) {
        final cloudAchievements = List<String>.from(data['achievements']);
        final localAchievements = await db.getUnlockedAchievementIds();
        for (var id in cloudAchievements) {
          if (!localAchievements.contains(id)) {
            await db.markAchievementUnlocked(id);
          }
        }
      }
      
      db.notifyDataChanged();
    } catch (e) {
      debugPrint('Error pulling from cloud: $e');
    }
  }

  Future<void> pushAllLocalData() async {
    final fs = _firestore;
    if (uid == null || fs == null) return;
    
    final db = DatabaseService();
    
    try {
      final streak = await db.getStreak();
      final totalTime = await db.getTotalStudyTime();
      final lessons = await db.getLessons();
      final bookmarks = await db.getBookmarkedVocabularyIds();
      final learnedKanji = await db.getAllLearnedKanjiChars();
      
      await fs.collection('users').doc(uid).set({
        'stats': {
          'current_streak': streak,
          'total_study_time_seconds': totalTime,
          'last_study_date': DateTime.now().toIso8601String().split('T')[0],
          'last_sync': FieldValue.serverTimestamp(),
        },
        'lessons': {
          for (var l in lessons) l.id.toString(): {
            'progress': l.progress,
            'completed': l.completed ? 1 : 0,
          }
        },
        'bookmarks': bookmarks.toList(),
        'learned_kanji': learnedKanji.toList(),
        'achievements': await db.getUnlockedAchievementIds(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error pushing all data to cloud: $e');
    }
  }

  // Slice-based push methods for real-time updates
  Future<void> pushStats(int streak, int totalTime) async {
    final fs = _firestore;
    if (uid == null || fs == null) return;
    try {
      await fs.collection('users').doc(uid).update({
        'stats.current_streak': streak,
        'stats.total_study_time_seconds': totalTime,
        'stats.last_study_date': DateTime.now().toIso8601String(),
        'stats.last_sync': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // If doc doesn't exist, use pushAllLocalData
      await pushAllLocalData();
    }
  }

  Future<void> pushSingleLessonProgress(int lessonId, double progress) async {
    final fs = _firestore;
    if (uid == null || fs == null) return;
    try {
      await fs.collection('users').doc(uid).update({
        'lessons.$lessonId': {
          'progress': progress,
          'completed': progress >= 1.0 ? 1 : 0,
        }
      });
    } catch (e) {
      await pushAllLocalData();
    }
  }

  Future<void> pushBookmarks(List<String> bookmarks) async {
    final fs = _firestore;
    if (uid == null || fs == null) return;
    try {
      await fs.collection('users').doc(uid).update({
        'bookmarks': bookmarks,
      });
    } catch (e) {
      await pushAllLocalData();
    }
  }

  Future<void> pushLearnedKanji(List<String> kanji) async {
    final fs = _firestore;
    if (uid == null || fs == null) return;
    try {
      await fs.collection('users').doc(uid).update({
        'learned_kanji': FieldValue.arrayUnion(kanji),
      });
    } catch (e) {
      await pushAllLocalData();
    }
  }

  Future<void> pushAchievements(List<String> ids) async {
    final fs = _firestore;
    if (uid == null || fs == null) return;
    try {
      await fs.collection('users').doc(uid).update({
        'achievements': ids,
      });
    } catch (e) {
      await pushAllLocalData();
    }
  }

  Future<void> deleteUserData(String userId) async {
    final fs = _firestore;
    if (fs == null) return;
    try {
      await fs.collection('users').doc(userId).delete();
    } catch (e) {
      debugPrint('Error deleting user data: $e');
    }
  }
}
