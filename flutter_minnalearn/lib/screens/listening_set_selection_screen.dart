import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'listening_practice_screen.dart';
import '../utils/app_theme.dart';
import '../widgets/bouncing_widget.dart';
import '../services/database_service.dart';
import '../services/japanese_font_service.dart';

class _ListeningModeCardModel {
  final ListeningMode mode;
  final String title;
  final String japaneseTitle;
  final String subtitle;
  final String description;
  final int questionCount;
  final String estimatedTime;
  final IconData icon;
  final Color accentColor;
  final Color lightBg;
  final Color borderColor;
  final String badgeText;
  final bool isFeatured;

  const _ListeningModeCardModel({
    required this.mode,
    required this.title,
    required this.japaneseTitle,
    required this.subtitle,
    required this.description,
    required this.questionCount,
    required this.estimatedTime,
    required this.icon,
    required this.accentColor,
    required this.lightBg,
    required this.borderColor,
    required this.badgeText,
    this.isFeatured = false,
  });
}

class ListeningSetSelectionScreen extends StatefulWidget {
  const ListeningSetSelectionScreen({Key? key}) : super(key: key);

  @override
  State<ListeningSetSelectionScreen> createState() =>
      _ListeningSetSelectionScreenState();
}

class _ListeningSetSelectionScreenState
    extends State<ListeningSetSelectionScreen> {
  late Future<Map<String, int?>> _bestScoresFuture;

  static const List<_ListeningModeCardModel> _modes = [
    _ListeningModeCardModel(
      mode: ListeningMode.fullMock,
      title: 'Full N5 Listening Mock Exam',
      japaneseTitle: '聴解 模擬試験',
      subtitle: 'Task & Point Comprehension',
      description:
          'Continuous 20-question session combining Task & Point comprehension, paced like the JLPT test.',
      questionCount: 20,
      estimatedTime: '~15-20 min',
      icon: LucideIcons.graduationCap,
      accentColor: AppColors.primary,
      lightBg: AppColors.primaryLight,
      borderColor: AppColors.primaryBorder,
      badgeText: 'MOCK EXAM',
      isFeatured: true,
    ),
    _ListeningModeCardModel(
      mode: ListeningMode.section1,
      title: 'Task-Based Comprehension',
      japaneseTitle: '問題1・課題理解',
      subtitle: 'Questions 1–10 • Action & Task Focused',
      description:
          'Listen to situational dialogues and determine what action the speaker should carry out next.',
      questionCount: 10,
      estimatedTime: '~8 min',
      icon: LucideIcons.checkSquare,
      accentColor: AppColors.bambooDark,
      lightBg: AppColors.bambooLight,
      borderColor: AppColors.bambooBorder,
      badgeText: 'SECTION 1',
    ),
    _ListeningModeCardModel(
      mode: ListeningMode.section2,
      title: 'Key Point Comprehension',
      japaneseTitle: '問題2・ポイント理解',
      subtitle: 'Questions 11–20 • Detail & Condition Focused',
      description:
          'Focus on specific details, conditions, directions, numbers, and descriptive clues in the audio prompt.',
      questionCount: 10,
      estimatedTime: '~8 min',
      icon: LucideIcons.target,
      accentColor: AppColors.azureDark,
      lightBg: AppColors.azureLight,
      borderColor: AppColors.azureBorder,
      badgeText: 'SECTION 2',
    ),
    _ListeningModeCardModel(
      mode: ListeningMode.quickDrill,
      title: 'Rapid 5-Question Drill',
      japaneseTitle: '高速ドリル',
      subtitle: '5 Randomized Questions • Quick Commute Practice',
      description:
          'Randomly draws 5 illustrated audio questions from the 20-question bank for fast daily practice.',
      questionCount: 5,
      estimatedTime: '~3 min',
      icon: LucideIcons.zap,
      accentColor: AppColors.amberDark,
      lightBg: AppColors.amberLight,
      borderColor: AppColors.amberBorder,
      badgeText: 'SPEED DRILL',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _bestScoresFuture = _loadBestScores();
  }

  Future<Map<String, int?>> _loadBestScores() async {
    final scores = await Future.wait([
      DatabaseService().getUserStatInt('listening_best_fullMock'),
      DatabaseService().getUserStatInt('listening_best_section1'),
      DatabaseService().getUserStatInt('listening_best_section2'),
      DatabaseService().getUserStatInt('listening_best_quickDrill'),
    ]);
    return {
      'fullMock': scores[0],
      'section1': scores[1],
      'section2': scores[2],
      'quickDrill': scores[3],
    };
  }

  void _refreshScores() {
    setState(() {
      _bestScoresFuture = _loadBestScores();
    });
  }

  Future<void> _openPractice(ListeningMode mode, String title) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListeningPracticeScreen(
          mode: mode,
          title: title,
        ),
      ),
    );
    _refreshScores();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.scaffold,
        body: Column(
          children: [
            _buildModernHeader(),
            Expanded(
              child: FutureBuilder<Map<String, int?>>(
                future: _bestScoresFuture,
                builder: (context, snapshot) {
                  final bestScores = snapshot.data ?? {};
                  final mockBest = bestScores['fullMock'];

                  return ListView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // Top Practice Bank Overview Card
                      _buildTopOverviewCard(mockBest),
                      const SizedBox(height: 20),

                      // Practice Modes Title Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Practice Modes',
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink900,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '20 Practice Questions',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 4 Mode Cards
                      for (final modeModel in _modes) ...[
                        _buildModeCard(
                          modeModel,
                          bestScore: bestScores[modeModel.mode.name],
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Strategy / Study Tip Card
                      _buildStrategiesCard(),
                      SizedBox(
                          height:
                              MediaQuery.of(context).padding.bottom + 24),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildModernHeader() {
    final topPadding = MediaQuery.of(context).padding.top;
    final safeTop = topPadding > 30 ? topPadding + 14 : 52.0;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppGradients.primaryHeader,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Stack(
        children: [
          // Japanese Choukai (Listening) watermark
          Positioned(
            right: 4,
            bottom: -10,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.1,
                child: Text(
                  '聴解',
                  style: JapaneseFontService().getJapaneseTextStyle(
                    fontSize: 100,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
                top: safeTop, bottom: 22, left: 20, right: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Notch-Safe Back Button
                BouncingWidget(
                  scaleFactor: 0.95,
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.arrowLeft,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Back',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Main Title & Japanese Subtitle Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Listening Practice',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'JLPT N5 Choukai Prep • 日本語聴解',
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.35)),
                      ),
                      child: Text(
                        'JLPT N5',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Top Practice Bank Overview Card ────────────────────────────────────────
  Widget _buildTopOverviewCard(int? mockBest) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.ink200, width: 1.2),
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primaryBorder),
                ),
                child: const Icon(LucideIcons.headphones,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Listening Practice Bank',
                      style: GoogleFonts.inter(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '20 audio dialogues with illustrated answer choices',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.ink500,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatPill('20 Total', 'Questions', LucideIcons.fileQuestion),
              const SizedBox(width: 8),
              _buildStatPill('2 Sections', 'Task & Point', LucideIcons.layers),
              const SizedBox(width: 8),
              _buildStatPill(
                mockBest != null ? '$mockBest / 20' : '-- / 20',
                'Exam Best',
                LucideIcons.trophy,
                isHighlight: mockBest != null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String top, String bottom, IconData icon,
      {bool isHighlight = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
        decoration: BoxDecoration(
          color: isHighlight ? const Color(0xFFFFFBEB) : AppColors.cardAlt,
          gradient: isHighlight
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFFDF5), Color(0xFFFEF3C7)],
                )
              : null,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isHighlight ? const Color(0xFFF59E0B) : AppColors.ink200,
            width: isHighlight ? 1.3 : 1.0,
          ),
          boxShadow: isHighlight
              ? [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withOpacity(0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 13,
                  color:
                      isHighlight ? const Color(0xFFD97706) : AppColors.ink700,
                ),
                const SizedBox(width: 4),
                Text(
                  top,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isHighlight
                        ? const Color(0xFFB45309)
                        : AppColors.ink900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 1),
            Text(
              bottom,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isHighlight ? const Color(0xFFB45309) : AppColors.ink500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Mode Card ──────────────────────────────────────────────────────────────
  Widget _buildModeCard(_ListeningModeCardModel model, {int? bestScore}) {
    final bool hasBest = bestScore != null;

    if (model.isFeatured) {
      return BouncingWidget(
        scaleFactor: 0.98,
        onTap: () => _openPractice(model.mode, model.title),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primaryBorder, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.1),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Featured Header Strip (Clean, without sparkle icon)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: const BoxDecoration(
                  gradient: AppGradients.primaryHeader,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(22),
                    topRight: Radius.circular(22),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      model.badgeText,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      model.japaneseTitle,
                      style: JapaneseFontService().getJapaneseTextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withOpacity(0.95),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: AppGradients.primaryHeader,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(model.icon,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                model.title,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                model.subtitle,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      model.description,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.ink700,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Bottom Row: Fixed overflow & standardized dimensions
                    Row(
                      children: [
                        _buildTag(
                            '${model.questionCount} Qs',
                            LucideIcons.helpCircle),
                        const SizedBox(width: 6),
                        if (hasBest)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: const Color(0xFFF59E0B), width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFF59E0B).withOpacity(0.14),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.trophy,
                                    size: 12, color: Color(0xFFD97706)),
                                const SizedBox(width: 4),
                                Text(
                                  'Best: $bestScore/${model.questionCount}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF92400E),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          _buildTag(model.estimatedTime, LucideIcons.clock),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 11, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: AppGradients.primaryHeader,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.25),
                                blurRadius: 4,
                                offset: const Offset(0, 1.5),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                hasBest ? 'Retake' : 'Start',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(LucideIcons.arrowRight,
                                  size: 13, color: Colors.white),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Standard Mode Cards (Section 1, Section 2, Quick Drill)
    return BouncingWidget(
      scaleFactor: 0.98,
      onTap: () => _openPractice(model.mode, model.title),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: model.borderColor, width: 1.5),
          boxShadow: AppShadows.subtle,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: model.lightBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: model.borderColor),
                  ),
                  child: Icon(model.icon,
                      color: model.accentColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Expanded(
                            child: Text(
                              model.title,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            model.japaneseTitle,
                            style: JapaneseFontService().getJapaneseTextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: model.accentColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        model.subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.ink500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              model.description,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: AppColors.ink700,
                fontWeight: FontWeight.w400,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildTag(
                    '${model.questionCount} Qs', LucideIcons.helpCircle),
                const SizedBox(width: 6),
                _buildTag(model.estimatedTime, LucideIcons.clock),
                const Spacer(),
                if (hasBest)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: model.lightBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: model.borderColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.checkCheck,
                            size: 13, color: model.accentColor),
                        const SizedBox(width: 4),
                        Text(
                          'Best: $bestScore/${model.questionCount}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: model.accentColor,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Icon(LucideIcons.chevronRight,
                      size: 20, color: Colors.grey.shade400),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.ink200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.ink500),
          const SizedBox(width: 4),
          Text(
            text,
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

  // ── Strategy Tip Card ──────────────────────────────────────────────────────
  Widget _buildStrategiesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(LucideIcons.lightbulb,
                color: Color(0xFF16A34A), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'JLPT Choukai Tip',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF166534),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'In Task Comprehension (問題1), preview all 4 illustrations during the introductory pause to identify key visual differences before the dialogue starts.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF15803D),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
