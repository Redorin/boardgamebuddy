import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Vibrant Retro Color Scheme - 80s/90s Arcade Vibes
class AppColors {
  // Primary Retro Colors - Vibrant & Electric
  static const Color primary = Color(0xFF77BEF0); // Bright Cyan Blue
  static const Color primaryDark = Color(0xFF5A9FD4); // Darker Cyan
  static const Color accent = Color(0xFFFFCB61); // Vibrant Gold/Yellow
  static const Color accentLight = Color(0xFFFFE291); // Light Gold

  // Secondary Colors - Retro Warm
  static const Color secondary = Color(0xFFFF894F); // Vibrant Orange
  static const Color tertiary = Color(0xFFEA5B6F); // Hot Pink/Coral

  // Background Colors - Dark with Retro Feel
  static const Color darkBg = Color(0xFF0A0A0A); // Deep Black
  static const Color darkBgSecondary = Color(0xFF1A1A2E); // Dark Purple-Blue
  static const Color surface = Color(0xFF16213E); // Navy Blue
  static const Color surfaceLight = Color(0xFF0F3460); // Slightly Lighter Navy

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF); // Pure White
  static const Color textSecondary = Color(0xFFFFCB61); // Gold (accent)
  static const Color textTertiary = Color(0xFF77BEF0); // Cyan (primary)

  // Semantic Colors - Retro Bright
  static const Color success = Color(0xFF00FF00); // Neon Green
  static const Color warning = Color(0xFFFFAA00); // Retro Orange
  static const Color error = Color(0xFFFF0000); // Bright Red
  static const Color info = Color(0xFF77BEF0); // Cyan

  // Gradient - Retro Synthwave
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF77BEF0), Color(0xFFFFCB61)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFF894F), Color(0xFFEA5B6F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// Text styles - Mix of 8-bit (VT323) and modern (Inter) fonts
class AppTextStyles {
  // 8-bit pixel style for large prominent text
  static TextStyle headingLarge = GoogleFonts.vt323(
    fontSize: 32,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary, // Gold for impact
    letterSpacing: 2.0,
  );

  // 8-bit style for medium headings
  static TextStyle headingMedium = GoogleFonts.vt323(
    fontSize: 20,
    fontWeight: FontWeight.normal,
    color: AppColors.primary, // Cyan
    letterSpacing: 1.5,
  );

  // 8-bit for smaller headings
  static TextStyle headingSmall = GoogleFonts.vt323(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.accent,
    letterSpacing: 1.0,
  );

  // Modern clean font for body
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    letterSpacing: 0.3,
  );

  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    letterSpacing: 0.2,
  );

  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
    letterSpacing: 0.1,
  );

  // 8-bit labels for emphasis
  static TextStyle labelLarge = GoogleFonts.vt323(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.accent,
    letterSpacing: 1.0,
  );

  static TextStyle labelSmall = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.8,
  );
}

// Spacing constants
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

// Animation constants
class AppAnimation {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
}

// Border Radius
class AppRadius {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 999;
}
