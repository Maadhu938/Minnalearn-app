import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/pro_entitlement_service.dart';
import '../widgets/bouncing_widget.dart';

class ProUpgradeScreen extends StatefulWidget {
  const ProUpgradeScreen({Key? key}) : super(key: key);

  @override
  State<ProUpgradeScreen> createState() => _ProUpgradeScreenState();
}

class _ProUpgradeScreenState extends State<ProUpgradeScreen> {
  int _selectedPlanIndex = 0; // 0: Lifetime ($9.99), 1: Monthly ($2.99)
  bool _isProcessing = false;

  final List<Map<String, dynamic>> _plans = [
    {
      'title': 'Lifetime Pass',
      'price': '\$9.99',
      'period': 'One-time payment',
      'tag': 'BEST VALUE',
      'isBestValue': true,
    },
    {
      'title': 'Monthly Plan',
      'price': '\$2.99',
      'period': 'per month',
      'tag': 'FLEXIBLE',
      'isBestValue': false,
    },
  ];

  final List<Map<String, dynamic>> _features = [
    {
      'icon': Icons.menu_book_rounded,
      'iconColor': Color(0xFFE11D48),
      'iconBg': Color(0xFFFFEEF3),
      'title': 'Complete JLPT N5 & N4 Curriculum',
      'desc': 'All vocabulary, sentence patterns, grammar lessons & dialogues unlocked',
    },
    {
      'icon': Icons.edit_note_rounded,
      'iconColor': Color(0xFFD97706),
      'iconBg': Color(0xFFFEF3C7),
      'title': '200 Kanji Stroke Tracing & Order',
      'desc': 'Interactive animations, numbered stroke order & practice quizzes',
    },
    {
      'icon': Icons.block_rounded,
      'iconColor': Color(0xFFE11D48),
      'iconBg': Color(0xFFFFE4E6),
      'title': '100% Ad-Free Learning',
      'desc': 'Zero interruptions, focus completely on Japanese',
    },
    {
      'icon': Icons.cloud_download_rounded,
      'iconColor': Color(0xFF0284C7),
      'iconBg': Color(0xFFE0F2FE),
      'title': 'Offline Study Mode',
      'desc': 'Download lessons, vocab, kanji and practice anywhere',
    },
    {
      'icon': Icons.sports_esports_rounded,
      'iconColor': Color(0xFF9333EA),
      'iconBg': Color(0xFFF3E8FF),
      'title': 'Games & Achievements',
      'desc': 'Stay motivated with fun games and exclusive PRO achievements',
    },
  ];

  Future<void> _handlePurchase() async {
    setState(() {
      _isProcessing = true;
    });

    HapticFeedback.mediumImpact();
    // Simulate transaction
    await Future.delayed(const Duration(milliseconds: 700));

    await ProEntitlementService().setProStatus(true);

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE11D48), width: 1.2),
        ),
        content: Row(
          children: [
            Image.asset(
              'assets/crown_pro.png',
              width: 24,
              height: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'MinnaLearn PRO Activated! All lessons and kanji unlocked.',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Navigator.of(context).pop(true);
  }

  Future<void> _handleRestore() async {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          'Purchases restored successfully.',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAlreadyPro = ProEntitlementService().isPro;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF0F5),
              Color(0xFFFFF7FA),
              Colors.white,
            ],
            stops: [0.0, 0.35, 0.75],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Top Bar with Back Button
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 4),
                child: Row(
                  children: [
                    BouncingWidget(
                      scaleFactor: 0.92,
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Color(0xFF0F172A),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero Header with Mascot
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Mascot placed on the right
                          Positioned(
                            top: -16,
                            right: -10,
                            width: 175,
                            height: 200,
                            child: Image.asset(
                              'assets/mascot_pro_crown.png',
                              fit: BoxFit.contain,
                              alignment: Alignment.topRight,
                            ),
                          ),

                          // Text Content on Left
                          Padding(
                            padding: const EdgeInsets.only(right: 145),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isAlreadyPro
                                        ? const Color(0xFFDCFCE7)
                                        : const Color(0xFFFFEEF3),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Image.asset(
                                        'assets/crown_pro.png',
                                        width: 14,
                                        height: 14,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        isAlreadyPro ? 'PRO ACTIVE' : 'PREMIUM ACCESS',
                                        style: GoogleFonts.inter(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                          color: isAlreadyPro
                                              ? const Color(0xFF16A34A)
                                              : const Color(0xFFE11D48),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  isAlreadyPro
                                      ? 'MinnaLearn PRO\nActivated!'
                                      : 'Master Japanese to\nJLPT N4',
                                  style: GoogleFonts.inter(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF0F172A),
                                    height: 1.18,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  isAlreadyPro
                                      ? 'You have lifetime unlocked access to all 50 lessons, kanji tracing, and ad-free immersion.'
                                      : 'Unlock all 50 lessons, interactive kanji stroke order tracing, and study with 100% ad-free immersion.',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    color: const Color(0xFF64748B),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // If already PRO: Show Active Banner
                      if (isAlreadyPro) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF86EFAC),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF16A34A),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Lifetime PRO Membership Active',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF14532D),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'All JLPT N5 & N4 features are completely unlocked.',
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        color: const Color(0xFF166534),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ] else ...[
                        // Select Plan Section (Only shown to free users!)
                        Text(
                          'Select Plan',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Plan Cards Row
                        Row(
                          children: List.generate(_plans.length, (index) {
                            final plan = _plans[index];
                            final isSelected = _selectedPlanIndex == index;

                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: index == 0 ? 6 : 0,
                                  left: index == 1 ? 6 : 0,
                                ),
                                child: BouncingWidget(
                                  scaleFactor: 0.96,
                                  onTap: () {
                                    setState(() {
                                      _selectedPlanIndex = index;
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFFE11D48)
                                            : const Color(0xFFF1F5F9),
                                        width: isSelected ? 2 : 1.5,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: const Color(0xFFE11D48)
                                                    .withOpacity(0.10),
                                                blurRadius: 14,
                                                offset: const Offset(0, 4),
                                              ),
                                            ]
                                          : [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.02),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Top row with Tag and Selector
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 3.5,
                                              ),
                                              decoration: BoxDecoration(
                                                color: plan['isBestValue']
                                                    ? const Color(0xFFE11D48)
                                                    : const Color(0xFFF1F5F9),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                plan['tag'],
                                                style: GoogleFonts.inter(
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w800,
                                                  color: plan['isBestValue']
                                                      ? Colors.white
                                                      : const Color(0xFF64748B),
                                                ),
                                              ),
                                            ),
                                            Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: isSelected
                                                    ? const Color(0xFFE11D48)
                                                    : Colors.transparent,
                                                border: Border.all(
                                                  color: isSelected
                                                      ? const Color(0xFFE11D48)
                                                      : const Color(0xFFCBD5E1),
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: isSelected
                                                  ? const Icon(
                                                      Icons.check_rounded,
                                                      size: 13,
                                                      color: Colors.white,
                                                    )
                                                  : null,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                        Text(
                                          plan['title'],
                                          style: GoogleFonts.inter(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          plan['price'],
                                          style: GoogleFonts.inter(
                                            fontSize: 25,
                                            fontWeight: FontWeight.w900,
                                            color: plan['isBestValue']
                                                ? const Color(0xFFE11D48)
                                                : const Color(0xFF0F172A),
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          plan['period'],
                                          style: GoogleFonts.inter(
                                            fontSize: 11.5,
                                            color: const Color(0xFF94A3B8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // What is Included in PRO Section
                      Text(
                        isAlreadyPro ? 'Your Unlocked Features' : 'What is Included in PRO',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: const Color(0xFFF1F5F9),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.025),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: List.generate(_features.length, (index) {
                            final f = _features[index];
                            final isLast = index == _features.length - 1;

                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          color: f['iconBg'] as Color,
                                          borderRadius:
                                              BorderRadius.circular(13),
                                        ),
                                        child: Icon(
                                          f['icon'] as IconData,
                                          color: f['iconColor'] as Color,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              f['title'] as String,
                                              style: GoogleFonts.inter(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w800,
                                                color: const Color(0xFF0F172A),
                                              ),
                                            ),
                                            const SizedBox(height: 2.5),
                                            Text(
                                              f['desc'] as String,
                                              style: GoogleFonts.inter(
                                                fontSize: 11.5,
                                                color: const Color(0xFF64748B),
                                                height: 1.35,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        isAlreadyPro
                                            ? Icons.check_circle_rounded
                                            : Icons.chevron_right_rounded,
                                        color: isAlreadyPro
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFFCBD5E1),
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isLast)
                                  const Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: Color(0xFFF8FAFC),
                                  ),
                              ],
                            );
                          }),
                        ),
                      ),

                      const SizedBox(height: 20),

                      if (!isAlreadyPro)
                        Center(
                          child: TextButton(
                            onPressed: _handleRestore,
                            child: Text(
                              'Restore Purchases',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 80), // Padding for sticky bottom button
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // Bottom Sticky Upgrade Button
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: isAlreadyPro
                  ? () => Navigator.pop(context)
                  : (_isProcessing ? null : _handlePurchase),
              style: ElevatedButton.styleFrom(
                backgroundColor: isAlreadyPro
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFE11D48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                elevation: 0,
                shadowColor: (isAlreadyPro
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFE11D48))
                    .withOpacity(0.35),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isAlreadyPro ? 'PRO Active — Continue Learning' : 'Upgrade Now',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isAlreadyPro
                                ? Icons.check_rounded
                                : Icons.chevron_right_rounded,
                            color: isAlreadyPro
                                ? const Color(0xFF0F172A)
                                : const Color(0xFFE11D48),
                            size: 19,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
