import 'package:flutter/material.dart';

import '../widgets/bottom_nav.dart';
import 'games_screen.dart';
import 'home_screen.dart';
import 'lessons_screen.dart';
import 'profile_screen.dart';
import 'stats_screen.dart';
import '../services/analytics_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late final PageController _pageController;
  late final List<Widget> _screens;
  final List<List<Color>> _backgroundPalettes = const [
    [Color(0xFFFFF4F7), Color(0xFFFFE4EC), Color(0xFFFDE7F3)],
    [Color(0xFFF8F7FF), Color(0xFFEFE9FF), Color(0xFFE8F2FF)],
    [Color(0xFFFFF8F1), Color(0xFFFFEAD9), Color(0xFFFFF1E2)],
    [Color(0xFFF3FAFF), Color(0xFFE1F1FF), Color(0xFFE8ECFF)],
    [Color(0xFFFFF7FA), Color(0xFFFCE7F3), Color(0xFFF5F3FF)],
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _screens = [
      KeepAliveWrapper(child: HomeScreen(onTabChange: _changeTab)),
      const KeepAliveWrapper(child: LessonsScreen()),
      const KeepAliveWrapper(child: GamesScreen()),
      const KeepAliveWrapper(child: StatsScreen()),
      const KeepAliveWrapper(child: ProfileScreen()),
    ];

    // Log initial screen
    _logScreen(_currentIndex);
  }

  void _changeTab(int index) {
    if (!mounted || index == _currentIndex) {
      return;
    }

    final distance = (index - _currentIndex).abs();
    final duration = Duration(milliseconds: 220 + (distance * 35));

    _pageController.animateToPage(
      index,
      duration: duration,
      curve: Curves.easeInOutCubicEmphasized,
    );

    setState(() {
      _currentIndex = index;
    });

    _logScreen(index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: _buildParallaxBackdrop(context),
            ),
          ),
          PageView(
            controller: _pageController,
            physics: const PageScrollPhysics(),
            allowImplicitScrolling: true,
            onPageChanged: (index) {
              if (!mounted) {
                return;
              }

              setState(() {
                _currentIndex = index;
              });

              _logScreen(index);
            },
            children: _screens
                .map(
                  (screen) => RepaintBoundary(
                    child: screen,
                  ),
                )
                .toList(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: _currentIndex,
        onTap: _changeTab,
      ),
    );
  }

  double get _currentPageValue {
    if (_pageController.hasClients && _pageController.position.hasContentDimensions) {
      return _pageController.page ?? _currentIndex.toDouble();
    }
    return _currentIndex.toDouble();
  }

  Widget _buildParallaxBackdrop(BuildContext context) {
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, _) {
        final page = _currentPageValue;
        final lowerIndex = page.floor().clamp(0, _backgroundPalettes.length - 1);
        final upperIndex = (lowerIndex + 1).clamp(0, _backgroundPalettes.length - 1);
        final progress = (page - lowerIndex).clamp(0.0, 1.0);

        final startColor = Color.lerp(
          _backgroundPalettes[lowerIndex][0],
          _backgroundPalettes[upperIndex][0],
          progress,
        )!;
        final middleColor = Color.lerp(
          _backgroundPalettes[lowerIndex][1],
          _backgroundPalettes[upperIndex][1],
          progress,
        )!;
        final endColor = Color.lerp(
          _backgroundPalettes[lowerIndex][2],
          _backgroundPalettes[upperIndex][2],
          progress,
        )!;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [startColor, middleColor, endColor],
            ),
          ),
          child: Stack(
            children: [
              _buildParallaxShape(
                page: page,
                top: -70,
                left: -60,
                size: 220,
                xShift: -16,
                yShift: 6,
                colors: [
                  const Color(0xFFFFB6CF).withOpacity(0.48),
                  const Color(0xFFFFD9E8).withOpacity(0.10),
                ],
              ),
              _buildParallaxShape(
                page: page,
                top: 90,
                right: -40,
                size: 200,
                xShift: 18,
                yShift: -8,
                colors: [
                  const Color(0xFFC7B8FF).withOpacity(0.38),
                  const Color(0xFFE8E1FF).withOpacity(0.08),
                ],
              ),
              _buildParallaxShape(
                page: page,
                bottom: 120,
                left: 30,
                size: 180,
                xShift: -10,
                yShift: 12,
                colors: [
                  const Color(0xFFFFC88E).withOpacity(0.34),
                  const Color(0xFFFFE7C5).withOpacity(0.10),
                ],
              ),
              _buildParallaxShape(
                page: page,
                bottom: -30,
                right: 25,
                size: 220,
                xShift: 14,
                yShift: 8,
                colors: [
                  const Color(0xFFA5D8FF).withOpacity(0.30),
                  const Color(0xFFDDF0FF).withOpacity(0.08),
                ],
              ),
              IgnorePointer(
                child: Opacity(
                  opacity: 0.08,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.55),
                          Colors.transparent,
                          Colors.white.withOpacity(0.2),
                        ],
                      ),
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildParallaxShape({
    required double page,
    double? top,
    double? left,
    double? right,
    double? bottom,
    required double size,
    required double xShift,
    required double yShift,
    required List<Color> colors,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Transform.translate(
        offset: Offset(page * xShift, page * yShift),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: colors,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.first.withOpacity(0.18),
                blurRadius: 34,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _logScreen(int index) {
    const names = ['Home', 'Lessons', 'Games', 'Stats', 'Profile'];
    if (index >= 0 && index < names.length) {
      final analytics = AnalyticsService();
      analytics.logScreen(names[index]);
      analytics.logTabView(names[index]);
    }
  }
}

class KeepAliveWrapper extends StatefulWidget {
  final Widget child;

  const KeepAliveWrapper({Key? key, required this.child}) : super(key: key);

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper> with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}
