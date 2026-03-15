import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/lesson.dart';
import '../services/database_service.dart';
import '../services/study_timer_service.dart';

enum _KanjiPracticeMode {
  flashcards,
  writing,
  quiz,
}

class KanjiScreen extends StatefulWidget {
  const KanjiScreen({Key? key}) : super(key: key);

  @override
  State<KanjiScreen> createState() => _KanjiScreenState();
}

class _KanjiScreenState extends State<KanjiScreen> {
  final Random _random = Random();

  List<Kanji> _allKanji = [];
  Future<List<Lesson>>? _lessonsFuture;
  int _selectedKanjiIndex = 0;
  _KanjiPracticeMode _practiceMode = _KanjiPracticeMode.flashcards;
  bool _isFlashcardFlipped = false;
  List<String> _quizOptions = [];
  String? _quizSelectedAnswer;
  bool _quizAnswered = false;

  @override
  void initState() {
    super.initState();
    StudyTimerService().startTimer();
    _lessonsFuture = DatabaseService().getLessons();
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

  final List<Map<String, dynamic>> _activities = [
    {
      'title': 'Kanji Flashcards',
      'mode': _KanjiPracticeMode.flashcards,
      'icon': LucideIcons.bookOpen,
      'color': const Color(0xFFEFF6FF),
      'iconColor': const Color(0xFF3B82F6),
    },
    {
      'title': 'Writing Practice',
      'mode': _KanjiPracticeMode.writing,
      'icon': LucideIcons.penTool,
      'color': const Color(0xFFFAF5FF),
      'iconColor': const Color(0xFFA855F7),
    },
    {
      'title': 'Kanji Quiz',
      'mode': _KanjiPracticeMode.quiz,
      'icon': LucideIcons.target,
      'color': const Color(0xFFF0FDF4),
      'iconColor': const Color(0xFF22C55E),
    },
  ];

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
  Widget build(BuildContext context) {
    return FutureBuilder<List<Lesson>>(
      future: _lessonsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _allKanji.isEmpty) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData && _allKanji.isEmpty) {
          _allKanji = (snapshot.data ?? []).expand((lesson) => lesson.kanji).toList();
          if (_allKanji.isNotEmpty) {
            _selectedKanjiIndex = 0;
            _prepareQuiz();
          }
        }

        final kanji = _selectedKanji;

        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          body: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 60, bottom: 32, left: 24, right: 24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFF472B6),
                        Color(0xFFEC4899),
                        Color(0xFFE11D48),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Back',
                              style: GoogleFonts.inter(color: Colors.white.withOpacity(0.9)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Kanji Learning',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_allKanji.length} common JLPT N5 kanji',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                if (kanji == null)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'No kanji available yet.',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF6B7280),
                        fontSize: 16,
                      ),
                    ),
                  )
                else ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Practice Options',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _activities.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final activity = _activities[index];
                            final isSelected = _practiceMode == activity['mode'];
                            return GestureDetector(
                              onTap: () => _changeMode(activity['mode']),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: isSelected ? activity['iconColor'] : Colors.transparent,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: activity['color'],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        activity['icon'],
                                        color: activity['iconColor'],
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        activity['title'],
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: const Color(0xFF1F2937),
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        LucideIcons.checkCircle2,
                                        color: activity['iconColor'],
                                        size: 20,
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
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: _buildPracticePanel(kanji),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _selectedKanjiIndex > 0 ? () => _setSelectedKanji(_selectedKanjiIndex - 1) : null,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            ),
                            child: Text('Previous', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _selectedKanjiIndex < _allKanji.length - 1
                                ? () => _setSelectedKanji(_selectedKanjiIndex + 1)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEC4899),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            ),
                            child: Text(
                              'Next',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'All Kanji',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 16),
                        GridView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                          ),
                          itemCount: _allKanji.length,
                          itemBuilder: (context, index) {
                            final item = _allKanji[index];
                            final isSelected = index == _selectedKanjiIndex;
                            return GestureDetector(
                              onTap: () => _setSelectedKanji(index),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: isSelected ? Border.all(color: Colors.pink, width: 2) : null,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    item.character,
                                    style: GoogleFonts.inter(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.pink : const Color(0xFF1F2937),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPracticePanel(Kanji kanji) {
    switch (_practiceMode) {
      case _KanjiPracticeMode.flashcards:
        return GestureDetector(
          onTap: () {
            setState(() {
              _isFlashcardFlipped = !_isFlashcardFlipped;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  _isFlashcardFlipped ? kanji.meaning : kanji.character,
                  style: GoogleFonts.inter(
                    fontSize: _isFlashcardFlipped ? 34 : 96,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                if (_isFlashcardFlipped) ...[
                  _buildKanjiInfoRow('On Reading', kanji.onReading, Colors.pink),
                  const SizedBox(height: 12),
                  _buildKanjiInfoRow('Kun Reading', kanji.kunReading, Colors.purple),
                  const SizedBox(height: 12),
                  _buildKanjiInfoRow('Used In', 'Lesson ${kanji.lessonId ?? '-'}', Colors.blue),
                ] else
                  Text(
                    'Tap to reveal meaning and readings',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF6B7280),
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
        );
      case _KanjiPracticeMode.writing:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trace and remember the shape',
                style: GoogleFonts.inter(
                  color: const Color(0xFF6B7280),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: SizedBox(
                  width: 220,
                  height: 220,
                  child: GridPaper(
                    divisions: 2,
                    subdivisions: 4,
                    color: const Color(0xFFFBCFE8),
                    child: Center(
                      child: Text(
                        kanji.character,
                        style: GoogleFonts.inter(
                          fontSize: 110,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildKanjiInfoRow('Meaning', kanji.meaning, const Color(0xFF1F2937)),
              const SizedBox(height: 12),
              _buildKanjiInfoRow('On Reading', kanji.onReading, Colors.pink),
              const SizedBox(height: 12),
              _buildKanjiInfoRow('Kun Reading', kanji.kunReading, Colors.purple),
            ],
          ),
        );
      case _KanjiPracticeMode.quiz:
        final correctMeaning = kanji.meaning;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What does this kanji mean?',
                style: GoogleFonts.inter(
                  color: const Color(0xFF6B7280),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  kanji.character,
                  style: GoogleFonts.inter(
                    fontSize: 96,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ..._quizOptions.map((option) {
                final isCorrect = option == correctMeaning;
                final isSelected = option == _quizSelectedAnswer;

                Color borderColor = const Color(0xFFE5E7EB);
                Color backgroundColor = Colors.white;

                if (_quizAnswered && isCorrect) {
                  borderColor = const Color(0xFF10B981);
                  backgroundColor = const Color(0xFFECFDF5);
                } else if (_quizAnswered && isSelected && !isCorrect) {
                  borderColor = const Color(0xFFEF4444);
                  backgroundColor = const Color(0xFFFEF2F2);
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () => _selectQuizAnswer(option),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: borderColor, width: 2),
                      ),
                      child: Text(
                        option,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                    ),
                  ),
                );
              }),
              if (_quizAnswered)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _nextQuizQuestion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22C55E),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      child: Text(
                        'Next Question',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
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

  Widget _buildKanjiInfoRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: const Color(0xFF6B7280),
            fontSize: 14,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: valueColor,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
