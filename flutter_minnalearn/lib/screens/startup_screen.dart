import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../services/cloud_service.dart';
import 'main_screen.dart';
import 'onboarding_screen.dart';
import 'auth_screen.dart';
import '../services/notification_service.dart';
import '../utils/app_theme.dart';

class StartupScreen extends StatefulWidget {
  const StartupScreen({Key? key}) : super(key: key);

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  String? _errorMessage;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  @override
  void initState() {
    super.initState();
    _bootstrapApp();
  }

  Future<void> _bootstrapApp() async {
    try {
      final dbService = DatabaseService();
      await dbService.initialize();
      try {
        await NotificationService().initialize();
        await NotificationService().rescheduleAll();
      } catch (e, st) {
        debugPrint('Notification init/schedule failed: $e');
        debugPrintStack(stackTrace: st);
      }

      final hasSeenOnboarding = await dbService.hasSeenOnboarding();
      if (!hasSeenOnboarding) {
        // First time - request notification permission during onboarding flow
        try {
          final granted = await NotificationService().requestPermission();
          if (granted) {
            await NotificationService().rescheduleAll();
          }
        } catch (e, st) {
          debugPrint('Notification permission/schedule failed: $e');
          debugPrintStack(stackTrace: st);
        }
      } else {
        // Returning users: attempt scheduling (permission should already be set)
        try {
          await NotificationService().rescheduleAll();
        } catch (e) {
          debugPrint('Failed to schedule notifications: $e');
        }
      }
      final currentUser = AuthService().currentUser;

      if (!mounted) {
        return;
      }

      Widget nextScreen;
      
      if (currentUser != null) {
      // Fire and forget, don't block startup (with error handling)
      Future.microtask(() async {
        try {
          await CloudService().syncAll();
        } catch (e) {
          debugPrint('Background cloud sync failed: $e');
        }
      });
        nextScreen = const MainScreen();
      } else if (hasSeenOnboarding) {
        nextScreen = const AuthScreen();
      } else {
        nextScreen = const OnboardingScreen();
      }

      await Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 260),
          pageBuilder: (_, __, ___) => nextScreen,
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      _retryCount++;
      setState(() {
        _errorMessage = _retryCount >= _maxRetries
            ? 'Could not start the app after $_maxRetries attempts. Please restart the app.'
            : 'Could not start the app. Tap to try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: Stack(
        children: [
          // Background subtle warm glow circles
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryLight.withOpacity(0.4),
              ),
            ),
          ),
          Positioned(
            bottom: -90,
            right: -70,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.amberLight.withOpacity(0.5),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(34),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.20),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(34),
                      child: Image.asset(
                        'assets/logo.jpg',
                        width: 124,
                        height: 124,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'MinnaLearn',
                    style: GoogleFonts.inter(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      '日本語 N5 • Japanese Journey',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        fontFamilyFallback: ['Noto Sans CJK JP', 'sans-serif'],
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage ?? 'Preparing your Japanese journey...',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.ink500,
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (_errorMessage == null)
                    SizedBox(
                      width: 130,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: const LinearProgressIndicator(
                          minHeight: 5,
                          backgroundColor: AppColors.ink200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                    )
                  else
                    ElevatedButton(
                      onPressed: _bootstrapApp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 14,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        'Retry',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
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
