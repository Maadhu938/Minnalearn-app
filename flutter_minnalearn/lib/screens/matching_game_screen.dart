import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/lesson.dart';
import '../services/database_service.dart';
import '../services/speech_service.dart';
import '../services/audio_service.dart';
import '../services/study_timer_service.dart';
import '../utils/vocabulary_display.dart';

class MatchingGameScreen extends StatefulWidget {
  final Lesson lesson;

  const MatchingGameScreen({Key? key, required this.lesson}) : super(key: key);

  @override
  State<MatchingGameScreen> createState() => _MatchingGameScreenState();
}

class _MatchingGameScreenState extends State<MatchingGameScreen> {
  final Random _random = Random();

  late List<Vocabulary> _gameWords;
  late List<_MatchOption> _kanaOptions;
  late List<_MatchOption> _meaningOptions;

  int? _selectedKanaId;
  int? _selectedMeaningId;
  Set<int> _matchedIds = <int>{};
  int? _correctKanaId;
  int? _correctMeaningId;
  int? _wrongKanaId;
  int? _wrongMeaningId;

  bool _isChecking = false;
  bool _isGameOver = false;
  bool _scoreSaved = false;
  int _attempts = 0;

  @override
  void initState() {
    super.initState();
    StudyTimerService().startTimer();
    _initGame();
  }

  @override
  void dispose() {
    StudyTimerService().stopTimer();
    super.dispose();
  }

  void _initGame() {
    final vocabulary = List<Vocabulary>.from(widget.lesson.vocabulary)..shuffle(_random);
    _gameWords = vocabulary.take(min(5, vocabulary.length)).toList();

    _kanaOptions = [
      for (int index = 0; index < _gameWords.length; index++)
        _MatchOption(id: index, text: _gameWords[index].kanaText),
    ]..shuffle(_random);

    _meaningOptions = [
      for (int index = 0; index < _gameWords.length; index++)
        _MatchOption(id: index, text: _gameWords[index].meaning),
    ]..shuffle(_random);

    _selectedKanaId = null;
    _selectedMeaningId = null;
    _matchedIds = <int>{};
    _correctKanaId = null;
    _correctMeaningId = null;
    _wrongKanaId = null;
    _wrongMeaningId = null;
    _isChecking = false;
    _isGameOver = false;
    _scoreSaved = false;
    _attempts = 0;
  }

  void _onKanaTap(int id) {
    if (_matchedIds.contains(id) || _isGameOver || _isChecking) {
      return;
    }

    setState(() {
      _selectedKanaId = _selectedKanaId == id ? null : id;
    });

    _checkMatchIfReady();
  }

  void _onMeaningTap(int id) {
    if (_matchedIds.contains(id) || _isGameOver || _isChecking) {
      return;
    }

    setState(() {
      _selectedMeaningId = _selectedMeaningId == id ? null : id;
    });

    _checkMatchIfReady();
  }

  Future<void> _checkMatchIfReady() async {
    if (_selectedKanaId == null || _selectedMeaningId == null) {
      return;
    }

    final kanaId = _selectedKanaId!;
    final meaningId = _selectedMeaningId!;
    _attempts += 1;

    if (kanaId == meaningId) {
      SpeechService().playCorrectAnswer();
      setState(() {
        _isChecking = true;
        _correctKanaId = kanaId;
        _correctMeaningId = meaningId;
      });

      await Future.delayed(const Duration(milliseconds: 380));
      if (!mounted) {
        return;
      }

      setState(() {
        _matchedIds = {..._matchedIds, kanaId};
        _correctKanaId = null;
        _correctMeaningId = null;
        _selectedKanaId = null;
        _selectedMeaningId = null;
        _isChecking = false;
        _isGameOver = _matchedIds.length == _gameWords.length;
      });

      if (_isGameOver) {
        AudioService().playLevelComplete();
        await _saveScoreIfNeeded();
      }
      return;
    }

    setState(() {
      _isChecking = true;
      _wrongKanaId = kanaId;
      _wrongMeaningId = meaningId;
    });
    SpeechService().playWrongAnswer();

    await Future.delayed(const Duration(milliseconds: 550));
    if (!mounted) {
      return;
    }

    setState(() {
      _wrongKanaId = null;
      _wrongMeaningId = null;
      _selectedKanaId = null;
      _selectedMeaningId = null;
      _isChecking = false;
    });
  }

  Future<void> _saveScoreIfNeeded() async {
    if (_scoreSaved) {
      return;
    }

    _scoreSaved = true;
    final penalty = max(0, _attempts - _gameWords.length) * 10;
    final score = max(20, 100 - penalty);
    await DatabaseService().saveGameScore('Match Game', score);
  }

  @override
  Widget build(BuildContext context) {
    if (_gameWords.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: Center(
          child: Text(
            'Not enough vocabulary to play Match Game.',
            style: GoogleFonts.inter(
              color: const Color(0xFF6B7280),
              fontSize: 15,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(LucideIcons.arrowLeft, color: Color(0xFF4B5563)),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Matching Game',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Text(
                    'Match the kana with the correct meaning.',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF6B7280),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildStatCard('Pairs', '${_matchedIds.length}/${_gameWords.length}')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard('Attempts', '$_attempts')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          _buildColumnLabel('Kana'),
                          const SizedBox(height: 12),
                          Expanded(
                            child: Column(
                              children: _kanaOptions.map((option) => _buildItem(option, true)).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        children: [
                          _buildColumnLabel('Meaning'),
                          const SizedBox(height: 12),
                          Expanded(
                            child: Column(
                              children: _meaningOptions.map((option) => _buildItem(option, false)).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isGameOver)
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(_initGame);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Text(
                      'Play Again',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              )
            else
              const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildColumnLabel(String label) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF6B7280),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(_MatchOption option, bool isKanaColumn) {
    final isMatched = _matchedIds.contains(option.id);
    final isCorrect = isKanaColumn ? _correctKanaId == option.id : _correctMeaningId == option.id;
    final isWrong = isKanaColumn ? _wrongKanaId == option.id : _wrongMeaningId == option.id;
    final isSelected = isKanaColumn ? _selectedKanaId == option.id : _selectedMeaningId == option.id;

    Color backgroundColor = Colors.white;
    Color borderColor = Colors.grey.shade200;
    Color textColor = const Color(0xFF374151);

    if (isMatched || isCorrect) {
      backgroundColor = const Color(0xFFECFDF5);
      borderColor = const Color(0xFF10B981);
      textColor = const Color(0xFF047857);
    } else if (isWrong) {
      backgroundColor = const Color(0xFFFEF2F2);
      borderColor = const Color(0xFFEF4444);
      textColor = const Color(0xFFB91C1C);
    } else if (isSelected) {
      backgroundColor = const Color(0xFFEFF6FF);
      borderColor = const Color(0xFF3B82F6);
      textColor = const Color(0xFF1D4ED8);
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GestureDetector(
          onTap: () => isKanaColumn ? _onKanaTap(option.id) : _onMeaningTap(option.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor, width: 2),
              boxShadow: [
                if (!isMatched)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Center(
              child: Text(
                option.text,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: isKanaColumn ? 20 : 15,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MatchOption {
  final int id;
  final String text;

  const _MatchOption({
    required this.id,
    required this.text,
  });
}
