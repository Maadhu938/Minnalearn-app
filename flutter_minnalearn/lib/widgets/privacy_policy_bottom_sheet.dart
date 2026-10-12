import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/app_theme.dart';
import 'bouncing_widget.dart';

class PrivacyPolicyBottomSheet extends StatelessWidget {
  const PrivacyPolicyBottomSheet({Key? key}) : super(key: key);

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PrivacyPolicyBottomSheet(),
    );
  }

  Future<void> _launchWebPolicy(BuildContext context) async {
    final uri = Uri.parse('https://getminnalearn.xyz/privacy-policy.html');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not launch privacy policy URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.88;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                  color: AppColors.azureLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  LucideIcons.shieldCheck,
                  color: AppColors.azureDark,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Privacy Policy',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'How MinnaLearn safeguards your data and privacy',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        color: AppColors.ink500,
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

          const SizedBox(height: 16),

          // Trust Highlights Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildBadge(
                  icon: LucideIcons.ban,
                  text: '100% Ad-Free',
                  bgColor: AppColors.bambooLight,
                  fgColor: AppColors.bambooDark,
                  borderColor: AppColors.bambooBorder,
                ),
                const SizedBox(width: 8),
                _buildBadge(
                  icon: LucideIcons.lock,
                  text: 'Encrypted Cloud Sync',
                  bgColor: AppColors.azureLight,
                  fgColor: AppColors.azureDark,
                  borderColor: AppColors.azureBorder,
                ),
                const SizedBox(width: 8),
                _buildBadge(
                  icon: LucideIcons.userX,
                  text: 'No Data Brokers',
                  bgColor: AppColors.amberLight,
                  fgColor: AppColors.amberDark,
                  borderColor: AppColors.amberBorder,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Scrollable Policy Details
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildSectionCard(
                    icon: LucideIcons.database,
                    title: '1. Data We Collect',
                    points: [
                      'Account Credentials: Email address and display name via Google Sign-In or Firebase Authentication.',
                      'Learning History: Lesson completion, quiz scores, bookmarked vocabulary, study streaks, and learned kanji.',
                      'App Diagnostics: Anonymous session stats via Firebase Analytics (no advertising ID, no behavioral profiling).',
                      'Approximate Region: Coarse country/region inferred from IP for localized performance; no GPS or Bluetooth tracking.',
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSectionCard(
                    icon: LucideIcons.cpu,
                    title: '2. How Data is Used',
                    points: [
                      'Sync your study progress across multiple Android devices.',
                      'Calculate learning streaks, XP, level achievements, and review cards.',
                      'Send scheduled local study notifications (only if explicitly enabled).',
                      'Maintain stability and detect crashes to improve app quality.',
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSectionCard(
                    icon: LucideIcons.shieldOff,
                    title: '3. Data Sharing & Third Parties',
                    points: [
                      'We do not sell, rent, or trade your personal data to any third parties.',
                      'Backend infrastructure is provided by Google Cloud / Firebase (Authentication, Cloud Firestore, Analytics).',
                      'Zero advertising SDKs or third-party behavioral trackers.',
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSectionCard(
                    icon: LucideIcons.lock,
                    title: '4. Storage & Security',
                    points: [
                      'Learning data is stored locally in device SQLite and backed up to Firestore when signed in.',
                      'All network communications are encrypted via TLS 1.3 / HTTPS encryption in transit and at rest.',
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSectionCard(
                    icon: LucideIcons.userCheck,
                    title: '5. Your Rights & Control',
                    points: [
                      'You have the full right to inspect, export, or permanently delete your account & data anytime.',
                      'Account deletion is available right here in Profile -> Delete Account.',
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSectionCard(
                    icon: LucideIcons.heartHandshake,
                    title: '6. Children & Compliance',
                    points: [
                      'Rated IARC 3+ (suitable for all ages). MinnaLearn is an educational app that does not collect data from children under 13.',
                      'Support & Privacy contact: maadhuavati7@gmail.com',
                      'Last updated: April 8, 2026',
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Web Policy Button
                  BouncingWidget(
                    scaleFactor: 0.98,
                    onTap: () => _launchWebPolicy(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.ink200,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.azureLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              LucideIcons.globe,
                              size: 16,
                              color: AppColors.azureDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'View Full Online Policy',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink900,
                                  ),
                                ),
                                Text(
                                  'getminnalearn.xyz/privacy-policy.html',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11.5,
                                    color: AppColors.azureDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            LucideIcons.externalLink,
                            size: 16,
                            color: AppColors.ink400,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Primary Done Button
          BouncingWidget(
            scaleFactor: 0.98,
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppShadows.primaryGlow,
              ),
              child: Center(
                child: Text(
                  'Got It',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String text,
    required Color bgColor,
    required Color fgColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fgColor),
          const SizedBox(width: 5),
          Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: fgColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required List<String> points,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.ink200.withOpacity(0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...points.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6, right: 8),
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppColors.ink400,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      point,
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        color: AppColors.ink700,
                        height: 1.4,
                      ),
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
}
