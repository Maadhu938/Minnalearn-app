import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/startup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MinnaLearnApp());
}

class MinnaLearnApp extends StatelessWidget {
  const MinnaLearnApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      home: const StartupScreen(),
    );
  }
}
