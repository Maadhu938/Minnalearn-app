import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../services/database_service.dart';
import '../services/study_timer_service.dart';
import '../services/auth_service.dart';
import '../services/achievement_service.dart';
import '../services/cloud_service.dart';
import '../utils/app_theme.dart';
import '../widgets/bouncing_widget.dart';
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
  Set<String> _unlockedAchievementIds = {};
  bool _disposed = false;
  PackageInfo? _appInfo;
  String? _avatarValue;

  static const List<Map<String, dynamic>> _kPresetAvatars = [
    {
      'id': 'crest:gaku',
      'kanji': '学',
      'reading': 'Gaku',
      'label': 'Learning',
      'bg': Color(0xFF0F172A),
      'fg': Colors.white,
    },
    {
      'id': 'crest:nichi',
      'kanji': '日',
      'reading': 'Nichi',
      'label': 'Japan',
      'bg': Color(0xFFE11D48),
      'fg': Colors.white,
    },
    {
      'id': 'crest:wa',
      'kanji': '和',
      'reading': 'Wa',
      'label': 'Harmony',
      'bg': Color(0xFF047857),
      'fg': Colors.white,
    },
    {
      'id': 'crest:dou',
      'kanji': '道',
      'reading': 'Dō',
      'label': 'The Way',
      'bg': Color(0xFF1D4ED8),
      'fg': Colors.white,
    },
    {
      'id': 'crest:shin',
      'kanji': '心',
      'reading': 'Kokoro',
      'label': 'Spirit',
      'bg': Color(0xFFB45309),
      'fg': Colors.white,
    },
    {
      'id': 'crest:shi',
      'kanji': '志',
      'reading': 'Aspiration',
      'label': 'Resolve',
      'bg': Color(0xFF475569),
      'fg': Colors.white,
    },
    {
      'id': 'crest:hikari',
      'kanji': '光',
      'reading': 'Hikari',
      'label': 'Clarity',
      'bg': Color(0xFF0369A1),
      'fg': Colors.white,
    },
    {
      'id': 'crest:tomo',
      'kanji': '友',
      'reading': 'Tomo',
      'label': 'Friendship',
      'bg': Color(0xFF9F1239),
      'fg': Colors.white,
    },
  ];

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
    final avatar = await db.getProfileAvatar();

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
      _avatarValue = avatar;
    });
  }

  @override
  Widget build(BuildContext context) {
    final unlockedCount = _unlockedAchievementIds.length;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 56, bottom: 32, left: 20, right: 20),
            decoration: const BoxDecoration(
              gradient: AppGradients.primaryHeader,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Row(
              children: [
                _buildAvatarWidget(),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _authService.currentUser?.email?.split('@')[0] ?? 'Learner',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _authService.currentUser?.email ?? 'Japanese N5 Journey',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                BouncingWidget(
                  onTap: () async {
                    KanjiScreen.clearCache();
                    await _authService.signOut();
                    if (!mounted) return;
                    Navigator.of(context, rootNavigator: true).pushReplacement(
                      MaterialPageRoute(builder: (_) => const AuthScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.logOut, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadStats,
              color: AppColors.primary,
              child: ListView(
                physics: const ClampingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                children: [
                    Row(
                      children: [
                        _buildStatItemExpanded(
                          LucideIcons.bookOpen,
                          _vocabCount.toString(),
                          'Vocab',
                          AppColors.azureLight,
                          AppColors.azureDark,
                        ),
                        const SizedBox(width: 8),
                        _buildStatItemExpanded(
                          LucideIcons.languages,
                          _kanjiCount.toString(),
                          'Kanji',
                          AppColors.amberLight,
                          AppColors.amberDark,
                        ),
                        const SizedBox(width: 8),
                        _buildStatItemExpanded(
                          LucideIcons.flame,
                          _streak.toString(),
                          'Streak',
                          AppColors.coralLight,
                          AppColors.coralDark,
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
                                  const Icon(LucideIcons.award, color: AppColors.primary, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Achievements',
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.ink900,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.amberLight,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '$unlockedCount unlocked',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.amberDark,
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

  Widget _buildAvatarWidget() {
    return BouncingWidget(
      scaleFactor: 0.94,
      onTap: _showAvatarPicker,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: AppShadows.card,
              border: Border.all(color: Colors.white, width: 2.5),
            ),
            child: ClipOval(
              child: _buildAvatarContent(),
            ),
          ),
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.8),
                boxShadow: AppShadows.subtle,
              ),
              child: const Icon(
                LucideIcons.camera,
                size: 12,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarContent() {
    if (_avatarValue != null && _avatarValue!.startsWith('file:')) {
      final path = _avatarValue!.substring(5);
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: 68,
          height: 68,
          fit: BoxFit.cover,
        );
      }
    }

    if (_avatarValue != null && _avatarValue!.startsWith('crest:')) {
      final preset = _kPresetAvatars.firstWhere(
        (p) => p['id'] == _avatarValue,
        orElse: () => _kPresetAvatars[0],
      );
      return Container(
        color: preset['bg'] as Color,
        alignment: Alignment.center,
        child: Text(
          preset['kanji'] as String,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: preset['fg'] as Color,
            fontFamilyFallback: const ['Noto Sans CJK JP', 'sans-serif'],
          ),
        ),
      );
    }

    final initial = (_authService.currentUser?.email?.isNotEmpty == true)
        ? _authService.currentUser!.email![0].toUpperCase()
        : 'M';

    return Container(
      color: AppColors.primaryLight,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.inter(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (image != null) {
        await DatabaseService().setProfileAvatar('file:${image.path}');
        if (mounted) {
          setState(() {
            _avatarValue = 'file:${image.path}';
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.ink200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profile Avatar',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Upload custom photo or select a Japanese learner crest',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.ink500,
                        ),
                      ),
                    ],
                  ),
                  if (_avatarValue != null && _avatarValue!.isNotEmpty)
                    TextButton(
                      onPressed: () async {
                        await DatabaseService().setProfileAvatar('');
                        setState(() => _avatarValue = null);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: Text(
                        'Reset',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              // Photo Upload Options
              Row(
                children: [
                  Expanded(
                    child: _buildUploadOptionButton(
                      icon: LucideIcons.image,
                      label: 'Choose Photo',
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildUploadOptionButton(
                      icon: LucideIcons.camera,
                      label: 'Take Photo',
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Japanese Learner Crests (家紋)',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink900,
                ),
              ),
              const SizedBox(height: 14),
              // Grid of Preset Kanji Crests
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _kPresetAvatars.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemBuilder: (context, index) {
                  final preset = _kPresetAvatars[index];
                  final isSelected = _avatarValue == preset['id'];

                  return BouncingWidget(
                    scaleFactor: 0.90,
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      await DatabaseService().setProfileAvatar(preset['id'] as String);
                      setState(() => _avatarValue = preset['id'] as String);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: preset['bg'] as Color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppColors.primary : Colors.transparent,
                              width: isSelected ? 3.0 : 0.0,
                            ),
                            boxShadow: AppShadows.subtle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            preset['kanji'] as String,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: preset['fg'] as Color,
                              fontFamilyFallback: const ['Noto Sans CJK JP', 'sans-serif'],
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${preset['reading']} • ${preset['label']}',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? AppColors.primary : AppColors.ink500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUploadOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return BouncingWidget(
      scaleFactor: 0.95,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardAlt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.ink200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.ink900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

