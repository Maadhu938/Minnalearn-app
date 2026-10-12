import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/lesson.dart';
import '../services/database_service.dart';
import '../services/speech_service.dart';
import '../services/study_timer_service.dart';
import '../services/achievement_service.dart';
import '../utils/vocabulary_display.dart';
import '../utils/app_theme.dart';
import '../widgets/bouncing_widget.dart';
import '../widgets/fox_mascot_bubble.dart';
import '../services/japanese_font_service.dart';

class TrueOrFalseScreen extends StatefulWidget {
  final Lesson lesson;

  const TrueOrFalseScreen({Key? key, required this.lesson}) : super(key: key);

  @override
  State<TrueOrFalseScreen> createState() => _TrueOrFalseScreenState();
}

class _TrueOrFalseScreenState extends State<TrueOrFalseScreen> {
  final Random _random = Random();

  late List<Vocabulary> _vocabPool;
  Vocabulary? _currentWord;
  String? _displayMeaning;
  bool _isCorrectPair = false;

  int _score = 0;
  int _combo = 0;
  int _timeLeft = 60;
  int _correctCount = 0;
  int _totalAnswered = 0;
  Timer? _gameTimer;
  bool _isPlaying = false;
  bool _isGameOver = false;
  bool _showFeedback = false;
  bool? _lastAnswerCorrect;

  String _mascotMessage = 'Does this Japanese word match the meaning?';
  FoxMood _mascotMood = FoxMood.neutral;

  @override
  void initState() {
    super.initState();
    StudyTimerService().startTimer();
    DatabaseService().updateStreak();
    _vocabPool = List.from(widget.lesson.vocabulary)
      ..removeWhere((v) => v.meaning.trim().isEmpty);
    _startGame();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    StudyTimerService().stopTimer();
    super.dispose();
  }

  void _startGame() {
    if (_vocabPool.isEmpty) return;

    setState(() {
      _score = 0;
      _combo = 0;
      _timeLeft = 60;
      _correctCount = 0;
      _totalAnswered = 0;
      _isPlaying = true;
      _isGameOver = false;
      _showFeedback = false;
      _lastAnswerCorrect = null;
      _mascotMessage = 'Does this Japanese word match the meaning?';
      _mascotMood = FoxMood.neutral;
    });

    _loadNextQuestion();

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _endGame();
        }
      });
    });
  }

  void _endGame() {
    _gameTimer?.cancel();
    setState(() {
      _isPlaying = false;
      _isGameOver = true;
      _mascotMessage = 'Yatta! Time is up! Superb practice! 🏆';
      _mascotMood = FoxMood.celebrate;
    });
    DatabaseService().saveGameScore('True or False', _score);
    AchievementService().checkAchievements(context: context);
  }

  void _loadNextQuestion() {
    final word = _vocabPool[_random.nextInt(_vocabPool.length)];
    final isTrue = _random.nextBool();
    String meaning;

    if (isTrue) {
      meaning = word.meaning.trim();
    } else {
      final otherWords = _vocabPool.where((v) => v.meaning.trim() != word.meaning.trim()).toList();
      if (otherWords.isEmpty) {
        meaning = word.meaning.trim();
      } else {
        meaning = otherWords[_random.nextInt(otherWords.length)].meaning.trim();
      }
    }

    setState(() {
      _currentWord = word;
      _displayMeaning = meaning;
      _isCorrectPair = meaning == word.meaning.trim();
      _showFeedback = false;
      _lastAnswerCorrect = null;
      _mascotMessage = 'Does this Japanese word match the meaning?';
      _mascotMood = FoxMood.neutral;
    });
  }

  Future<void> _onAnswer(bool userSaidTrue) async {
    if (!_isPlaying || _showFeedback) return;

    final isCorrect = userSaidTrue == _isCorrectPair;
    _totalAnswered++;

    if (isCorrect) {
      SpeechService().playCorrectAnswer();
      setState(() {
        _combo++;
        int points = 10;
        if (_combo >= 3) points = 15;
        if (_combo >= 5) points = 20;
        if (_combo >= 10) points = 30;
        _score += points;
        _correctCount++;
        _showFeedback = true;
        _lastAnswerCorrect = true;
        _mascotMessage = _combo >= 3
            ? 'Sugoi! 🔥 Combo x$_combo!'
            : 'Yatta! Spot on! 🎉';
        _mascotMood = FoxMood.happy;
      });
    } else {
      SpeechService().playWrongAnswer();
      setState(() {
        _combo = 0;
        _showFeedback = true;
        _lastAnswerCorrect = false;
        _mascotMessage = 'Oops! Not this one! 🦊 Keep going!';
        _mascotMood = FoxMood.encouraging;
      });
    }

    await Future.delayed(const Duration(milliseconds: 650));
    if (mounted && _isPlaying) {
      _loadNextQuestion();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: _vocabPool.isEmpty
            ? _buildEmptyState()
            : Column(
                children: [
                  _buildHeader(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: FoxMascotBubble(
                      message: _mascotMessage,
                      mood: _mascotMood,
                    ),
                  ),
                  Expanded(
                    child: _isGameOver ? _buildGameOver() : _buildGameBoard(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'Not enough vocabulary to play True or False.',
        style: GoogleFonts.outfit(fontSize: 16, color: AppColors.ink500),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          Row(
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
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(LucideIcons.arrowLeft, color: AppColors.ink700, size: 20),
                ),
              ),

              // Title Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.amberLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.amberBorder, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.checkCheck, size: 15, color: AppColors.amberDark),
                    const SizedBox(width: 6),
                    Text(
                      widget.lesson.id > 0
                          ? 'True or False • Lesson ${widget.lesson.id}'
                          : 'True or False • All Lessons',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.amberDark,
                      ),
                    ),
                  ],
                ),
              ),

              // Reset / Restart
              BouncingWidget(
                onTap: _startGame,
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

          const SizedBox(height: 12),

          // Stat Pills (Score, Combo, Time)
          Row(
            children: [
              Expanded(
                child: _buildHeaderStat(
                  label: 'Score',
                  value: '$_score',
                  color: AppColors.primary,
                  icon: LucideIcons.trophy,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildHeaderStat(
                  label: 'Combo',
                  value: 'x$_combo',
                  color: _combo >= 3 ? AppColors.amberDark : AppColors.ink500,
                  icon: LucideIcons.flame,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildHeaderStat(
                  label: 'Time',
                  value: '${_timeLeft}s',
                  color: _timeLeft <= 10 ? AppColors.primary : AppColors.azureDark,
                  icon: LucideIcons.clock,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.ink200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink400,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGameBoard() {
    if (_currentWord == null || _displayMeaning == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.ink200, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Japanese Kana with speak audio button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _currentWord!.kanaText,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                style: JapaneseFontService().getJapaneseTextStyle(
                                  fontSize: _currentWord!.kanaText.length > 7 ? 30 : 38,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.ink900,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          BouncingWidget(
                            onTap: () {
                              SpeechService().speakJapanese(_currentWord!.kanaText);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: AppColors.azureLight,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.azureBorder, width: 1),
                              ),
                              child: const Icon(
                                LucideIcons.volume2,
                                size: 16,
                                color: AppColors.azureDark,
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (_currentWord!.romaji.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          _currentWord!.romaji,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            color: AppColors.ink400,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],

                      const SizedBox(height: 22),

                      // Equal symbol or divider
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.ink100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.arrowDownUp,
                          size: 16,
                          color: AppColors.ink500,
                        ),
                      ),

                      const SizedBox(height: 22),

                      // Meaning Pill
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.ink200, width: 1.5),
                        ),
                        child: Text(
                          _displayMeaning!,
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: _displayMeaning!.length > 30
                                ? 15.0
                                : (_displayMeaning!.length > 18 ? 17.5 : 20.0),
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink900,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Tactile 3D Action Buttons (False / True)
          Row(
            children: [
              // FALSE (Crimson)
              Expanded(
                child: _buildDuolingoButton(
                  label: 'False',
                  icon: LucideIcons.x,
                  bgColor: const Color(0xFFE11D48),
                  topBorderColor: const Color(0xFFF43F5E),
                  bottomBorderColor: const Color(0xFF9F1239),
                  onTap: () => _onAnswer(false),
                  isFeedbackActive: _showFeedback && _lastAnswerCorrect != null,
                ),
              ),

              const SizedBox(width: 16),

              // TRUE (Bamboo Emerald)
              Expanded(
                child: _buildDuolingoButton(
                  label: 'True',
                  icon: LucideIcons.check,
                  bgColor: const Color(0xFF10B981),
                  topBorderColor: const Color(0xFF34D399),
                  bottomBorderColor: const Color(0xFF059669),
                  onTap: () => _onAnswer(true),
                  isFeedbackActive: _showFeedback && _lastAnswerCorrect != null,
                ),
              ),
            ],
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom + 12 : 20),
        ],
      ),
    );
  }

  Widget _buildDuolingoButton({
    required String label,
    required IconData icon,
    required Color bgColor,
    required Color topBorderColor,
    required Color bottomBorderColor,
    required VoidCallback onTap,
    required bool isFeedbackActive,
  }) {
    return BouncingWidget(
      scaleFactor: 0.94,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: topBorderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: bottomBorderColor,
              offset: const Offset(0, 4.5),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameOver() {
    final accuracy = _totalAnswered > 0
        ? ((_correctCount / _totalAnswered) * 100).round()
        : 0;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Fox Mascot Avatar Celebrating
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFDBA74), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEA580C).withOpacity(0.18),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/gif/Shiba Happy.gif',
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              "Time's Up!",
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppColors.ink900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Great speed session! Keep challenging yourself!",
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppColors.ink500,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 24),

            // Results Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.ink200, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildResultPill('Score', '$_score', AppColors.primary),
                  Container(width: 1, height: 40, color: AppColors.ink200),
                  _buildResultPill('Correct', '$_correctCount/$_totalAnswered', AppColors.bambooDark),
                  Container(width: 1, height: 40, color: AppColors.ink200),
                  _buildResultPill('Accuracy', '$accuracy%', AppColors.azureDark),
                ],
              ),
            ),

            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: BouncingWidget(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
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
                      child: Center(
                        child: Text(
                          'Exit',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 2,
                  child: BouncingWidget(
                    onTap: _startGame,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
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
                          const Icon(LucideIcons.rotateCcw, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Play Again',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultPill(String title, String val, Color col) {
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(fontSize: 12, color: AppColors.ink400, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          val,
          style: GoogleFonts.outfit(fontSize: 20, color: col, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
