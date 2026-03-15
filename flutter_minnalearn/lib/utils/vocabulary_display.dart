import '../models/lesson.dart';

extension VocabularyDisplay on Vocabulary {
  // The current seed stores kana in `romaji`; use that as the study prompt.
  String get kanaText {
    final reading = romaji.trim();
    if (reading.isNotEmpty) {
      return reading;
    }
    return japanese.trim();
  }

  String get kanjiText {
    final written = japanese.trim();
    if (written.isEmpty || written == kanaText) {
      return '';
    }
    return written;
  }

  bool get hasKanjiForm => kanjiText.isNotEmpty;
}
