import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/lesson.dart';
import '../services/database_service.dart';
import '../services/speech_service.dart';
import '../services/audio_service.dart';
import '../services/study_timer_service.dart';
import '../services/achievement_service.dart';
import '../utils/vocabulary_display.dart';
import '../utils/app_theme.dart';
import '../widgets/bouncing_widget.dart';
import '../widgets/fox_mascot_bubble.dart';
import '../services/japanese_font_service.dart';

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

  String _mascotMessage = 'Match each Japanese word with its meaning!';
  FoxMood _mascotMood = FoxMood.neutral;

  @override
  void initState() {
    super.initState();
    StudyTimerService().startTimer();
    DatabaseService().updateStreak();
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
        _MatchOption(
          id: index,
          text: _gameWords[index].kanaText,
          kanji: _gameWords[index].kanjiText,
        ),
    ]..shuffle(_random);

    _meaningOptions = [
      for (int index = 0; index < _gameWords.length; index++)
        _MatchOption(
          id: index,
          text: _gameWords[index].meaning,
        ),
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
    _mascotMessage = 'Match each Japanese word with its meaning!';
    _mascotMood = FoxMood.neutral;
  }

  void _onKanaTap(int id) {
    if (_matchedIds.contains(id) || _isGameOver || _isChecking) {
      return;
    }

    setState(() {
      _selectedKanaId = _selectedKanaId == id ? null : id;
      if (_selectedKanaId != null) {
        if (_selectedMeaningId == null) {
          _mascotMessage = 'Great! Now tap its English meaning! 🎯';
          _mascotMood = FoxMood.thinking;
        }
      } else if (_selectedMeaningId == null) {
        _mascotMessage = 'Tap any card to start matching!';
        _mascotMood = FoxMood.neutral;
      }
    });

    _checkMatchIfReady();
  }

  void _onMeaningTap(int id) {
    if (_matchedIds.contains(id) || _isGameOver || _isChecking) {
      return;
    }

    setState(() {
      _selectedMeaningId = _selectedMeaningId == id ? null : id;
      if (_selectedMeaningId != null) {
        if (_selectedKanaId == null) {
          _mascotMessage = 'Nice! Now find its Japanese word! 🎌';
          _mascotMood = FoxMood.thinking;
        }
      } else if (_selectedKanaId == null) {
        _mascotMessage = 'Tap any card to start matching!';
        _mascotMood = FoxMood.neutral;
      }
    });

    _checkMatchIfReady();
  }

  Future<void> _checkMatchIfReady() async {
    if (_selectedKanaId == null || _selectedMeaningId == null) {
      return;
    }

    // Set checking guard immediately before async work
    _isChecking = true;
    final kanaId = _selectedKanaId!;
    final meaningId = _selectedMeaningId!;
    _attempts += 1;

    if (kanaId == meaningId) {
      SpeechService().playCorrectAnswer();
      setState(() {
        _correctKanaId = kanaId;
        _correctMeaningId = meaningId;
        _mascotMessage = _getRandomCorrectCheer();
        _mascotMood = FoxMood.happy;
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

        if (_isGameOver) {
          _mascotMessage = 'Yatta! All ${_gameWords.length} pairs matched! 🏆';
          _mascotMood = FoxMood.celebrate;
        } else {
          _mascotMessage = '${_matchedIds.length}/${_gameWords.length} pairs! Keep going! 🦊';
          _mascotMood = FoxMood.neutral;
        }
      });

      if (_isGameOver) {
        AudioService().playLevelComplete();
        await _saveScoreIfNeeded();
      }
      return;
    }

    setState(() {
      _wrongKanaId = kanaId;
      _wrongMeaningId = meaningId;
      _mascotMessage = 'Not quite a pair! Try another one! 💭';
      _mascotMood = FoxMood.encouraging;
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

  String _getRandomCorrectCheer() {
    final cheers = [
      'Sugoi! Perfect match! 🎉',
      'Yatta! Spot on! ✨',
      'Subarashii! Great job! 🌟',
      'Bingo! Exactly right! 🔥',
    ];
    return cheers[_random.nextInt(cheers.length)];
  }

  Future<void> _saveScoreIfNeeded() async {
    if (_scoreSaved) {
      return;
    }

    _scoreSaved = true;
    final penalty = max(0, _attempts - _gameWords.length) * 10;
    final score = max(20, 100 - penalty);
    await DatabaseService().saveGameScore('Match Game', score);
    if (mounted) {
      AchievementService().checkAchievements(context: context);
    }
  }

  int _calculateStars() {
    final extra = _attempts - _gameWords.length;
    if (extra <= 1) return 3;
    if (extra <= 3) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    if (_gameWords.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.scaffold,
        body: Center(
          child: Text(
            'Not enough vocabulary to play Match Game.',
            style: GoogleFonts.outfit(
              color: AppColors.ink500,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
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
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        LucideIcons.arrowLeft,
                        color: AppColors.ink700,
                        size: 20,
                      ),
                    ),
                  ),

                  // Header Badge
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
                        const Icon(LucideIcons.shuffle, size: 15, color: AppColors.azureDark),
                        const SizedBox(width: 6),
                        Text(
                          widget.lesson.id > 0
                              ? 'Matching Game • Lesson ${widget.lesson.id}'
                              : 'Matching Game • All Lessons',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.azureDark,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Reset Button
                  BouncingWidget(
                    onTap: () {
                      setState(_initGame);
                    },
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
                      child: const Icon(
                        LucideIcons.rotateCcw,
                        color: AppColors.ink500,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Fox Mascot Prompt Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: FoxMascotBubble(
                message: _mascotMessage,
                mood: _mascotMood,
              ),
            ),

            const SizedBox(height: 10),

            // Progress & Stats Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
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
                    // Pairs progress pill
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Pairs Matched',
                                style: GoogleFonts.outfit(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink500,
                                ),
                              ),
                              Text(
                                '${_matchedIds.length} / ${_gameWords.length}',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.azureDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: _gameWords.isEmpty
                                  ? 0
                                  : _matchedIds.length / _gameWords.length,
                              backgroundColor: AppColors.ink100,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.bamboo,
                              ),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Attempts Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.amberLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.amberBorder, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.target, size: 14, color: AppColors.amberDark),
                          const SizedBox(width: 5),
                          Text(
                            '$_attempts attempts',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.amberDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Two Matching Columns
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    // Left Column: Japanese Kana
                    Expanded(
                      child: Column(
                        children: [
                          _buildColumnHeader(
                            title: '日本語',
                            subtitle: 'Japanese',
                            color: AppColors.azureDark,
                            bgColor: AppColors.azureLight,
                            borderColor: AppColors.azureBorder,
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: Column(
                              children: _kanaOptions
                                  .map((opt) => _buildItem(opt, true))
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 14),

                    // Right Column: English Meaning
                    Expanded(
                      child: Column(
                        children: [
                          _buildColumnHeader(
                            title: '意味',
                            subtitle: 'Meaning',
                            color: AppColors.coralDark,
                            bgColor: AppColors.coralLight,
                            borderColor: AppColors.coralBorder,
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: Column(
                              children: _meaningOptions
                                  .map((opt) => _buildItem(opt, false))
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Game completion banner / button
            if (_isGameOver)
              _buildGameOverBar()
            else
              const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildColumnHeader({
    required String title,
    required String subtitle,
    required Color color,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: JapaneseFontService().getJapaneseTextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '($subtitle)',
            style: GoogleFonts.outfit(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(_MatchOption option, bool isKanaColumn) {
    final isMatched = _matchedIds.contains(option.id);
    final isCorrect = isKanaColumn
        ? _correctKanaId == option.id
        : _correctMeaningId == option.id;
    final isWrong = isKanaColumn
        ? _wrongKanaId == option.id
        : _wrongMeaningId == option.id;
    final isSelected = isKanaColumn
        ? _selectedKanaId == option.id
        : _selectedMeaningId == option.id;

    // Duolingo-style 3D tactile palette
    Color backgroundColor = Colors.white;
    Color borderColor = AppColors.ink200;
    Color bottomBorderColor = const Color(0xFFCBD5E1); // 3D depth shadow
    Color textColor = AppColors.ink900;
    Widget? statusBadge;

    if (isMatched || isCorrect) {
      backgroundColor = const Color(0xFFECFDF5);
      borderColor = AppColors.bamboo;
      bottomBorderColor = AppColors.bambooDark;
      textColor = const Color(0xFF047857);
      statusBadge = const Icon(
        LucideIcons.checkCheck,
        size: 16,
        color: AppColors.bambooDark,
      );
    } else if (isWrong) {
      backgroundColor = const Color(0xFFFEF2F2);
      borderColor = AppColors.primary;
      bottomBorderColor = AppColors.primaryDark;
      textColor = const Color(0xFFB91C1C);
      statusBadge = const Icon(
        LucideIcons.x,
        size: 16,
        color: AppColors.primary,
      );
    } else if (isSelected) {
      backgroundColor = const Color(0xFFEFF6FF);
      borderColor = AppColors.azure;
      bottomBorderColor = AppColors.azureDark;
      textColor = const Color(0xFF1D4ED8);
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: BouncingWidget(
          scaleFactor: isMatched ? 1.0 : 0.94,
          onTap: () {
            if (isKanaColumn) {
              _onKanaTap(option.id);
            } else {
              _onMeaningTap(option.id);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: isMatched ? Colors.transparent : bottomBorderColor,
                  offset: Offset(0, isSelected ? 2 : 3.5),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      option.text,
                      textAlign: TextAlign.center,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: isKanaColumn
                          ? JapaneseFontService().getJapaneseTextStyle(
                              fontSize: option.text.length > 8 ? 14 : 16,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                              height: 1.2,
                            )
                          : GoogleFonts.outfit(
                              fontSize: option.text.length > 30
                                  ? 11.0
                                  : (option.text.length > 16 ? 12.0 : 13.5),
                              fontWeight: FontWeight.w700,
                              color: textColor,
                              height: 1.2,
                            ),
                    ),
                  ),
                ),

                // Audio speak icon for Kana cards
                if (isKanaColumn && !isMatched)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        SpeechService().speakJapanese(option.text);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.azureLight.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.volume2,
                          size: 13,
                          color: AppColors.azureDark,
                        ),
                      ),
                    ),
                  ),

                // Matched / Wrong status icon
                if (statusBadge != null)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: statusBadge,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverBar() {
    final stars = _calculateStars();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.amberBorder, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.amber.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              final isFilled = index < stars;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  LucideIcons.star,
                  size: 28,
                  color: isFilled ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            stars == 3
                ? 'Subarashii! Master Matcher!'
                : 'Good Job! Game Cleared!',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.ink900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Cleared in $_attempts attempts',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.ink500,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: BouncingWidget(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.ink100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.ink200, width: 1.5),
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
                        'Exit',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: BouncingWidget(
                  onTap: () {
                    setState(_initGame);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF43F5E), width: 1.5),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFF9F1239),
                          offset: Offset(0, 3.5),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.rotateCcw, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Play Again',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
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
    );
  }
}

class _MatchOption {
  final int id;
  final String text;
  final String? kanji;

  const _MatchOption({
    required this.id,
    required this.text,
    this.kanji,
  });
}
