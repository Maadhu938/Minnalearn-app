enum VocabularyType {
  vocabulary,
  expression,
  additional,
}

class Vocabulary {
  final String? id;
  final String japanese;
  final String romaji;
  final String meaning;
  final VocabularyType type;
  final int? lessonId;

  Vocabulary({
    this.id,
    required this.japanese,
    required this.romaji,
    required this.meaning,
    required this.type,
    this.lessonId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'japanese': japanese,
      'romaji': romaji,
      'meaning': meaning,
      'type': type.name,
      'lesson_id': lessonId,
    };
  }

  factory Vocabulary.fromMap(Map<String, dynamic> map) {
    return Vocabulary(
      id: map['id']?.toString(),
      japanese: map['japanese'],
      romaji: map['romaji'],
      meaning: map['meaning'],
      type: VocabularyType.values.byName(map['type']),
      lessonId: map['lesson_id'],
    );
  }
}

class Kanji {
  final String? id;
  final String character;
  final String meaning;
  final String onReading;
  final String kunReading;
  final int? lessonId;

  Kanji({
    this.id,
    required this.character,
    required this.meaning,
    required this.onReading,
    required this.kunReading,
    this.lessonId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'character': character,
      'meaning': meaning,
      'on_reading': onReading,
      'kun_reading': kunReading,
      'lesson_id': lessonId,
    };
  }

  factory Kanji.fromMap(Map<String, dynamic> map) {
    return Kanji(
      id: map['id']?.toString(),
      character: map['character'],
      meaning: map['meaning'],
      onReading: map['on_reading'],
      kunReading: map['kun_reading'],
      lessonId: map['lesson_id'],
    );
  }
}

class Lesson {
  final int id;
  final String title;
  final List<Vocabulary> vocabulary;
  final List<Kanji> kanji;
  final bool completed;
  final double progress;

  Lesson({
    required this.id,
    required this.title,
    this.vocabulary = const [],
    this.kanji = const [],
    this.completed = false,
    this.progress = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'completed': completed ? 1 : 0,
      'progress': progress,
    };
  }

  factory Lesson.fromMap(Map<String, dynamic> map, {List<Vocabulary> vocab = const [], List<Kanji> kanji = const []}) {
    return Lesson(
      id: map['id'],
      title: map['title'],
      completed: map['completed'] == 1,
      progress: (map['progress'] as num).toDouble(),
      vocabulary: vocab,
      kanji: kanji,
    );
  }
}
