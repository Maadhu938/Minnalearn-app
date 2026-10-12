import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/app_theme.dart';
import 'bouncing_widget.dart';
import 'whats_new_dialog.dart';

class AppUpdateInfo {
  final String latestVersion;
  final int? latestBuildNumber;
  final String? title;
  final String? message;
  final List<String> releaseNotes;
  final bool forceUpdate;
  final String playStoreUrl;

  const AppUpdateInfo({
    required this.latestVersion,
    this.latestBuildNumber,
    this.title,
    this.message,
    this.releaseNotes = const [],
    this.forceUpdate = false,
    this.playStoreUrl =
        'https://play.google.com/store/apps/details?id=com.maadhu.minnalearn',
  });
}

class AppUpdateDialog extends StatelessWidget {
  final AppUpdateInfo updateInfo;

  const AppUpdateDialog({
    Key? key,
    required this.updateInfo,
  }) : super(key: key);

  static Future<void> show(BuildContext context, AppUpdateInfo info) {
    return showDialog(
      context: context,
      barrierDismissible: !info.forceUpdate,
      builder: (context) => PopScope(
        canPop: !info.forceUpdate,
        child: AppUpdateDialog(updateInfo: info),
      ),
    );
  }

  static Future<void> showUpToDate(
    BuildContext context, {
    required String currentVersion,
    required int currentBuild,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _AppUpToDateDialog(
        currentVersion: currentVersion,
        currentBuild: currentBuild,
      ),
    );
  }

  static Future<void> showOffline(
    BuildContext context, {
    required String currentVersion,
    required int currentBuild,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _AppOfflineDialog(
        currentVersion: currentVersion,
        currentBuild: currentBuild,
      ),
    );
  }

  static Future<void> launchStore(String? playStoreUrl) async {
    final marketUri = Uri.parse('market://details?id=com.maadhu.minnalearn');
    final webUri = Uri.parse(playStoreUrl != null && playStoreUrl.isNotEmpty
        ? playStoreUrl
        : 'https://play.google.com/store/apps/details?id=com.maadhu.minnalearn');

    try {
      final launchedMarket =
          await launchUrl(marketUri, mode: LaunchMode.externalApplication);
      if (!launchedMarket) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      try {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } catch (e) {
        debugPrint('Error launching store: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
              // Mascot badge
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.azureDark.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.azureDark.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/gif/Shiba Happy.gif',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Text('🚀', style: TextStyle(fontSize: 34)),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Version chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.azureLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.azureBorder, width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.sparkles,
                        size: 13, color: AppColors.azureDark),
                    const SizedBox(width: 6),
                    Text(
                      'Update Available: v${updateInfo.latestVersion} 🚀',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.azureDark,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Title
              Text(
                updateInfo.title ?? 'New Update Available!',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink900,
                  letterSpacing: -0.4,
                ),
              ),

              const SizedBox(height: 6),

              // Message
              Text(
                updateInfo.message ??
                    'A new version of MinnaLearn is available on Google Play with new practice features, kanji improvements, and bug fixes.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink500,
                  height: 1.35,
                ),
              ),

              if (updateInfo.releaseNotes.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.ink100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.ink200, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What\'s New in this version:',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...updateInfo.releaseNotes.map(
                        (note) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 3, right: 8),
                                child: Icon(
                                  LucideIcons.checkCircle2,
                                  size: 14,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  note,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.ink900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 22),

              // Primary "Update on Google Play" Button
              BouncingWidget(
                scaleFactor: 0.95,
                onTap: () => launchStore(updateInfo.playStoreUrl),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF059669), Color(0xFF10B981)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border:
                        Border.all(color: const Color(0xFF34D399), width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFF047857),
                        offset: Offset(0, 4),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.downloadCloud,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Update on Google Play',
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

              if (!updateInfo.forceUpdate) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Maybe Later',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink400,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Up to Date Dialog ────────────────────────────────────────────────────────
class _AppUpToDateDialog extends StatelessWidget {
  final String currentVersion;
  final int currentBuild;

  const _AppUpToDateDialog({
    Key? key,
    required this.currentVersion,
    required this.currentBuild,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.bambooBorder, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mascot Badge
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.bamboo,
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.bamboo.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/gif/Shiba Happy.gif',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Text('🎉', style: TextStyle(fontSize: 34)),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Status chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.bambooLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.bambooBorder, width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.checkCircle2,
                        size: 14, color: AppColors.bambooDark),
                    const SizedBox(width: 6),
                    Text(
                      'v$currentVersion (Build $currentBuild) • Up to Date',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.bambooDark,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'You\'re on the Latest Version! 🎉',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink900,
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Your app is fully up to date with the latest JLPT N5 lessons, Kanji stroke studio, and Listening Prep hub.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink500,
                  height: 1.35,
                ),
              ),

              const SizedBox(height: 20),

              // What's New button
              BouncingWidget(
                scaleFactor: 0.96,
                onTap: () {
                  Navigator.of(context).pop();
                  WhatsNewDialog.show(context, currentVersion);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.primary.withOpacity(0.3), width: 1.2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.sparkles,
                          color: AppColors.primary, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'View Features in this Version',
                        style: GoogleFonts.outfit(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Check on Play Store button
              BouncingWidget(
                scaleFactor: 0.96,
                onTap: () {
                  Navigator.of(context).pop();
                  AppUpdateDialog.launchStore(null);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.cardAlt,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.ink200, width: 1.2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.externalLink,
                          color: AppColors.ink700, size: 15),
                      const SizedBox(width: 8),
                      Text(
                        'Check Google Play Store',
                        style: GoogleFonts.outfit(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Done',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Offline / Connection Fallback Dialog ─────────────────────────────────────
class _AppOfflineDialog extends StatelessWidget {
  final String currentVersion;
  final int currentBuild;

  const _AppOfflineDialog({
    Key? key,
    required this.currentVersion,
    required this.currentBuild,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.ink200, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: AppColors.amberLight,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.amberBorder, width: 2),
                ),
                child: const Icon(LucideIcons.wifiOff,
                    size: 30, color: AppColors.amberDark),
              ),

              const SizedBox(height: 14),

              Text(
                'Could Not Connect to Server',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink900,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Currently installed: v$currentVersion (Build $currentBuild).\nPlease check your internet connection, or view the Google Play Store directly.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink500,
                  height: 1.35,
                ),
              ),

              const SizedBox(height: 20),

              BouncingWidget(
                scaleFactor: 0.96,
                onTap: () {
                  Navigator.of(context).pop();
                  AppUpdateDialog.launchStore(null);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF059669), Color(0xFF10B981)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.externalLink,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Check on Google Play',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Dismiss',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
