import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/lesson.dart';
import '../services/database_service.dart';
import '../services/speech_service.dart';
import '../services/study_timer_service.dart';
import '../utils/vocabulary_display.dart';

class VocabularyListScreen extends StatefulWidget {
  final Lesson lesson;

  const VocabularyListScreen({Key? key, required this.lesson}) : super(key: key);

  @override
  State<VocabularyListScreen> createState() => _VocabularyListScreenState();
}

class _VocabularyListScreenState extends State<VocabularyListScreen> {
  Set<String> _bookmarkedIds = <String>{};
  bool _isLoadingBookmarks = true;

  @override
  void initState() {
    super.initState();
    StudyTimerService().startTimer();
    _loadBookmarks();
  }

  @override
  void dispose() {
    StudyTimerService().stopTimer();
    super.dispose();
  }

  Future<void> _loadBookmarks() async {
    final bookmarks = await DatabaseService().getBookmarkedVocabularyIds(
      lessonId: widget.lesson.id,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _bookmarkedIds = bookmarks;
      _isLoadingBookmarks = false;
    });
  }

  Future<void> _handleSpeak(String text) async {
    var didSpeak = await SpeechService().speakJapanese(text);
    if (!didSpeak) {
      await Future.delayed(const Duration(milliseconds: 450));
      didSpeak = await SpeechService().speakJapanese(text);
    }

    if (!mounted || didSpeak) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Japanese voice is not available on this device yet.'),
      ),
    );
  }

  Future<void> _toggleBookmark(Vocabulary word) async {
    final vocabularyId = word.id;
    if (vocabularyId == null || vocabularyId.isEmpty) {
      return;
    }

    final isBookmarked = await DatabaseService().toggleVocabularyBookmark(vocabularyId);
    if (!mounted) {
      return;
    }

    setState(() {
      if (isBookmarked) {
        _bookmarkedIds = {..._bookmarkedIds, vocabularyId};
      } else {
        _bookmarkedIds = _bookmarkedIds.where((id) => id != vocabularyId).toSet();
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isBookmarked ? 'Saved to bookmarks' : 'Removed from bookmarks'),
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }

  Color _getTypeBgColor(VocabularyType type) {
    switch (type) {
      case VocabularyType.vocabulary:
        return Colors.blue.shade50;
      case VocabularyType.expression:
        return Colors.purple.shade50;
      case VocabularyType.additional:
        return Colors.green.shade50;
    }
  }

  Color _getTypeTextColor(VocabularyType type) {
    switch (type) {
      case VocabularyType.vocabulary:
        return Colors.blue.shade700;
      case VocabularyType.expression:
        return Colors.purple.shade700;
      case VocabularyType.additional:
        return Colors.green.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 32, left: 24, right: 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF472B6),
                  Color(0xFFEC4899),
                  Color(0xFFE11D48),
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Back',
                        style: GoogleFonts.inter(color: Colors.white.withOpacity(0.9)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Vocabulary List',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.lesson.title.isEmpty
                      ? 'Lesson ${widget.lesson.id}'
                      : 'Lesson ${widget.lesson.id}: ${widget.lesson.title}',
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: widget.lesson.vocabulary.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final word = widget.lesson.vocabulary[index];
                final vocabularyId = word.id ?? '';
                final isBookmarked = vocabularyId.isNotEmpty && _bookmarkedIds.contains(vocabularyId);

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  word.kanaText,
                                  style: GoogleFonts.inter(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1F2937),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getTypeBgColor(word.type),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    word.type.name,
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: _getTypeTextColor(word.type),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              word.meaning,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: const Color(0xFF4B5563),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          _buildCircleButton(
                            LucideIcons.volume2,
                            Colors.pink.shade50,
                            Colors.pink,
                            onTap: () => _handleSpeak(word.kanaText),
                          ),
                          const SizedBox(width: 8),
                          _buildCircleButton(
                            LucideIcons.bookmark,
                            isBookmarked ? const Color(0xFFFCE7F3) : Colors.grey.shade50,
                            isBookmarked ? const Color(0xFFDB2777) : Colors.grey.shade400,
                            onTap: _isLoadingBookmarks ? null : () => _toggleBookmark(word),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.pink.shade50,
                    Colors.purple.shade50,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      '${widget.lesson.vocabulary.length}',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      'Total words in this lesson',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF4B5563),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton(
    IconData icon,
    Color bgColor,
    Color iconColor, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
    );
  }
}
