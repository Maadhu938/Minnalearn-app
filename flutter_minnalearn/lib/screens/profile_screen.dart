import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../services/database_service.dart';
import '../services/study_timer_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _vocabCount = 0;
  int _kanjiCount = 0;
  int _completedLessons = 0;
  int _streak = 0;
  String _studyTime = '0m';
  bool _isLoading = false;

  final List<_AchievementDefinition> _achievements = const [
    _AchievementDefinition(
      title: 'First Lesson',
      description: 'Finish your first lesson to unlock this badge.',
      icon: LucideIcons.flag,
      goal: 1,
      color: Color(0xFF3B82F6),
      kind: _AchievementKind.lessons,
    ),
    _AchievementDefinition(
      title: 'Week Warrior',
      description: 'Build a 7 day streak.',
      icon: LucideIcons.flame,
      goal: 7,
      color: Color(0xFFF97316),
      kind: _AchievementKind.streak,
    ),
    _AchievementDefinition(
      title: 'Vocab Master',
      description: 'Learn 100 vocabulary items.',
      icon: LucideIcons.bookOpen,
      goal: 100,
      color: Color(0xFFEC4899),
      kind: _AchievementKind.vocabulary,
    ),
    _AchievementDefinition(
      title: 'Kanji Learner',
      description: 'Study 25 kanji cards.',
      icon: LucideIcons.sparkles,
      goal: 25,
      color: Color(0xFF8B5CF6),
      kind: _AchievementKind.kanji,
    ),
    _AchievementDefinition(
      title: 'Grammar Goal',
      description: 'Complete 5 lessons.',
      icon: LucideIcons.target,
      goal: 5,
      color: Color(0xFF22C55E),
      kind: _AchievementKind.lessons,
    ),
    _AchievementDefinition(
      title: 'Halfway There',
      description: 'Reach 12 completed lessons.',
      icon: LucideIcons.award,
      goal: 12,
      color: Color(0xFF14B8A6),
      kind: _AchievementKind.lessons,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadStats();
    DatabaseService.refreshNotifier.addListener(_loadStats);
  }

  @override
  void dispose() {
    DatabaseService.refreshNotifier.removeListener(_loadStats);
    super.dispose();
  }

  Future<void> _loadStats() async {
    final db = DatabaseService();
    final vocab = await db.getLearnedVocabularyCount();
    final kanji = await db.getLearnedKanjiCount();
    final lessons = await db.getCompletedLessonsCount();
    final streak = await db.getStreak();
    final time = await StudyTimerService().getFormattedStudyTime();

    if (!mounted) {
      return;
    }

    setState(() {
      _vocabCount = vocab;
      _kanjiCount = kanji;
      _completedLessons = lessons;
      _streak = streak;
      _studyTime = time;
      _isLoading = false;
    });
  }

  int _currentValueFor(_AchievementKind kind) {
    switch (kind) {
      case _AchievementKind.vocabulary:
        return _vocabCount;
      case _AchievementKind.kanji:
        return _kanjiCount;
      case _AchievementKind.lessons:
        return _completedLessons;
      case _AchievementKind.streak:
        return _streak;
    }
  }

  @override
  Widget build(BuildContext context) {

    final unlockedCount = _achievements.where((item) => _currentValueFor(item.kind) >= item.goal).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 32, left: 24, right: 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF472B6),
                  Color(0xFFEC4899),
                  Color(0xFFE11D48),
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      LucideIcons.user,
                      color: Colors.pink,
                      size: 34,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Learner',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Japanese N5 Journey',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadStats,
              color: const Color(0xFFEC4899),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            LucideIcons.bookOpen,
                            _vocabCount.toString(),
                            'Vocab',
                            Colors.blue.shade50,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatItem(
                            LucideIcons.sparkles,
                            _kanjiCount.toString(),
                            'Kanji',
                            Colors.purple.shade50,
                            Colors.purple,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatItem(
                            LucideIcons.flame,
                            _streak.toString(),
                            'Streak',
                            Colors.orange.shade50,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Study Summary',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildSummaryRow('Total Study Time', _studyTime),
                          const SizedBox(height: 12),
                          _buildSummaryRow('Lessons Completed', '$_completedLessons / 25'),
                          const SizedBox(height: 12),
                          _buildSummaryRow('Achievements Unlocked', '$unlockedCount / ${_achievements.length}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(LucideIcons.award, color: Colors.pink, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Achievements',
                                    style: GoogleFonts.inter(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1F2937),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFCE7F3),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '$unlockedCount unlocked',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFBE185D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          ..._achievements.map((achievement) {
                            final current = _currentValueFor(achievement.kind);
                            final unlocked = current >= achievement.goal;
                            final progress = (current / achievement.goal).clamp(0.0, 1.0);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: unlocked ? achievement.color.withOpacity(0.08) : const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: unlocked ? achievement.color.withOpacity(0.35) : const Color(0xFFE5E7EB),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 46,
                                      height: 46,
                                      decoration: BoxDecoration(
                                        color: achievement.color.withOpacity(unlocked ? 0.18 : 0.08),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        achievement.icon,
                                        color: achievement.color,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  achievement.title,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w700,
                                                    color: const Color(0xFF1F2937),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                unlocked ? 'Unlocked' : '$current / ${achievement.goal}',
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: unlocked ? achievement.color : const Color(0xFF6B7280),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            achievement.description,
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              color: const Color(0xFF6B7280),
                                              height: 1.3,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(999),
                                            child: LinearProgressIndicator(
                                              value: progress,
                                              minHeight: 8,
                                              backgroundColor: const Color(0xFFE5E7EB),
                                              color: achievement.color,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'MinnaLearn - Japanese N5',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF6B7280),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Made with ${String.fromCharCodes([0x2764, 0xFE0F])} by Maadhu',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF9CA3AF),
                            ),
                          ),
                          if (false)
                          Text(
                            'Made with ❤️ by Maadhu',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF4B5563))),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? const Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }
}

enum _AchievementKind {
  vocabulary,
  kanji,
  lessons,
  streak,
}

class _AchievementDefinition {
  final String title;
  final String description;
  final IconData icon;
  final int goal;
  final Color color;
  final _AchievementKind kind;

  const _AchievementDefinition({
    required this.title,
    required this.description,
    required this.icon,
    required this.goal,
    required this.color,
    required this.kind,
  });
}
