import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/lesson.dart';
import '../services/database_service.dart';
import '../services/study_timer_service.dart';
import '../services/audio_service.dart';
import '../services/achievement_service.dart';
import '../services/speech_service.dart';
import '../widgets/kanji_drawing_board.dart';
import '../utils/app_theme.dart';
import '../widgets/bouncing_widget.dart';

enum _KanjiPracticeMode {
  flashcards,
  writing,
  quiz,
}

class KanjiScreen extends StatefulWidget {
  const KanjiScreen({Key? key}) : super(key: key);

  /// Call this early (e.g. from HomeScreen.initState) to pre-load kanji data.
  static Future<void> prefetch() async {
    if (_KanjiScreenState._cachedKanji.isNotEmpty) return;
    final lessons = await DatabaseService().getLessons();
    final seen = <String>{};
    _KanjiScreenState._cachedKanji = lessons
        .expand((l) => l.kanji)
        .where((k) => seen.add(k.character))
        .toList();
  }

  /// Clear the static cache (call on user switch or data deletion).
  static void clearCache() {
    _KanjiScreenState._cachedKanji = [];
  }

  @override
  State<KanjiScreen> createState() => _KanjiScreenState();
}

class _KanjiScreenState extends State<KanjiScreen> {
  final Random _random = Random();

  static List<Kanji> _cachedKanji = [];
  List<Kanji> _allKanji = _cachedKanji;
  bool _isLoading = false;
  int _selectedKanjiIndex = 0;
  _KanjiPracticeMode _practiceMode = _KanjiPracticeMode.flashcards;
  bool _isFlashcardFlipped = false;
  List<String> _quizOptions = [];
  String? _quizSelectedAnswer;
  bool _quizAnswered = false;

  final GlobalKey<KanjiDrawingBoardState> _drawingBoardKey = GlobalKey<KanjiDrawingBoardState>();
  bool _isDrawing = false;

  @override
  void initState() {
    super.initState();
    StudyTimerService().startTimer();
    if (_cachedKanji.isNotEmpty) {
      _allKanji = _cachedKanji;
      _prepareQuiz();
    } else {
      _loadKanji();
    }
  }

  Future<void> _loadKanji() async {
    _isLoading = true;
    try {
      final lessons = await DatabaseService().getLessons();
      final seen = <String>{};
      final kanji = lessons
          .expand((l) => l.kanji)
          .where((k) => seen.add(k.character))
          .toList();
      _cachedKanji = kanji;
      if (mounted) {
        setState(() {
          _allKanji = kanji;
          _isLoading = false;
          if (_allKanji.isNotEmpty) {
            _selectedKanjiIndex = 0;
            _prepareQuiz();
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    StudyTimerService().stopTimer();
    super.dispose();
  }

  Kanji? get _selectedKanji {
    if (_allKanji.isEmpty) {
      return null;
    }
    return _allKanji[_selectedKanjiIndex];
  }


  void _setSelectedKanji(int index) {
    if (index < 0 || index >= _allKanji.length) {
      return;
    }

    setState(() {
      _selectedKanjiIndex = index;
      _isFlashcardFlipped = false;
      if (_practiceMode == _KanjiPracticeMode.quiz) {
        _prepareQuiz();
      }
      _drawingBoardKey.currentState?.clear(); // Clear drawing board when changing kanji
      AudioService().playClick();
    });
  }

  void _changeMode(_KanjiPracticeMode mode) {
    setState(() {
      _practiceMode = mode;
      _isFlashcardFlipped = false;
      if (mode == _KanjiPracticeMode.quiz) {
        _prepareQuiz();
      }
    });
  }

  void _prepareQuiz() {
    final kanji = _selectedKanji;
    if (kanji == null || _allKanji.length < 4) {
      _quizOptions = [];
      _quizSelectedAnswer = null;
      _quizAnswered = false;
      return;
    }

    final distractors = List<Kanji>.from(_allKanji)
      ..removeWhere((item) => item.id == kanji.id)
      ..shuffle(_random);

    final options = <String>[
      kanji.meaning,
      ...distractors.take(3).map((item) => item.meaning),
    ]..shuffle(_random);

    _quizOptions = options;
    _quizSelectedAnswer = null;
    _quizAnswered = false;
  }

  void _selectQuizAnswer(String answer) {
    if (_quizAnswered) {
      return;
    }

    setState(() {
      _quizSelectedAnswer = answer;
      _quizAnswered = true;
    });

    if (answer == _selectedKanji?.meaning) {
      AudioService().playCorrect();
      DatabaseService().markKanjiAsLearned(_selectedKanji!.character);
      DatabaseService().updateStreak();
      AchievementService().checkAchievements(context: context);
    } else {
      AudioService().playWrong();
    }
  }

  void _nextQuizQuestion() {
    if (_allKanji.isEmpty) {
      return;
    }

    final nextIndex = _random.nextInt(_allKanji.length);
    setState(() {
      _selectedKanjiIndex = nextIndex;
      _prepareQuiz();
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: Column(
        children: [
          // Pinned Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 56, bottom: 24, left: 20, right: 20),
            decoration: const BoxDecoration(
              gradient: AppGradients.primaryHeader,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BouncingWidget(
                  scaleFactor: 0.94,
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Back',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kanji Learning',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _allKanji.isEmpty
                              ? 'Loading kanji...'
                              : '${_allKanji.length} JLPT N5 characters',
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.92),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'JLPT N5',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Scrollable Content with Clamping Physics
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _allKanji.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_allKanji.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No kanji available yet.',
            style: GoogleFonts.inter(
              color: AppColors.ink500,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    final kanji = _selectedKanji;
    if (kanji == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      key: const ValueKey('content'),
      physics: _isDrawing
          ? const NeverScrollableScrollPhysics()
          : const ClampingScrollPhysics(),
      child: Column(
        children: [
          // Sleek 3-Mode Segmented Selector
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.ink100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _buildSegmentItem('Flashcards', LucideIcons.layers, _KanjiPracticeMode.flashcards),
                  _buildSegmentItem('Writing', LucideIcons.pencil, _KanjiPracticeMode.writing),
                  _buildSegmentItem('Quiz', LucideIcons.target, _KanjiPracticeMode.quiz),
                ],
              ),
            ),
          ),

          // Practice Hero Panel
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: _buildPracticePanel(kanji),
          ),

          // Previous / Next Navigation Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: BouncingWidget(
                    scaleFactor: 0.95,
                    onTap: _selectedKanjiIndex > 0
                        ? () => _setSelectedKanji(_selectedKanjiIndex - 1)
                        : null,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _selectedKanjiIndex > 0
                              ? AppColors.ink200
                              : AppColors.ink100,
                        ),
                        boxShadow: AppShadows.subtle,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.chevronLeft,
                            size: 18,
                            color: _selectedKanjiIndex > 0
                                ? AppColors.ink700
                                : AppColors.ink400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Previous',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: _selectedKanjiIndex > 0
                                  ? AppColors.ink700
                                  : AppColors.ink400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    '${_selectedKanjiIndex + 1} / ${_allKanji.length}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink500,
                    ),
                  ),
                ),
                Expanded(
                  child: BouncingWidget(
                    scaleFactor: 0.95,
                    onTap: _selectedKanjiIndex < _allKanji.length - 1
                        ? () => _setSelectedKanji(_selectedKanjiIndex + 1)
                        : null,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: _selectedKanjiIndex < _allKanji.length - 1
                            ? AppGradients.primaryHeader
                            : null,
                        color: _selectedKanjiIndex < _allKanji.length - 1
                            ? null
                            : AppColors.ink100,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _selectedKanjiIndex < _allKanji.length - 1
                            ? AppShadows.primaryGlow
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Next',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: _selectedKanjiIndex < _allKanji.length - 1
                                  ? Colors.white
                                  : AppColors.ink400,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            LucideIcons.chevronRight,
                            size: 18,
                            color: _selectedKanjiIndex < _allKanji.length - 1
                                ? Colors.white
                                : AppColors.ink400,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // All Kanji Grid Section
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'All Kanji',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      '${_allKanji.length} characters',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: _allKanji.length,
                  itemBuilder: (context, index) {
                    final item = _allKanji[index];
                    final isSelected = index == _selectedKanjiIndex;
                    return BouncingWidget(
                      scaleFactor: 0.92,
                      onTap: () => _setSelectedKanji(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryLight : AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.ink200.withOpacity(0.9),
                            width: isSelected ? 2 : 1.2,
                          ),
                          boxShadow: isSelected ? AppShadows.primaryGlow : AppShadows.subtle,
                        ),
                        child: Center(
                          child: Text(
                            item.character,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? AppColors.primary : AppColors.ink900,
                              fontFamilyFallback: const ['Noto Sans CJK JP', 'sans-serif'],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentItem(String title, IconData icon, _KanjiPracticeMode mode) {
    final isSelected = _practiceMode == mode;
    return Expanded(
      child: BouncingWidget(
        scaleFactor: 0.94,
        onTap: () => _changeMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? AppColors.primary : AppColors.ink500,
              ),
              const SizedBox(width: 5),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? AppColors.ink900 : AppColors.ink500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPracticePanel(Kanji kanji) {
    switch (_practiceMode) {
      case _KanjiPracticeMode.flashcards:
        return BouncingWidget(
          scaleFactor: 0.98,
          onTap: () {
            setState(() {
              _isFlashcardFlipped = !_isFlashcardFlipped;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.ink200.withOpacity(0.8), width: 1.2),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '#${_selectedKanjiIndex + 1}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    BouncingWidget(
                      scaleFactor: 0.90,
                      onTap: () => SpeechService().speakJapanese(kanji.character),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.amberLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.volume2,
                          size: 18,
                          color: AppColors.amberDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (!_isFlashcardFlipped) ...[
                  Text(
                    kanji.character,
                    style: const TextStyle(
                      fontSize: 88,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink900,
                      fontFamilyFallback: ['Noto Sans CJK JP', 'sans-serif'],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.ink100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.rotateCcw, size: 13, color: AppColors.ink500),
                        const SizedBox(width: 6),
                        Text(
                          'Tap to reveal meaning & readings',
                          style: GoogleFonts.inter(
                            color: AppColors.ink500,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Text(
                    kanji.meaning,
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink900,
                      letterSpacing: -0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  _buildKanjiInfoRow('On Reading (音)', kanji.onReading, AppColors.azureDark, AppColors.azureLight),
                  const SizedBox(height: 10),
                  _buildKanjiInfoRow('Kun Reading (訓)', kanji.kunReading, AppColors.amberDark, AppColors.amberLight),
                  const SizedBox(height: 16),
                  Text(
                    kanji.character,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      fontFamilyFallback: ['Noto Sans CJK JP', 'sans-serif'],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      case _KanjiPracticeMode.writing:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.ink200.withOpacity(0.8), width: 1.2),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Trace & Practice',
                    style: GoogleFonts.inter(
                      color: AppColors.ink700,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  BouncingWidget(
                    scaleFactor: 0.90,
                    onTap: () {
                      _drawingBoardKey.currentState?.clear();
                      AudioService().playClick();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.ink100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.eraser, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            'Clear',
                            style: GoogleFonts.inter(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.ink200, width: 1.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: GridPaper(
                      divisions: 2,
                      subdivisions: 2,
                      color: AppColors.ink200.withOpacity(0.5),
                      child: Stack(
                        children: [
                          Center(
                            child: Text(
                              kanji.character,
                              style: TextStyle(
                                fontSize: 130,
                                fontWeight: FontWeight.bold,
                                color: AppColors.ink200.withOpacity(0.4),
                                fontFamilyFallback: const ['Noto Sans CJK JP', 'sans-serif'],
                              ),
                            ),
                          ),
                          KanjiDrawingBoard(
                            key: _drawingBoardKey,
                            strokeGuide: kanji.character,
                            onStrokeStart: () {
                              setState(() {
                                _isDrawing = true;
                              });
                            },
                            onStrokeComplete: () {
                              setState(() {
                                _isDrawing = false;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildKanjiInfoRow('Meaning', kanji.meaning, AppColors.ink900, AppColors.ink100),
              const SizedBox(height: 8),
              _buildKanjiInfoRow('On Reading', kanji.onReading, AppColors.azureDark, AppColors.azureLight),
              const SizedBox(height: 8),
              _buildKanjiInfoRow('Kun Reading', kanji.kunReading, AppColors.amberDark, AppColors.amberLight),
            ],
          ),
        );
      case _KanjiPracticeMode.quiz:
        final correctMeaning = kanji.meaning;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.ink200.withOpacity(0.8), width: 1.2),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'What does this kanji mean?',
                style: GoogleFonts.inter(
                  color: AppColors.ink500,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                kanji.character,
                style: const TextStyle(
                  fontSize: 84,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink900,
                  fontFamilyFallback: ['Noto Sans CJK JP', 'sans-serif'],
                ),
              ),
              const SizedBox(height: 18),
              ..._quizOptions.map((option) {
                final isCorrect = option == correctMeaning;
                final isSelected = option == _quizSelectedAnswer;

                Color borderColor = AppColors.ink200;
                Color backgroundColor = Colors.white;
                Color textColor = AppColors.ink900;

                if (_quizAnswered && isCorrect) {
                  borderColor = AppColors.bamboo;
                  backgroundColor = AppColors.bambooLight;
                  textColor = AppColors.bambooDark;
                } else if (_quizAnswered && isSelected && !isCorrect) {
                  borderColor = AppColors.primary;
                  backgroundColor = AppColors.primaryLight;
                  textColor = AppColors.primaryDark;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: BouncingWidget(
                    scaleFactor: 0.96,
                    onTap: () => _selectQuizAnswer(option),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor, width: 1.5),
                        boxShadow: AppShadows.subtle,
                      ),
                      child: Text(
                        option,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                );
              }),
              if (_quizAnswered)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: BouncingWidget(
                    scaleFactor: 0.96,
                    onTap: _nextQuizQuestion,
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: AppGradients.bamboo,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.bamboo.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Next Question',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
    }
  }

  Widget _buildKanjiInfoRow(String label, String value, Color textColor, Color pillBg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: pillBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: textColor.withOpacity(0.85),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          Flexible(
            child: Text(
              value.isEmpty ? '--' : value,
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: textColor,
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
