import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/stat_card.dart';
import '../widgets/feature_card.dart';
import 'kanji_screen.dart';
import 'kana_screen.dart';
import 'listening_set_selection_screen.dart';
import '../services/database_service.dart';
import '../services/study_timer_service.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onTabChange;
  const HomeScreen({Key? key, this.onTabChange}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _fetchStats();
    DatabaseService.refreshNotifier.addListener(_refresh);
    KanjiScreen.prefetch();
  }

  Future<Map<String, dynamic>> _fetchStats() async {
    final results = await Future.wait([
      DatabaseService().getLearnedVocabularyCount(),
      DatabaseService().getLearnedKanjiCount(),
      StudyTimerService().getFormattedStudyTime(),
    ]);
    return {
      'vocab': results[0],
      'kanji': results[1],
      'studyTime': results[2],
    };
  }

  @override
  void dispose() {
    DatabaseService.refreshNotifier.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {
        _statsFuture = _fetchStats();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFF472B6),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                  top: 60,
                  bottom: 48,
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
                    bottomLeft: Radius.circular(48),
                    bottomRight: Radius.circular(48),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello Learner!',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'MinnaLearn',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'N5 Learning Journey',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTimeGreeting(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),

              FutureBuilder<Map<String, dynamic>>(
                future: _statsFuture,
                builder: (context, snapshot) {
                  final vocabCount = snapshot.data?['vocab'] ?? 0;
                  final kanjiCount = snapshot.data?['kanji'] ?? 0;
                  final studyTime = snapshot.data?['studyTime'] ?? '0m';

                  return Transform.translate(
                    offset: const Offset(0, -24),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildStatCardExpanded(
                            vocabCount.toString(),
                            'Vocab',
                            Colors.blue.shade50,
                          ),
                          const SizedBox(width: 8),
                          _buildStatCardExpanded(
                            kanjiCount.toString(),
                            'Kanji',
                            Colors.purple.shade50,
                          ),
                          const SizedBox(width: 8),
                          _buildStatCardExpanded(
                            studyTime,
                            'Time',
                            Colors.pink.shade50,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildKanaCard(),
                    const SizedBox(height: 12),
                    Builder(
                      builder: (context) {
                        final cardW =
                            (MediaQuery.of(context).size.width - 48 - 16) / 2;
                        final cardH = (cardW * 0.72).clamp(90.0, 140.0);
                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: cardH,
                                    child: FeatureCard(
                                      title: 'Vocabulary',
                                      icon: LucideIcons.bookOpen,
                                      bgColor: const Color(0xFFEFF6FF),
                                      iconColor: const Color(0xFF3B82F6),
                                      onTap: () => widget.onTabChange?.call(1),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: SizedBox(
                                    height: cardH,
                                    child: FeatureCard(
                                      title: 'Learn Kanji',
                                      icon: LucideIcons.sparkles,
                                      bgColor: const Color(0xFFFAF5FF),
                                      iconColor: const Color(0xFFA855F7),
                                      onTap: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const KanjiScreen(),
                                          ),
                                        );
                                        _refresh();
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: cardH,
                                    child: FeatureCard(
                                      title: 'Games',
                                      icon: LucideIcons.gamepad2,
                                      bgColor: const Color(0xFFF0FDF4),
                                      iconColor: const Color(0xFF22C55E),
                                      onTap: () => widget.onTabChange?.call(2),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: SizedBox(
                                    height: cardH,
                                    child: FeatureCard(
                                      title: 'Listening Prep',
                                      icon: LucideIcons.headphones,
                                      bgColor: const Color(0xFFFFF7ED),
                                      iconColor: const Color(0xFFF97316),
                                      onTap: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const ListeningSetSelectionScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    const SizedBox(height: 64),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCardExpanded(String value, String label, Color bgColor) {
    return Expanded(
      child: StatCard(
        value: value,
        label: label,
        bgColor: bgColor,
      ),
    );
  }

  Map<String, String> _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return {'jp': 'おはよう', 'romaji': 'Ohayou'};
    } else if (hour >= 12 && hour < 18) {
      return {'jp': 'こんにちは', 'romaji': 'Konnichiwa'};
    } else {
      return {'jp': 'おやすみ', 'romaji': 'Oyasumi'};
    }
  }

  Widget _buildTimeGreeting() {
    final greeting = _getTimeGreeting();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            greeting['jp']!,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            greeting['romaji']!,
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.85),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKanaCard() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const KanaScreen()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFFBEB),
              Color(0xFFFEF3C7),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'あ',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFD97706),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ア',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hiragana & Katakana',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF92400E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Practice Japanese characters',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFFB45309),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFDE68A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                LucideIcons.arrowRight,
                color: Color(0xFFD97706),
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
