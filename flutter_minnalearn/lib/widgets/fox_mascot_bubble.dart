import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum FoxMood {
  neutral,
  happy,
  encouraging,
  thinking,
  celebrate,
}

/// A friendly Fox Mascot widget with a seamless speech bubble.
/// Inspires and cheers Japanese language learners Duolingo-style.
class FoxMascotBubble extends StatefulWidget {
  final String message;
  final FoxMood mood;
  final bool animate;
  final double foxSize;
  final Widget? trailing;
  final VoidCallback? onFoxTap;

  const FoxMascotBubble({
    Key? key,
    required this.message,
    this.mood = FoxMood.neutral,
    this.animate = true,
    this.foxSize = 52,
    this.trailing,
    this.onFoxTap,
  }) : super(key: key);

  @override
  State<FoxMascotBubble> createState() => _FoxMascotBubbleState();
}

class _FoxMascotBubbleState extends State<FoxMascotBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -5.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -5.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
    ]).animate(_bounceController);

    if (widget.animate) {
      _bounceController.repeat();
    }
  }

  @override
  void didUpdateWidget(FoxMascotBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _bounceController.repeat();
      } else {
        _bounceController.stop();
        _bounceController.reset();
      }
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  Color _getBubbleBg() {
    switch (widget.mood) {
      case FoxMood.happy:
        return const Color(0xFFECFDF5); // Emerald light
      case FoxMood.encouraging:
        return const Color(0xFFFFF1F2); // Rose light
      case FoxMood.celebrate:
        return const Color(0xFFFEF3C7); // Amber light
      case FoxMood.thinking:
        return const Color(0xFFEFF6FF); // Sky blue light
      case FoxMood.neutral:
      default:
        return Colors.white;
    }
  }

  Color _getBubbleBorder() {
    switch (widget.mood) {
      case FoxMood.happy:
        return const Color(0xFF10B981);
      case FoxMood.encouraging:
        return const Color(0xFFF43F5E);
      case FoxMood.celebrate:
        return const Color(0xFFF59E0B);
      case FoxMood.thinking:
        return const Color(0xFF38BDF8);
      case FoxMood.neutral:
      default:
        return const Color(0xFFCBD5E1);
    }
  }

  Color _getShadowColor() {
    return _getBubbleBorder().withOpacity(0.35);
  }

  Color _getTextColor() {
    switch (widget.mood) {
      case FoxMood.happy:
        return const Color(0xFF065F46);
      case FoxMood.encouraging:
        return const Color(0xFF9F1239);
      case FoxMood.celebrate:
        return const Color(0xFF92400E);
      case FoxMood.thinking:
        return const Color(0xFF0369A1);
      case FoxMood.neutral:
      default:
        return const Color(0xFF1E293B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bubbleBg = _getBubbleBg();
    final bubbleBorder = _getBubbleBorder();
    final shadowColor = _getShadowColor();
    final textColor = _getTextColor();
    const double tailWidth = 9.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Fox Mascot Avatar
        GestureDetector(
          onTap: widget.onFoxTap,
          child: AnimatedBuilder(
            animation: _bounceAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, widget.animate ? _bounceAnimation.value : 0),
                child: child,
              );
            },
            child: Container(
              width: widget.foxSize,
              height: widget.foxSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFF2EB),
                    Color(0xFFFFEDD5),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFFFDBA74),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEA580C).withOpacity(0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '🦊',
                  style: TextStyle(
                    fontSize: widget.foxSize * 0.56,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 4),

        // Seamless Speech Bubble (Pointer + Box as single continuous path)
        Expanded(
          child: CustomPaint(
            painter: _SeamlessBubblePainter(
              fillColor: bubbleBg,
              borderColor: bubbleBorder,
              shadowColor: shadowColor,
              tailWidth: tailWidth,
              tailHeight: 12.0,
              radius: 16.0,
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                left: tailWidth + 12,
                right: 12,
                top: 10,
                bottom: 10,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.message,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        height: 1.3,
                      ),
                    ),
                  ),
                  if (widget.trailing != null) ...[
                    const SizedBox(width: 8),
                    widget.trailing!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom painter that renders the speech bubble AND pointer tail
/// as ONE CONTINUOUS SHAPE with ZERO seams, zero gap, and zero line slicing.
class _SeamlessBubblePainter extends CustomPainter {
  final Color fillColor;
  final Color borderColor;
  final Color shadowColor;
  final double tailWidth;
  final double tailHeight;
  final double radius;

  _SeamlessBubblePainter({
    required this.fillColor,
    required this.borderColor,
    required this.shadowColor,
    required this.tailWidth,
    required this.tailHeight,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= tailWidth || size.height <= 0) return;

    final effectiveRadius = radius.clamp(2.0, (size.height / 2) - 1.0);
    final effectiveTailHeight = tailHeight.clamp(6.0, (size.height - (effectiveRadius * 2)).clamp(4.0, size.height));
    final rect = Rect.fromLTWH(tailWidth, 0, size.width - tailWidth, size.height);
    final tailCenterY = size.height / 2;
    final minTailY = effectiveRadius;
    final maxTailY = size.height - effectiveRadius - effectiveTailHeight;
    final double tailTopY;
    if (maxTailY >= minTailY) {
      tailTopY = (tailCenterY - (effectiveTailHeight / 2)).clamp(minTailY, maxTailY);
    } else {
      tailTopY = (size.height - effectiveTailHeight) / 2;
    }
    final tailBottomY = tailTopY + effectiveTailHeight;

    try {
      final path = Path();
      // Start at top-left of rounded box
      path.moveTo(rect.left + effectiveRadius, rect.top);
      // Top edge to top-right
      path.lineTo(rect.right - effectiveRadius, rect.top);
      path.arcToPoint(Offset(rect.right, rect.top + effectiveRadius), radius: Radius.circular(effectiveRadius));
      // Right edge to bottom-right
      path.lineTo(rect.right, rect.bottom - effectiveRadius);
      path.arcToPoint(Offset(rect.right - effectiveRadius, rect.bottom), radius: Radius.circular(effectiveRadius));
      // Bottom edge to bottom-left
      path.lineTo(rect.left + effectiveRadius, rect.bottom);
      path.arcToPoint(Offset(rect.left, rect.bottom - effectiveRadius), radius: Radius.circular(effectiveRadius));
      // Left edge up to bottom of tail
      path.lineTo(rect.left, tailBottomY);
      // Point outwards to left!
      path.lineTo(0, tailCenterY);
      // Return to top of tail
      path.lineTo(rect.left, tailTopY);
      // Left edge up to top-left corner
      path.lineTo(rect.left, rect.top + effectiveRadius);
      path.arcToPoint(Offset(rect.left + effectiveRadius, rect.top), radius: Radius.circular(effectiveRadius));
      path.close();

      // 1. Draw 3D bottom shadow (Offset 0, 3)
      final shadowPaint = Paint()
        ..color = shadowColor
        ..style = PaintingStyle.fill;
      canvas.save();
      canvas.translate(0, 3);
      canvas.drawPath(path, shadowPaint);
      canvas.restore();

      // 2. Draw Fill
      final fillPaint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);

      // 3. Draw Continuous Stroke Border
      final borderPaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, borderPaint);
    } catch (_) {
      final fallbackRRect = RRect.fromRectAndRadius(rect, Radius.circular(effectiveRadius));
      canvas.drawRRect(fallbackRRect, Paint()..color = fillColor);
      canvas.drawRRect(
        fallbackRRect,
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SeamlessBubblePainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.shadowColor != shadowColor;
  }
}
