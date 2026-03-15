import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/lesson.dart';
import '../services/database_service.dart';
import '../services/speech_service.dart';
import '../services/study_timer_service.dart';
import '../utils/vocabulary_display.dart';

class WordCatchScreen extends StatefulWidget {
  final Lesson lesson;

  const WordCatchScreen({Key? key, required this.lesson}) : super(key: key);

  @override
  State<WordCatchScreen> createState() => _WordCatchScreenState();
}

class _WordCatchScreenState extends State<WordCatchScreen> {
  static const int _totalRounds = 6;
  static const int _fallDurationMs = 3200;

  final math.Random _random = math.Random();

  List<_CatchOption> _options = [];
  Vocabulary? _targetWord;
  int _round = 0;
  int _score = 0;
  int _combo = 0;
  bool _dropStarted = false;
  bool _isRoundLocked = false;
  bool _isFinished = false;
  bool _scoreSaved = false;
  double _timeRemaining = 1.0;
  int? _revealedCorrectId;
  int? _selectedWrongId;
  String _feedbackText = 'Tap the matching kana before it falls.';
  Color _feedbackColor = const Color(0xFF6B7280);

  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    StudyTimerService().startTimer();
    _startRound(reset: true);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    StudyTimerService().stopTimer();
    super.dispose();
  }

  void _startRound({bool reset = false}) {
    final vocabulary = List<Vocabulary>.from(widget.lesson.vocabulary)..shuffle(_random);
    if (vocabulary.length < 4) {
      setState(() {
        _options = [];
        _targetWord = null;
      });
      return;
    }

    final nextRound = reset ? 1 : _round + 1;
    if (nextRound > _totalRounds) {
      _finishGame();
      return;
    }

    final selectedWords = vocabulary.take(4).toList();
    final correctIndex = _random.nextInt(selectedWords.length);
    final targetWord = selectedWords[correctIndex];

    _countdownTimer?.cancel();

    setState(() {
      _round = nextRound;
      _targetWord = targetWord;
      _options = [
        for (int index = 0; index < selectedWords.length; index++)
          _CatchOption(
            id: index,
            text: selectedWords[index].kanaText,
            isCorrect: index == correctIndex,
            lane: index % 2,
            wave: index ~/ 2,
          ),
      ]..shuffle(_random);
      _dropStarted = false;
      _isRoundLocked = false;
      _isFinished = false;
      _timeRemaining = 1.0;
      _revealedCorrectId = null;
      _selectedWrongId = null;
      _feedbackText = 'Tap the matching kana before it falls.';
      _feedbackColor = const Color(0xFF6B7280);
      if (reset) {
        _score = 0;
        _combo = 0;
        _scoreSaved = false;
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _dropStarted = true;
      });
      _startCountdown();
    });
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    final startedAt = DateTime.now();
    _countdownTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted || _isRoundLocked || _isFinished) {
        timer.cancel();
        return;
      }

      final elapsed = DateTime.now().difference(startedAt).inMilliseconds;
      final remaining = 1.0 - (elapsed / _fallDurationMs);

      if (remaining <= 0) {
        timer.cancel();
        _handleTimeout();
        return;
      }

      setState(() {
        _timeRemaining = remaining.clamp(0.0, 1.0);
      });
    });
  }

  Future<void> _handleOptionTap(_CatchOption option) async {
    if (_isRoundLocked || _isFinished) {
      return;
    }

    _countdownTimer?.cancel();

    setState(() {
      _isRoundLocked = true;
      _revealedCorrectId = _options.firstWhere((entry) => entry.isCorrect).id;
      if (option.isCorrect) {
        _score += 1;
        _combo += 1;
        _feedbackText = 'Nice catch!';
        _feedbackColor = const Color(0xFF047857);
        SpeechService().playCorrectAnswer();
      } else {
        _combo = 0;
        _selectedWrongId = option.id;
        _feedbackText = 'Wrong pick. Watch the green answer.';
        _feedbackColor = const Color(0xFFB91C1C);
        SpeechService().playWrongAnswer();
      }
    });

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) {
      return;
    }

    _startRound();
  }

  Future<void> _handleTimeout() async {
    if (_isRoundLocked || _isFinished) {
      return;
    }

    setState(() {
      _isRoundLocked = true;
      _combo = 0;
      _revealedCorrectId = _options.firstWhere((entry) => entry.isCorrect).id;
      _feedbackText = 'Time up. The green card was correct.';
      _feedbackColor = const Color(0xFFB45309);
      _timeRemaining = 0;
    });
    SpeechService().playWrongAnswer();

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) {
      return;
    }

    _startRound();
  }

  Future<void> _finishGame() async {
    _countdownTimer?.cancel();
    setState(() {
      _isFinished = true;
      _feedbackText = 'Round complete';
      _feedbackColor = const Color(0xFF6B7280);
    });
    await _saveScoreIfNeeded();
  }

  Future<void> _saveScoreIfNeeded() async {
    if (_scoreSaved) {
      return;
    }

    _scoreSaved = true;
    final score = ((_score / _totalRounds) * 100).round();
    await DatabaseService().saveGameScore('Word Catch', score);
  }

  @override
  Widget build(BuildContext context) {
    final hasEnoughWords = _targetWord != null && _options.isNotEmpty;

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
                          'Word Catch',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFB923C), Color(0xFFF97316)],
                        ),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isFinished ? 'Final Score' : 'Round $_round of $_totalRounds',
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _isFinished ? 'You caught $_score / $_totalRounds words.' : 'Catch the kana for:',
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.92),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isFinished ? '${((_score / _totalRounds) * 100).round()}%' : _targetWord!.meaning,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        _buildBadge('Score', '$_score'),
                        const SizedBox(width: 12),
                        _buildBadge('Combo', 'x$_combo'),
                        const SizedBox(width: 12),
                        _buildBadge('Timer', '${(_timeRemaining * 100).round()}%'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: _timeRemaining,
                        minHeight: 10,
                        backgroundColor: const Color(0xFFE5E7EB),
                        color: _timeRemaining > 0.35 ? const Color(0xFFF97316) : const Color(0xFFEF4444),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _feedbackText,
                      style: GoogleFonts.inter(
                        color: _feedbackColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: _isFinished
                          ? Center(
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => _startRound(reset: true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF97316),
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                  child: Text(
                                    'Play Again',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : LayoutBuilder(
                              builder: (context, constraints) {
                                final laneWidth = (constraints.maxWidth - 52) / 2;
                                final targetTop = math.max(140.0, constraints.maxHeight - 120);
                                return Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(28),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: Row(
                                          children: [
                                            Expanded(child: Container()),
                                            Container(width: 1, color: const Color(0xFFF3F4F6)),
                                            Expanded(child: Container()),
                                          ],
                                        ),
                                      ),
                                      Positioned(
                                        left: 18,
                                        right: 18,
                                        bottom: 30,
                                        child: Container(
                                          height: 14,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFDE68A),
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            'CATCH ZONE',
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF92400E),
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ),
                                      ),
                                      for (final option in _options)
                                        AnimatedPositioned(
                                          key: ValueKey('$_round-${option.id}-${option.text}'),
                                          duration: const Duration(milliseconds: _fallDurationMs),
                                          curve: Curves.linear,
                                          top: _dropStarted ? targetTop - (option.wave * 72) : -120 - (option.wave * 150),
                                          left: option.lane == 0 ? 18 : laneWidth + 34,
                                          child: GestureDetector(
                                            onTap: () => _handleOptionTap(option),
                                            child: _buildCatchCard(option, laneWidth),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                )
              : Center(
                  child: Text(
                    'Not enough vocabulary to start Word Catch.',
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

  Widget _buildCatchCard(_CatchOption option, double laneWidth) {
    Color backgroundColor = Colors.white;
    Color borderColor = const Color(0xFFE5E7EB);
    Color textColor = const Color(0xFF1F2937);

    if (_revealedCorrectId == option.id) {
      backgroundColor = const Color(0xFFECFDF5);
      borderColor = const Color(0xFF10B981);
      textColor = const Color(0xFF047857);
    } else if (_selectedWrongId == option.id) {
      backgroundColor = const Color(0xFFFEF2F2);
      borderColor = const Color(0xFFEF4444);
      textColor = const Color(0xFFB91C1C);
    }

    return IgnorePointer(
      ignoring: _isRoundLocked,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: laneWidth,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          option.text,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                color: const Color(0xFF6B7280),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.inter(
                color: const Color(0xFF1F2937),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatchOption {
  final int id;
  final String text;
  final bool isCorrect;
  final int lane;
  final int wave;

  const _CatchOption({
    required this.id,
    required this.text,
    required this.isCorrect,
    required this.lane,
    required this.wave,
  });
}
