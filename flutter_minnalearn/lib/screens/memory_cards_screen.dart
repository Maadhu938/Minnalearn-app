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

class MemoryCardsScreen extends StatefulWidget {
  final Lesson lesson;

  const MemoryCardsScreen({Key? key, required this.lesson}) : super(key: key);

  @override
  State<MemoryCardsScreen> createState() => _MemoryCardsScreenState();
}

class _MemoryCardsScreenState extends State<MemoryCardsScreen> {
  final math.Random _random = math.Random();

  List<_MemoryCard> _cards = [];
  List<int> _openedIndexes = [];
  Set<int> _matchedPairIds = <int>{};
  int _turns = 0;
  bool _isChecking = false;
  bool _scoreSaved = false;

  @override
  void initState() {
    super.initState();
    StudyTimerService().startTimer();
    _setupGame();
  }

  @override
  void dispose() {
    StudyTimerService().stopTimer();
    super.dispose();
  }

  void _setupGame() {
    final vocabulary = List<Vocabulary>.from(widget.lesson.vocabulary)..shuffle(_random);
    final pairCount = math.min(6, vocabulary.length);
    final selectedWords = vocabulary.take(pairCount).toList();

    final cards = <_MemoryCard>[];
    for (int index = 0; index < selectedWords.length; index++) {
      final word = selectedWords[index];
      cards.add(_MemoryCard(pairId: index, text: word.kanaText, isJapanese: true));
      cards.add(_MemoryCard(pairId: index, text: word.meaning, isJapanese: false));
    }

    cards.shuffle(_random);

    setState(() {
      _cards = cards;
      _openedIndexes = [];
      _matchedPairIds = <int>{};
      _turns = 0;
      _isChecking = false;
      _scoreSaved = false;
    });
  }

  Future<void> _onCardTap(int index) async {
    if (_isChecking || _openedIndexes.contains(index)) {
      return;
    }

    final card = _cards[index];
    if (_matchedPairIds.contains(card.pairId)) {
      return;
    }

    setState(() {
      _cards[index] = card.copyWith(isFaceUp: true);
      _openedIndexes = [..._openedIndexes, index];
    });

    if (_openedIndexes.length < 2) {
      return;
    }

    _turns += 1;
    final firstIndex = _openedIndexes[0];
    final secondIndex = _openedIndexes[1];
    final firstCard = _cards[firstIndex];
    final secondCard = _cards[secondIndex];

    if (firstCard.pairId == secondCard.pairId && firstCard.isJapanese != secondCard.isJapanese) {
      SpeechService().playCorrectAnswer();
      setState(() {
        _matchedPairIds = {..._matchedPairIds, firstCard.pairId};
        _openedIndexes = [];
      });

      if (_matchedPairIds.length == _cards.length ~/ 2) {
        AudioService().playLevelComplete();
        await _saveScoreIfNeeded();
      }
      return;
    }

    setState(() {
      _isChecking = true;
    });
    SpeechService().playWrongAnswer();

    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) {
      return;
    }

    setState(() {
      _cards[firstIndex] = _cards[firstIndex].copyWith(isFaceUp: false);
      _cards[secondIndex] = _cards[secondIndex].copyWith(isFaceUp: false);
      _openedIndexes = [];
      _isChecking = false;
    });
  }

  Future<void> _saveScoreIfNeeded() async {
    if (_scoreSaved) {
      return;
    }

    _scoreSaved = true;
    final pairCount = _cards.length ~/ 2;
    final score = math.max(10, 100 - math.max(0, _turns - pairCount) * 10);
    await DatabaseService().saveGameScore('Memory Cards', score);
  }

  @override
  Widget build(BuildContext context) {
    final notEnoughWords = widget.lesson.vocabulary.length < 3;
    final completed = _matchedPairIds.length == _cards.length ~/ 2 && _cards.isNotEmpty;

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
                    'Memory Cards',
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
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoBlock('Turns', '$_turns'),
                    _buildInfoBlock('Pairs', '${_matchedPairIds.length}/${_cards.length ~/ 2}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                notEnoughWords
                    ? 'Add more vocabulary to this lesson to play this game.'
                    : 'Flip cards and match Japanese with the correct meaning.',
                style: GoogleFonts.inter(
                  color: const Color(0xFF6B7280),
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: notEnoughWords
                    ? Center(
                        child: Text(
                          'Not enough words for Memory Cards.',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF6B7280),
                            fontSize: 15,
                          ),
                        ),
                      )
                    : GridView.builder(
                        itemCount: _cards.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.0,
                        ),
                        itemBuilder: (context, index) {
                          final card = _cards[index];
                          final isMatched = _matchedPairIds.contains(card.pairId);
                          return GestureDetector(
                            onTap: () => _onCardTap(index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              decoration: BoxDecoration(
                                color: card.isFaceUp || isMatched ? Colors.white : const Color(0xFFEC4899),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: isMatched
                                      ? const Color(0xFF10B981)
                                      : card.isFaceUp
                                          ? const Color(0xFFEC4899)
                                          : Colors.transparent,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 12,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Text(
                                    card.isFaceUp || isMatched ? card.text : '?',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: card.isJapanese ? 24 : 16,
                                      fontWeight: FontWeight.w700,
                                      color: card.isFaceUp || isMatched
                                          ? const Color(0xFF1F2937)
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
            if (completed)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _setupGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Text(
                      'Play Again',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              )
            else
              const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBlock(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
    );
  }
}

class _MemoryCard {
  final int pairId;
  final String text;
  final bool isJapanese;
  final bool isFaceUp;

  const _MemoryCard({
    required this.pairId,
    required this.text,
    required this.isJapanese,
    this.isFaceUp = false,
  });

  _MemoryCard copyWith({
    int? pairId,
    String? text,
    bool? isJapanese,
    bool? isFaceUp,
  }) {
    return _MemoryCard(
      pairId: pairId ?? this.pairId,
      text: text ?? this.text,
      isJapanese: isJapanese ?? this.isJapanese,
      isFaceUp: isFaceUp ?? this.isFaceUp,
    );
  }
}
