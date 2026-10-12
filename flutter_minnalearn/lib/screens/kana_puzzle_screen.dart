import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/lesson.dart';
import '../services/audio_service.dart';
import '../services/speech_service.dart';
import '../services/database_service.dart';
import '../services/study_timer_service.dart';
import '../services/achievement_service.dart';
import '../utils/vocabulary_display.dart';
import '../utils/app_theme.dart';
import '../widgets/bouncing_widget.dart';
import '../widgets/fox_mascot_bubble.dart';
import '../services/japanese_font_service.dart';

class KanaPuzzleScreen extends StatefulWidget {
  final Lesson lesson;

  const KanaPuzzleScreen({Key? key, required this.lesson}) : super(key: key);

  @override
  State<KanaPuzzleScreen> createState() => _KanaPuzzleScreenState();
}

class _KanaPuzzleScreenState extends State<KanaPuzzleScreen> {
  final _random = Random();
  late List<Vocabulary> _vocabPool;

  Vocabulary? _currentVocab;
  List<String> _targetCharacters = [];
  List<String> _availableTiles = [];
  List<String> _selectedTiles = [];

  int _score = 0;
  int _combo = 0;
  int _timeLeft = 60;
  Timer? _gameTimer;
  bool _isPlaying = false;
  bool _isGameOver = false;

  String _mascotMessage = 'Tap or drag the tiles to spell the Japanese word!';
  FoxMood _mascotMood = FoxMood.neutral;

  @override
  void initState() {
    super.initState();
    StudyTimerService().startTimer();
    DatabaseService().updateStreak();
    _vocabPool = List.from(widget.lesson.vocabulary)
      ..removeWhere((v) => v.romaji.isEmpty);

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
      _isPlaying = true;
      _isGameOver = false;
      _mascotMessage = 'Tap or drag the tiles to spell the Japanese word!';
      _mascotMood = FoxMood.neutral;
    });

    _loadNextWord();

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
      _mascotMessage = 'Yatta! Fantastic puzzle session! 🏆';
      _mascotMood = FoxMood.celebrate;
    });

    DatabaseService().saveGameScore('Kana Puzzle', _score);
    if (_score > 0) {
      AchievementService().checkAchievements(context: context);
    }
  }

  void _loadNextWord() {
    setState(() {
      _currentVocab = _vocabPool[_random.nextInt(_vocabPool.length)];
      _targetCharacters = _currentVocab!.romaji.characters.toList();
      _availableTiles = List.from(_targetCharacters)..shuffle(_random);
      _selectedTiles = [];
      _mascotMessage = 'Build the kana for: "${_currentVocab!.meaning}"';
      _mascotMood = FoxMood.neutral;
    });
  }

  void _onTileSelected(String tile, int index) {
    if (!_isPlaying || index >= _availableTiles.length) return;

    setState(() {
      _availableTiles.removeAt(index);
      _selectedTiles.add(tile);
    });

    if (_selectedTiles.length == _targetCharacters.length) {
      _validateSelection();
    }
  }

  void _onTileDeselected(String tile, int index) {
    if (!_isPlaying || index >= _selectedTiles.length) return;

    setState(() {
      _selectedTiles.removeAt(index);
      _availableTiles.add(tile);
    });
  }

  Future<void> _validateSelection() async {
    final builtWord = _selectedTiles.join();
    final isCorrect = builtWord == _currentVocab!.romaji;

    if (isCorrect) {
      AudioService().playCorrect();
      setState(() {
        _combo++;
        int points = 10;
        if (_combo >= 3) points *= 2;
        if (_combo >= 6) points *= 3;
        _score += points;
        _mascotMessage = _combo >= 3
            ? 'Sugoi! 🔥 Combo x$_combo!'
            : 'Yatta! Perfect spelling! 🎉';
        _mascotMood = FoxMood.happy;
      });
      await Future.delayed(const Duration(milliseconds: 350));
      if (mounted && _isPlaying) {
        _loadNextWord();
      }
    } else {
      AudioService().playWrong();
      setState(() {
        _combo = 0;
        _mascotMessage = 'Not quite! Rearrange the tiles! 🦊';
        _mascotMood = FoxMood.encouraging;
      });
      await Future.delayed(const Duration(milliseconds: 450));
      if (mounted && _isPlaying) {
        setState(() {
          _availableTiles.addAll(_selectedTiles);
          _availableTiles.shuffle(_random);
          _selectedTiles.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_vocabPool.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.scaffold,
        body: Center(
          child: Text(
            'Not enough vocabulary to play Kana Puzzle.',
            style: GoogleFonts.outfit(color: AppColors.ink500, fontSize: 16),
          ),
        ),
      );
    }

    return ValueListenableBuilder<String>(
      valueListenable: JapaneseFontService.currentFontNotifier,
      builder: (context, fontKey, _) {
        return Scaffold(
          backgroundColor: AppColors.scaffold,
          body: SafeArea(
            child: Column(
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
      },
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
                  ),
                  child: const Icon(LucideIcons.arrowLeft, color: AppColors.ink700, size: 20),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.azureLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.azureBorder, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.puzzle, size: 15, color: AppColors.azureDark),
                    const SizedBox(width: 6),
                    Text(
                      widget.lesson.id > 0
                          ? 'Kana Puzzle • Lesson ${widget.lesson.id}'
                          : 'Kana Puzzle • All Lessons',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.azureDark,
                      ),
                    ),
                  ],
                ),
              ),
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
    if (_currentVocab == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          // Target Word Meaning Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
                      'Target Meaning',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    BouncingWidget(
                      onTap: () {
                        SpeechService().speakJapanese(_currentVocab!.kanaText);
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
                const SizedBox(height: 10),
                Text(
                  _currentVocab!.meaning,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: _currentVocab!.meaning.length > 28
                        ? 18.0
                        : (_currentVocab!.meaning.length > 16 ? 21.0 : 25.0),
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink900,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Selected Slots Area (Tap or Drop)
          Text(
            'Built Word (Tap to remove)',
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.ink500,
            ),
          ),
          const SizedBox(height: 10),

          DragTarget<String>(
            builder: (context, candidateData, rejectedData) {
              return Container(
                constraints: const BoxConstraints(minHeight: 74),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: candidateData.isNotEmpty ? AppColors.primary : AppColors.ink200,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...List.generate(_selectedTiles.length, (index) {
                      return _buildSelectedTile(_selectedTiles[index], index);
                    }),
                    ...List.generate(
                      max(0, _targetCharacters.length - _selectedTiles.length),
                      (index) => _buildEmptySlot(),
                    ),
                  ],
                ),
              );
            },
            onWillAcceptWithDetails: (details) => _isPlaying,
            onAcceptWithDetails: (details) {
              final data = details.data;
              final index = _availableTiles.indexOf(data);
              if (index != -1) {
                _onTileSelected(data, index);
              }
            },
          ),

          const SizedBox(height: 28),

          // Available Tiles Area (Tap or Drag)
          Text(
            'Available Kana Tiles (Tap or Drag)',
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.ink500,
            ),
          ),
          const SizedBox(height: 14),

          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: List.generate(_availableTiles.length, (index) {
              return _buildTactileTile(_availableTiles[index], index);
            }),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTactileTile(String char, int index) {
    return Draggable<String>(
      data: char,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: AppColors.azureLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.azure, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.azure.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              char,
              style: JapaneseFontService().getJapaneseTextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.azureDark,
              ),
            ),
          ),
        ),
      ),
      childWhenDragging: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: AppColors.ink100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.ink200, width: 1.5),
        ),
        child: Center(
          child: Text(
            char,
            style: JapaneseFontService().getJapaneseTextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.ink200,
            ),
          ),
        ),
      ),
      child: BouncingWidget(
        scaleFactor: 0.92,
        onTap: () => _onTileSelected(char, index),
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            border: Border.all(color: AppColors.ink200, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFFCBD5E1),
                offset: Offset(0, 3.5),
                blurRadius: 0,
              ),
            ],
          ),
          child: Center(
            child: Text(
              char,
              style: JapaneseFontService().getJapaneseTextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.ink900,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedTile(String char, int index) {
    return BouncingWidget(
      scaleFactor: 0.92,
      onTap: () => _onTileDeselected(char, index),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          border: Border.all(color: const Color(0xFF93C5FD), width: 2),
          boxShadow: const [
            BoxShadow(
              color: AppColors.azure,
              offset: Offset(0, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: Text(
            char,
            style: JapaneseFontService().getJapaneseTextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.azureDark,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySlot() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.ink100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.ink200, width: 1.5),
      ),
    );
  }

  Widget _buildGameOver() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
            const SizedBox(height: 8),
            Text(
              'Final Score: $_score points',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 36),
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
                        borderRadius: const BorderRadius.all(Radius.circular(20)),
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
}
