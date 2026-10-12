import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'screens/startup_screen.dart';
import 'services/notification_service.dart';
import 'services/analytics_service.dart';
import 'services/japanese_font_service.dart';
import 'utils/app_theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    if (Platform.isAndroid) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('Firebase initialized (Android)');
    } else {
      debugPrint('Firebase init skipped: unsupported platform $defaultTargetPlatform');
    }
  } catch (e) {
    debugPrint('Firebase init failed: $e - Analytics/notifications may be limited');
  }
  
  // Initialize user preferred Japanese font globally
  try {
    await JapaneseFontService().initialize();
  } catch (e) {
    debugPrint('Japanese font service init failed: $e');
  }

  final NotificationService notificationService = NotificationService();
  try {
    await notificationService.initialize();
  } catch (e) {
    debugPrint('Notification initialization failed: $e');
  }
  
  runApp(const MinnaLearnApp());
}

class MinnaLearnApp extends StatelessWidget {
  const MinnaLearnApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: JapaneseFontService.currentFontNotifier,
      builder: (context, fontKey, _) {
        return MaterialApp(
          key: ValueKey(fontKey),
          navigatorKey: navigatorKey,
          title: 'MinnaLearn',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.getTheme(fontKey),
          navigatorObservers: [AnalyticsService().observer],
          home: const StartupScreen(),
        );
      },
    );
  }
}
