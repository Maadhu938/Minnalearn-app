import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/lesson.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';
import '../widgets/bouncing_widget.dart';
import 'true_or_false_screen.dart';
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
  bool _loadingInProgress = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_loadingInProgress) return;
    _loadingInProgress = true;

    final db = DatabaseService();
    final scoresFuture = db.getRecentGameScores(10);
    final lessonsFuture = db.getLessons();

    final scores = await scoresFuture;
    final lessons = await lessonsFuture;
    final playableLessons =
        lessons.where((lesson) => lesson.vocabulary.length >= 5).toList();

    if (!mounted) {
      _loadingInProgress = false;
      return;
    }

    setState(() {
      _recentScores = scores;
      _gameLesson = _buildGameLesson(playableLessons);
      _isLoading = false;
      _loadingInProgress = false;
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
        backgroundColor: AppColors.scaffold,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: Column(
        children: [
          _buildModernHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.primary,
              child: ListView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                children: [
                  GridView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                          MediaQuery.of(context).size.width > 600 ? 4 : 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio:
                          MediaQuery.of(context).size.width > 600 ? 1.2 : 0.88,
                    ),
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      switch (index) {
                        case 0:
                          return _buildGameCard(
                            'Match Game',
                            _gameLesson == null
                                ? 'Add more vocabulary to unlock'
                                : 'Match kana with meanings',
                            LucideIcons.shuffle,
                            const [Color(0xFF0284C7), Color(0xFF0369A1)],
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
                          );
                        case 1:
                          return _buildGameCard(
                            'True or False',
                            _gameLesson == null
                                ? 'Add more vocabulary to unlock'
                                : 'Quick-fire kana challenge',
                            LucideIcons.checkCheck,
                            const [Color(0xFFF59E0B), Color(0xFFD97706)],
                            isLocked: _gameLesson == null,
                            onTap: _gameLesson == null
                                ? null
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TrueOrFalseScreen(
                                          lesson: _gameLesson!,
                                        ),
                                      ),
                                    ).then((_) => _loadData());
                                  },
                          );
                        case 2:
                          return _buildGameCard(
                            'Typing Test',
                            _gameLesson == null
                                ? 'Add more vocabulary to unlock'
                                : 'Type English meaning fast',
                            LucideIcons.keyboard,
                            const [Color(0xFF10B981), Color(0xFF059669)],
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
                          );
                        case 3:
                          return _buildGameCard(
                            'Kana Puzzle',
                            _gameLesson == null
                                ? 'Add more vocabulary to unlock'
                                : 'Assemble kana from meaning',
                            LucideIcons.puzzle,
                            const [Color(0xFFF97316), Color(0xFFEA580C)],
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
                          );
                        default:
                          return const SizedBox();
                      }
                    },
                  ),
                  const SizedBox(height: 28),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent High Scores',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink900,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const Icon(
                        LucideIcons.trophy,
                        size: 18,
                        color: AppColors.amberDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: AppColors.ink200.withOpacity(0.8),
                        width: 1.2,
                      ),
                      boxShadow: AppShadows.card,
                    ),
                    child: _recentScores.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Column(
                                children: [
                                  const Icon(
                                    LucideIcons.gamepad2,
                                    size: 36,
                                    color: AppColors.ink400,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'No game records yet',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.ink700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Play any mini-game above to record your score!',
                                    style: GoogleFonts.inter(
                                      color: AppColors.ink500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Column(
                            children: List.generate(
                              _recentScores.length * 2 - 1,
                              (index) {
                                if (index.isOdd) {
                                  return Divider(
                                    height: 22,
                                    color: AppColors.ink100,
                                  );
                                }

                                final scoreData = _recentScores[index ~/ 2];
                                return _buildScoreItem(
                                  scoreData['game_name']?.toString() ?? 'Game',
                                  _formatDate(scoreData['date']?.toString()),
                                  scoreData['score']?.toString() ?? '0',
                                );
                              },
                            ),
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

  Widget _buildModernHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppGradients.primaryHeader,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -15,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.08,
                child: Text(
                  '遊',
                  style: GoogleFonts.notoSansJp(
                    fontSize: 104,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              top: 56,
              bottom: 30,
              left: 20,
              right: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Interactive Practice',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Mini Games',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Reinforce recall with gamified challenges',
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
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
      if (DateFormat('yyyy-MM-dd').format(date) ==
          DateFormat('yyyy-MM-dd').format(now)) {
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
    return BouncingWidget(
      scaleFactor: 0.95,
      onTap: isLocked ? null : onTap,
      child: Opacity(
        opacity: isLocked ? 0.65 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: colors[1].withOpacity(0.28),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      isLocked ? LucideIcons.lock : icon,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.arrowUpRight,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.88),
                  fontSize: 11.5,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreItem(String game, String date, String score) {
    IconData gameIcon = LucideIcons.gamepad2;
    Color iconColor = AppColors.azureDark;
    Color iconBg = AppColors.azureLight;

    if (game.contains('Match')) {
      gameIcon = LucideIcons.shuffle;
      iconColor = AppColors.azureDark;
      iconBg = AppColors.azureLight;
    } else if (game.contains('True')) {
      gameIcon = LucideIcons.checkCheck;
      iconColor = AppColors.amberDark;
      iconBg = AppColors.amberLight;
    } else if (game.contains('Typing')) {
      gameIcon = LucideIcons.keyboard;
      iconColor = AppColors.bambooDark;
      iconBg = AppColors.bambooLight;
    } else if (game.contains('Puzzle')) {
      gameIcon = LucideIcons.puzzle;
      iconColor = AppColors.coralDark;
      iconBg = AppColors.coralLight;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(gameIcon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  game,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: AppColors.ink500,
                  ),
                ),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            score,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
