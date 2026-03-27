import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../main.dart';
import 'database_service.dart';
import 'cloud_service.dart';
import 'audio_service.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final int goal;
  final Color color;
  final _AchievementType type;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.goal,
    required this.color,
    required this.type,
  });
}

enum _AchievementType { lessons, streak, vocabulary, kanji, score }

class AchievementService {
  AchievementService._internal();
  static final AchievementService _instance = AchievementService._internal();
  factory AchievementService() => _instance;

  final List<Achievement> _allAchievements = [
    Achievement(
      id: 'first_lesson',
      title: 'First Step',
      description: 'Complete your first lesson.',
      icon: LucideIcons.flag,
      goal: 1,
      color: const Color(0xFF3B82F6),
      type: _AchievementType.lessons,
    ),
    Achievement(
      id: 'streak_3',
      title: 'Consistent Learner',
      description: 'Reach a 3-day study streak.',
      icon: LucideIcons.flame,
      goal: 3,
      color: const Color(0xFFF97316),
      type: _AchievementType.streak,
    ),
    Achievement(
      id: 'streak_7',
      title: 'Week Warrior',
      description: 'Build a 7 day streak.',
      icon: LucideIcons.flame,
      goal: 7,
      color: const Color(0xFFF59E0B),
      type: _AchievementType.streak,
    ),
    Achievement(
      id: 'kanji_10',
      title: 'Kanji Beginner',
      description: 'Learn 10 distinct Kanji.',
      icon: LucideIcons.sparkles,
      goal: 10,
      color: const Color(0xFF8B5CF6),
      type: _AchievementType.kanji,
    ),
    Achievement(
      id: 'kanji_25',
      title: 'Kanji Learner',
      description: 'Study 25 kanji cards.',
      icon: LucideIcons.sparkles,
      goal: 25,
      color: const Color(0xFF6366F1),
      type: _AchievementType.kanji,
    ),
    Achievement(
      id: 'vocab_50',
      title: 'Vocab Starter',
      description: 'Learn 50 vocabulary items.',
      icon: LucideIcons.bookOpen,
      goal: 50,
      color: const Color(0xFFEC4899),
      type: _AchievementType.vocabulary,
    ),
    Achievement(
      id: 'vocab_100',
      title: 'Vocab Master',
      description: 'Learn 100 vocabulary items.',
      icon: LucideIcons.bookOpen,
      goal: 100,
      color: const Color(0xFFE11D48),
      type: _AchievementType.vocabulary,
    ),
    Achievement(
      id: 'lessons_12',
      title: 'Halfway There',
      description: 'Reach 12 completed lessons.',
      icon: LucideIcons.award,
      goal: 12,
      color: const Color(0xFF14B8A6),
      type: _AchievementType.lessons,
    ),
    Achievement(
      id: 'score_100',
      title: 'Perfectionist',
      description: 'Get 100% on any quiz.',
      icon: LucideIcons.star,
      goal: 100,
      color: const Color(0xFFEAB308),
      type: _AchievementType.score,
    ),
  ];

  List<Achievement> get allAchievements => _allAchievements;

  Future<void> checkAchievements({BuildContext? context, int? lastScore}) async {
    final db = DatabaseService();
    
    // Fetch stats
    final lessons = await db.getCompletedLessonsCount();
    final streak = await db.getStreak();
    final kanji = await db.getLearnedKanjiCount();
    final vocab = await db.getLearnedVocabularyCount();

    for (final ach in _allAchievements) {
      bool shouldUnlock = false;
      
      switch (ach.type) {
        case _AchievementType.lessons:
          shouldUnlock = lessons >= ach.goal;
          break;
        case _AchievementType.streak:
          shouldUnlock = streak >= ach.goal;
          break;
        case _AchievementType.kanji:
          shouldUnlock = kanji >= ach.goal;
          break;
        case _AchievementType.vocabulary:
          shouldUnlock = vocab >= ach.goal;
          break;
        case _AchievementType.score:
          if (lastScore != null) {
            shouldUnlock = lastScore >= ach.goal;
          }
          break;
      }

      if (shouldUnlock) {
        await _unlock(ach.id, context);
      }
    }
  }

  Future<void> _unlock(String id, BuildContext? context) async {
    final db = DatabaseService();
    if (await db.isAchievementUnlocked(id)) return;

    await db.markAchievementUnlocked(id);
    
    final achievement = _allAchievements.firstWhere((a) => a.id == id);
    
    // Push achievement to Firestore
    final ids = await db.getUnlockedAchievementIds();
    CloudService().pushAchievements(ids);
    
    // Try to show popup
    final targetContext = context ?? navigatorKey.currentContext;
    if (targetContext != null) {
      _showAchievementPopup(targetContext, achievement);
      AudioService().playLevelComplete();
    }
  }

  void _showAchievementPopup(BuildContext context, Achievement achievement) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.pink.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(achievement.icon, size: 48, color: Colors.pink),
              ),
              const SizedBox(height: 20),
              Text(
                'Achievement Unlocked!',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.pink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                achievement.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                achievement.description,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Awesome!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
