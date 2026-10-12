import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

import '../models/lesson.dart';
import '../services/quiz_engine.dart';
import '../services/database_service.dart';
import '../services/study_timer_service.dart';
import '../services/audio_service.dart';
import '../services/speech_service.dart';
import '../services/achievement_service.dart';
import '../utils/app_theme.dart';
import '../widgets/bouncing_widget.dart';
import '../widgets/fox_mascot_bubble.dart';
import '../services/japanese_font_service.dart';

class QuizScreen extends StatefulWidget {
  final Lesson lesson;

  const QuizScreen({Key? key, required this.lesson}) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late List<Question> _questions;
  int _currentIndex = 0;
  int _score = 0;
  int _streak = 0;
  bool _isAnswered = false;
  int? _selectedOptionIndex;
  bool _showResults = false;
  int _questionGeneration = 0;

  String _mascotMessage = 'What does this kana word mean?';
  FoxMood _mascotMood = FoxMood.neutral;

  @override
  void initState() {
    super.initState();
    StudyTimerService().startTimer();
    DatabaseService().updateStreak();
    _questions = QuizEngine().generateQuiz(widget.lesson);
    _updateMascotPrompt();
  }

  @override
  void dispose() {
    StudyTimerService().stopTimer();
    super.dispose();
  }

  void _updateMascotPrompt() {
    if (_questions.isEmpty) return;
    final currentQ = _questions[_currentIndex];
    if (currentQ.type == QuestionType.kanaToEnglish) {
      _mascotMessage = 'What does this kana word mean?';
    } else {
      _mascotMessage = 'Choose the matching kana for this meaning:';
    }
    _mascotMood = FoxMood.neutral;
  }

  void _handleAnswer(int optionIndex) {
    if (_isAnswered) return;

    final generation = _questionGeneration;
    final currentQ = _questions[_currentIndex];
    final isCorrect = currentQ.options[optionIndex] == currentQ.correctAnswer;

    setState(() {
      _isAnswered = true;
      _selectedOptionIndex = optionIndex;
      if (isCorrect) {
        _score++;
        _streak++;
        AudioService().playCorrect();
        _mascotMessage = _streak > 1
            ? 'Sugoi! 🔥 $_streak in a row!'
            : 'Yatta! That is correct! 🎉';
        _mascotMood = FoxMood.happy;
      } else {
        _streak = 0;
        AudioService().playWrong();
        _mascotMessage = 'Oops! Correct: "${currentQ.correctAnswer}" 💡';
        _mascotMood = FoxMood.encouraging;
      }
    });

    if (_currentIndex < _questions.length - 1) {
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted && generation == _questionGeneration) {
          setState(() {
            _currentIndex++;
            _isAnswered = false;
            _selectedOptionIndex = null;
            _updateMascotPrompt();
          });
        }
      });
    } else {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            _showResults = true;
          });
          AudioService().playLevelComplete();
          _updateLessonProgress();
        }
      });
    }
  }

  Future<void> _updateLessonProgress() async {
    if (_questions.isEmpty) return;
    double progress = _score / _questions.length;
    final bool wasCompleted = widget.lesson.progress >= 1.0;
    // Re-query current progress from database to avoid stale comparison after cloud sync
    final currentLessons = await DatabaseService().getLessons();
    final currentLesson = currentLessons.firstWhere(
      (l) => l.id == widget.lesson.id,
      orElse: () => widget.lesson,
    );
    if (progress > currentLesson.progress) {
      await DatabaseService().updateLessonProgress(widget.lesson.id, progress);
    }
    await DatabaseService().updateStreak();

    if (mounted) {
      await AchievementService().checkAchievements(
        context: context,
        lastScore: (_score / _questions.length * 100).toInt(),
      );
    }

    // Show lesson completion popup when lesson reaches 100% for the first time
    if (progress >= 1.0 && !wasCompleted && mounted) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        _showLessonCompletionDialog();
      }
    }
  }

  void _showLessonCompletionDialog() {
    AudioService().playLevelComplete();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.bambooLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.trophy, size: 48, color: AppColors.bambooDark),
              ),
              const SizedBox(height: 20),
              Text(
                'Sugoi desu ne!',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.lesson.id > 0 ? 'Lesson ${widget.lesson.id} completed!' : 'Quiz completed!',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: AppColors.ink500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: BouncingWidget(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.bamboo,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF34D399), width: 1.5),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.bambooDark,
                          offset: Offset(0, 4),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Yatta!',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _restartQuiz() {
    setState(() {
      _questionGeneration++;
      _currentIndex = 0;
      _score = 0;
      _streak = 0;
      _isAnswered = false;
      _selectedOptionIndex = null;
      _showResults = false;
      _questions = QuizEngine().generateQuiz(widget.lesson);
      _updateMascotPrompt();
    });
  }

  bool _isJapaneseText(String text) {
    return RegExp(
            r'[\u3040-\u30ff\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff\uff66-\uff9f]')
        .hasMatch(text);
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.scaffold,
        body: Center(
          child: Text(
            'No questions available for this lesson.',
            style: GoogleFonts.outfit(fontSize: 16, color: AppColors.ink500),
          ),
        ),
      );
    }

    if (_showResults) {
      return _buildResultsScreen();
    }

    final currentQuestion = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;
    final isJapaneseQuestion = currentQuestion.type == QuestionType.kanaToEnglish;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            // Header with Progress & Close
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      BouncingWidget(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.ink200, width: 1.5),
                          ),
                          child: const Icon(LucideIcons.x, color: AppColors.ink700, size: 18),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: LinearPercentIndicator(
                          padding: EdgeInsets.zero,
                          lineHeight: 12.0,
                          percent: progress,
                          backgroundColor: AppColors.ink200.withOpacity(0.6),
                          progressColor: AppColors.primary,
                          barRadius: const Radius.circular(10),
                          animation: true,
                          animateFromLastPercent: true,
                          animationDuration: 250,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _streak > 0 ? AppColors.amberLight : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _streak > 0 ? AppColors.amberBorder : AppColors.ink200,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _streak > 0 ? '🔥' : '🎯',
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_currentIndex + 1}/${_questions.length}',
                              style: GoogleFonts.outfit(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: _streak > 0 ? AppColors.amberDark : AppColors.ink700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Fox Mascot Speech Bubble
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: FoxMascotBubble(
                message: _mascotMessage,
                mood: _mascotMood,
              ),
            ),

            // Question Box & Choices
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  children: [
                    // Question Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.ink200, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 12,
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
                                isJapaneseQuestion ? 'Japanese Kana' : 'English Meaning',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              if (isJapaneseQuestion) ...[
                                const SizedBox(width: 8),
                                BouncingWidget(
                                  onTap: () {
                                    SpeechService().speakJapanese(currentQuestion.question);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.azureLight,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.azureBorder, width: 1),
                                    ),
                                    child: const Icon(
                                      LucideIcons.volume2,
                                      size: 15,
                                      color: AppColors.azureDark,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            currentQuestion.question,
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: (isJapaneseQuestion ||
                                    _isJapaneseText(currentQuestion.question))
                                ? JapaneseFontService().getJapaneseTextStyle(
                                    fontSize: currentQuestion.question.length > 7 ? 26 : 34,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.ink900,
                                    height: 1.25,
                                  )
                                : GoogleFonts.outfit(
                                    fontSize: currentQuestion.question.length > 28
                                        ? 18
                                        : (currentQuestion.question.length > 16 ? 21 : 25),
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink900,
                                    height: 1.25,
                                  ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Options: Tactile 3D Buttons
                    ...List.generate(currentQuestion.options.length, (index) {
                      return _buildOptionButton(index, currentQuestion);
                    }),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton(int index, Question question) {
    final optionText = question.options[index];
    final isCorrect = optionText == question.correctAnswer;
    final isSelected = _selectedOptionIndex == index;

    final optionLetters = ['A', 'B', 'C', 'D'];
    final letter = index < optionLetters.length ? optionLetters[index] : '${index + 1}';

    Color bgColor = Colors.white;
    Color borderColor = AppColors.ink200;
    Color bottomBorderColor = const Color(0xFFCBD5E1); // 3D depth border
    Color textColor = AppColors.ink900;
    Color letterBg = AppColors.ink100;
    Color letterColor = AppColors.ink700;
    Widget? statusIcon;

    if (_isAnswered) {
      if (isCorrect) {
        bgColor = const Color(0xFFECFDF5);
        borderColor = AppColors.bamboo;
        bottomBorderColor = AppColors.bambooDark;
        textColor = const Color(0xFF047857);
        letterBg = AppColors.bamboo;
        letterColor = Colors.white;
        statusIcon = const Icon(LucideIcons.checkCircle2, color: AppColors.bambooDark, size: 20);
      } else if (isSelected) {
        bgColor = const Color(0xFFFEF2F2);
        borderColor = AppColors.primary;
        bottomBorderColor = AppColors.primaryDark;
        textColor = const Color(0xFFB91C1C);
        letterBg = AppColors.primary;
        letterColor = Colors.white;
        statusIcon = const Icon(LucideIcons.xCircle, color: AppColors.primary, size: 20);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BouncingWidget(
        scaleFactor: 0.96,
        onTap: () => _handleAnswer(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: bottomBorderColor,
                offset: const Offset(0, 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              // Option Letter Pill (A, B, C, D)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: letterBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    letter,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: letterColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Option Text
              Expanded(
                child: Text(
                  optionText,
                  style: _isJapaneseText(optionText)
                      ? JapaneseFontService().getJapaneseTextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        )
                      : GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                ),
              ),

              if (statusIcon != null) statusIcon,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsScreen() {
    double percentage = (_score / _questions.length) * 100;
    bool isPassed = percentage >= 80;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Celebratory Fox Mascot Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isPassed ? AppColors.bambooBorder : AppColors.amberBorder,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isPassed ? AppColors.bamboo : AppColors.amber).withOpacity(0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Fox Avatar Badge
                    Container(
                      width: 104,
                      height: 104,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isPassed ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isPassed ? AppColors.bamboo : AppColors.amber,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isPassed ? AppColors.bamboo : AppColors.amber).withOpacity(0.2),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        isPassed ? 'assets/gif/Shiba Happy.gif' : 'assets/gif/Shiba Sad.gif',
                        width: 80,
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 18),

                    Text(
                      isPassed ? 'Sugoi! Quiz Passed! 🎉' : 'Good Effort! Keep Going! 💪',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isPassed
                          ? (widget.lesson.id > 0 ? 'You mastered the vocabulary in Lesson ${widget.lesson.id}!' : 'You mastered the vocabulary from All Lessons!')
                          : 'Practice makes perfect. Review the words and try again!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 14.5,
                        color: AppColors.ink500,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Stats Cards
              Row(
                children: [
                  Expanded(
                    child: _buildResultStatCard(
                      icon: LucideIcons.checkCheck,
                      iconColor: AppColors.bambooDark,
                      iconBg: AppColors.bambooLight,
                      label: 'Score',
                      value: '$_score / ${_questions.length}',
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildResultStatCard(
                      icon: LucideIcons.award,
                      iconColor: AppColors.azureDark,
                      iconBg: AppColors.azureLight,
                      label: 'Accuracy',
                      value: '${percentage.toInt()}%',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _buildResultStatCard(
                      icon: LucideIcons.flame,
                      iconColor: AppColors.amberDark,
                      iconBg: AppColors.amberLight,
                      label: 'Streak Bonus',
                      value: '+${_score * 5} XP',
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildResultStatCard(
                      icon: LucideIcons.bookOpen,
                      iconColor: AppColors.primary,
                      iconBg: AppColors.primaryLight,
                      label: 'Lesson',
                      value: widget.lesson.id > 0 ? 'Lesson ${widget.lesson.id}' : 'All Lessons',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Action Buttons (Duolingo Tactile 3D Buttons)
              Row(
                children: [
                  Expanded(
                    child: BouncingWidget(
                      onTap: _restartQuiz,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.ink200, width: 2),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0xFFCBD5E1),
                              offset: Offset(0, 4),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LucideIcons.rotateCcw, color: AppColors.ink700, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Retry',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 2,
                    child: BouncingWidget(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFF43F5E), width: 2),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0xFF9F1239),
                              offset: Offset(0, 4),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Continue',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(LucideIcons.arrowRight, color: Colors.white, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultStatCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.ink200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
