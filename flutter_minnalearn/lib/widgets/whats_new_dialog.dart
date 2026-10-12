import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../services/database_service.dart';
import '../utils/app_theme.dart';
import 'bouncing_widget.dart';

class WhatsNewDialog extends StatelessWidget {
  final String currentVersion;

  const WhatsNewDialog({
    Key? key,
    required this.currentVersion,
  }) : super(key: key);

  static Future<void> show(BuildContext context, String version) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => WhatsNewDialog(currentVersion: version),
    );
  }

  Future<void> _acknowledge(BuildContext context) async {
    final db = DatabaseService();
    await db.setUserStatText('last_seen_app_version', currentVersion);
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          DatabaseService()
              .setUserStatText('last_seen_app_version', currentVersion);
        }
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.ink200, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.14),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Version & celebration chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF1F2), Color(0xFFFFE4E6)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.primary.withOpacity(0.3), width: 1.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.sparkles,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'What\'s New in v$currentVersion 🎉',
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  'MinnaLearn Just Got Better!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink900,
                    letterSpacing: -0.4,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Here are the latest features and improvements designed to accelerate your Japanese:',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink500,
                    height: 1.35,
                  ),
                ),

                const SizedBox(height: 20),

                // Feature 1: Kanji Stroke Tracing Studio
                _buildFeatureRow(
                  icon: LucideIcons.pencil,
                  iconColor: AppColors.primary,
                  iconBg: AppColors.primaryLight,
                  title: 'Kanji Stroke Tracing Studio',
                  description:
                      'Stroke-by-stroke animations, numbered badges, and guided interactive tracing for all JLPT N5 Kanji.',
                ),

                const SizedBox(height: 14),

                // Feature 2: Upgraded Mini-Games
                _buildFeatureRow(
                  icon: LucideIcons.gamepad2,
                  iconColor: AppColors.azureDark,
                  iconBg: AppColors.azureLight,
                  title: 'Redesigned Mini-Games UI',
                  description:
                      'Matching Game, True or False, and Kana Puzzle now feature responsive multi-line cards and centered layouts.',
                ),

                const SizedBox(height: 14),

                // Feature 3: Precision Touch Controls
                _buildFeatureRow(
                  icon: LucideIcons.hand,
                  iconColor: AppColors.bambooDark,
                  iconBg: AppColors.bambooLight,
                  title: 'Smooth Drawing & Zero Scrolling',
                  description:
                      'Drawing vertical strokes on the calligraphy canvas now has full gesture lock without page scroll interruptions.',
                ),

                const SizedBox(height: 14),

                // Feature 4: Feedback & Play Store Reviews
                _buildFeatureRow(
                  icon: LucideIcons.star,
                  iconColor: AppColors.amberDark,
                  iconBg: AppColors.amberLight,
                  title: 'Rate & Support Development',
                  description:
                      'Easily share your feedback or rate MinnaLearn on Google Play after 5 minutes of practice.',
                ),

                const SizedBox(height: 24),

                // Primary "Awesome, Let's Learn!" Button
                BouncingWidget(
                  scaleFactor: 0.95,
                  onTap: () => _acknowledge(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: AppGradients.primaryHeader,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: const Color(0xFFF43F5E), width: 1.5),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFF9F1239),
                          offset: Offset(0, 4),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.rocket,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Awesome, Let\'s Learn!',
                          style: GoogleFonts.outfit(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: iconColor.withOpacity(0.25), width: 1),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink500,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
