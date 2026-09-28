import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central Design System for MinnaLearn
/// Authentic Japanese Modern Aesthetic (Akane Crimson, Warm Sun Amber, Bamboo Emerald, Sky Azure)
/// Zero purple/violet, non-AI modern tactile design.
class AppColors {
  // Primary: Japanese Akane Crimson (Torii gate inspiration)
  static const Color primary = Color(0xFFE11D48);
  static const Color primaryDark = Color(0xFFBE123C);
  static const Color primaryLight = Color(0xFFFFF1F2);
  static const Color primaryBorder = Color(0xFFFECDD3);

  // Accent / Energy: Warm Sun Amber
  static const Color amber = Color(0xFFF59E0B);
  static const Color amberDark = Color(0xFFD97706);
  static const Color amberLight = Color(0xFFFEF3C7);
  static const Color amberBorder = Color(0xFFFDE68A);

  // Success / Mastery: Bamboo Emerald
  static const Color bamboo = Color(0xFF10B981);
  static const Color bambooDark = Color(0xFF059669);
  static const Color bambooLight = Color(0xFFD1FAE5);
  static const Color bambooBorder = Color(0xFFA7F3D0);

  // Study / Info: Sky Azure
  static const Color azure = Color(0xFF0284C7);
  static const Color azureDark = Color(0xFF0369A1);
  static const Color azureLight = Color(0xFFE0F2FE);
  static const Color azureBorder = Color(0xFFBAE6FD);

  // Sunset Coral (Warm Orange-Red)
  static const Color coral = Color(0xFFEA580C);
  static const Color coralDark = Color(0xFFC2410C);
  static const Color coralLight = Color(0xFFFFEDD5);
  static const Color coralBorder = Color(0xFFFED7AA);

  // Neutrals & Sumi Ink
  static const Color ink900 = Color(0xFF0F172A); // Primary headlines
  static const Color ink700 = Color(0xFF334155); // Body text
  static const Color ink500 = Color(0xFF64748B); // Secondary / subtitles
  static const Color ink400 = Color(0xFF94A3B8); // Muted / placeholders
  static const Color ink200 = Color(0xFFE2E8F0); // Card borders & dividers
  static const Color ink100 = Color(0xFFF1F5F9); // Light pill fills
  static const Color border = Color(0xFFE2E8F0); // Default card border

  // Surfaces
  static const Color scaffold = Color(0xFFF8FAFC); // Crisp porcelain off-white
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardAlt = Color(0xFFFAFAFA);
}

class AppGradients {
  static const LinearGradient primaryHeader = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFE11D48),
      Color(0xFFF43F5E),
      Color(0xFFFB7185),
    ],
  );

  static const LinearGradient primaryDeep = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF9F1239),
      Color(0xFFBE123C),
      Color(0xFFE11D48),
    ],
  );

  static const LinearGradient amber = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF59E0B),
      Color(0xFFD97706),
    ],
  );

  static const LinearGradient bamboo = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF10B981),
      Color(0xFF059669),
    ],
  );

  static const LinearGradient azure = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0284C7),
      Color(0xFF0369A1),
    ],
  );

  static const LinearGradient coral = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF97316),
      Color(0xFFEA580C),
    ],
  );

  static const LinearGradient kanaCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFBEB),
      Color(0xFFFEF3C7),
    ],
  );
}

class AppShadows {
  static final List<BoxShadow> subtle = [
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.04),
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
  ];

  static final List<BoxShadow> card = [
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.05),
      blurRadius: 14,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.02),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static final List<BoxShadow> elevated = [
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.08),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.03),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  static final List<BoxShadow> primaryGlow = [
    BoxShadow(
      color: AppColors.primary.withOpacity(0.28),
      blurRadius: 14,
      offset: const Offset(0, 5),
    ),
  ];

  static final List<BoxShadow> amberGlow = [
    BoxShadow(
      color: AppColors.amber.withOpacity(0.25),
      blurRadius: 14,
      offset: const Offset(0, 5),
    ),
  ];
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.scaffold,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.amber,
        surface: AppColors.card,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(
          color: AppColors.ink900,
          fontWeight: FontWeight.w800,
        ),
        headlineLarge: GoogleFonts.inter(
          color: AppColors.ink900,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: GoogleFonts.inter(
          color: AppColors.ink900,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: GoogleFonts.inter(
          color: AppColors.ink700,
        ),
        bodyMedium: GoogleFonts.inter(
          color: AppColors.ink700,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
