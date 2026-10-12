import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/kanji_stroke_dictionary.dart';
import '../utils/app_theme.dart';
import '../services/audio_service.dart';

enum TracingMode {
  guided,
  freehand,
}

class KanjiTracingBoard extends StatefulWidget {
  final String character;
  final TracingMode mode;
  final bool showNumbers;
  final double ghostOpacity;
  final VoidCallback? onStrokeCompleted;
  final VoidCallback? onKanjiMastered;
  final ValueChanged<int>? onActiveStrokeChanged;
  final VoidCallback? onInteractionStarted;
  final VoidCallback? onInteractionEnded;

  const KanjiTracingBoard({
    Key? key,
    required this.character,
    this.mode = TracingMode.guided,
    this.showNumbers = true,
    this.ghostOpacity = 0.35,
    this.onStrokeCompleted,
    this.onKanjiMastered,
    this.onActiveStrokeChanged,
    this.onInteractionStarted,
    this.onInteractionEnded,
  }) : super(key: key);

  @override
  State<KanjiTracingBoard> createState() => KanjiTracingBoardState();
}

class KanjiTracingBoardState extends State<KanjiTracingBoard>
    with TickerProviderStateMixin {
  late KanjiStrokeData _strokeData;
  int _currentStrokeIndex = 0;
  final List<List<Offset>> _userStrokes = [];
  List<Offset> _currentDrawing = [];
  final Set<int> _completedStrokeIndices = {};

  // Animation controller for "Watch / Animate Stroke Order"
  late AnimationController _demoController;
  late Animation<double> _demoProgress;
  bool _isDemonstrating = false;
  int _demoCurrentStroke = 0;

  // Pulse animation for active stroke start indicator
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _loadStrokeData();

    _demoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _demoProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _demoController, curve: Curves.easeInOut),
    );

    _demoController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (_demoCurrentStroke < _strokeData.strokes.length - 1) {
          Future.delayed(const Duration(milliseconds: 250), () {
            if (mounted && _isDemonstrating) {
              setState(() {
                _demoCurrentStroke++;
              });
              _demoController.forward(from: 0.0);
            }
          });
        } else {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              setState(() {
                _isDemonstrating = false;
              });
            }
          });
        }
      }
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant KanjiTracingBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.character != widget.character) {
      reset();
      _loadStrokeData();
    }
  }

  void _loadStrokeData() {
    _strokeData = KanjiStrokeDictionary.getStrokeData(widget.character);
    _currentStrokeIndex = 0;
    _completedStrokeIndices.clear();
    widget.onActiveStrokeChanged?.call(_currentStrokeIndex);
  }

  @override
  void dispose() {
    _demoController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  /// Start animated stroke order walkthrough
  void playDemonstration() {
    setState(() {
      _isDemonstrating = true;
      _demoCurrentStroke = 0;
    });
    _demoController.forward(from: 0.0);
  }

  void stopDemonstration() {
    _demoController.stop();
    setState(() {
      _isDemonstrating = false;
    });
  }

  void reset() {
    setState(() {
      _userStrokes.clear();
      _currentDrawing.clear();
      _completedStrokeIndices.clear();
      _currentStrokeIndex = 0;
      _isDemonstrating = false;
    });
    _demoController.reset();
    widget.onActiveStrokeChanged?.call(_currentStrokeIndex);
  }

  void undo() {
    if (_userStrokes.isNotEmpty) {
      setState(() {
        _userStrokes.removeLast();
        if (_completedStrokeIndices.isNotEmpty) {
          final lastCompleted = _completedStrokeIndices.last;
          _completedStrokeIndices.remove(lastCompleted);
          _currentStrokeIndex = lastCompleted;
          widget.onActiveStrokeChanged?.call(_currentStrokeIndex);
        }
      });
    }
  }

  int get currentStrokeOrder => _currentStrokeIndex + 1;
  int get totalStrokes => _strokeData.strokeCount;
  bool get isCompleted => _completedStrokeIndices.length >= _strokeData.strokes.length;

  void _onPointerDown(PointerDownEvent event, Size canvasSize) {
    if (_isDemonstrating) stopDemonstration();
    widget.onInteractionStarted?.call();

    setState(() {
      _currentDrawing = [event.localPosition];
    });
  }

  void _onPointerCancel(PointerCancelEvent event) {
    widget.onInteractionEnded?.call();
    setState(() {
      _currentDrawing.clear();
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    setState(() {
      _currentDrawing.add(event.localPosition);
    });
  }

  void _onPointerUp(PointerUpEvent event, Size canvasSize) {
    if (_currentDrawing.isEmpty) return;

    if (widget.mode == TracingMode.guided && !isCompleted) {
      _evaluateGuidedStroke(canvasSize);
    } else {
      setState(() {
        _userStrokes.add(List.from(_currentDrawing));
        _currentDrawing.clear();
      });
      AudioService().playClick();
      widget.onStrokeCompleted?.call();
    }
    widget.onInteractionEnded?.call();
  }

  /// Evaluates whether user's stroke accurately matches the active Kanji stroke
  void _evaluateGuidedStroke(Size canvasSize) {
    final targetStroke = _strokeData.strokes[_currentStrokeIndex];
    final targetStart = Offset(
      targetStroke.start.dx * canvasSize.width,
      targetStroke.start.dy * canvasSize.height,
    );
    final targetEnd = Offset(
      targetStroke.end.dx * canvasSize.width,
      targetStroke.end.dy * canvasSize.height,
    );

    final userStart = _currentDrawing.first;
    final userEnd = _currentDrawing.last;

    final startDistance = (userStart - targetStart).distance;
    final endDistance = (userEnd - targetEnd).distance;

    // Forgiving tolerance threshold (65 physical pixels)
    final double tolerance = canvasSize.width * 0.28;

    final bool isStartValid = startDistance <= tolerance;
    final bool isEndValid = endDistance <= tolerance;

    if (isStartValid && isEndValid && _currentDrawing.length >= 2) {
      // Stroke matched successfully!
      setState(() {
        _completedStrokeIndices.add(_currentStrokeIndex);
        _userStrokes.add(List.from(_currentDrawing));
        _currentDrawing.clear();
        _currentStrokeIndex++;
      });

      AudioService().playClick();
      widget.onStrokeCompleted?.call();
      widget.onActiveStrokeChanged?.call(_currentStrokeIndex);

      if (isCompleted) {
        AudioService().playCorrect();
        widget.onKanjiMastered?.call();
      }
    } else {
      // Soft hint stroke clear
      setState(() {
        _currentDrawing.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double size = math.min(constraints.maxWidth, constraints.maxHeight);
        final canvasSize = Size(size, size);

        return Center(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.ink200, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Traditional Calligraphy Rice Paper Grid (田字格)
                  CustomPaint(
                    size: canvasSize,
                    painter: _RiceGridPainter(),
                  ),

                  // 2. WriteJapanese / Duolingo Stroke Tracing & Animation Engine (Single Soft Grey Shade, 100% Coincidence)
                  AnimatedBuilder(
                    animation: Listenable.merge([_pulseController, _demoController]),
                    builder: (context, _) {
                      return CustomPaint(
                        size: canvasSize,
                        painter: _WriteJapaneseTracingPainter(
                          strokeData: _strokeData,
                          ghostOpacity: widget.ghostOpacity,
                          currentStrokeIndex: _currentStrokeIndex,
                          completedStrokeIndices: _completedStrokeIndices,
                          showNumbers: widget.showNumbers,
                          isGuidedMode: widget.mode == TracingMode.guided,
                          pulseValue: _pulseController.value,
                          isDemonstrating: _isDemonstrating,
                          demoCurrentStroke: _demoCurrentStroke,
                          demoProgress: _demoProgress.value,
                        ),
                      );
                    },
                  ),

                  // 4. User Inking Canvas with EagerGestureRecognizer to prevent parent scroll
                  RawGestureDetector(
                    behavior: HitTestBehavior.opaque,
                    gestures: {
                      EagerGestureRecognizer: GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(
                        () => EagerGestureRecognizer(),
                        (EagerGestureRecognizer instance) {},
                      ),
                    },
                    child: Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: (e) => _onPointerDown(e, canvasSize),
                      onPointerMove: _onPointerMove,
                      onPointerUp: (e) => _onPointerUp(e, canvasSize),
                      onPointerCancel: _onPointerCancel,
                      child: CustomPaint(
                        size: canvasSize,
                        painter: _UserStrokesPainter(
                          userStrokes: _userStrokes,
                          currentDrawing: _currentDrawing,
                        ),
                      ),
                    ),
                  ),

                  // 5. Demonstrating Indicator (Compact floating chip in top-right)
                  if (_isDemonstrating)
                    Positioned(
                      top: 10,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primaryBorder, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Stroke ${_demoCurrentStroke + 1} of ${_strokeData.strokeCount}',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}



/// Calligraphy Rice Paper Grid Painter (田字格)
class _RiceGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final dashPaint = Paint()
      ..color = const Color(0xFFCBD5E1).withOpacity(0.6)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Outer frame
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), borderPaint);

    // Crosshair dashed guidelines
    _drawDashedLine(canvas, Offset(0, size.height / 2), Offset(size.width, size.height / 2), dashPaint);
    _drawDashedLine(canvas, Offset(size.width / 2, 0), Offset(size.width / 2, size.height), dashPaint);

    // Subtle diagonal dashed guidelines
    final diagonalPaint = Paint()
      ..color = const Color(0xFFE2E8F0).withOpacity(0.4)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    _drawDashedLine(canvas, Offset.zero, Offset(size.width, size.height), diagonalPaint, dash: 4, gap: 6);
    _drawDashedLine(canvas, Offset(size.width, 0), Offset(0, size.height), diagonalPaint, dash: 4, gap: 6);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint, {double dash = 5, double gap = 4}) {
    final double distance = (end - start).distance;
    final Offset step = (end - start) / distance;
    double current = 0;
    while (current < distance) {
      final double next = math.min(current + dash, distance);
      canvas.drawLine(start + step * current, start + step * next, paint);
      current += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// WriteJapanese / Duolingo-style Kanji Tracing & Animation Engine:
/// - Single clean ghost stroke track in soft grey (#E2E8F0) (Zero double-shades, zero artifacts)
/// - Red animated stroke order walkthrough ("Watch" mode) matching WriteJapanese.com exactly
/// - Guided tracing with pulsing start badge, direction guide, and instant auto-snap to solid black
/// - 100% path coincidence across all Kanji characters
class _WriteJapaneseTracingPainter extends CustomPainter {
  final KanjiStrokeData strokeData;
  final double ghostOpacity;
  final int currentStrokeIndex;
  final Set<int> completedStrokeIndices;
  final bool showNumbers;
  final bool isGuidedMode;
  final double pulseValue;
  final bool isDemonstrating;
  final int demoCurrentStroke;
  final double demoProgress;

  _WriteJapaneseTracingPainter({
    required this.strokeData,
    required this.ghostOpacity,
    required this.currentStrokeIndex,
    required this.completedStrokeIndices,
    required this.showNumbers,
    required this.isGuidedMode,
    required this.pulseValue,
    required this.isDemonstrating,
    required this.demoCurrentStroke,
    required this.demoProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokes = strokeData.strokes;
    if (strokes.isEmpty) return;

    // Stroke width proportioned exactly like WriteJapanese / Duolingo (8.2% of canvas)
    final double strokeWidth = math.max(16.0, size.width * 0.082);

    // 1. GHOST STROKE TRACK (Single soft grey shade - Exactly like WriteJapanese)
    if (ghostOpacity > 0.0) {
      final ghostPaint = Paint()
        ..color = const Color(0xFFE2E8F0).withOpacity((ghostOpacity * 2.5).clamp(0.3, 0.95))
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      for (final stroke in strokes) {
        _drawStrokePath(canvas, size, stroke, 1.0, ghostPaint);
      }
    }

    // 2. DEMONSTRATION ANIMATION MODE ("Watch" - Exactly like WriteJapanese.com)
    if (isDemonstrating) {
      final completedDemoPaint = Paint()
        ..color = const Color(0xFF0F172A) // Solid black for strokes already finished
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final animatingPaint = Paint()
        ..color = const Color(0xFFEF4444) // Vibrant Red for current stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      // Draw all previous demo strokes in solid black (just like WriteJapanese image 2!)
      for (int i = 0; i < demoCurrentStroke; i++) {
        if (i < strokes.length) {
          _drawStrokePath(canvas, size, strokes[i], 1.0, completedDemoPaint);
        }
      }

      // Draw currently animating stroke in Red
      if (demoCurrentStroke < strokes.length) {
        final currentStroke = strokes[demoCurrentStroke];
        final currentTip = _drawStrokePath(canvas, size, currentStroke, demoProgress, animatingPaint);

        // Badge at start of current stroke with order number (like WriteJapanese image 2!)
        final startPx = Offset(currentStroke.start.dx * size.width, currentStroke.start.dy * size.height);
        _drawBadge(canvas, startPx, '${currentStroke.order}', const Color(0xFFEF4444), Colors.white);

        // Leading tip cursor
        if (currentTip != null) {
          canvas.drawCircle(currentTip, strokeWidth * 0.45, Paint()..color = const Color(0xFFEF4444));
          canvas.drawCircle(currentTip, strokeWidth * 0.22, Paint()..color = Colors.white);
        }
      }
    } else if (isGuidedMode) {
      // 3. GUIDED TRACING MODE
      // 3a. Completed user strokes: drawn in solid black
      if (completedStrokeIndices.isNotEmpty) {
        final completedPaint = Paint()
          ..color = const Color(0xFF0F172A)
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke;

        for (final idx in completedStrokeIndices) {
          if (idx < strokes.length) {
            _drawStrokePath(canvas, size, strokes[idx], 1.0, completedPaint);
          }
        }
      }

      // 3b. Active stroke:
      if (currentStrokeIndex < strokes.length) {
        final activeStroke = strokes[currentStrokeIndex];
        final startPx = Offset(activeStroke.start.dx * size.width, activeStroke.start.dy * size.height);

        // Dashed guide line following the authentic stroke polyline (like WriteJapanese!)
        final dashGuidePaint = Paint()
          ..color = const Color(0xFFEF4444).withOpacity(0.55)
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        _drawStrokeDashedGuide(canvas, size, activeStroke, dashGuidePaint);

        // Glowing Start Badge with stroke number
        final pulseHalo = 12.0 + (pulseValue * 5.0);
        canvas.drawCircle(startPx, pulseHalo, Paint()..color = const Color(0xFFEF4444).withOpacity(0.25));
        _drawBadge(canvas, startPx, '${activeStroke.order}', const Color(0xFFEF4444), Colors.white);
      }

      // 3c. Numbers on other upcoming strokes (if showNumbers == true)
      if (showNumbers) {
        for (int i = 0; i < strokes.length; i++) {
          if (i == currentStrokeIndex) continue;
          final stroke = strokes[i];
          final isCompleted = completedStrokeIndices.contains(i);
          final center = Offset(stroke.numberPosition.dx * size.width, stroke.numberPosition.dy * size.height);

          if (isCompleted) {
            _drawBadge(canvas, center, '✓', const Color(0xFF10B981), Colors.white, radius: 8.5);
          } else {
            _drawBadge(canvas, center, '${stroke.order}', const Color(0xFFE2E8F0), const Color(0xFF475569), radius: 8.5);
          }
        }
      }
    } else {
      // 4. FREEHAND MODE
      if (completedStrokeIndices.isNotEmpty) {
        final inkPaint = Paint()
          ..color = const Color(0xFF0F172A)
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke;

        for (final idx in completedStrokeIndices) {
          if (idx < strokes.length) {
            _drawStrokePath(canvas, size, strokes[idx], 1.0, inkPaint);
          }
        }
      }
    }
  }

  void _drawBadge(Canvas canvas, Offset center, String text, Color bg, Color textColor, {double radius = 10.0}) {
    canvas.drawCircle(center, radius + 1.5, Paint()..color = Colors.white..style = PaintingStyle.fill);
    canvas.drawCircle(center, radius, Paint()..color = bg..style = PaintingStyle.fill);

    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.outfit(
          color: textColor,
          fontSize: radius * 1.05,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, Offset(center.dx - (tp.width / 2), center.dy - (tp.height / 2)));
  }

  void _drawStrokeDashedGuide(Canvas canvas, Size size, KanjiStroke stroke, Paint dashPaint) {
    if (stroke.points.isEmpty) return;
    final pts = stroke.points;
    if (pts.length == 1) return;

    final path = Path();
    path.moveTo(pts.first.dx * size.width, pts.first.dy * size.height);
    for (int i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx * size.width, pts[i].dy * size.height);
    }

    for (final metric in path.computeMetrics()) {
      final totalLen = metric.length;
      if (totalLen <= 0) continue;

      // Draw dashed guideline strictly along the stroke's actual trajectory
      double current = 0.0;
      const double dash = 5.0;
      const double gap = 4.0;
      while (current < totalLen) {
        final double next = math.min(current + dash, totalLen);
        final extracted = metric.extractPath(current, next);
        canvas.drawPath(extracted, dashPaint);
        current += dash + gap;
      }

      // Draw directional chevron along initial direction of stroke travel
      if (totalLen >= 28) {
        final arrowDist = math.min(36.0, totalLen * 0.35);
        final tangent = metric.getTangentForOffset(arrowDist);
        if (tangent != null && tangent.vector.distance > 0) {
          _drawPathDirectionArrow(canvas, tangent.position, tangent.vector, const Color(0xFFEF4444));
        }
      }
    }
  }

  void _drawPathDirectionArrow(Canvas canvas, Offset pos, Offset directionVector, Color color) {
    final angle = math.atan2(directionVector.dy, directionVector.dx);
    const arrowLength = 9.0;
    const arrowAngle = 26 * (math.pi / 180);

    final arrowPaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final p1 = pos - Offset(arrowLength * math.cos(angle - arrowAngle), arrowLength * math.sin(angle - arrowAngle));
    final p2 = pos - Offset(arrowLength * math.cos(angle + arrowAngle), arrowLength * math.sin(angle + arrowAngle));

    canvas.drawLine(pos, p1, arrowPaint);
    canvas.drawLine(pos, p2, arrowPaint);
  }

  Offset? _drawStrokePath(Canvas canvas, Size size, KanjiStroke stroke, double progress, Paint paint) {
    if (stroke.points.isEmpty || progress <= 0.0) return null;
    final pts = stroke.points;
    final startPx = Offset(pts.first.dx * size.width, pts.first.dy * size.height);

    if (pts.length == 1) {
      canvas.drawCircle(startPx, paint.strokeWidth / 2, Paint()..color = paint.color);
      return startPx;
    }

    if (progress >= 1.0) {
      final path = Path();
      path.moveTo(startPx.dx, startPx.dy);
      for (int i = 1; i < pts.length; i++) {
        path.lineTo(pts[i].dx * size.width, pts[i].dy * size.height);
      }
      canvas.drawPath(path, paint);
      return Offset(pts.last.dx * size.width, pts.last.dy * size.height);
    }

    // Cumulative arc-length distance interpolation
    double totalLength = 0.0;
    final segmentLengths = <double>[];
    for (int i = 0; i < pts.length - 1; i++) {
      final p1 = Offset(pts[i].dx * size.width, pts[i].dy * size.height);
      final p2 = Offset(pts[i + 1].dx * size.width, pts[i + 1].dy * size.height);
      final len = (p2 - p1).distance;
      segmentLengths.add(len);
      totalLength += len;
    }

    if (totalLength == 0.0) {
      canvas.drawCircle(startPx, paint.strokeWidth / 2, Paint()..color = paint.color);
      return startPx;
    }

    final targetDist = totalLength * progress;
    double accumulated = 0.0;
    final path = Path();
    path.moveTo(startPx.dx, startPx.dy);
    Offset currentTip = startPx;

    for (int i = 0; i < segmentLengths.length; i++) {
      final segLen = segmentLengths[i];
      final p1 = Offset(pts[i].dx * size.width, pts[i].dy * size.height);
      final p2 = Offset(pts[i + 1].dx * size.width, pts[i + 1].dy * size.height);

      if (accumulated + segLen <= targetDist) {
        path.lineTo(p2.dx, p2.dy);
        accumulated += segLen;
        currentTip = p2;
      } else {
        final remaining = targetDist - accumulated;
        final t = (remaining / segLen).clamp(0.0, 1.0);
        final interpolated = Offset.lerp(p1, p2, t)!;
        path.lineTo(interpolated.dx, interpolated.dy);
        currentTip = interpolated;
        break;
      }
    }

    canvas.drawPath(path, paint);
    return currentTip;
  }

  @override
  bool shouldRepaint(covariant _WriteJapaneseTracingPainter oldDelegate) => true;
}

/// Renders User Freehand Inking with Smooth Pressure
class _UserStrokesPainter extends CustomPainter {
  final List<List<Offset>> userStrokes;
  final List<Offset> currentDrawing;

  _UserStrokesPainter({
    required this.userStrokes,
    required this.currentDrawing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final inkPaint = Paint()
      ..color = const Color(0xFF0F172A) // Sumi black
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = math.max(7.5, size.width * 0.046)
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke;

    // Committed strokes
    for (final stroke in userStrokes) {
      if (stroke.isEmpty) continue;
      if (stroke.length == 1) {
        canvas.drawCircle(stroke.first, 3.75, Paint()..color = const Color(0xFF0F172A));
        continue;
      }

      final path = Path();
      path.moveTo(stroke.first.dx, stroke.first.dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, inkPaint);
    }

    // Active stroke currently being drawn
    if (currentDrawing.isNotEmpty) {
      if (currentDrawing.length == 1) {
        canvas.drawCircle(currentDrawing.first, 3.75, Paint()..color = const Color(0xFF0F172A));
      } else {
        final path = Path();
        path.moveTo(currentDrawing.first.dx, currentDrawing.first.dy);
        for (int i = 1; i < currentDrawing.length; i++) {
          path.lineTo(currentDrawing[i].dx, currentDrawing[i].dy);
        }
        canvas.drawPath(path, inkPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _UserStrokesPainter oldDelegate) => true;
}
