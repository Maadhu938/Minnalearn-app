import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'database_service.dart';

class JapaneseFontService {
  static final JapaneseFontService _instance = JapaneseFontService._internal();
  factory JapaneseFontService() => _instance;
  JapaneseFontService._internal();

  /// Key of the selected font ('mincho', 'classic', 'gothic')
  static final ValueNotifier<String> currentFontNotifier =
      ValueNotifier<String>('mincho');

  String get currentFontKey => currentFontNotifier.value;

  Future<void> initialize() async {
    try {
      final db = DatabaseService();
      final saved = await db.getUserStatText('preferred_japanese_font');
      if (saved != null && saved.isNotEmpty) {
        currentFontNotifier.value = saved;
      }
    } catch (_) {}
  }

  Future<void> setFont(String fontKey) async {
    currentFontNotifier.value = fontKey;
    try {
      final db = DatabaseService();
      await db.setUserStatText('preferred_japanese_font', fontKey);
    } catch (_) {}
  }

  String get fontDisplayName {
    switch (currentFontNotifier.value) {
      case 'classic':
        return 'Shippori Mincho';
      case 'gothic':
        return 'Noto Sans JP';
      case 'mincho':
      default:
        return 'Sawarabi Mincho';
    }
  }

  String get currentFontFamily {
    switch (currentFontNotifier.value) {
      case 'gothic':
        return GoogleFonts.notoSansJp().fontFamily ?? 'sans-serif';
      case 'classic':
        return GoogleFonts.shipporiMincho().fontFamily ?? 'serif';
      case 'mincho':
      default:
        return GoogleFonts.sawarabiMincho().fontFamily ?? 'serif';
    }
  }

  /// Returns a TextStyle using the user's currently selected Japanese font.
  TextStyle getJapaneseTextStyle({
    required double fontSize,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    switch (currentFontNotifier.value) {
      case 'gothic':
        return GoogleFonts.notoSansJp(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
          letterSpacing: letterSpacing,
        );
      case 'classic':
        return GoogleFonts.shipporiMincho(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
          letterSpacing: letterSpacing,
        );
      case 'mincho':
      default:
        return GoogleFonts.sawarabiMincho(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
          letterSpacing: letterSpacing,
        );
    }
  }

  static const List<Map<String, String>> availableFonts = [
    {
      'key': 'mincho',
      'name': 'Sawarabi Mincho (さわらび明朝)',
      'label': 'Traditional Brush Mincho',
      'description':
          'Textbook calligraphy brush strokes with clear stroke stops and hooks.',
      'sample': 'あ漢',
      'preview': '駅 • 日本語',
    },
    {
      'key': 'classic',
      'name': 'Shippori Mincho (しっぽり明朝)',
      'label': 'Classic Elegant Mincho',
      'description':
          'Graceful Japanese literary typeface with authentic proportioning.',
      'sample': 'あ漢',
      'preview': '道 • 学び',
    },
    {
      'key': 'gothic',
      'name': 'Noto Sans JP (ゴシック体)',
      'label': 'Modern Clean Gothic',
      'description':
          'Modern, high-legibility digital sans-serif typeface.',
      'sample': 'あ漢',
      'preview': '本 • 練習',
    },
  ];
}
