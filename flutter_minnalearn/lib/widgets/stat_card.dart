import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/app_theme.dart';
import 'bouncing_widget.dart';

class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color bgColor;
  final IconData? icon;
  final Widget? customIcon;
  final Color? accentColor;
  final VoidCallback? onTap;

  const StatCard({
    Key? key,
    required this.value,
    required this.label,
    required this.bgColor,
    this.icon,
    this.customIcon,
    this.accentColor,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveAccent = accentColor ?? AppColors.primary;

    return BouncingWidget(
      scaleFactor: onTap != null ? 0.96 : 1.0,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.ink200.withOpacity(0.8),
            width: 1.2,
          ),
          boxShadow: AppShadows.subtle,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (customIcon != null || icon != null) ...[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: customIcon ??
                      Icon(
                        icon,
                        size: 16,
                        color: effectiveAccent,
                      ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: AppColors.ink900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.ink500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
