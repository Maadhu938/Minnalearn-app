import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/lesson.dart';
import '../services/database_service.dart';
import '../services/speech_service.dart';
import '../services/study_timer_service.dart';
import '../utils/vocabulary_display.dart';

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

  @override
  void initState() {
    super.initState();
    StudyTimerService().startTimer();
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
    });
    DatabaseService().saveGameScore('True or False', _score);
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
      });
    } else {
      SpeechService().playWrongAnswer();
      setState(() {
        _combo = 0;
        _showFeedback = true;
        _lastAnswerCorrect = false;
      });
    }

    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted && _isPlaying) {
      _loadNextQuestion();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: _vocabPool.isEmpty
            ? _buildEmptyState()
            : Column(
                children: [
                  _buildHeader(),
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
        style: GoogleFonts.inter(color: const Color(0xFF6B7280), fontSize: 15),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(LucideIcons.arrowLeft, color: Color(0xFF4B5563)),
              ),
              const SizedBox(width: 16),
              Text(
                'True or False',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStat('Score', '$_score', const Color(0xFFEC4899))),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStat(
                  'Combo',
                  'x$_combo',
                  _combo >= 3 ? const Color(0xFFEAB308) : const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStat(
                  'Time',
                  '${_timeLeft}s',
                  _timeLeft <= 10 ? const Color(0xFFEF4444) : const Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(),
          Text(
            'Does this kana match this meaning?',
            style: GoogleFonts.inter(
              color: const Color(0xFF6B7280),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  _currentWord!.kanaText,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansJp(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                if (_currentWord!.romaji.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _currentWord!.romaji,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: const Color(0xFF9CA3AF),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _displayMeaning!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF374151),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(
                child: _buildAnswerButton(
                  label: 'True',
                  icon: LucideIcons.check,
                  baseColor: const Color(0xFF10B981),
                  onTap: () => _onAnswer(true),
                  feedbackColor: _showFeedback
                      ? (_isCorrectPair ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAnswerButton(
                  label: 'False',
                  icon: LucideIcons.x,
                  baseColor: const Color(0xFFEF4444),
                  onTap: () => _onAnswer(false),
                  feedbackColor: _showFeedback
                      ? (!_isCorrectPair ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                      : null,
                ),
              ),
            ],
          ),
          if (_showFeedback && _lastAnswerCorrect != null) ...[
            const SizedBox(height: 16),
            Text(
              _lastAnswerCorrect! ? 'Correct!' : 'Wrong!',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _lastAnswerCorrect!
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
              ),
            ),
          ],
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildAnswerButton({
    required String label,
    required IconData icon,
    required Color baseColor,
    required VoidCallback onTap,
    Color? feedbackColor,
  }) {
    final color = feedbackColor ?? baseColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
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
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFEC4899),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.trophy, size: 64, color: Colors.white),
            ),
            const SizedBox(height: 32),
            Text(
              "Time's Up!",
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text(
                      '$_correctCount / $_totalAnswered',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                    Text(
                      'Correct',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 40),
                Column(
                  children: [
                    Text(
                      '$accuracy%',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                    Text(
                      'Accuracy',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Score: $_score',
              style: GoogleFonts.inter(
                fontSize: 18,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEC4899),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Play Again',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Back to Menu',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
