import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/lesson.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';
import '../widgets/animated_progress_bar.dart';
import '../widgets/bouncing_widget.dart';
import 'lesson_detail_screen.dart';

class LessonsScreen extends StatefulWidget {
  const LessonsScreen({Key? key}) : super(key: key);

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  int _selectedFilter = 0; // 0: All, 1: In Progress, 2: Completed

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: Column(
        children: [
          _buildModernHeader(),
          _buildFilterTabs(),
          Expanded(
            child: FutureBuilder<List<Lesson>>(
              future: DatabaseService().getLessons(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: GoogleFonts.inter(color: AppColors.ink500),
                    ),
                  );
                }

                final allLessons = snapshot.data ?? [];
                final filteredLessons = allLessons.where((lesson) {
                  if (_selectedFilter == 1) {
                    return lesson.progress > 0.0 && lesson.progress < 1.0;
                  } else if (_selectedFilter == 2) {
                    return lesson.progress >= 1.0;
                  }
                  return true;
                }).toList();

                if (filteredLessons.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _selectedFilter == 2
                              ? LucideIcons.award
                              : LucideIcons.bookOpen,
                          size: 48,
                          color: AppColors.ink400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _selectedFilter == 2
                              ? 'No completed lessons yet.'
                              : 'No lessons in progress.',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Start exploring Lesson 1!',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.ink500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  itemCount: filteredLessons.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final lesson = filteredLessons[index];
                    return _buildLessonCard(lesson);
                  },
                );
              },
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
                opacity: 0.07,
                child: Text(
                  '第課',
                  style: GoogleFonts.notoSansJp(
                    fontSize: 96,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        'Minna no Nihongo I',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    FutureBuilder<List<Lesson>>(
                      future: DatabaseService().getLessons(),
                      builder: (context, snapshot) {
                        final lessons = snapshot.data ?? [];
                        final completed =
                            lessons.where((l) => l.progress >= 1.0).length;
                        return Text(
                          '$completed / 25 Done',
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Structured Lessons',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Master vocabulary, kanji, and grammar step-by-step',
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

  Widget _buildFilterTabs() {
    final filters = ['All (25)', 'In Progress', 'Completed'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: List.generate(filters.length, (index) {
          final isSelected = _selectedFilter == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: BouncingWidget(
              scaleFactor: 0.94,
              onTap: () {
                setState(() {
                  _selectedFilter = index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.ink200.withOpacity(0.8),
                    width: 1.2,
                  ),
                  boxShadow: isSelected ? AppShadows.primaryGlow : AppShadows.subtle,
                ),
                child: Text(
                  filters[index],
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.ink700,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildLessonCard(Lesson lesson) {
    final isDone = lesson.progress >= 1.0;
    final percentInt = (lesson.progress * 100).toInt();

    return BouncingWidget(
      scaleFactor: 0.98,
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LessonDetailScreen(lesson: lesson),
          ),
        );
        if (mounted) setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDone
                ? AppColors.bambooBorder
                : AppColors.ink200.withOpacity(0.8),
            width: 1.2,
          ),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Lesson badge
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppColors.bambooLight
                        : (lesson.progress > 0
                            ? AppColors.amberLight
                            : AppColors.primaryLight),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      '${lesson.id}',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDone
                            ? AppColors.bambooDark
                            : (lesson.progress > 0
                                ? AppColors.amberDark
                                : AppColors.primary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Lesson ${lesson.id}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink500,
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (isDone)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.bambooLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    LucideIcons.checkCircle2,
                                    size: 11,
                                    color: AppColors.bambooDark,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Complete',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.bambooDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lesson.title.isEmpty ? 'Vocabulary & Grammar' : lesson.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink900,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.ink100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.chevronRight,
                    color: AppColors.ink500,
                    size: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Chips: words count, quiz status
            Row(
              children: [
                _buildInfoChip(
                  icon: LucideIcons.bookOpen,
                  label: '${lesson.vocabulary.length} words',
                ),
                const Spacer(),
                Text(
                  '$percentInt%',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isDone ? AppColors.bambooDark : AppColors.ink700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Animated Progress Bar
            AnimatedProgressBar(
              value: lesson.progress,
              height: 7,
              foregroundColor: isDone ? AppColors.bamboo : AppColors.primary,
              gradient: isDone ? AppGradients.bamboo : AppGradients.primaryHeader,
              backgroundColor: AppColors.ink100,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.ink100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.ink500),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.ink700,
            ),
          ),
        ],
      ),
    );
  }
}
