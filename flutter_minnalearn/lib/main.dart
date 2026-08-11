import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'screens/startup_screen.dart';
import 'services/notification_service.dart';
import 'services/analytics_service.dart';

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
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'MinnaLearn',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.pink,
          primary: Colors.pink,
          secondary: Colors.pinkAccent,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
      ),
      navigatorObservers: [AnalyticsService().observer],
      home: const StartupScreen(),
    );
  }
}
