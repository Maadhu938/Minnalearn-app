import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/stat_card.dart';
import '../widgets/feature_card.dart';
import 'kanji_screen.dart';
import '../services/database_service.dart';
import '../services/study_timer_service.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onTabChange;
  const HomeScreen({Key? key, this.onTabChange}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    DatabaseService.refreshNotifier.addListener(_refresh);
  }

  @override
  void dispose() {
    DatabaseService.refreshNotifier.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Gray-50
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Pink gradient header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 60, bottom: 60, left: 24, right: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFF472B6), // Pink-400
                    Color(0xFFEC4899), // Pink-500
                    Color(0xFFE11D48), // Rose-500
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
                    'Welcome back!',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Minna no Nihongo',
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
                  const SizedBox(height: 32),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.bookOpen,
                        color: Colors.white,
                        size: 64,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            FutureBuilder<Map<String, dynamic>>(
              future: Future.wait([
                DatabaseService().getLearnedVocabularyCount(),
                DatabaseService().getLearnedKanjiCount(),
                StudyTimerService().getFormattedStudyTime(),
              ]).then((results) => {
                'vocab': results[0],
                'kanji': results[1],
                'studyTime': results[2],
              }),
              builder: (context, snapshot) {
                final vocabCount = snapshot.data?['vocab'] ?? 0;
                final kanjiCount = snapshot.data?['kanji'] ?? 0;
                final studyTime = snapshot.data?['studyTime'] ?? '0m';

                return Transform.translate(
                  offset: const Offset(0, -30),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            value: vocabCount.toString(),
                            label: 'Vocabulary',
                            bgColor: Colors.blue.shade50,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: StatCard(
                            value: kanjiCount.toString(),
                            label: 'Kanji',
                            bgColor: Colors.purple.shade50,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: StatCard(
                            value: studyTime,
                            label: 'Study Time',
                            bgColor: Colors.pink.shade50,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Feature cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: FeatureCard(
                              title: 'Vocabulary Lessons',
                              icon: LucideIcons.bookOpen,
                              bgColor: const Color(0xFFEFF6FF), // Blue-50
                              iconColor: const Color(0xFF3B82F6), // Blue-500
                              onTap: () => widget.onTabChange?.call(1),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: FeatureCard(
                              title: 'Kanji Learning',
                              icon: LucideIcons.sparkles,
                              bgColor: const Color(0xFFFAF5FF), // Purple-50
                              iconColor: const Color(0xFFA855F7), // Purple-500
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const KanjiScreen()),
                                );
                                _refresh();
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: FeatureCard(
                              title: 'Games',
                              icon: LucideIcons.gamepad2,
                              bgColor: const Color(0xFFF0FDF4), // Green-50
                              iconColor: const Color(0xFF22C55E), // Green-500
                              onTap: () => widget.onTabChange?.call(2),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: FeatureCard(
                              title: 'Progress',
                              icon: LucideIcons.barChart3,
                              bgColor: const Color(0xFFFFF7ED), // Orange-50
                              iconColor: const Color(0xFFF97316), // Orange-500
                              onTap: () => widget.onTabChange?.call(3),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(height: 80), // Space for bottom nav
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
