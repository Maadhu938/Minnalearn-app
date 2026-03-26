import 'dart:convert';

import 'package:flutter/services.dart';

import '../data/n5_kanji_data.dart';
import '../models/lesson.dart';

class DataSeeder {
  static Future<List<Lesson>> loadInitialLessons() async {
    final List<Lesson> lessons = [];
    for (int i = 1; i <= 25; i++) {
      try {
        final content = await rootBundle.loadString('assets/vocab/bai$i.txt');
        final vocab = _parseTxtVocab(content, i);
        lessons.add(
          Lesson(
            id: i,
            title: '',
            vocabulary: vocab,
            kanji: N5KanjiData.buildKanjiForLesson(i),
          ),
        );
      } catch (e) {
        // Fallback for missing assets
        lessons.add(
          Lesson(
            id: i,
            title: '',
            vocabulary: const [],
            kanji: N5KanjiData.buildKanjiForLesson(i),
          ),
        );
      }
    }
    return lessons;
  }

  static List<Vocabulary> _parseTxtVocab(String content, int lessonId) {
    final List<Vocabulary> vocabulary = [];
    final List<String> lines = content.split('\n');
    int index = 1;

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      final match = RegExp(r'^(.+?)(?:\s*\[(.+?)\])?\s*/(.+?)/$').firstMatch(line);
      if (match != null) {
        final mainText = match.group(1)!.trim();
        final reading = match.group(2)?.trim();
        final meaning = match.group(3)!.trim();

        vocabulary.add(
          Vocabulary(
            id: 'lesson_${lessonId}_vocab_${index.toString().padLeft(3, '0')}',
            japanese: mainText,
            romaji: reading ?? mainText,
            meaning: meaning,
            type: VocabularyType.vocabulary,
            lessonId: lessonId,
          ),
        );
        index++;
      }
    }
    return vocabulary;
  }


}
