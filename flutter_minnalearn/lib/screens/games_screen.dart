import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/lesson.dart';
import '../services/database_service.dart';
import 'memory_cards_screen.dart';
import 'matching_game_screen.dart';
import 'typing_test_screen.dart';
import 'kana_puzzle_screen.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({Key? key}) : super(key: key);

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  List<Map<String, dynamic>> _recentScores = [];
  Lesson? _gameLesson;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = DatabaseService();
    final scoresFuture = db.getRecentGameScores(10);
    final lessonsFuture = db.getLessons();

    final scores = await scoresFuture;
    final lessons = await lessonsFuture;
    final playableLessons = lessons.where((lesson) => lesson.vocabulary.length >= 5).toList();

    if (!mounted) {
      return;
    }

    setState(() {
      _recentScores = scores;
      _gameLesson = _buildGameLesson(playableLessons);
      _isLoading = false;
    });
  }

  Lesson? _buildGameLesson(List<Lesson> lessons) {
    if (lessons.isEmpty) {
      return null;
    }

    final combinedVocabulary = <Vocabulary>[
      for (final lesson in lessons) ...lesson.vocabulary,
    ];

    return Lesson(
      id: 0,
      title: 'All Lessons',
      vocabulary: combinedVocabulary,
      kanji: const [],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFEC4899)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 60,
              bottom: 32,
              left: 24,
              right: 24,
            ),
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
                Text(
                  'Games',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Learn while having fun!',
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFFEC4899),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                children: [
                  GridView.count(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.85,
                    children: [
                      _buildGameCard(
                        'Match Game',
                        _gameLesson == null
                            ? 'Add more vocabulary to unlock'
                            : 'Match kana with meanings',
                        LucideIcons.shuffle,
                        const [Color(0xFF60A5FA), Color(0xFF3B82F6)],
                        isLocked: _gameLesson == null,
                        onTap: _gameLesson == null
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MatchingGameScreen(
                                      lesson: _gameLesson!,
                                    ),
                                  ),
                                ).then((_) => _loadData());
                              },
                      ),
                      _buildGameCard(
                        'Memory Cards',
                        _gameLesson == null
                            ? 'Add more vocabulary to unlock'
                            : 'Match kana cards and clear the board',
                        LucideIcons.brain,
                        const [Color(0xFFC084FC), Color(0xFFA855F7)],
                        isLocked: _gameLesson == null,
                        onTap: _gameLesson == null
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MemoryCardsScreen(
                                      lesson: _gameLesson!,
                                    ),
                                  ),
                                ).then((_) => _loadData());
                              },
                      ),
                      _buildGameCard(
                        'Typing Test',
                        _gameLesson == null
                            ? 'Add more vocabulary to unlock'
                            : 'Type the English meaning fast',
                        LucideIcons.keyboard,
                        const [Color(0xFF34D399), Color(0xFF10B981)],
                        isLocked: _gameLesson == null,
                        onTap: _gameLesson == null
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TypingTestScreen(
                                      lesson: _gameLesson!,
                                    ),
                                  ),
                                ).then((_) => _loadData());
                              },
                      ),
                      _buildGameCard(
                        'Kana Puzzle',
                        _gameLesson == null
                            ? 'Add more vocabulary to unlock'
                            : 'Build the Kana from meaning',
                        LucideIcons.puzzle,
                        const [Color(0xFFFB923C), Color(0xFFF97316)],
                        isLocked: _gameLesson == null,
                        onTap: _gameLesson == null
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => KanaPuzzleScreen(
                                      lesson: _gameLesson!,
                                    ),
                                  ),
                                ).then((_) => _loadData());
                              },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Recent Scores',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
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
                    child: _recentScores.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Text(
                                'No scores yet. Play a game!',
                                style: GoogleFonts.inter(color: Colors.grey),
                              ),
                            ),
                          )
                        : Column(
                            children: List.generate(_recentScores.length * 2 - 1, (
                              index,
                            ) {
                              if (index.isOdd) {
                                return const Divider(height: 24);
                              }

                              final scoreData = _recentScores[index ~/ 2];
                              return _buildScoreItem(
                                scoreData['game_name']?.toString() ?? 'Game',
                                _formatDate(scoreData['date']?.toString()),
                                scoreData['score']?.toString() ?? '0',
                              );
                            }),
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

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) {
      return '';
    }

    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      if (DateFormat('yyyy-MM-dd').format(date) == DateFormat('yyyy-MM-dd').format(now)) {
        return 'Today';
      }
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (_) {
      return '';
    }
  }

  Widget _buildGameCard(
    String title,
    String desc,
    IconData icon,
    List<Color> colors, {
    VoidCallback? onTap,
    bool isLocked = false,
  }) {
    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: Opacity(
        opacity: isLocked ? 0.7 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: colors[1].withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isLocked ? LucideIcons.lock : icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const Spacer(),
              Text(
                title,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                desc,
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreItem(String game, String date, String score) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              game,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
            ),
            Text(
              date,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        Text(
          score,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFEC4899),
          ),
        ),
      ],
    );
  }
}
