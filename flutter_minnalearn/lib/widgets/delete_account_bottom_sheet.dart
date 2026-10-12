import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../utils/app_theme.dart';
import 'bouncing_widget.dart';

class DeleteAccountBottomSheet extends StatelessWidget {
  final String? appVersion;
  final Future<void> Function() onConfirmDelete;

  const DeleteAccountBottomSheet({
    Key? key,
    this.appVersion,
    required this.onConfirmDelete,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context, {
    String? appVersion,
    required Future<void> Function() onConfirmDelete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DeleteAccountBottomSheet(
        appVersion: appVersion,
        onConfirmDelete: onConfirmDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top drag handle pill
          Center(
            child: Container(
              width: 42,
              height: 4.5,
              decoration: BoxDecoration(
                color: AppColors.ink200,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  LucideIcons.alertTriangle,
                  color: Color(0xFFEF4444),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delete Account',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Permanent action • Irreversible data deletion',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFEF4444),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              BouncingWidget(
                scaleFactor: 0.90,
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    LucideIcons.x,
                    size: 16,
                    color: AppColors.ink500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // High Warning Notice Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFFECACA),
                width: 1.2,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  LucideIcons.alertOctagon,
                  size: 18,
                  color: Color(0xFFDC2626),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Once deleted, your account cannot be recovered. All associated cloud data will be wiped permanently.',
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF991B1B),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Data Categories List
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.ink200.withOpacity(0.7),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'The following will be deleted immediately:',
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink700,
                  ),
                ),
                const SizedBox(height: 10),
                _buildDeleteItem(
                  icon: LucideIcons.user,
                  title: 'Account & Credentials',
                  subtitle: 'Email, display name, and authentication tokens',
                ),
                _buildDeleteItem(
                  icon: LucideIcons.bookOpen,
                  title: 'Learning & Quiz Records',
                  subtitle: 'Completed lessons, accuracy rates, and quiz scores',
                ),
                _buildDeleteItem(
                  icon: LucideIcons.flame,
                  title: 'Streaks & Study Time',
                  subtitle: 'Daily streak counters, timers, and active sessions',
                ),
                _buildDeleteItem(
                  icon: LucideIcons.bookmark,
                  title: 'Learned Kanji & Bookmarks',
                  subtitle: 'Traced characters, custom bookmarks, and notes',
                ),
                _buildDeleteItem(
                  icon: LucideIcons.trophy,
                  title: 'Achievements & High Scores',
                  subtitle: 'All unlocked badge records and mini-game ranks',
                ),
                _buildDeleteItem(
                  icon: LucideIcons.cloudOff,
                  title: 'Cloud Database',
                  subtitle: 'Synced documents stored on Google Firebase',
                  isLast: true,
                ),
              ],
            ),
          ),

          if (appVersion != null) ...[
            const SizedBox(height: 10),
            Center(
              child: Text(
                'MinnaLearn • Version $appVersion',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: AppColors.ink400,
                ),
              ),
            ),
          ],

          const SizedBox(height: 18),

          // Primary Danger Action: Delete
          BouncingWidget(
            scaleFactor: 0.98,
            onTap: () async {
              HapticFeedback.heavyImpact();
              Navigator.of(context).pop();
              await onConfirmDelete();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    LucideIcons.trash2,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Permanently Delete Account',
                    style: GoogleFonts.outfit(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Neutral Action: Keep Account
          BouncingWidget(
            scaleFactor: 0.98,
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.ink200,
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  'Cancel & Keep Account',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteItem({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 11,
              color: const Color(0xFFEF4444),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink900,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppColors.ink500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
