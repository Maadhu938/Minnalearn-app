import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/lesson.dart';
import '../services/database_service.dart';
import '../services/speech_service.dart';
import '../services/audio_service.dart';
import '../services/study_timer_service.dart';
import '../utils/vocabulary_display.dart';

class TypingTestScreen extends StatefulWidget {
  final Lesson lesson;

  const TypingTestScreen({Key? key, required this.lesson}) : super(key: key);

  @override
  State<TypingTestScreen> createState() => _TypingTestScreenState();
}

class _TypingTestScreenState extends State<TypingTestScreen> {
  final math.Random _random = math.Random();
  final TextEditingController _controller = TextEditingController();

  List<Vocabulary> _questions = [];
  int _currentIndex = 0;
  int _correctAnswers = 0;
  bool _answered = false;
  bool _wasCorrect = false;
  bool _scoreSaved = false;

  @override
  void initState() {
    super.initState();
    StudyTimerService().startTimer();
    _setupQuiz();
  }

  @override
  void dispose() {
    StudyTimerService().stopTimer();
    _controller.dispose();
    super.dispose();
  }

  void _setupQuiz() {
    final vocabulary = List<Vocabulary>.from(widget.lesson.vocabulary)..shuffle(_random);
    setState(() {
      _questions = vocabulary.take(math.min(5, vocabulary.length)).toList();
      _currentIndex = 0;
      _correctAnswers = 0;
      _answered = false;
      _wasCorrect = false;
      _scoreSaved = false;
      _controller.clear();
    });
  }

  Future<void> _submitAnswer() async {
    if (_answered || _questions.isEmpty) {
      return;
    }

    final answer = _normalize(_controller.text);
    final correct = _isCorrect(answer, _questions[_currentIndex].meaning);

    setState(() {
      _answered = true;
      _wasCorrect = correct;
      if (correct) {
        _correctAnswers += 1;
      }
    });

    if (correct) {
      SpeechService().playCorrectAnswer();
    } else {
      SpeechService().playWrongAnswer();
    }

    if (_currentIndex == _questions.length - 1) {
      AudioService().playLevelComplete();
      await _saveScoreIfNeeded();
    }
  }

  void _nextQuestion() {
    if (_currentIndex >= _questions.length - 1) {
      return;
    }

    setState(() {
      _currentIndex += 1;
      _answered = false;
      _wasCorrect = false;
      _controller.clear();
    });
  }

  bool _isCorrect(String answer, String meaning) {
    if (answer.isEmpty) {
      return false;
    }

    final acceptedAnswers = _candidateAnswers(meaning);

    return acceptedAnswers.contains(answer);
  }

  Set<String> _candidateAnswers(String meaning) {
    final values = <String>{};

    // Strip parenthetical content - it's explanatory, not an alternative answer
    // e.g., "to walk (go on foot)" → only "to walk" is accepted
    final cleaned = meaning
        .replaceAll(RegExp(r'\([^)]*\)'), '')
        .replaceAll(RegExp(r'（[^）]*）'), '')
        .trim();

    // Split by comma, slash, semicolon for alternative meanings
    // e.g., "he, she" → both "he" and "she" accepted
    final segments = cleaned.split(RegExp(r'[,/]'));

    for (final segment in segments) {
      final normalized = _normalize(segment);
      if (normalized.isEmpty) {
        continue;
      }

      values.add(normalized);

      // Strip common prefixes: "to walk" also accepts "walk"
      for (final prefix in ['to ', 'a ', 'an ', 'the ']) {
        if (normalized.startsWith(prefix)) {
          final trimmed = _normalize(normalized.substring(prefix.length));
          if (trimmed.isNotEmpty) {
            values.add(trimmed);
          }
        }
      }
    }

    return values;
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s~-]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<void> _saveScoreIfNeeded() async {
    if (_scoreSaved || _questions.isEmpty) {
      return;
    }

    _scoreSaved = true;
    final score = ((_correctAnswers / _questions.length) * 100).round();
    await DatabaseService().saveGameScore('Typing Test', score);
  }

  @override
  Widget build(BuildContext context) {
    final hasEnoughWords = _questions.isNotEmpty;
    final isFinished = hasEnoughWords && _answered && _currentIndex == _questions.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: hasEnoughWords
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(LucideIcons.arrowLeft, color: Color(0xFF4B5563)),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Typing Test',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Question ${_currentIndex + 1} of ${_questions.length}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: (_currentIndex + (_answered ? 1 : 0)) / _questions.length,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFE5E7EB),
                        color: const Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFF34D399), Color(0xFF10B981)],
                                ),
                                borderRadius: BorderRadius.circular(28),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Type English meaning of kana',
                                    style: GoogleFonts.inter(
                                      color: Colors.white.withOpacity(0.92),
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Text(
                                    _questions[_currentIndex].kanaText,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            TextField(
                              controller: _controller,
                              enabled: !_answered,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _submitAnswer(),
                              decoration: InputDecoration(
                                hintText: 'Type the meaning here',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                              ),
                            ),
                            const SizedBox(height: 20),
                            if (_answered)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: _wasCorrect ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _wasCorrect ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA),
                                  ),
                                ),
                                child: Text(
                                  _wasCorrect
                                      ? 'Correct! "${_questions[_currentIndex].meaning}"'
                                      : 'Correct answer: ${_questions[_currentIndex].meaning}',
                                  style: GoogleFonts.inter(
                                    color: _wasCorrect ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Score',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF6B7280),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$_correctAnswers',
                                  style: GoogleFonts.inter(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1F2937),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: isFinished
                                ? _setupQuiz
                                : _answered
                                    ? _nextQuestion
                                    : _submitAnswer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: Text(
                              isFinished ? 'Play Again' : _answered ? 'Next Word' : 'Submit',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : Center(
                  child: Text(
                    'Not enough vocabulary to start Typing Test.',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF6B7280),
                      fontSize: 15,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
