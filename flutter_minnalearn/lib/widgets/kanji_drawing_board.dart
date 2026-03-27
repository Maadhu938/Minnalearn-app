import 'package:flutter/material.dart';

class KanjiDrawingBoard extends StatefulWidget {
  final String strokeGuide; 
  final VoidCallback? onStrokeComplete;
  final VoidCallback? onStrokeStart;

  const KanjiDrawingBoard({
    Key? key,
    required this.strokeGuide,
    this.onStrokeComplete,
    this.onStrokeStart,
  }) : super(key: key);

  @override
  State<KanjiDrawingBoard> createState() => KanjiDrawingBoardState();
}

class KanjiDrawingBoardState extends State<KanjiDrawingBoard> {
  List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  bool _drawing = false;

  void clear() {
    setState(() {
      _strokes = [];
      _currentStroke = [];
      _drawing = false;
    });
  }

  void undo() {
    if (_strokes.isNotEmpty) {
      setState(() {
        _strokes.removeLast();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listener bypasses the gesture arena entirely, so the parent
    // ScrollView cannot compete for vertical drags while drawing.
    return Listener(
      onPointerDown: (event) {
        _drawing = true;
        setState(() {
          _currentStroke = [event.localPosition];
        });
        widget.onStrokeStart?.call();
      },
      onPointerMove: (event) {
        if (!_drawing) return;
        setState(() {
          _currentStroke.add(event.localPosition);
        });
      },
      onPointerUp: (event) {
        if (!_drawing) return;
        _drawing = false;
        if (_currentStroke.isNotEmpty) {
          setState(() {
            _strokes.add(List.from(_currentStroke));
            _currentStroke = [];
          });
          widget.onStrokeComplete?.call();
        }
      },
      onPointerCancel: (event) {
        _drawing = false;
        if (_currentStroke.isNotEmpty) {
          setState(() {
            _currentStroke = [];
          });
        }
      },
      child: CustomPaint(
        painter: _KanjiPainter(
          strokes: _strokes,
          currentStroke: _currentStroke,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _KanjiPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;

  _KanjiPainter({required this.strokes, required this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1F2937)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6.0
      ..isAntiAlias = true;

    for (final stroke in strokes) {
      for (int i = 0; i < stroke.length - 1; i++) {
        canvas.drawLine(stroke[i], stroke[i + 1], paint);
      }
    }

    for (int i = 0; i < currentStroke.length - 1; i++) {
      canvas.drawLine(currentStroke[i], currentStroke[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(covariant _KanjiPainter oldDelegate) => true;
}
