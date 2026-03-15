import 'dart:math';

import '../models/lesson.dart';
import '../utils/vocabulary_display.dart';

enum QuestionType {
  kanaToEnglish,
  englishToKana,
}

class Question {
  final String question;
  final String correctAnswer;
  final List<String> options;
  final QuestionType type;
  final dynamic originalObject; // Vocabulary source item

  Question({
    required this.question,
    required this.correctAnswer,
    required this.options,
    required this.type,
    required this.originalObject,
  });
}

class QuizEngine {
  final Random _random = Random();

  List<Question> generateQuiz(Lesson lesson, {int questionCount = 10}) {
    final questions = <Question>[];
    final allItems = List<Vocabulary>.from(lesson.vocabulary);
    if (allItems.isEmpty) {
      return [];
    }

    allItems.shuffle(_random);
    final actualCount = min(questionCount, allItems.length);
    final selectedItems = allItems.take(actualCount).toList();

    for (final item in selectedItems) {
      questions.add(_generateVocabQuestion(item, lesson.vocabulary));
    }

    return questions;
  }

  Question _generateVocabQuestion(Vocabulary vocab, List<Vocabulary> allVocab) {
    final availableTypes = <QuestionType>[
      QuestionType.kanaToEnglish,
      QuestionType.englishToKana,
    ];
    final type = availableTypes[_random.nextInt(availableTypes.length)];
    late final String questionText;
    late final String correctAnswer;

    if (type == QuestionType.kanaToEnglish) {
      questionText = vocab.kanaText;
      correctAnswer = vocab.meaning;
    } else {
      questionText = vocab.meaning;
      correctAnswer = vocab.kanaText;
    }

    final options = _generateOptions(correctAnswer, allVocab, type);

    return Question(
      question: questionText,
      correctAnswer: correctAnswer,
      options: options,
      type: type,
      originalObject: vocab,
    );
  }

  List<String> _generateOptions(
    String correctAnswer,
    List<dynamic> pool,
    QuestionType type,
  ) {
    final options = <String>{correctAnswer};
    final shuffledPool = List<dynamic>.from(pool)..shuffle(_random);

    for (final item in shuffledPool) {
      if (options.length >= 4) {
        break;
      }

      var distractor = '';
      if (item is Vocabulary) {
        if (type == QuestionType.kanaToEnglish) {
          distractor = item.meaning;
        } else if (type == QuestionType.englishToKana) {
          distractor = item.kanaText;
        }
      }

      if (distractor.isNotEmpty && distractor != correctAnswer) {
        options.add(distractor);
      }
    }

    final fallbackDistractors = type == QuestionType.kanaToEnglish
        ? ['practice', 'review', 'study', 'lesson']
        : ['option a', 'option b', 'option c', 'option d'];
    var i = 0;
    while (options.length < 4) {
      options.add(fallbackDistractors[i % fallbackDistractors.length]);
      i++;
    }

    final result = options.toList();
    result.shuffle(_random);
    return result;
  }
}
