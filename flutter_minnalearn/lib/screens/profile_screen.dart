import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../services/database_service.dart';
import '../services/study_timer_service.dart';
import '../services/auth_service.dart';
import '../services/achievement_service.dart';
import '../services/cloud_service.dart';
import 'auth_screen.dart';
import 'kanji_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  int _vocabCount = 0;
  int _kanjiCount = 0;
  int _completedLessons = 0;
  int _streak = 0;
  String _studyTime = '0m';
  bool _isLoading = false;
  Set<String> _unlockedAchievementIds = {};
  bool _disposed = false;
  PackageInfo? _appInfo;

  final List<Achievement> _achievements = AchievementService().allAchievements;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadAppInfo();
    DatabaseService.refreshNotifier.addListener(_loadStats);
  }

  Future<void> _loadAppInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted && !_disposed) {
      setState(() {
        _appInfo = info;
      });
    }
  }

  @override
  void dispose() {
    _disposed = true;
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
    final unlockedIds = (await db.getUnlockedAchievementIds()).toSet();

    if (!mounted || _disposed) {
      return;
    }

    setState(() {
      _vocabCount = vocab;
      _kanjiCount = kanji;
      _completedLessons = lessons;
      _streak = streak;
      _studyTime = time;
      _unlockedAchievementIds = unlockedIds;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    final unlockedCount = _unlockedAchievementIds.length;

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
                        _authService.currentUser?.email?.split('@')[0] ?? 'Learner',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _authService.currentUser?.email ?? 'Japanese N5 Journey',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.logOut, color: Colors.white),
                  onPressed: () async {
                    KanjiScreen.clearCache();
                    await _authService.signOut();
                    if (!mounted) return;
                    Navigator.of(context, rootNavigator: true).pushReplacement(
                      MaterialPageRoute(builder: (_) => const AuthScreen()),
                    );
                  },
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
                        _buildStatItemExpanded(
                          LucideIcons.bookOpen,
                          _vocabCount.toString(),
                          'Vocab',
                          Colors.blue.shade50,
                          Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        _buildStatItemExpanded(
                          LucideIcons.sparkles,
                          _kanjiCount.toString(),
                          'Kanji',
                          Colors.purple.shade50,
                          Colors.purple,
                        ),
                        const SizedBox(width: 8),
                        _buildStatItemExpanded(
                          LucideIcons.flame,
                          _streak.toString(),
                          'Streak',
                          Colors.orange.shade50,
                          Colors.orange,
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
                            final unlocked = _unlockedAchievementIds.contains(achievement.id);
                            final Color cardColor = achievement.color;
                            final current = unlocked
                                ? achievement.goal
                                : achievement.getCurrentValue(
                                    completedLessons: _completedLessons,
                                    streak: _streak,
                                    kanjiCount: _kanjiCount,
                                    vocabCount: _vocabCount,
                                  ).clamp(0, achievement.goal);
                            final progress = unlocked ? 1.0 : (current / achievement.goal).clamp(0.0, 1.0);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: unlocked ? cardColor.withOpacity(0.08) : const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: unlocked ? cardColor.withOpacity(0.35) : const Color(0xFFE5E7EB),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 46,
                                      height: 46,
                                      decoration: BoxDecoration(
                                        color: cardColor.withOpacity(unlocked ? 0.18 : 0.08),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        achievement.icon,
                                        color: cardColor,
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
                                                  color: unlocked ? cardColor : const Color(0xFF6B7280),
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
                                              color: cardColor,
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          ListTile(
                            leading: const Icon(LucideIcons.shieldCheck, color: Color(0xFF6B7280)),
                            title: Text(
                              'Privacy Policy',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                            trailing: const Icon(LucideIcons.chevronRight, size: 18, color: Color(0xFF9CA3AF)),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(
                                    'Privacy Policy',
                                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                                  ),
                                  content: SingleChildScrollView(
                                    child: Text(
                                      'Last updated: April 8, 2026\n\n'
                                      'This policy applies to MinnaLearn: Japanese N5 on Google Play. We respect your privacy and are committed to protecting your personal data.\n\n'
                                      '1) Data We Collect\n'
                                      '- Account: email and display name (Firebase Authentication / Google Sign-In).\n'
                                      '- Learning: lesson completion, study time, streaks, quiz scores, bookmarked vocabulary, learned kanji, achievements.\n'
                                      '- Usage: screen views and feature usage (first_open, session_start) via Firebase Analytics.\n'
                                      '- Approximate location: city/region inferred from IP; no GPS/Wi-Fi/Bluetooth location is collected.\n'
                                      '- Device: app version and device type for troubleshooting. Learning assets are bundled; no Firebase Storage downloads.\n\n'
                                      '2) How We Use Data\n'
                                      '- Create and manage your account; sync progress (Firestore).\n'
                                      '- Track progress and streaks.\n'
                                      '- Send local study reminders/streak alerts (with permission).\n'
                                      '- Improve features using aggregated analytics.\n\n'
                                      '3) Sharing\n'
                                      '- Processed by Firebase (Google) for auth, analytics, and sync.\n'
                                      '- We do not sell, rent, or share data with other third parties; no ads or profiling (ad ID disabled).\n\n'
                                      '4) Storage & Security\n'
                                      '- Stored locally in SQLite; synced to Firestore when signed in.\n'
                                      '- Firebase encrypts data in transit and at rest.\n\n'
                                      '5) Third-Party Services\n'
                                      '- Firebase Authentication; Firebase Cloud Firestore; Firebase Analytics (all by Google; see Google Privacy Policy).\n\n'
                                      '6) Your Rights\n'
                                      '- Access, correct, or delete your data.\n'
                                      '- Delete Account via Profile -> Delete Account.\n'
                                      '- Sign out anytime.\n\n'
                                      '7) Children\'s Privacy\n'
                                      '- Not directed to children under 13; contact us if a child provided data.\n'
                                      '- Rated IARC 3+; no ads.\n\n'
                                      '8) Changes\n'
                                      '- Updates will be posted in the app and on the docs page.\n\n'
                                      '9) Contact\n'
                                      '- maadhuavati7@gmail.com',
                                      style: GoogleFonts.inter(fontSize: 13, height: 1.5),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(LucideIcons.trash2, color: Color(0xFFEF4444)),
                            title: Text(
                              'Delete Account',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFEF4444),
                              ),
                            ),
                            trailing: const Icon(LucideIcons.chevronRight, size: 18, color: Color(0xFF9CA3AF)),
                            onTap: _showDeleteAccountDialog,
                          ),
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
                          if (_appInfo != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Version ${_appInfo!.version}',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
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

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(LucideIcons.alertTriangle, color: Color(0xFFEF4444), size: 22),
            const SizedBox(width: 8),
            Text(
              'Delete Account',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will permanently delete your account and all data including:\n\n'
              '• Account (email and display name)\n'
              '• Lesson progress and quiz scores\n'
              '• Study time, streaks, and sessions\n'
              '• Learned kanji and bookmarks\n'
              '• Achievements and game scores\n\n'
              'This action cannot be undone.',
              style: GoogleFonts.inter(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 16),
            if (_appInfo != null)
              Text(
                'App version: ${_appInfo!.version} (${_appInfo!.buildNumber})',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF9CA3AF)),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: const Color(0xFF6B7280)),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAccount();
            },
            child: Text(
              'Delete',
              style: GoogleFonts.inter(
                color: const Color(0xFFEF4444),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final user = _authService.currentUser;
      if (user == null) return;

      // Save UID before deleting auth
      final uid = user.uid;

      // Step 1: Delete from Firestore first (need auth to still be valid)
      try {
        await CloudService().deleteUserData(uid);
      } catch (_) {}

      // Step 2: Delete from local database
      try {
        await DatabaseService().deleteAllUserData();
      } catch (_) {}

      KanjiScreen.clearCache();

      // Step 3: Try to delete Firebase Auth account (requires recent login)
      try {
        await user.delete();
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          if (!mounted) return;
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                'Please sign out and sign in again, then try deleting your account.',
                style: GoogleFonts.inter(),
              ),
              backgroundColor: const Color(0xFFF59E0B),
              duration: const Duration(seconds: 5),
            ),
          );
          return;
        }
        rethrow;
      }

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Account deleted successfully', style: GoogleFonts.inter()),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      Navigator.of(context, rootNavigator: true).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to delete account. Please try again.', style: GoogleFonts.inter()),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
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

  Widget _buildStatItemExpanded(IconData icon, String value, String label, Color bgColor, Color iconColor) {
    return Expanded(
      child: _buildStatItem(icon, value, label, bgColor, iconColor),
    );
  }
}
