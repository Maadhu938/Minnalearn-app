import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../services/japanese_font_service.dart';
import '../utils/app_theme.dart';
import 'bouncing_widget.dart';

class JapaneseFontPickerDialog extends StatelessWidget {
  const JapaneseFontPickerDialog({Key? key}) : super(key: key);

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const JapaneseFontPickerDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: ValueListenableBuilder<String>(
        valueListenable: JapaneseFontService.currentFontNotifier,
        builder: (context, currentKey, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top drag pill
              Center(
                child: Container(
                  width: 42,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: AppColors.ink200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      LucideIcons.type,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Japanese Font Style',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Choose your preferred Japanese font for the entire app',
                          style: GoogleFonts.outfit(
                            fontSize: 12.5,
                            color: AppColors.ink500,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Font options
              ...JapaneseFontService.availableFonts.map((font) {
                final isSelected = font['key'] == currentKey;
                final key = font['key']!;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: BouncingWidget(
                    scaleFactor: 0.98,
                    onTap: () async {
                      await JapaneseFontService().setFont(key);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryLight.withOpacity(0.5)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.ink200.withOpacity(0.7),
                          width: isSelected ? 1.8 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Sample Box (Shows Kana + Kanji together)
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary.withOpacity(0.35)
                                    : AppColors.ink200,
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                font['sample'] ?? 'あ漢',
                                style: _getSampleStyle(key),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Font Title & Description
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  font['name']!,
                                  style: GoogleFonts.outfit(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.ink900,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  font['description']!,
                                  style: GoogleFonts.outfit(
                                    fontSize: 11.5,
                                    color: AppColors.ink500,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Clean Right-Aligned Selection Indicator
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.ink200,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    size: 15,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 8),

              // Bottom note indicating full-app coverage
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.ink100.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.sparkles,
                      size: 14,
                      color: AppColors.amberDark,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Applies to all vocabulary, grammar, kana, kanji, and games.',
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  TextStyle _getSampleStyle(String key) {
    switch (key) {
      case 'gothic':
        return GoogleFonts.notoSansJp(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.ink900,
        );
      case 'classic':
        return GoogleFonts.shipporiMincho(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.ink900,
        );
      case 'mincho':
      default:
        return GoogleFonts.sawarabiMincho(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.ink900,
        );
    }
  }
}
