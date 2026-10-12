import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/lesson.dart';
import '../services/japanese_font_service.dart';
import '../utils/app_theme.dart';

class GrammarScreen extends StatefulWidget {
  final Lesson lesson;

  const GrammarScreen({Key? key, required this.lesson}) : super(key: key);

  @override
  State<GrammarScreen> createState() => _GrammarScreenState();
}

class _GrammarScreenState extends State<GrammarScreen> {
  List<GrammarPoint> _grammarPoints = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGrammar();
  }

  Future<void> _loadGrammar() async {
    try {
      final content = await rootBundle
          .loadString('assets/grammar/grammar${widget.lesson.id}.txt');
      final points = _parseGrammar(content);
      if (mounted) {
        setState(() {
          _grammarPoints = points;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not load grammar for this lesson.';
          _isLoading = false;
        });
      }
    }
  }

  List<GrammarPoint> _parseGrammar(String content) {
    final List<GrammarPoint> points = [];
    final sections = content.split('#');

    for (var section in sections) {
      final lines = section.trim().split('\n');
      if (lines.isEmpty || (lines.length == 1 && lines[0].trim().isEmpty)) {
        continue;
      }

      // Remove the numbering label (e.g., "1.1) ") from the title
      String title = lines[0].trim();
      title = title.replaceFirst(RegExp(r'^\d+(\.\d+)*\)?\s*'), '').trim();

      final explanation = lines.skip(1).join('\n').trim();

      if (title.isNotEmpty) {
        points.add(GrammarPoint(title: title, content: explanation));
      }
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          'Lesson ${widget.lesson.id} Grammar',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        centerTitle: true,
      ),
      body: ValueListenableBuilder<String>(
        valueListenable: JapaneseFontService.currentFontNotifier,
        builder: (context, fontKey, _) {
          if (_isLoading) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (_error != null) {
            return Center(
                child: Text(_error!,
                    style: GoogleFonts.inter(color: Colors.grey)));
          }
          if (_grammarPoints.isEmpty) {
            return Center(
                child: Text('No grammar notes available yet.',
                    style: GoogleFonts.inter(color: Colors.grey)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _grammarPoints.length,
            itemBuilder: (context, index) {
              final point = _grammarPoints[index];
              return _buildGrammarCard(point);
            },
          );
        },
      ),
    );
  }

  Widget _buildGrammarCard(GrammarPoint point) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.bookOpen,
                    color: Color(0xFFE11D48), size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  point.title,
                  style: JapaneseFontService().getJapaneseTextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            point.content,
            style: JapaneseFontService().getJapaneseTextStyle(
              fontSize: 14.5,
              color: const Color(0xFF374151),
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

class GrammarPoint {
  final String title;
  final String content;

  GrammarPoint({required this.title, required this.content});
}
