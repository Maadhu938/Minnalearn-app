import 'dart:math' as math;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/lesson.dart';
import '../services/database_service.dart';
import '../services/study_timer_service.dart';
import '../services/audio_service.dart';
import '../services/achievement_service.dart';
import '../services/speech_service.dart';
import '../widgets/kanji_tracing_board.dart';
import '../data/kanji_stroke_dictionary.dart';
import '../utils/app_theme.dart';
import '../widgets/bouncing_widget.dart';
import '../services/japanese_font_service.dart';
import '../services/pro_entitlement_service.dart';
import 'pro_upgrade_screen.dart';

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
  ScrollPhysics _scrollPhysics = const ClampingScrollPhysics();
  final Random _random = Random();

  static List<Kanji> _cachedKanji = [];
  List<Kanji> _allKanji = _cachedKanji;
  int _selectedLevel = 0; // 0: JLPT N5 (100 characters), 1: JLPT N4 (100 characters)
  bool _isLoading = false;
  int _selectedKanjiIndex = 0;
  _KanjiPracticeMode _practiceMode = _KanjiPracticeMode.flashcards;
  bool _isFlashcardFlipped = false;
  List<String> _quizOptions = [];
  String? _quizSelectedAnswer;
  bool _quizAnswered = false;

  final GlobalKey<KanjiTracingBoardState> _tracingBoardKey =
      GlobalKey<KanjiTracingBoardState>();
  TracingMode _tracingMode = TracingMode.guided;
  bool _showStrokeNumbers = true;
  double _ghostOpacity = 0.35;
  int _activeStrokeIndex = 0;
  bool _isKanjiMastered = false;

  List<Kanji> get _currentKanjiList {
    if (_allKanji.isEmpty) return const [];
    if (_selectedLevel == 0) {
      return _allKanji.length >= 100 ? _allKanji.sublist(0, 100) : _allKanji;
    } else {
      return _allKanji.length > 100 ? _allKanji.sublist(100) : const [];
    }
  }

  @override
  void initState() {
    super.initState();
    StudyTimerService().startTimer();
    ProEntitlementService().addListener(_onProChanged);
    if (_cachedKanji.isNotEmpty) {
      _allKanji = _cachedKanji;
      _prepareQuiz();
    } else {
      _loadKanji();
    }
  }

  void _onProChanged() {
    if (mounted) setState(() {});
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
          if (_currentKanjiList.isNotEmpty) {
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
    ProEntitlementService().removeListener(_onProChanged);
    super.dispose();
  }

  Kanji? get _selectedKanji {
    final list = _currentKanjiList;
    if (list.isEmpty) {
      return null;
    }
    if (_selectedKanjiIndex >= list.length) {
      return list.first;
    }
    return list[_selectedKanjiIndex];
  }

  void _setSelectedKanji(int index) {
    final list = _currentKanjiList;
    if (index < 0 || index >= list.length) {
      return;
    }

    setState(() {
      _selectedKanjiIndex = index;
      _isFlashcardFlipped = false;
      _isKanjiMastered = false;
      _activeStrokeIndex = 0;
      if (_practiceMode == _KanjiPracticeMode.quiz) {
        _prepareQuiz();
      }
      _tracingBoardKey.currentState?.reset();
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
    final list = _currentKanjiList;
    if (kanji == null || list.length < 4) {
      _quizOptions = [];
      _quizSelectedAnswer = null;
      _quizAnswered = false;
      return;
    }

    final distractors = List<Kanji>.from(list)
      ..removeWhere((item) => item.character == kanji.character)
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
    final list = _currentKanjiList;
    if (list.isEmpty) {
      return;
    }

    final nextIndex = _random.nextInt(list.length);
    setState(() {
      _selectedKanjiIndex = nextIndex;
      _prepareQuiz();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: Column(
        children: [
          // Pinned Header
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.only(top: 54, bottom: 20, left: 20, right: 20),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    BouncingWidget(
                      scaleFactor: 0.94,
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.arrow_back_rounded,
                                color: Colors.white, size: 16),
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _selectedLevel == 0 ? 'JLPT N5' : 'JLPT N4',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
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
                      : '${_currentKanjiList.length} JLPT ${_selectedLevel == 0 ? "N5" : "N4"} Characters',
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.92),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                // Level Switcher Tabs
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.25), width: 1),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: BouncingWidget(
                          scaleFactor: 0.96,
                          onTap: () {
                            if (_selectedLevel != 0) {
                              setState(() {
                                _selectedLevel = 0;
                                _selectedKanjiIndex = 0;
                                _isFlashcardFlipped = false;
                                _isKanjiMastered = false;
                                _activeStrokeIndex = 0;
                              });
                              if (_practiceMode == _KanjiPracticeMode.quiz) {
                                _prepareQuiz();
                              }
                              _tracingBoardKey.currentState?.reset();
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _selectedLevel == 0
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: _selectedLevel == 0
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.12),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _selectedLevel == 0
                                        ? AppColors.primary
                                        : Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'N5',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'JLPT N5',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: _selectedLevel == 0
                                        ? AppColors.primaryDark
                                        : Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: BouncingWidget(
                          scaleFactor: 0.96,
                          onTap: () {
                            if (_selectedLevel != 1) {
                              setState(() {
                                _selectedLevel = 1;
                                _selectedKanjiIndex = 0;
                                _isFlashcardFlipped = false;
                                _isKanjiMastered = false;
                                _activeStrokeIndex = 0;
                              });
                              if (_practiceMode == _KanjiPracticeMode.quiz) {
                                _prepareQuiz();
                              }
                              _tracingBoardKey.currentState?.reset();
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _selectedLevel == 1
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: _selectedLevel == 1
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.12),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _selectedLevel == 1
                                        ? AppColors.primary
                                        : Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (!ProEntitlementService().isPro) ...[
                                        const Icon(
                                          Icons.lock_rounded,
                                          size: 10,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 3),
                                      ],
                                      Text(
                                        'N4',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'JLPT N4',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: _selectedLevel == 1
                                        ? AppColors.primaryDark
                                        : Colors.white.withOpacity(0.9),
                                  ),
                                ),
                                if (!ProEntitlementService().isPro) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFBBF24),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'PRO',
                                      style: GoogleFonts.inter(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
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

          // Scrollable Content with Clamping Physics
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildN4LockedBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFFFEEF3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE11D48).withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F2),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE11D48).withOpacity(0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Image.asset(
                'assets/crown_pro.png',
                width: 48,
                height: 48,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEEF3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'PRO EXCLUSIVE',
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFE11D48),
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'JLPT N4 Kanji is Locked',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upgrade to MinnaLearn PRO to unlock all 100 JLPT N4 Kanji characters, animated stroke orders, handwriting tracing canvas, and practice quizzes.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProUpgradeScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE11D48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/crown_pro.png',
                    width: 22,
                    height: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Unlock JLPT N4 with PRO',
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
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

    final isPro = ProEntitlementService().isPro;
    final isLevelLocked = _selectedLevel == 1 && !isPro;

    return SingleChildScrollView(
      key: const ValueKey('content'),
      physics: _scrollPhysics,
      child: Column(
        children: [
          if (isLevelLocked)
            _buildN4LockedBanner()
          else ...[
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
                  _buildSegmentItem('Flashcards', Icons.view_carousel_rounded,
                      _KanjiPracticeMode.flashcards),
                  _buildSegmentItem('Writing', Icons.edit_rounded,
                      _KanjiPracticeMode.writing),
                  _buildSegmentItem(
                      'Quiz', Icons.quiz_rounded, _KanjiPracticeMode.quiz),
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
                            Icons.chevron_left_rounded,
                            size: 20,
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
                    '${_selectedKanjiIndex + 1} / ${_currentKanjiList.length}',
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
                    onTap: _selectedKanjiIndex < _currentKanjiList.length - 1
                        ? () => _setSelectedKanji(_selectedKanjiIndex + 1)
                        : null,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: _selectedKanjiIndex < _currentKanjiList.length - 1
                            ? AppGradients.primaryHeader
                            : null,
                        color: _selectedKanjiIndex < _currentKanjiList.length - 1
                            ? null
                            : AppColors.ink100,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _selectedKanjiIndex < _currentKanjiList.length - 1
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
                              color: _selectedKanjiIndex < _currentKanjiList.length - 1
                                  ? Colors.white
                                  : AppColors.ink400,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: _selectedKanjiIndex < _currentKanjiList.length - 1
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
        ],

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
                      '${_selectedLevel == 0 ? "JLPT N5" : "JLPT N4"} Kanji',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      '${_currentKanjiList.length} characters',
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
                  itemCount: _currentKanjiList.length,
                  itemBuilder: (context, index) {
                    final item = _currentKanjiList[index];
                    final isSelected = index == _selectedKanjiIndex && !isLevelLocked;

                    return BouncingWidget(
                      scaleFactor: 0.92,
                      onTap: () {
                        if (isLevelLocked) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProUpgradeScreen(),
                            ),
                          );
                        } else {
                          _setSelectedKanji(index);
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryLight
                              : AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.ink200.withOpacity(0.9),
                            width: isSelected ? 2 : 1.2,
                          ),
                          boxShadow: isSelected
                              ? AppShadows.primaryGlow
                              : AppShadows.subtle,
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: ValueListenableBuilder<String>(
                                valueListenable:
                                    JapaneseFontService.currentFontNotifier,
                                builder: (context, fontKey, _) {
                                  return Text(
                                    item.character,
                                    style: JapaneseFontService().getJapaneseTextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? AppColors.primary
                                          : (isLevelLocked
                                              ? const Color(0xFF94A3B8)
                                              : AppColors.ink900),
                                    ),
                                  );
                                },
                              ),
                            ),
                            if (isLevelLocked)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(2.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE11D48).withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.lock_rounded,
                                    size: 10,
                                    color: Color(0xFFE11D48),
                                  ),
                                ),
                              ),
                          ],
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

  Widget _buildSegmentItem(
      String title, IconData icon, _KanjiPracticeMode mode) {
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
                size: 16,
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
              border: Border.all(
                  color: AppColors.ink200.withOpacity(0.8), width: 1.2),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
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
                      onTap: () =>
                          SpeechService().speakJapanese(kanji.character),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.amberLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.volume_up_rounded,
                          size: 18,
                          color: AppColors.amberDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (!_isFlashcardFlipped) ...[
                  ValueListenableBuilder<String>(
                    valueListenable: JapaneseFontService.currentFontNotifier,
                    builder: (context, fontKey, _) {
                      return Text(
                        kanji.character,
                        style: JapaneseFontService().getJapaneseTextStyle(
                          fontSize: 92,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink900,
                        ),
                        textAlign: TextAlign.center,
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.ink100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.refresh_rounded,
                            size: 13, color: AppColors.ink500),
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
                  _buildKanjiInfoRow('On Reading (音)', kanji.onReading,
                      AppColors.azureDark, AppColors.azureLight),
                  const SizedBox(height: 10),
                  _buildKanjiInfoRow('Kun Reading (訓)', kanji.kunReading,
                      AppColors.amberDark, AppColors.amberLight),
                  const SizedBox(height: 16),
                  ValueListenableBuilder<String>(
                    valueListenable: JapaneseFontService.currentFontNotifier,
                    builder: (context, fontKey, _) {
                      return Text(
                        kanji.character,
                        style: JapaneseFontService().getJapaneseTextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      case _KanjiPracticeMode.writing:
        final strokeData = KanjiStrokeDictionary.getStrokeData(kanji.character);
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
                color: AppColors.ink200.withOpacity(0.8), width: 1.2),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Kanji Character Header & Info (Clear visual focus)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFF1F2), Color(0xFFFFE4E6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.primary.withOpacity(0.3),
                              width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: ValueListenableBuilder<String>(
                            valueListenable:
                                JapaneseFontService.currentFontNotifier,
                            builder: (context, fontKey, _) {
                              return Text(
                                kanji.character,
                                style: JapaneseFontService().getJapaneseTextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            kanji.meaning,
                            style: GoogleFonts.outfit(
                              color: AppColors.ink900,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${strokeData.strokeCount} 画 (Strokes)',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Speak Audio Button
                  BouncingWidget(
                    onTap: () {
                      SpeechService().speakJapanese(kanji.character);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.azureLight,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.azureBorder, width: 1.2),
                      ),
                      child: const Icon(
                        Icons.volume_up_rounded,
                        size: 18,
                        color: AppColors.azureDark,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 2. Full-Width Mode Switcher (Guided vs Freehand) - Never cut off!
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.ink100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildModeTab(
                        'Guided Tracing',
                        TracingMode.guided,
                        Icons.explore_rounded,
                      ),
                    ),
                    Expanded(
                      child: _buildModeTab(
                        'Freehand Canvas',
                        TracingMode.freehand,
                        Icons.edit_rounded,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 3. Action Toolbar: [ 🎬 Watch ] [ 🔢 Numbers ] [ 👁 Outline ] [ ↩ Undo ] [ 🔄 Clear ]
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: AppColors.ink200.withOpacity(0.8), width: 1),
                ),
                child: Row(
                  children: [
                    _buildToolButton(
                      label: 'Watch',
                      icon: Icons.play_circle_fill_rounded,
                      color: AppColors.primary,
                      onTap: () {
                        _tracingBoardKey.currentState?.playDemonstration();
                      },
                    ),
                    _buildToolButton(
                      label: 'Numbers',
                      icon: Icons.format_list_numbered_rounded,
                      color: _showStrokeNumbers
                          ? AppColors.azureDark
                          : AppColors.ink400,
                      isActive: _showStrokeNumbers,
                      onTap: () {
                        setState(() {
                          _showStrokeNumbers = !_showStrokeNumbers;
                        });
                      },
                    ),
                    _buildToolButton(
                      label: 'Outline',
                      icon: Icons.visibility_rounded,
                      color: _ghostOpacity > 0
                          ? AppColors.bambooDark
                          : AppColors.ink400,
                      isActive: _ghostOpacity > 0,
                      onTap: () {
                        setState(() {
                          if (_ghostOpacity >= 0.35) {
                            _ghostOpacity = 0.15;
                          } else if (_ghostOpacity > 0.0) {
                            _ghostOpacity = 0.0;
                          } else {
                            _ghostOpacity = 0.35;
                          }
                        });
                      },
                    ),
                    _buildToolButton(
                      label: 'Undo',
                      icon: Icons.undo_rounded,
                      color: AppColors.ink700,
                      onTap: () {
                        _tracingBoardKey.currentState?.undo();
                      },
                    ),
                    _buildToolButton(
                      label: 'Clear',
                      icon: Icons.refresh_rounded,
                      color: AppColors.ink700,
                      onTap: () {
                        _tracingBoardKey.currentState?.reset();
                        setState(() {
                          _isKanjiMastered = false;
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 4. Current Stroke Instruction & Progress (in Guided mode)
              if (_tracingMode == TracingMode.guided && !_isKanjiMastered) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  decoration: BoxDecoration(
                    color: AppColors.azureLight,
                    borderRadius: BorderRadius.circular(18),
                    border:
                        Border.all(color: AppColors.azureBorder, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.azure.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0284C7), Color(0xFF0EA5E9)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0284C7).withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                '${_activeStrokeIndex + 1}',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'STROKE ${_activeStrokeIndex + 1} OF ${strokeData.strokeCount}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.azureDark.withOpacity(0.85),
                                    letterSpacing: 0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _activeStrokeIndex < strokeData.strokes.length
                                      ? strokeData
                                          .strokes[_activeStrokeIndex].displayDescription
                                      : 'Complete!',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink900,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: AppColors.azureBorder, width: 1),
                            ),
                            child: Text(
                              '${_activeStrokeIndex + 1}/${strokeData.strokeCount}',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.azureDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: strokeData.strokeCount > 0
                              ? (_activeStrokeIndex + 1) / strokeData.strokeCount
                              : 0.0,
                          minHeight: 5,
                          backgroundColor:
                              const Color(0xFFBAE6FD).withOpacity(0.5),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.azureDark),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // 5. Tracing Canvas (Responsive & Centered)
              LayoutBuilder(
                builder: (context, constraints) {
                  final canvasSize = math.min(constraints.maxWidth, 280.0);
                  return SizedBox(
                    width: canvasSize,
                    height: canvasSize,
                    child: KanjiTracingBoard(
                      key: _tracingBoardKey,
                      character: kanji.character,
                      mode: _tracingMode,
                      showNumbers: _showStrokeNumbers,
                      ghostOpacity: _ghostOpacity,
                      onInteractionStarted: () {
                        if (_scrollPhysics is! NeverScrollableScrollPhysics) {
                          setState(() {
                            _scrollPhysics =
                                const NeverScrollableScrollPhysics();
                          });
                        }
                      },
                      onInteractionEnded: () {
                        if (_scrollPhysics is! ClampingScrollPhysics) {
                          setState(() {
                            _scrollPhysics = const ClampingScrollPhysics();
                          });
                        }
                      },
                      onActiveStrokeChanged: (index) {
                        setState(() {
                          _activeStrokeIndex = index;
                        });
                      },
                      onKanjiMastered: () {
                        setState(() {
                          _isKanjiMastered = true;
                        });
                        DatabaseService().markKanjiAsLearned(kanji.character);
                        DatabaseService().updateStreak();
                        AchievementService()
                            .checkAchievements(context: context);
                      },
                    ),
                  );
                },
              ),

              // 6. Celebration Banner when Kanji is Mastered!
              if (_isKanjiMastered) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(18),
                    border:
                        Border.all(color: const Color(0xFFA7F3D0), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.asset(
                            'assets/gif/Shiba Happy.gif',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sugoi! Kanji Mastered!',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF047857),
                              ),
                            ),
                            Text(
                              'Stroke order perfected for ${kanji.character} (${kanji.meaning})',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF065F46),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // 7. Stroke Order Rule Tip
              if (strokeData.strokeOrderTip.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: const Color(0xFFFDE68A), width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline_rounded,
                          size: 16, color: Color(0xFFD97706)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          strokeData.strokeOrderTip,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // 8. Kanji Information Cards (Meaning, On'yomi, Kun'yomi)
              _buildKanjiInfoRow(
                  'Meaning', kanji.meaning, AppColors.ink900, AppColors.ink100),
              const SizedBox(height: 8),
              _buildKanjiInfoRow('On Reading', kanji.onReading,
                  AppColors.azureDark, AppColors.azureLight),
              const SizedBox(height: 8),
              _buildKanjiInfoRow('Kun Reading', kanji.kunReading,
                  AppColors.amberDark, AppColors.amberLight),
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
            border: Border.all(
                color: AppColors.ink200.withOpacity(0.8), width: 1.2),
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
              ValueListenableBuilder<String>(
                valueListenable: JapaneseFontService.currentFontNotifier,
                builder: (context, fontKey, _) {
                  return Text(
                    kanji.character,
                    style: JapaneseFontService().getJapaneseTextStyle(
                      fontSize: 84,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink900,
                    ),
                  );
                },
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
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

  Widget _buildKanjiInfoRow(
      String label, String value, Color textColor, Color pillBg) {
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
              style: JapaneseFontService().getJapaneseTextStyle(
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

  Widget _buildModeTab(String label, TracingMode mode, IconData icon) {
    final isSelected = _tracingMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _tracingMode = mode;
          _isKanjiMastered = false;
        });
        _tracingBoardKey.currentState?.reset();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
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
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.ink900 : AppColors.ink500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Expanded(
      child: BouncingWidget(
        scaleFactor: 0.92,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
          decoration: BoxDecoration(
            color: isActive ? color.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? color.withOpacity(0.35) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 19, color: color),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
