import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../utils/app_theme.dart';
import '../widgets/bouncing_widget.dart';
import '../widgets/fox_mascot_bubble.dart';
import '../services/database_service.dart';

enum ListeningMode {
  fullMock,
  section1,
  section2,
  quickDrill,
}

class ListeningQuestion {
  final String imageAsset;
  final String audioAsset;
  final int correctAnswer;
  final int questionNumber;
  final String sectionName;
  final String folder;
  final int originalIndex;

  const ListeningQuestion({
    required this.imageAsset,
    required this.audioAsset,
    required this.correctAnswer,
    required this.questionNumber,
    required this.sectionName,
    required this.folder,
    required this.originalIndex,
  });
}

class ListeningPracticeScreen extends StatefulWidget {
  final String setFolder; // Backward compatibility
  final ListeningMode? mode;
  final String? title;

  const ListeningPracticeScreen({
    Key? key,
    this.setFolder = 'n5_1',
    this.mode,
    this.title,
  }) : super(key: key);

  ListeningMode get effectiveMode {
    if (mode != null) return mode!;
    if (setFolder == 'n5_2') return ListeningMode.section2;
    if (setFolder == 'n5_1') return ListeningMode.section1;
    return ListeningMode.fullMock;
  }

  @override
  State<ListeningPracticeScreen> createState() =>
      _ListeningPracticeScreenState();
}

class _ListeningPracticeScreenState extends State<ListeningPracticeScreen>
    with SingleTickerProviderStateMixin {
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
  DateTime _startTime = DateTime.now();

  int? _previousBestScore;
  bool _isNewBestScore = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _questionsFuture = _loadQuestions();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _playerState = state;
        });
        if (state == PlayerState.playing) {
          _pulseController.repeat(reverse: true);
        } else {
          _pulseController.stop();
          _pulseController.reset();
        }
      }
    });

    _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _playerState = PlayerState.completed;
        });
        _pulseController.stop();
        _pulseController.reset();
      }
    });

    _loadPreviousBest();
  }

  Future<void> _loadPreviousBest() async {
    try {
      final key = 'listening_best_${widget.effectiveMode.name}';
      final prev = await DatabaseService().getUserStatInt(key);
      if (mounted) {
        setState(() {
          _previousBestScore = prev;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _player.stop();
    _player.dispose();
    super.dispose();
  }

  Future<void> _exitScreen() async {
    await _stopAudio();
    if (mounted) Navigator.pop(context);
  }

  // ── Question Loader ────────────────────────────────────────────────────────
  Future<List<int>> _parseAnswers(String folder) async {
    try {
      final answerKeyText = await rootBundle
          .loadString('assets/JLPTN5 audio/$folder/answers_1to10.txt');
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
      return answers;
    } catch (e) {
      debugPrint('Failed to load answer key for $folder: $e');
      return [];
    }
  }

  Future<List<ListeningQuestion>> _loadQuestionsForFolder(
    String folder,
    String sectionName, {
    int startDisplayNumber = 1,
  }) async {
    final answers = await _parseAnswers(folder);
    final questions = <ListeningQuestion>[];
    for (int i = 0; i < answers.length; i++) {
      final fileNum = i + 1;
      final displayNum = startDisplayNumber + i;
      questions.add(
        ListeningQuestion(
          imageAsset: 'assets/JLPTN5 audio/$folder/${folder}_$fileNum.png',
          audioAsset: 'JLPTN5 audio/$folder/${folder}_$fileNum.mp3',
          correctAnswer: answers[i],
          questionNumber: displayNum,
          sectionName: sectionName,
          folder: folder,
          originalIndex: fileNum,
        ),
      );
    }
    return questions;
  }

  Future<List<ListeningQuestion>> _loadQuestions() async {
    final mode = widget.effectiveMode;

    switch (mode) {
      case ListeningMode.fullMock:
        final q1 = await _loadQuestionsForFolder(
          'n5_1',
          'Part 1: Task Comprehension (課題理解)',
          startDisplayNumber: 1,
        );
        final q2 = await _loadQuestionsForFolder(
          'n5_2',
          'Part 2: Point Comprehension (ポイント理解)',
          startDisplayNumber: 11,
        );
        return [...q1, ...q2];

      case ListeningMode.section1:
        return await _loadQuestionsForFolder(
          'n5_1',
          'Task-Based Comprehension (課題理解)',
          startDisplayNumber: 1,
        );

      case ListeningMode.section2:
        return await _loadQuestionsForFolder(
          'n5_2',
          'Point Comprehension (ポイント理解)',
          startDisplayNumber: 1,
        );

      case ListeningMode.quickDrill:
        final q1 = await _loadQuestionsForFolder(
          'n5_1',
          'Task Comprehension (課題理解)',
          startDisplayNumber: 1,
        );
        final q2 = await _loadQuestionsForFolder(
          'n5_2',
          'Point Comprehension (ポイント理解)',
          startDisplayNumber: 11,
        );
        final all = [...q1, ...q2];
        all.shuffle(Random());
        final selected = all.take(5).toList();
        return [
          for (int i = 0; i < selected.length; i++)
            ListeningQuestion(
              imageAsset: selected[i].imageAsset,
              audioAsset: selected[i].audioAsset,
              correctAnswer: selected[i].correctAnswer,
              questionNumber: i + 1,
              sectionName: selected[i].sectionName,
              folder: selected[i].folder,
              originalIndex: selected[i].originalIndex,
            ),
        ];
    }
  }

  // ── Audio Player Controls ──────────────────────────────────────────────────
  Future<void> _toggleAudio(String assetPath) async {
    try {
      HapticFeedback.lightImpact();
      if (_activeAudioAsset == assetPath) {
        if (_playerState == PlayerState.playing) {
          await _player.pause();
          return;
        }

        if (_playerState == PlayerState.paused) {
          await _player.resume();
          return;
        }

        if (_playerState == PlayerState.completed) {
          await _player.seek(Duration.zero);
          await _player.resume();
          return;
        }
      }

      await _player.stop();
      _activeAudioAsset = assetPath;
      await _player.play(AssetSource(assetPath));
    } catch (e) {
      debugPrint('Audio playback error: $e');
    }
  }

  Future<void> _replayAudio(String assetPath) async {
    try {
      HapticFeedback.mediumImpact();
      await _player.stop();
      _activeAudioAsset = assetPath;
      await _player.play(AssetSource(assetPath));
    } catch (e) {
      debugPrint('Audio replay error: $e');
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

  // ── Answer Handling ────────────────────────────────────────────────────────
  void _handleAnswer(int option) {
    if (_answered) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _selectedAnswer = option;
      _answered = true;
      if (option == _currentCorrectAnswer) {
        _score++;
      }
    });
  }

  // ── Save Results & Stats ───────────────────────────────────────────────────
  Future<void> _recordCompletion(int totalQuestions) async {
    try {
      final elapsed = DateTime.now().difference(_startTime).inSeconds;
      if (elapsed > 5) {
        await DatabaseService().addStudyTime(elapsed);
      }

      final key = 'listening_best_${widget.effectiveMode.name}';
      final prevBest = await DatabaseService().getUserStatInt(key) ?? 0;
      if (_score > prevBest || _previousBestScore == null) {
        await DatabaseService().setUserStatInt(key, _score);
        await DatabaseService().setUserStatInt(
            'listening_total_${widget.effectiveMode.name}', totalQuestions);
        if (mounted) {
          setState(() {
            _isNewBestScore = true;
          });
        }
      }
      DatabaseService().notifyDataChanged();
    } catch (e) {
      debugPrint('Failed to save listening stats: $e');
    }
  }

  String _getModeTitle() {
    if (widget.title != null) return widget.title!;
    switch (widget.effectiveMode) {
      case ListeningMode.fullMock:
        return 'Full JLPT Mock Exam';
      case ListeningMode.section1:
        return 'Part 1: Task Comprehension';
      case ListeningMode.section2:
        return 'Part 2: Point Comprehension';
      case ListeningMode.quickDrill:
        return 'Quick 5-Question Drill';
    }
  }

  // ── Build Main UI ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.scaffold,
        body: FutureBuilder<List<ListeningQuestion>>(
          future: _questionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data!.isEmpty) {
              return _buildErrorScreen();
            }

            final questions = snapshot.data!;

            if (_showResults) {
              return _buildResultsScreen(questions.length);
            }

            final question = questions[_currentIndex];
            _currentCorrectAnswer = question.correctAnswer;

            return Column(
              children: [
                _buildHeader(question, questions.length),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width - 40,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Fox Mascot Encouragement
                            FoxMascotBubble(
                              message: _answered
                                  ? (_selectedAnswer == _currentCorrectAnswer
                                      ? 'Sugoi! Correct illustration! 🎉'
                                      : 'Oops! Correct option was #$_currentCorrectAnswer 💡')
                                  : (_playerState == PlayerState.playing
                                      ? 'Listening... Focus on the keywords! 🔊'
                                      : 'Listen to the dialogue and choose the matching illustration! 🎧'),
                              mood: _answered
                                  ? (_selectedAnswer == _currentCorrectAnswer
                                      ? FoxMood.happy
                                      : FoxMood.encouraging)
                                  : (_playerState == PlayerState.playing
                                      ? FoxMood.thinking
                                      : FoxMood.neutral),
                            ),
                            const SizedBox(height: 14),

                            // Question Illustration Card
                            _buildQuestionImage(question.imageAsset),
                            const SizedBox(height: 16),

                            // Enhanced Audio Player Bar
                            _buildAudioPlayerCard(question.audioAsset),
                            const SizedBox(height: 20),

                            // 4 Choice Buttons
                            _buildAnswerButtons(),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 320),
                              curve: Curves.easeInOutCubic,
                              child: _answered
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 16),
                                      child: _buildNextButton(questions.length),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                            SizedBox(
                              height:
                                  MediaQuery.of(context).padding.bottom + 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Header Widget ──────────────────────────────────────────────────────────
  Widget _buildHeader(ListeningQuestion question, int total) {
    final topPadding = MediaQuery.of(context).padding.top;
    final safeTop = topPadding > 30 ? topPadding + 18 : 58.0;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
          top: safeTop, bottom: 18, left: 20, right: 20),
      decoration: const BoxDecoration(
        gradient: AppGradients.primaryHeader,
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
              // Exit button
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getModeTitle(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      question.sectionName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Audio Stop Button
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
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${_currentIndex + 1} of $total',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.95),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.check,
                        color: Color(0xFF86EFAC), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Score: $_score',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (_currentIndex + 1) / total,
              backgroundColor: Colors.white.withOpacity(0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  // ── Question Image Widget ──────────────────────────────────────────────────
  Widget _buildQuestionImage(String assetPath) {
    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = screenWidth - 40;
    // Before answer: larger image (~210-250px) using the open space for easy inspection
    // After answer: smoothly shrinks (~135-160px) so Next button fits without scrolling
    final targetHeight = _answered
        ? (contentWidth * 0.44).clamp(135.0, 160.0)
        : (contentWidth * 0.65).clamp(205.0, 250.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
      width: contentWidth,
      height: targetHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.ink200, width: 1.5),
        boxShadow: AppShadows.subtle,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.imageOff,
                            size: 36, color: Colors.grey.shade400),
                        const SizedBox(height: 6),
                        Text(
                          'Illustration not found',
                          style: GoogleFonts.inter(
                              color: Colors.grey.shade500, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // JLPT Quadrant Guide Pill
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Options 1 - 4',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Enhanced Audio Bar ─────────────────────────────────────────────────────
  Widget _buildAudioPlayerCard(String assetPath) {
    final isCurrentAsset = _activeAudioAsset == assetPath;
    final isThisPlaying = isCurrentAsset && _playerState == PlayerState.playing;
    final isThisPaused = isCurrentAsset && _playerState == PlayerState.paused;
    final isThisCompleted =
        isCurrentAsset && _playerState == PlayerState.completed;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isThisPlaying ? AppColors.azureBorder : AppColors.ink200,
          width: 1.5,
        ),
        boxShadow: AppShadows.subtle,
      ),
      child: Row(
        children: [
          // Main Play / Pause Circle
          BouncingWidget(
            scaleFactor: 0.92,
            onTap: () => _toggleAudio(assetPath),
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: isThisPlaying ? _pulseAnimation.value : 1.0,
                  child: child,
                );
              },
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isThisPlaying
                        ? [AppColors.azure, AppColors.azureDark]
                        : [AppColors.primary, AppColors.primaryDark],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isThisPlaying
                              ? AppColors.azure
                              : AppColors.primary)
                          .withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  isThisPlaying
                      ? LucideIcons.pause
                      : (isThisCompleted
                          ? LucideIcons.rotateCcw
                          : LucideIcons.play),
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Audio Status Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isThisPlaying
                      ? 'Playing Native Audio...'
                      : isThisPaused
                          ? 'Audio Paused'
                          : isThisCompleted
                              ? 'Finished Playing'
                              : 'Tap to Play Dialogue',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isThisPlaying
                        ? AppColors.azureDark
                        : AppColors.ink900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isThisPlaying
                      ? 'Listen for clues & answer'
                      : 'Native Japanese N5 recording',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink500,
                  ),
                ),
              ],
            ),
          ),

          // Replay Button
          BouncingWidget(
            scaleFactor: 0.92,
            onTap: () => _replayAudio(assetPath),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.cardAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.ink200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.rotateCcw,
                      color: AppColors.ink700, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Replay',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Answer Buttons ─────────────────────────────────────────────────────────
  Widget _buildAnswerButtons() {
    final options = [1, 2, 3, 4];
    return Column(
      children: List.generate(2, (row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: List.generate(2, (col) {
              final option = options[row * 2 + col];
              final isSelected = _selectedAnswer == option;
              final isCorrect = option == _currentCorrectAnswer;

              Color borderColor = AppColors.ink200;
              Color bottomBorderColor = const Color(0xFFCBD5E1);
              Color bgColor = Colors.white;
              Color textColor = AppColors.ink900;

              if (_answered) {
                if (isCorrect) {
                  borderColor = AppColors.bamboo;
                  bottomBorderColor = AppColors.bambooDark;
                  bgColor = const Color(0xFFECFDF5);
                  textColor = const Color(0xFF047857);
                } else if (isSelected && !isCorrect) {
                  borderColor = AppColors.primary;
                  bottomBorderColor = AppColors.primaryDark;
                  bgColor = const Color(0xFFFEF2F2);
                  textColor = const Color(0xFFB91C1C);
                }
              }

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: col == 0 ? 0 : 6,
                    right: col == 1 ? 0 : 6,
                  ),
                  child: BouncingWidget(
                    scaleFactor: 0.95,
                    onTap: _answered ? null : () => _handleAnswer(option),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: bottomBorderColor,
                            offset: const Offset(0, 4),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$option',
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                          if (_answered && isCorrect) ...[
                            const SizedBox(width: 8),
                            const Icon(LucideIcons.checkCircle2,
                                color: AppColors.bambooDark, size: 20),
                          ] else if (_answered && isSelected && !isCorrect) ...[
                            const SizedBox(width: 8),
                            const Icon(LucideIcons.xCircle,
                                color: AppColors.primary, size: 20),
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

  // ── Next Button ────────────────────────────────────────────────────────────
  Widget _buildNextButton(int total) {
    final isLast = _currentIndex >= total - 1;
    return BouncingWidget(
      onTap: () async {
        await _stopAudio();
        if (isLast) {
          await _recordCompletion(total);
          if (mounted) {
            setState(() {
              _showResults = true;
            });
          }
        } else {
          setState(() {
            _currentIndex++;
            _selectedAnswer = null;
            _answered = false;
          });
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF43F5E), width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF9F1239),
              offset: Offset(0, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: Text(
            isLast ? 'View Test Results ★' : 'Next Question →',
            style: GoogleFonts.outfit(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // ── Results Screen ─────────────────────────────────────────────────────────
  Widget _buildResultsScreen(int total) {
    final percentage = (total > 0 ? (_score / total) : 0) * 100;
    final isPassed = percentage >= 60; // 60% passing standard
    final isFullMock = widget.effectiveMode == ListeningMode.fullMock;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: _exitScreen,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.ink200),
                    ),
                    child: const Icon(LucideIcons.arrowLeft,
                        color: AppColors.ink900, size: 20),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Shiba Mascot Reaction
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color:
                      isPassed ? Colors.green.shade50 : Colors.orange.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isPassed
                        ? Colors.green.shade200
                        : Colors.orange.shade200,
                    width: 2,
                  ),
                ),
                child: Image.asset(
                  isPassed
                      ? 'assets/gif/Shiba Happy.gif'
                      : 'assets/gif/Shiba Sad.gif',
                  width: 110,
                  height: 110,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 20),

              Text(
                isPassed
                    ? (isFullMock ? 'Passed! 合格 🎉' : 'Great Job! よくできました')
                    : 'Keep Practicing! がんばって',
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isPassed
                    ? (isFullMock
                        ? 'You met the JLPT N5 Listening pass mark!'
                        : 'Strong listening comprehension skills!')
                    : 'Review the dialogue audio to sharpen your comprehension.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.ink500,
                  fontWeight: FontWeight.w500,
                ),
              ),

              if (_isNewBestScore) ...[
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.amberLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.amberBorder, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.sparkles,
                          color: AppColors.amberDark, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'NEW PERSONAL BEST!',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.amberDark,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
              _buildStatRow('Practice Mode', _getModeTitle()),
              const SizedBox(height: 10),
              _buildStatRow('Questions Answered', '$total'),
              const SizedBox(height: 10),
              _buildStatRow('Correct Answers', '$_score / $total'),
              const SizedBox(height: 10),
              _buildStatRow('Accuracy Score', '${percentage.toInt()}%'),

              const SizedBox(height: 28),
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
                      _isNewBestScore = false;
                      _startTime = DateTime.now();
                      _questionsFuture = _loadQuestions();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Try Again',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _exitScreen,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.ink500,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'Back to Listening Hub',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
        border: Border.all(color: AppColors.ink200),
        boxShadow: AppShadows.subtle,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  color: AppColors.ink500, fontWeight: FontWeight.w600)),
          Text(value,
              style: GoogleFonts.inter(
                  color: AppColors.ink900,
                  fontWeight: FontWeight.w800,
                  fontSize: 15)),
        ],
      ),
    );
  }

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
                        fontSize: 16, color: AppColors.ink500),
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
        gradient: AppGradients.primaryHeader,
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
            _getModeTitle(),
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
}
