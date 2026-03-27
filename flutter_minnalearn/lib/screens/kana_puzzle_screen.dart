import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/lesson.dart';
import '../services/audio_service.dart';
import '../services/database_service.dart';
import '../services/achievement_service.dart';

class KanaPuzzleScreen extends StatefulWidget {
  final Lesson lesson;

  const KanaPuzzleScreen({Key? key, required this.lesson}) : super(key: key);

  @override
  State<KanaPuzzleScreen> createState() => _KanaPuzzleScreenState();
}

class _KanaPuzzleScreenState extends State<KanaPuzzleScreen> {
  final _random = Random();
  late List<Vocabulary> _vocabPool;
  
  Vocabulary? _currentVocab;
  List<String> _targetCharacters = [];
  List<String> _availableTiles = [];
  List<String> _selectedTiles = [];
  
  int _score = 0;
  int _combo = 0;
  int _timeLeft = 60;
  Timer? _gameTimer;
  bool _isPlaying = false;
  bool _isGameOver = false;

  @override
  void initState() {
    super.initState();
    _vocabPool = List.from(widget.lesson.vocabulary)
      ..removeWhere((v) => v.romaji.isEmpty);
      
    _startGame();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    if (_vocabPool.isEmpty) return;
    
    setState(() {
      _score = 0;
      _combo = 0;
      _timeLeft = 60;
      _isPlaying = true;
      _isGameOver = false;
    });

    _loadNextWord();

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _endGame();
        }
      });
    });
  }

  void _endGame() {
    _gameTimer?.cancel();
    setState(() {
      _isPlaying = false;
      _isGameOver = true;
    });
    
    DatabaseService().saveGameScore('Kana Puzzle', _score);
    if (_score > 0) {
      AchievementService().checkAchievements(context: context);
    }
  }

  void _loadNextWord() {
    setState(() {
      _currentVocab = _vocabPool[_random.nextInt(_vocabPool.length)];
      // Use romaji (kana reading) instead of japanese (which may contain kanji)
      _targetCharacters = _currentVocab!.romaji.characters.toList();
      _availableTiles = List.from(_targetCharacters)..shuffle(_random);
      _selectedTiles = [];
    });
  }

  void _onTileSelected(String tile, int index) {
    if (!_isPlaying) return;
    
    setState(() {
      _availableTiles.removeAt(index);
      _selectedTiles.add(tile);
    });

    if (_selectedTiles.length == _targetCharacters.length) {
      _validateSelection();
    }
  }

  void _onTileDeselected(String tile, int index) {
    if (!_isPlaying) return;

    setState(() {
      _selectedTiles.removeAt(index);
      _availableTiles.add(tile);
    });
  }

  Future<void> _validateSelection() async {
    final builtWord = _selectedTiles.join();
    final isCorrect = builtWord == _currentVocab!.romaji;

    if (isCorrect) {
      AudioService().playCorrect();
      setState(() {
        _combo++;
        int points = 10;
        if (_combo >= 3) points *= 2;
        if (_combo >= 6) points *= 3;
        _score += points;
      });
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted && _isPlaying) {
        _loadNextWord();
      }
    } else {
      AudioService().playWrong();
      setState(() {
        _combo = 0;
      });
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted && _isPlaying) {
        setState(() {
          // Return all tiles to available, reshuffle
          _availableTiles.addAll(_selectedTiles);
          _availableTiles.shuffle(_random);
          _selectedTiles.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Kana Puzzle',
          style: GoogleFonts.inter(
            color: const Color(0xFF1F2937),
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _vocabPool.isEmpty
          ? Center(
              child: Text(
                'Not enough vocabulary to play this game.',
                style: GoogleFonts.inter(color: Colors.grey),
              ),
            )
          : Column(
              children: [
                _buildHUD(),
                Expanded(
                  child: _isGameOver ? _buildGameOver() : _buildGameBoard(),
                ),
              ],
            ),
    );
  }

  Widget _buildHUD() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStat('Score', _score.toString(), const Color(0xFFEC4899)),
          _buildStat(
            'Combo',
            'x$_combo',
            _combo >= 3 ? const Color(0xFFEAB308) : const Color(0xFF6B7280),
            animate: _combo >= 3,
          ),
          _buildStat(
              'Time',
              '${_timeLeft}s',
              _timeLeft <= 10 ? const Color(0xFFEF4444) : const Color(0xFF3B82F6)),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, Color valueColor, {bool animate = false}) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 4),
        AnimatedScale(
          scale: animate ? 1.1 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGameBoard() {
    if (_currentVocab == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Word Meaning Target
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFB923C), Color(0xFFF97316)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF97316).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Build kana for:',
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _currentVocab!.meaning,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Selected Tiles Area - DragTarget
          Text(
            'Drag kana here',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 12),
          DragTarget<String>(
            builder: (context, candidateData, rejectedData) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                constraints: const BoxConstraints(minHeight: 70),
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: candidateData.isNotEmpty
                      ? const Color(0xFFFDF2F8)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: candidateData.isNotEmpty
                        ? const Color(0xFFEC4899)
                        : const Color(0xFFE5E7EB),
                    width: 2,
                  ),
                ),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    ...List.generate(_selectedTiles.length, (index) {
                      return _buildSelectedTile(_selectedTiles[index], index);
                    }),
                    ...List.generate(
                      _targetCharacters.length - _selectedTiles.length,
                      (index) => _buildEmptySlot(),
                    ),
                  ],
                ),
              );
            },
            onWillAcceptWithDetails: (details) => _isPlaying,
            onAcceptWithDetails: (details) {
              final data = details.data;
              final index = _availableTiles.indexOf(data);
              if (index != -1) {
                _onTileSelected(data, index);
              }
            },
          ),

          const SizedBox(height: 40),

          // Available Tiles Area - Draggable
          Text(
            'Drag to select',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: List.generate(_availableTiles.length, (index) {
              return _buildDraggableTile(_availableTiles[index], index);
            }),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDraggableTile(String char, int index) {
    return Draggable<String>(
      data: char,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFFDF2F8),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEC4899).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: const Color(0xFFEC4899), width: 2),
          ),
          child: Center(
            child: Text(
              char,
              style: GoogleFonts.notoSansJp(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
          ),
        ),
      ),
      childWhenDragging: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
        ),
        child: Center(
          child: Text(
            char,
            style: GoogleFonts.notoSansJp(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFD1D5DB),
            ),
          ),
        ),
      ),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
        ),
        child: Center(
          child: Text(
            char,
            style: GoogleFonts.notoSansJp(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedTile(String char, int index) {
    return GestureDetector(
      onTap: () => _onTileDeselected(char, index),
      child: Container(
        width: 50,
        height: 50,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: const Color(0xFFEC4899), width: 2),
        ),
        child: Center(
          child: Text(
            char,
            style: GoogleFonts.notoSansJp(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySlot() {
    return Container(
      width: 50,
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildGameOver() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFEC4899),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.trophy,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Time\'s Up!',
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You scored $_score points',
              style: GoogleFonts.inter(
                fontSize: 18,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEC4899),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Play Again',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Back to Menu',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
