import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:audioplayers/audioplayers.dart';

class ListeningQuestion {
  final String imageAsset;
  final String audioAsset;
  final int correctAnswer;
  final int questionNumber;

  const ListeningQuestion({
    required this.imageAsset,
    required this.audioAsset,
    required this.correctAnswer,
    required this.questionNumber,
  });
}

class ListeningPracticeScreen extends StatefulWidget {
  final String setFolder;
  const ListeningPracticeScreen({Key? key, this.setFolder = 'n5_1'})
      : super(key: key);

  @override
  State<ListeningPracticeScreen> createState() =>
      _ListeningPracticeScreenState();
}

class _ListeningPracticeScreenState extends State<ListeningPracticeScreen> {
  // Own dedicated player so we can stop it on dispose / exit
  final AudioPlayer _player = AudioPlayer();
  PlayerState _playerState = PlayerState.stopped;
  String? _activeAudioAsset;

  late Future<List<ListeningQuestion>> _questionsFuture;
  int _currentIndex = 0;
  int _score = 0;
  int? _selectedAnswer;
  bool _answered = false;
  bool _showResults = false;
  late int _currentCorrectAnswer;

  @override
  void initState() {
    super.initState();
    _questionsFuture = _loadQuestions();

    _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _playerState = state;
        });
      }
    });
  }

  @override
  void dispose() {
    _player.stop();
    _player.dispose();
    super.dispose();
  }

  // ── Stop audio and pop ─────────────────────────────────────────────────────
  Future<void> _exitScreen() async {
    await _stopAudio();
    if (mounted) Navigator.pop(context);
  }

  // ── Load questions ─────────────────────────────────────────────────────────
  Future<List<ListeningQuestion>> _loadQuestions() async {
    String answerKeyText = '';
    try {
      answerKeyText = await rootBundle.loadString(
          'assets/JLPTN5 audio/${widget.setFolder}/answers_1to10.txt');
    } catch (e) {
      debugPrint('Failed to load answer key: $e');
    }

    final lines = answerKeyText.split('\n');
    final answers = <int>[];
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final parts = trimmed.split(')');
      if (parts.length == 2) {
        final answer = int.tryParse(parts[1].trim());
        if (answer != null && answer >= 1 && answer <= 4) {
          answers.add(answer);
        }
      }
    }

    if (answers.isEmpty) debugPrint('No answers parsed from answer key.');

    final questions = <ListeningQuestion>[];
    for (int i = 0; i < answers.length; i++) {
      final num = i + 1;
      questions.add(
        ListeningQuestion(
          imageAsset:
              'assets/JLPTN5 audio/${widget.setFolder}/${widget.setFolder}_$num.png',
          audioAsset:
              'JLPTN5 audio/${widget.setFolder}/${widget.setFolder}_$num.mp3',
          correctAnswer: answers[i],
          questionNumber: num,
        ),
      );
    }
    return questions;
  }

  // ── Play audio ─────────────────────────────────────────────────────────────
  Future<void> _toggleAudio(String assetPath) async {
    try {
      if (_activeAudioAsset == assetPath) {
        if (_playerState == PlayerState.playing) {
          await _player.pause();
          return;
        }

        if (_playerState == PlayerState.paused) {
          await _player.resume();
          return;
        }
      }

      await _player.stop();
      _activeAudioAsset = assetPath;
      await _player.play(AssetSource(assetPath));
    } catch (e) {
      debugPrint('Audio error: $e');
    }
  }

  Future<void> _stopAudio() async {
    try {
      await _player.stop();
      if (mounted) {
        setState(() {
          _activeAudioAsset = null;
          _playerState = PlayerState.stopped;
        });
      } else {
        _activeAudioAsset = null;
        _playerState = PlayerState.stopped;
      }
    } catch (e) {
      debugPrint('Audio stop error: $e');
    }
  }

  // ── Answer handling ────────────────────────────────────────────────────────
  void _handleAnswer(int option) {
    if (_answered) return;
    setState(() {
      _selectedAnswer = option;
      _answered = true;
      if (option == _currentCorrectAnswer) _score++;
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: FutureBuilder<List<ListeningQuestion>>(
        future: _questionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFEC4899)),
            );
          }

          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return _buildErrorScreen();
          }

          final questions = snapshot.data!;

          if (_showResults) return _buildResultsScreen(questions.length);

          final question = questions[_currentIndex];
          _currentCorrectAnswer = question.correctAnswer;

          return Column(
            children: [
              _buildHeader(questions.length),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 8),
                      _buildQuestionImage(question.imageAsset),
                      const SizedBox(height: 20),
                      _buildPlayButton(question.audioAsset),
                      const SizedBox(height: 32),
                      _buildAnswerButtons(),
                      if (_answered) ...[
                        const SizedBox(height: 24),
                        _buildNextButton(questions.length),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Error screen ───────────────────────────────────────────────────────────
  Widget _buildErrorScreen() {
    return Column(
      children: [
        _buildSimpleHeader(),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.alertCircle,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No listening questions available.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        fontSize: 16, color: const Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 56, bottom: 20, left: 24, right: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF472B6), Color(0xFFEC4899), Color(0xFFE11D48)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _exitScreen,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(LucideIcons.arrowLeft,
                  color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Listening Practice',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 56, bottom: 20, left: 24, right: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF472B6), Color(0xFFEC4899), Color(0xFFE11D48)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // ← Exit: stops audio then pops
              GestureDetector(
                onTap: _exitScreen,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.arrowLeft,
                      color: Colors.white, size: 20),
                ),
              ),
              const Spacer(),
              Text(
                'Listening Practice',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Stop button — stops audio without leaving screen
              GestureDetector(
                onTap: _stopAudio,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    LucideIcons.stopCircle,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Question ${_currentIndex + 1} of $total',
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (_currentIndex + 1) / total,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  // ── Question image ─────────────────────────────────────────────────────────
  Widget _buildQuestionImage(String assetPath) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxWidth < 360 ? 180.0 : 220.0;
        return Container(
          width: double.infinity,
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              assetPath,
              fit: BoxFit.contain,
              width: double.infinity,
              errorBuilder: (_, __, ___) => Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.imageOff,
                        size: 40, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text('Image not found',
                        style: GoogleFonts.inter(color: Colors.grey.shade500)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Play button ────────────────────────────────────────────────────────────
  Widget _buildPlayButton(String assetPath) {
    final isCurrentAsset = _activeAudioAsset == assetPath;
    final isThisPlaying = isCurrentAsset && _playerState == PlayerState.playing;
    final isThisPaused = isCurrentAsset && _playerState == PlayerState.paused;

    return GestureDetector(
      onTap: () => _toggleAudio(assetPath),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isThisPlaying
                ? [const Color(0xFF6366F1), const Color(0xFF4F46E5)]
                : [const Color(0xFFEC4899), const Color(0xFFE11D48)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: ((isThisPlaying
                      ? const Color(0xFF6366F1)
                      : const Color(0xFFEC4899)))
                  .withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(
          isThisPlaying
              ? LucideIcons.pause
              : isThisPaused
                  ? LucideIcons.play
                  : LucideIcons.play,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }

  // ── Answer buttons ─────────────────────────────────────────────────────────
  Widget _buildAnswerButtons() {
    final options = [1, 2, 3, 4];
    return Column(
      children: List.generate(2, (row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: List.generate(2, (col) {
              final option = options[row * 2 + col];
              final isSelected = _selectedAnswer == option;
              final isCorrect = option == _currentCorrectAnswer;

              Color borderColor = Colors.grey.shade200;
              Color bgColor = Colors.white;
              Color textColor = const Color(0xFF374151);

              if (_answered) {
                if (isCorrect) {
                  borderColor = Colors.green.shade400;
                  bgColor = Colors.green.shade50;
                  textColor = Colors.green.shade700;
                } else if (isSelected && !isCorrect) {
                  borderColor = Colors.red.shade400;
                  bgColor = Colors.red.shade50;
                  textColor = Colors.red.shade700;
                }
              }

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: col == 0 ? 0 : 6,
                    right: col == 1 ? 0 : 6,
                  ),
                  child: GestureDetector(
                    onTap: _answered ? null : () => _handleAnswer(option),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$option',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          if (_answered && isCorrect) ...[
                            const SizedBox(width: 6),
                            Icon(LucideIcons.checkCircle2,
                                color: Colors.green.shade600, size: 20),
                          ] else if (_answered && isSelected && !isCorrect) ...[
                            const SizedBox(width: 6),
                            Icon(LucideIcons.xCircle,
                                color: Colors.red.shade600, size: 20),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  // ── Next button ────────────────────────────────────────────────────────────
  Widget _buildNextButton(int total) {
    final isLast = _currentIndex >= total - 1;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          await _stopAudio();
          setState(() {
            if (isLast) {
              _showResults = true;
            } else {
              _currentIndex++;
              _selectedAnswer = null;
              _answered = false;
            }
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEC4899),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: Text(
          isLast ? 'See Results' : 'Next Question',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ── Results screen ─────────────────────────────────────────────────────────
  Widget _buildResultsScreen(int total) {
    final percentage = (_score / total) * 100;
    final isPassed = percentage >= 70;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
          child: Column(
            children: [
              // Back button at top of results
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: _exitScreen,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(LucideIcons.arrowLeft,
                        color: Color(0xFF374151), size: 20),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: isPassed ? Colors.green.shade50 : Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  isPassed ? 'assets/gif/Shiba Happy.gif' : 'assets/gif/Shiba Sad.gif',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isPassed ? 'Great Job!' : 'Keep Practicing!',
                style: GoogleFonts.inter(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'You scored $_score out of $total',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  color: const Color(0xFF4B5563),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${percentage.toInt()}% Accuracy',
                style: GoogleFonts.inter(
                    fontSize: 15, color: const Color(0xFF6B7280)),
              ),
              const SizedBox(height: 32),
              _buildStatRow('Total Questions', '$total'),
              const SizedBox(height: 10),
              _buildStatRow('Correct Answers', '$_score'),
              const SizedBox(height: 10),
              _buildStatRow('Accuracy', '${percentage.toInt()}%'),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _currentIndex = 0;
                      _score = 0;
                      _selectedAnswer = null;
                      _answered = false;
                      _showResults = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEC4899),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  child: Text('Try Again',
                      style: GoogleFonts.inter(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _exitScreen,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF6B7280),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text('Back to Home',
                      style: GoogleFonts.inter(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  color: const Color(0xFF6B7280), fontWeight: FontWeight.w500)),
          Text(value,
              style: GoogleFonts.inter(
                  color: const Color(0xFF1F2937),
                  fontWeight: FontWeight.bold,
                  fontSize: 17)),
        ],
      ),
    );
  }
}
