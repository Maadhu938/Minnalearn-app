import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/database_service.dart';
import '../services/study_timer_service.dart';
import '../services/auth_service.dart';
import '../services/achievement_service.dart';
import '../services/cloud_service.dart';
import 'auth_screen.dart';

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

  final List<Achievement> _achievements = AchievementService().allAchievements;

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
    final unlockedIds = (await db.getUnlockedAchievementIds()).toSet();

    if (!mounted) {
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
                            final progress = unlocked ? 1.0 : 0.0;
                            // For a truly dynamic display, we could query the Current Value
                            // but for now, we'll show "Goal / Goal" if unlocked, or "0 / Goal" if locked
                            final current = unlocked ? achievement.goal : 0;

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
                                      'Last updated: March 31, 2026\n\n'
                                      'MinnaLearn is a Japanese language learning app developed to help users learn Japanese at the JLPT N5 level. We value your privacy and are committed to protecting your personal data.\n\n'
                                      '1. Data We Collect\n'
                                      '- Account info: email address and display name (via Firebase Authentication, including Google Sign-In).\n'
                                      '- Study progress: lesson completion, study time, streaks, quiz scores, bookmarked vocabulary, learned kanji, and achievements.\n'
                                      '- All progress data is stored locally on your device using SQLite and synced to Firebase Cloud Firestore if you are signed in.\n\n'
                                      '2. How We Use Your Data\n'
                                      '- To create and manage your account.\n'
                                      '- To track your learning progress and streaks.\n'
                                      '- To save and sync your data across devices using Firebase Cloud Firestore.\n'
                                      '- To send local study reminders and notifications (with your permission).\n\n'
                                      '3. Data Sharing\n'
                                      '- Your data is shared with Firebase (Google) for authentication and cloud sync.\n'
                                      '- We do not sell, rent, or share your personal data with any other third parties.\n'
                                      '- No data is used for advertising or profiling purposes.\n\n'
                                      '4. Data Storage & Security\n'
                                      '- Your data is stored locally on your device and in Google Firebase Cloud Firestore.\n'
                                      '- Firebase provides industry-standard encryption for data in transit and at rest.\n'
                                      '- You can use the app offline without signing in; all data stays on your device.\n\n'
                                      '5. Third-Party Services\n'
                                      '- Firebase Authentication (Google): for sign-in functionality.\n'
                                      '- Firebase Cloud Firestore: for cloud sync of your progress.\n'
                                      '- These services are governed by Google\'s Privacy Policy.\n\n'
                                      '6. Your Rights\n'
                                      '- You may request access to, correction of, or deletion of your personal data at any time.\n'
                                      '- Delete your account and all associated data from the app settings (Profile → Delete Account).\n'
                                      '- Sign out at any time.\n\n'
                                      '7. Children\'s Privacy\n'
                                      '- MinnaLearn does not knowingly collect personal information from children under 13.\n'
                                      '- If you believe a child has provided personal data, please contact us.\n\n'
                                      '8. Changes to This Policy\n'
                                      '- We may update this Privacy Policy from time to time. Changes will be posted in the app.\n\n'
                                      '9. Contact\n'
                                      '- For questions, concerns, or data deletion requests, contact us at maadhuavati7@gmail.com.',
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
        content: Text(
          'This will permanently delete your account and all data including:\n\n'
          '• Study progress and streaks\n'
          '• Learned vocabulary and kanji\n'
          '• Bookmarks and achievements\n\n'
          'This action cannot be undone.',
          style: GoogleFonts.inter(fontSize: 14, height: 1.5),
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

      // Step 1: Try to delete Firebase Auth account (requires recent login)
      try {
        await user.delete();
      }       on FirebaseAuthException catch (e) {
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

      // Step 2: Delete from Firestore
      try {
        await CloudService().deleteUserData(user.uid);
      } catch (_) {}

      // Step 3: Delete from local database
      try {
        await DatabaseService().deleteAllUserData();
      } catch (_) {}

      // Step 4: Sign out and navigate
      await _authService.signOut();

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
