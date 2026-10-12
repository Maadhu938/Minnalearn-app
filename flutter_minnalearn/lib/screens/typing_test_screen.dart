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
import '../utils/app_theme.dart';
import '../widgets/bouncing_widget.dart';
import '../widgets/fox_mascot_bubble.dart';
import '../services/japanese_font_service.dart';

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

  String _mascotMessage = 'Type the English meaning of this Japanese word!';
  FoxMood _mascotMood = FoxMood.neutral;

  @override
  void initState() {
    super.initState();
    StudyTimerService().startTimer();
    DatabaseService().updateStreak();
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
      _mascotMessage = 'Type the English meaning of this Japanese word!';
      _mascotMood = FoxMood.neutral;
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
        _mascotMessage = 'Sugoi! Accurate typing! 🎉';
        _mascotMood = FoxMood.happy;
      } else {
        _mascotMessage = 'Oops! Correct was: "${_questions[_currentIndex].meaning}" 💡';
        _mascotMood = FoxMood.encouraging;
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
      _mascotMessage = 'Type the English meaning for the next word!';
      _mascotMood = FoxMood.neutral;
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

    final cleaned = meaning
        .replaceAll(RegExp(r'\([^)]*\)'), '')
        .replaceAll(RegExp(r'（[^）]*）'), '')
        .trim();

    final segments = cleaned.split(RegExp(r'[,/]'));

    for (final segment in segments) {
      final normalized = _normalize(segment);
      if (normalized.isEmpty) {
        continue;
      }

      values.add(normalized);

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
        .replaceAll(RegExp(r'[^a-z0-9\s~\-]'), ' ')
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

    if (!hasEnoughWords) {
      return Scaffold(
        backgroundColor: AppColors.scaffold,
        body: Center(
          child: Text(
            'Not enough vocabulary to start Typing Test.',
            style: GoogleFonts.outfit(color: AppColors.ink500, fontSize: 16),
          ),
        ),
      );
    }

    final currentWord = _questions[_currentIndex];

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  BouncingWidget(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.ink200, width: 1.5),
                      ),
                      child: const Icon(LucideIcons.arrowLeft, color: AppColors.ink700, size: 20),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.bambooLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.bambooBorder, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.keyboard, size: 15, color: AppColors.bambooDark),
                        const SizedBox(width: 6),
                        Text(
                          'Typing Test • Word ${_currentIndex + 1}/${_questions.length}',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.bambooDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  BouncingWidget(
                    onTap: _setupQuiz,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.ink200, width: 1.5),
                      ),
                      child: const Icon(LucideIcons.rotateCcw, color: AppColors.ink500, size: 18),
                    ),
                  ),
                ],
              ),
            ),

            // Fox Mascot Prompt
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: FoxMascotBubble(
                message: _mascotMessage,
                mood: _mascotMood,
              ),
            ),

            // Content Area
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  children: [
                    // Question Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: AppColors.ink200, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Japanese Word',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              BouncingWidget(
                                onTap: () {
                                  SpeechService().speakJapanese(currentWord.kanaText);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.azureLight,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.azureBorder, width: 1),
                                  ),
                                  child: const Icon(LucideIcons.volume2, size: 15, color: AppColors.azureDark),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              currentWord.kanaText,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              style: JapaneseFontService().getJapaneseTextStyle(
                                fontSize: currentWord.kanaText.length > 7 ? 28 : 38,
                                fontWeight: FontWeight.w900,
                                color: AppColors.ink900,
                              ),
                            ),
                          ),
                          if (currentWord.romaji.trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                currentWord.romaji,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  color: AppColors.ink400,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Input Field
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _answered
                              ? (_wasCorrect ? AppColors.bamboo : AppColors.primary)
                              : AppColors.ink200,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _controller,
                        enabled: !_answered,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submitAnswer(),
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink900,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Type English translation...',
                          hintStyle: GoogleFonts.outfit(
                            fontSize: 16,
                            color: AppColors.ink400,
                            fontWeight: FontWeight.w500,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          suffixIcon: _controller.text.isNotEmpty && !_answered
                              ? IconButton(
                                  icon: const Icon(LucideIcons.x, size: 18, color: AppColors.ink400),
                                  onPressed: () => setState(() => _controller.clear()),
                                )
                              : null,
                        ),
                      ),
                    ),

                    if (_answered) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        decoration: BoxDecoration(
                          color: _wasCorrect ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: _wasCorrect ? AppColors.bamboo : AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _wasCorrect ? LucideIcons.checkCircle2 : LucideIcons.alertCircle,
                              color: _wasCorrect ? AppColors.bambooDark : AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _wasCorrect
                                    ? 'Perfect! "${currentWord.meaning}"'
                                    : 'Meaning: ${currentWord.meaning}',
                                style: GoogleFonts.outfit(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: _wasCorrect ? const Color(0xFF065F46) : const Color(0xFF9F1239),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom Action Bar
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                10,
                20,
                MediaQuery.of(context).padding.bottom > 0
                    ? MediaQuery.of(context).padding.bottom + 14
                    : 20,
              ),
              child: Row(
                children: [
                  // Score Indicator Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.ink200, width: 1.5),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Score',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink400,
                          ),
                        ),
                        Text(
                          '$_correctAnswers/${_questions.length}',
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink900,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Tactile 3D Action Button
                  Expanded(
                    child: BouncingWidget(
                      scaleFactor: 0.95,
                      onTap: isFinished
                          ? _setupQuiz
                          : _answered
                              ? _nextQuestion
                              : _submitAnswer,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: isFinished
                              ? AppColors.azure
                              : _answered
                                  ? AppColors.primary
                                  : AppColors.bamboo,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isFinished
                                ? const Color(0xFF38BDF8)
                                : _answered
                                    ? const Color(0xFFF43F5E)
                                    : const Color(0xFF34D399),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isFinished
                                  ? AppColors.azureDark
                                  : _answered
                                      ? const Color(0xFF9F1239)
                                      : AppColors.bambooDark,
                              offset: const Offset(0, 4),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            isFinished
                                ? 'Play Again'
                                : _answered
                                    ? 'Next Word →'
                                    : 'Check Answer',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
