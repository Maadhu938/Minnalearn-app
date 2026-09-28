import 'package:flutter/material.dart';

class AnimatedProgressBar extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final double height;
  final Color backgroundColor;
  final Color foregroundColor;
  final LinearGradient? gradient;
  final BorderRadius? borderRadius;
  final Duration duration;
  final Curve curve;

  const AnimatedProgressBar({
    Key? key,
    required this.value,
    this.height = 8,
    this.backgroundColor = const Color(0xFFF1F5F9),
    this.foregroundColor = const Color(0xFFE11D48),
    this.gradient,
    this.borderRadius,
    this.duration = const Duration(milliseconds: 700),
    this.curve = Curves.easeOutCubic,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final clampedValue = value.clamp(0.0, 1.0);
    final radius = borderRadius ?? BorderRadius.circular(height / 2);

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: radius,
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: clampedValue),
                duration: duration,
                curve: curve,
                builder: (context, animValue, _) {
                  return FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: animValue,
                    child: Container(
                      decoration: BoxDecoration(
                        color: gradient == null ? foregroundColor : null,
                        gradient: gradient,
                        borderRadius: radius,
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
