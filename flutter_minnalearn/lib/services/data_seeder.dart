import 'dart:convert';

import 'package:flutter/services.dart';

import '../data/n5_kanji_data.dart';
import '../models/lesson.dart';

class DataSeeder {
  static const String _vocabularyAssetPath = 'vocabulary.json';

  static Future<List<Lesson>> loadInitialLessons() async {
    final rawJson = await rootBundle.loadString(_vocabularyAssetPath);
    return parseLessons(rawJson);
  }

  static List<Lesson> parseLessons(String rawJson) {
    final lessonBlocks = _decodeLessonBlocks(rawJson);
    final lessonsById = <int, List<Map<String, dynamic>>>{};

    for (final block in lessonBlocks) {
      final lessonId = _parseLessonId(block['lesson']);
      if (lessonId == null) {
        continue;
      }

      final words = (block['words'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((word) => Map<String, dynamic>.from(word))
          .toList();

      lessonsById.putIfAbsent(lessonId, () => <Map<String, dynamic>>[]).addAll(words);
    }

    return [
      for (int lessonId = 1; lessonId <= 25; lessonId++)
        Lesson(
          id: lessonId,
          title: '',
          vocabulary: _buildVocabulary(lessonId, lessonsById[lessonId] ?? const []),
          kanji: N5KanjiData.buildKanjiForLesson(lessonId),
        ),
    ];
  }

  static List<Map<String, dynamic>> _decodeLessonBlocks(String rawJson) {
    final trimmed = rawJson.trim();
    if (trimmed.isEmpty) {
      return const [];
    }

    final normalizedJson = trimmed.startsWith('[')
        ? trimmed
        : '[${trimmed.replaceAll(RegExp(r'}\s*[\r\n]+\s*{'), '},{')}]';
    final decoded = jsonDecode(normalizedJson);

    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    if (decoded is Map) {
      return [Map<String, dynamic>.from(decoded)];
    }

    return const [];
  }

  static int? _parseLessonId(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '');
  }

  static List<Vocabulary> _buildVocabulary(
    int lessonId,
    List<Map<String, dynamic>> words,
  ) {
    final vocabulary = <Vocabulary>[];
    final seenEntries = <String>{};

    for (final word in words) {
      final kana = _cleanText(word['kana']);
      final kanji = _cleanText(word['kanji']);
      final meaning = _cleanText(word['meaning']);
      final japanese = _buildJapaneseText(kana: kana, kanji: kanji);

      if (japanese.isEmpty || meaning.isEmpty) {
        continue;
      }

      final dedupeKey = '$japanese|$kana|$meaning';
      if (!seenEntries.add(dedupeKey)) {
        continue;
      }

      vocabulary.add(
        Vocabulary(
          id: 'lesson_${lessonId}_vocab_${(vocabulary.length + 1).toString().padLeft(3, '0')}',
          japanese: japanese,
          romaji: kana.isNotEmpty ? kana : japanese,
          meaning: meaning,
          type: VocabularyType.vocabulary,
          lessonId: lessonId,
        ),
      );
    }

    return vocabulary;
  }

  static String _buildJapaneseText({
    required String kana,
    required String kanji,
  }) {
    if (kanji.isEmpty) {
      return kana;
    }

    if (kana.isEmpty || kanji == kana) {
      return kanji;
    }

    return kanji;
  }

  static String _cleanText(dynamic value) {
    return value?.toString().trim() ?? '';
  }
}
