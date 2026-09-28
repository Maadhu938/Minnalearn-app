import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../services/database_service.dart';
import '../utils/app_theme.dart';
import '../widgets/animated_progress_bar.dart';
import '../widgets/bouncing_widget.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _streak = 0;
  List<Map<String, dynamic>> _weeklyTime = [];
  Map<String, double> _mastery = {
    'vocabulary': 0.0,
    'kanji': 0.0,
    'grammar': 0.0,
  };
  bool _isLoading = true;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
    DatabaseService.refreshNotifier.addListener(_loadStats);
  }

  @override
  void dispose() {
    _disposed = true;
    DatabaseService.refreshNotifier.removeListener(_loadStats);
    super.dispose();
  }

  Future<void> _loadStats() async {
    final db = DatabaseService();
    final streak = await db.getStreak();
    final weekly = await db.getWeeklyStudyTime();
    final mastery = await db.getMasteryPercentages();

    if (mounted && !_disposed) {
      setState(() {
        _streak = streak;
        _weeklyTime = weekly;
        _mastery = mastery;
        _isLoading = false;
      });
    }
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
              onRefresh: _loadStats,
              color: AppColors.primary,
              child: ListView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                children: [
                  // Streak Hero Banner
                  _buildStreakBanner(),
                  const SizedBox(height: 20),

                  // Weekly Study Time Chart Card
                  _buildWeeklyStudyCard(),
                  const SizedBox(height: 20),

                  // Mastery Progress Card
                  _buildMasteryCard(),
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
                  '進歩',
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
                    'Analytics & Mastery',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your Progress',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Track consistency, study time, and skill mastery',
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

  Widget _buildStreakBanner() {
    return BouncingWidget(
      scaleFactor: 0.98,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: AppGradients.amber,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.amberDark.withOpacity(0.28),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.flame,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Daily Study Streak',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.92),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_streak ${_streak == 1 ? 'Day' : 'Days'}',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _streak > 0
                        ? 'Consistency is king! Keep your habit alive!'
                        : 'Study today to ignite your streak!',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.92),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.35),
                  width: 2,
                ),
              ),
              child: const Center(
                child: Icon(
                  LucideIcons.flame,
                  color: Colors.white,
                  size: 38,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyStudyCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.ink200.withOpacity(0.8),
          width: 1.2,
        ),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.azureLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.barChart3,
                      color: AppColors.azureDark,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Weekly Study Time',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink900,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              Text(
                'Last 7 Days',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 140,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _weeklyTime.map((data) {
                return _buildAnimatedBar(
                  data['day']?.toString() ?? '',
                  (data['percent'] as num?)?.toDouble() ?? 0.0,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBar(String day, double percent) {
    final clampedPercent = percent.clamp(0.0, 1.0);
    final isMax = clampedPercent > 0.6;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: clampedPercent),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, val, _) {
            final barHeight = (val * 105).clamp(6.0, 105.0);
            return Container(
              width: 24,
              height: barHeight,
              decoration: BoxDecoration(
                gradient: isMax
                    ? AppGradients.primaryHeader
                    : AppGradients.azure,
                borderRadius: BorderRadius.circular(8),
                boxShadow: isMax ? AppShadows.primaryGlow : AppShadows.subtle,
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.ink500,
          ),
        ),
      ],
    );
  }

  Widget _buildMasteryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.ink200.withOpacity(0.8),
          width: 1.2,
        ),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.bambooLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.lineChart,
                  color: AppColors.bambooDark,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Skill Mastery Gauges',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink900,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildMasteryItem(
            label: 'Vocabulary Mastery',
            percent: _mastery['vocabulary'] ?? 0.0,
            icon: LucideIcons.bookOpen,
            color: AppColors.azureDark,
            gradient: AppGradients.azure,
            bgColor: AppColors.azureLight,
          ),
          const SizedBox(height: 16),
          _buildMasteryItem(
            label: 'Kanji Mastery',
            percent: _mastery['kanji'] ?? 0.0,
            icon: LucideIcons.languages,
            color: AppColors.amberDark,
            gradient: AppGradients.amber,
            bgColor: AppColors.amberLight,
          ),
          const SizedBox(height: 16),
          _buildMasteryItem(
            label: 'Grammar Mastery',
            percent: _mastery['grammar'] ?? 0.0,
            icon: LucideIcons.fileText,
            color: AppColors.bambooDark,
            gradient: AppGradients.bamboo,
            bgColor: AppColors.bambooLight,
          ),
        ],
      ),
    );
  }

  Widget _buildMasteryItem({
    required String label,
    required double percent,
    required IconData icon,
    required Color color,
    required LinearGradient gradient,
    required Color bgColor,
  }) {
    final percentInt = (percent.clamp(0.0, 1.0) * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 14),
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink700,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$percentInt%',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedProgressBar(
          value: percent,
          height: 8,
          gradient: gradient,
          backgroundColor: AppColors.ink100,
        ),
      ],
    );
  }
}
