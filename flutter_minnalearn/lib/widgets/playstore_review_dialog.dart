import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';
import 'bouncing_widget.dart';

class PlaystoreReviewDialog extends StatefulWidget {
  const PlaystoreReviewDialog({Key? key}) : super(key: key);

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const PlaystoreReviewDialog(),
    );
  }

  @override
  State<PlaystoreReviewDialog> createState() => _PlaystoreReviewDialogState();
}

class _PlaystoreReviewDialogState extends State<PlaystoreReviewDialog> {
  int _selectedStars = 5;

  Future<void> _launchPlayStore() async {
    final db = DatabaseService();
    await db.setUserStatText('playstore_review_status', 'rated');

    if (mounted) Navigator.of(context).pop();

    final marketUri = Uri.parse('market://details?id=com.maadhu.minnalearn');
    final webUri = Uri.parse(
        'https://play.google.com/store/apps/details?id=com.maadhu.minnalearn');

    try {
      if (await canLaunchUrl(marketUri)) {
        await launchUrl(marketUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching play store: $e');
    }
  }

  void _openDirectFeedbackModal() {
    Navigator.of(context).pop();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _DirectFeedbackSheet(),
    );
  }

  Future<void> _maybeLater() async {
    final db = DatabaseService();
    await db.setUserStatText('playstore_review_status', 'dismissed');
    await db.setUserStatInt(
      'playstore_review_dismissed_at',
      DateTime.now().millisecondsSinceEpoch,
    );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isHighRating = _selectedStars >= 4;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.ink200, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mascot celebration avatar
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF1F2), Color(0xFFFFE4E6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.3), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/gif/Shiba Happy.gif',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Text('🦊', style: TextStyle(fontSize: 36)),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Title
            Text(
              isHighRating
                  ? 'Enjoying MinnaLearn? 🦊'
                  : 'How can we improve? 💭',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.ink900,
                letterSpacing: -0.3,
              ),
            ),

            const SizedBox(height: 8),

            // Description
            Text(
              isHighRating
                  ? 'Your review takes only 10 seconds and helps more learners discover Japanese with MinnaLearn on Google Play!'
                  : 'We are constantly improving MinnaLearn! Please share your thoughts with us so we can make learning Japanese easier for you.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: AppColors.ink500,
                height: 1.35,
              ),
            ),

            const SizedBox(height: 16),

            // Interactive Star Rating row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final isSelected = index < _selectedStars;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedStars = index + 1;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: AnimatedScale(
                      scale: isSelected ? 1.05 : 0.95,
                      duration: const Duration(milliseconds: 150),
                      child: Icon(
                        LucideIcons.star,
                        size: 30,
                        color: isSelected
                            ? const Color(0xFFF59E0B)
                            : AppColors.ink200,
                      ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 22),

            // Primary Button
            if (isHighRating)
              BouncingWidget(
                scaleFactor: 0.95,
                onTap: _launchPlayStore,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF059669), Color(0xFF10B981)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border:
                        Border.all(color: const Color(0xFF34D399), width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFF047857),
                        offset: Offset(0, 4),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.star,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Rate on Google Play',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              BouncingWidget(
                scaleFactor: 0.95,
                onTap: _openDirectFeedbackModal,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: AppGradients.primaryHeader,
                    borderRadius: BorderRadius.circular(18),
                    border:
                        Border.all(color: const Color(0xFFF43F5E), width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFF9F1239),
                        offset: Offset(0, 4),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.messageSquare,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Send Us Feedback',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 10),

            // Secondary Button
            if (isHighRating)
              BouncingWidget(
                scaleFactor: 0.95,
                onTap: _openDirectFeedbackModal,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: AppColors.azureLight,
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: AppColors.azureBorder, width: 1.2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.messageSquare,
                          color: AppColors.azureDark, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Send Direct Feedback',
                        style: GoogleFonts.outfit(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.azureDark,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              BouncingWidget(
                scaleFactor: 0.95,
                onTap: _launchPlayStore,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: AppColors.ink100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.ink200, width: 1.2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.externalLink,
                          color: AppColors.ink700, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Open Google Play',
                        style: GoogleFonts.outfit(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // Maybe later
            TextButton(
              onPressed: _maybeLater,
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Maybe Later',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectFeedbackSheet extends StatefulWidget {
  const _DirectFeedbackSheet({Key? key}) : super(key: key);

  @override
  State<_DirectFeedbackSheet> createState() => _DirectFeedbackSheetState();
}

class _DirectFeedbackSheetState extends State<_DirectFeedbackSheet> {
  final TextEditingController _feedbackController = TextEditingController();
  String _selectedCategory = 'Suggestion';
  bool _isSending = false;

  final List<String> _categories = [
    'Suggestion',
    'Bug Report',
    'Vocabulary/Kanji',
    'Other'
  ];

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    final text = _feedbackController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your feedback')),
      );
      return;
    }

    setState(() => _isSending = true);

    final db = DatabaseService();
    await db.setUserStatText('playstore_review_status', 'feedback_sent');

    // Try saving to Firestore
    try {
      final user = AuthService().currentUser;
      final fs = FirebaseFirestore.instance;
      await fs.collection('feedback').add({
        'userId': user?.uid ?? 'anonymous',
        'userEmail': user?.email ?? 'anonymous',
        'category': _selectedCategory,
        'feedback': text,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Firestore feedback save failed, fallback to email: $e');
      final emailUri = Uri.parse(
        'mailto:maadhuavati7@gmail.com?subject=MinnaLearn%20Feedback%20($_selectedCategory)&body=${Uri.encodeComponent(text)}',
      );
      try {
        await launchUrl(emailUri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }

    if (mounted) {
      setState(() => _isSending = false);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              const Icon(LucideIcons.checkCircle,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Thank you for your feedback! Arigatou! 🙏',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.ink200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Send Your Feedback 💌',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.ink900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your thoughts directly shape the next updates of MinnaLearn.',
              style: GoogleFonts.outfit(fontSize: 13, color: AppColors.ink500),
            ),
            const SizedBox(height: 14),

            // Category selector
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = cat == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        cat,
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.ink700,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.ink100,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedCategory = cat);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 14),

            // Text field
            TextField(
              controller: _feedbackController,
              maxLines: 4,
              autofocus: true,
              style: GoogleFonts.outfit(fontSize: 14, color: AppColors.ink900),
              decoration: InputDecoration(
                hintText:
                    'What features would you love to see or what can we improve?',
                hintStyle:
                    GoogleFonts.outfit(fontSize: 13, color: AppColors.ink400),
                filled: true,
                fillColor: AppColors.ink100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      const BorderSide(color: AppColors.ink200, width: 1.2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Submit button
            BouncingWidget(
              scaleFactor: 0.95,
              onTap: _isSending ? null : _submitFeedback,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: AppGradients.primaryHeader,
                  borderRadius: BorderRadius.circular(18),
                  border:
                      Border.all(color: const Color(0xFFF43F5E), width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xFF9F1239),
                      offset: Offset(0, 4),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Center(
                  child: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LucideIcons.send,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Submit Feedback',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
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
