import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:google_fonts/google_fonts.dart';

import 'database_service.dart';
import '../widgets/app_update_dialog.dart';
import '../widgets/playstore_review_dialog.dart';
import '../widgets/whats_new_dialog.dart';
import '../utils/app_theme.dart';

class AppEngagementService with WidgetsBindingObserver {
  static final AppEngagementService _instance =
      AppEngagementService._internal();
  factory AppEngagementService() => _instance;
  AppEngagementService._internal();

  Timer? _usageTimer;
  int _sessionUsageSeconds = 0;
  int _cumulativeUsageSeconds = 0;
  int _secondsSinceLastSave = 0;
  bool _isTrackingStarted = false;
  bool _isCheckingReview = false;
  bool _isCheckingUpdate = false;
  bool _hasPromptedThisSession = false;

  BuildContext? _activeContext;

  /// Starts real-time tracking of active in-app foreground usage.
  Future<void> startTracking(BuildContext context) async {
    _activeContext = context;

    if (_isTrackingStarted) return;
    _isTrackingStarted = true;

    WidgetsBinding.instance.addObserver(this);

    final db = DatabaseService();
    _cumulativeUsageSeconds =
        await db.getUserStatInt('total_app_usage_seconds') ?? 0;

    _startTimer();
  }

  void updateContext(BuildContext context) {
    _activeContext = context;
  }

  void _startTimer() {
    _usageTimer?.cancel();
    _usageTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _sessionUsageSeconds++;
      _cumulativeUsageSeconds++;
      _secondsSinceLastSave++;

      // Save to SQLite every 10 seconds for persistence
      if (_secondsSinceLastSave >= 10) {
        _secondsSinceLastSave = 0;
        DatabaseService().setUserStatInt(
          'total_app_usage_seconds',
          _cumulativeUsageSeconds,
        );
      }

      // Only prompt when the user has actually used the app for 5 minutes (300s) in this session
      if (_sessionUsageSeconds >= 300 && !_hasPromptedThisSession) {
        if (_activeContext != null && _activeContext!.mounted) {
          checkAndPromptReview(_activeContext!);
        }
      }
    });
  }

  void _pauseTimer() {
    _usageTimer?.cancel();
    _usageTimer = null;
    DatabaseService().setUserStatInt(
      'total_app_usage_seconds',
      _cumulativeUsageSeconds,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startTimer();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _pauseTimer();
    }
  }

  /// Checks if the app was recently updated, and displays the "What's New" dialog.
  /// If it is the first installation, it records the current version so What's New
  /// is only shown when the user actually updates the app.
  Future<void> checkAndShowUpdateChangelog(BuildContext context) async {
    if (_isCheckingUpdate) return;
    _isCheckingUpdate = true;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final db = DatabaseService();

      final lastSeenVersion =
          await db.getUserStatText('last_seen_app_version');

      // First run ever: record baseline version without showing changelog
      if (lastSeenVersion == null) {
        await db.setUserStatText('last_seen_app_version', currentVersion);
        return;
      }

      // If user has updated from a previous version
      if (lastSeenVersion != currentVersion) {
        if (context.mounted) {
          await Future.delayed(const Duration(milliseconds: 600));
          if (context.mounted) {
            await WhatsNewDialog.show(context, currentVersion);
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking update changelog: $e');
    } finally {
      _isCheckingUpdate = false;
    }
  }

  /// Checks Firestore and remote version endpoint for available updates.
  /// When silentIfUpToDate is false, provides immediate visual feedback and
  /// displays the Up-to-Date or Update Available dialog.
  Future<void> checkForAvailableUpdate(
    BuildContext context, {
    bool silentIfUpToDate = true,
  }) async {
    BuildContext? loadingCtx;

    // Show visual loading dialog when explicitly tapped by user
    if (!silentIfUpToDate && context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) {
          loadingCtx = dialogCtx;
          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppShadows.card,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2.5,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Checking for updates...',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

      // 1. Try Firestore app_config/version
      Map<String, dynamic>? remoteData;
      try {
        final fs = FirebaseFirestore.instance;
        final doc = await fs
            .collection('app_config')
            .doc('version')
            .get()
            .timeout(const Duration(seconds: 3));
        if (doc.exists && doc.data() != null) {
          remoteData = doc.data();
        }
      } catch (_) {}

      // 2. Fallback to public web version.json if Firestore returned nothing
      if (remoteData == null) {
        remoteData = await _fetchRemoteVersionJson();
      }

      // Close loading dialog if open
      if (loadingCtx != null && loadingCtx!.mounted) {
        Navigator.of(loadingCtx!).pop();
        loadingCtx = null;
      }

      if (remoteData != null) {
        final latestVersion =
            (remoteData['latest_version'] as String?) ?? currentVersion;
        final latestBuild =
            (remoteData['latest_build_number'] as int?) ?? currentBuild;
        final forceUpdate =
            (remoteData['force_update'] as bool?) ?? false;
        final title = remoteData['title'] as String?;
        final message = remoteData['message'] as String?;
        final releaseNotes =
            List<String>.from(remoteData['release_notes'] ?? <String>[]);
        final playStoreUrl = (remoteData['play_store_url'] as String?) ??
            'https://play.google.com/store/apps/details?id=com.maadhu.minnalearn';

        final isNewer = _isRemoteNewer(
          remoteVer: latestVersion,
          remoteBuild: latestBuild,
          currentVer: currentVersion,
          currentBuild: currentBuild,
        );

        if (isNewer && context.mounted) {
          await AppUpdateDialog.show(
            context,
            AppUpdateInfo(
              latestVersion: latestVersion,
              latestBuildNumber: latestBuild,
              title: title,
              message: message,
              releaseNotes: releaseNotes,
              forceUpdate: forceUpdate,
              playStoreUrl: playStoreUrl,
            ),
          );
        } else if (!silentIfUpToDate && context.mounted) {
          await AppUpdateDialog.showUpToDate(
            context,
            currentVersion: currentVersion,
            currentBuild: currentBuild,
          );
        }
      } else {
        // If neither Firestore nor web returned a newer version, current version is up to date
        if (!silentIfUpToDate && context.mounted) {
          await AppUpdateDialog.showUpToDate(
            context,
            currentVersion: currentVersion,
            currentBuild: currentBuild,
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking remote app update: $e');

      if (loadingCtx != null && loadingCtx!.mounted) {
        Navigator.of(loadingCtx!).pop();
        loadingCtx = null;
      }

      if (!silentIfUpToDate && context.mounted) {
        try {
          final packageInfo = await PackageInfo.fromPlatform();
          await AppUpdateDialog.showOffline(
            context,
            currentVersion: packageInfo.version,
            currentBuild: int.tryParse(packageInfo.buildNumber) ?? 0,
          );
        } catch (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Could not check for updates. Please check your connection.'),
            ),
          );
        }
      }
    }
  }

  Future<Map<String, dynamic>?> _fetchRemoteVersionJson() async {
    final endpoints = [
      'https://raw.githubusercontent.com/Maadhu938/Minnalearn-app/main/docs/version.json',
      'https://getminnalearn.xyz/version.json',
    ];
    for (final url in endpoints) {
      try {
        final client = HttpClient()
          ..connectionTimeout = const Duration(seconds: 3);
        final request = await client.getUrl(Uri.parse(url));
        final response =
            await request.close().timeout(const Duration(seconds: 3));
        if (response.statusCode == 200) {
          final content = await response.transform(utf8.decoder).join();
          final data = jsonDecode(content);
          if (data is Map<String, dynamic>) {
            return data;
          }
        }
      } catch (_) {}
    }
    return null;
  }

  bool _isRemoteNewer({
    required String remoteVer,
    required int remoteBuild,
    required String currentVer,
    required int currentBuild,
  }) {
    try {
      final rParts = remoteVer
          .split('+')
          .first
          .split('.')
          .map((s) => int.tryParse(s) ?? 0)
          .toList();
      final cParts = currentVer
          .split('+')
          .first
          .split('.')
          .map((s) => int.tryParse(s) ?? 0)
          .toList();

      for (int i = 0; i < 3; i++) {
        final r = i < rParts.length ? rParts[i] : 0;
        final c = i < cParts.length ? cParts[i] : 0;
        if (r > c) return true;
        if (r < c) return false;
      }

      if (remoteBuild > currentBuild) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Checks if the user has reached 5 minutes (300s) of app usage or study,
  /// and prompts the Play Store review / direct feedback dialog.
  Future<void> checkAndPromptReview(BuildContext context) async {
    if (_isCheckingReview || _hasPromptedThisSession) return;
    _isCheckingReview = true;

    try {
      // Only trigger after user has actively used the app for at least 5 minutes (300s)
      if (_sessionUsageSeconds < 300) {
        return;
      }

      final db = DatabaseService();
      final reviewStatus =
          await db.getUserStatText('playstore_review_status');

      // If user already rated or sent feedback, never prompt again
      if (reviewStatus == 'rated' || reviewStatus == 'feedback_sent') {
        return;
      }

      // If user tapped "maybe later", wait at least 5 days before asking again
      if (reviewStatus == 'dismissed') {
        final dismissedAt =
            await db.getUserStatInt('playstore_review_dismissed_at') ?? 0;
        final elapsed = DateTime.now().millisecondsSinceEpoch - dismissedAt;
        const cooldown = 5 * 24 * 60 * 60 * 1000; // 5 days in ms
        if (elapsed < cooldown) {
          return;
        }
      }

      _hasPromptedThisSession = true;

      if (context.mounted) {
        await Future.delayed(const Duration(milliseconds: 1000));
        if (context.mounted) {
          await PlaystoreReviewDialog.show(context);
        }
      }
    } catch (e) {
      debugPrint('Error checking review prompt: $e');
    } finally {
      _isCheckingReview = false;
    }
  }

  void dispose() {
    _usageTimer?.cancel();
    _usageTimer = null;
    WidgetsBinding.instance.removeObserver(this);
    _isTrackingStarted = false;
  }
}
