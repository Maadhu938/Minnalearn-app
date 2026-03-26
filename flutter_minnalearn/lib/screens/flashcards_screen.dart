import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/lesson.dart';
import '../services/database_service.dart';
import '../services/speech_service.dart';
import '../services/study_timer_service.dart';
import '../utils/vocabulary_display.dart';

class FlashcardsScreen extends StatefulWidget {
  final Lesson lesson;

  const FlashcardsScreen({Key? key, required this.lesson}) : super(key: key);

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  int _currentIndex = 0;
  bool _isFlipped = false;

  void _handleCardSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity > 220) {
      _handlePrevious();
    } else if (velocity < -220) {
      _handleNext();
    }
  }

  void _handleNext() {
    if (_currentIndex < widget.lesson.vocabulary.length - 1) {
      setState(() {
        _currentIndex++;
        _isFlipped = false;
      });
      // Trigger streak update when moving through cards
      DatabaseService().updateStreak();
    }
  }

  void _handlePrevious() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _isFlipped = false;
      });
    }
  }

  void _handleFlip() {
    setState(() {
      _isFlipped = !_isFlipped;
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

  @override
  void initState() {
    super.initState();
    StudyTimerService().startTimer();
  }

  @override
  void dispose() {
    StudyTimerService().stopTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vocabulary = widget.lesson.vocabulary;
    if (vocabulary.isEmpty) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No vocabulary is available for this lesson yet.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 18, color: const Color(0xFF4B5563)),
            ),
          ),
        ),
      );
    }

    final currentWord = vocabulary[_currentIndex];
    final promptText = currentWord.kanaText;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF1F2), Color(0xFFF5F3FF)], // Pink-50 to Purple-50
          ),
        ),
        child: Column(
          children: [
            // Header
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.arrowLeft, color: Color(0xFF4B5563), size: 20),
                              const SizedBox(width: 8),
                              Text('Back', style: GoogleFonts.inter(color: const Color(0xFF4B5563))),
                            ],
                          ),
                        ),
                        Text(
                          '${_currentIndex + 1} / ${vocabulary.length}',
                          style: GoogleFonts.inter(color: const Color(0xFF4B5563), fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Flashcards',
                      style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.lesson.title.isEmpty
                          ? 'Lesson ${widget.lesson.id}'
                          : 'Lesson ${widget.lesson.id}: ${widget.lesson.title}',
                      style: GoogleFonts.inter(color: const Color(0xFF4B5563), fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

            // Flashcard
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                        onTap: _handleFlip,
                        onHorizontalDragEnd: _handleCardSwipe,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          width: double.infinity,
                          constraints: const BoxConstraints(minHeight: 280),
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (!_isFlipped) ...[
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: _handleFlip,
                                  child: Column(
                                    children: [
                                      Text(
                                        promptText,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(fontSize: 60, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937)),
                                      ),
                                      const SizedBox(height: 24),
                                      Text(
                                        'Tap to reveal',
                                        style: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 14),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Swipe left for next, right for previous',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(color: const Color(0xFFD1D5DB), fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: _handleFlip,
                                  child: Column(
                                    children: [
                                      Text(
                                        promptText,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(fontSize: 40, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937)),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        currentWord.meaning,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(fontSize: 20, color: const Color(0xFF4B5563)),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Tap the card to flip back',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                TextButton.icon(
                                  onPressed: () => _handleSpeak(promptText),
                                  icon: const Icon(LucideIcons.volume2, color: Colors.pink, size: 20),
                                  label: Text('Listen', style: GoogleFonts.inter(color: Colors.pink)),
                                ),
                                Text(
                                  'Swipe left for next, right for previous',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 12),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Navigation
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildNavButton(LucideIcons.chevronLeft, _currentIndex > 0, _handlePrevious),
                          Row(
                            children: List.generate(
                              (vocabulary.length > 5 ? 5 : vocabulary.length),
                              (index) => Container(
                                width: 32,
                                height: 6,
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  color: index == (_currentIndex % 5) ? Colors.pink : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                          _buildNavButton(LucideIcons.chevronRight, _currentIndex < vocabulary.length - 1, _handleNext),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton(IconData icon, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: enabled ? const Color(0xFF374151) : Colors.grey.shade300, size: 24),
      ),
    );
  }
}
