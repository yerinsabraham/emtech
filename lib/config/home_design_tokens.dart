import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────
// GLOBAL COLOR SYSTEM
// ─────────────────────────────────────────────

class AppColors {
  // ── Backgrounds ──────────────────────────────
  static const background = Color(0xFF0A0E1A); // deep navy
  static const surface = Color(0xFF111827); // card base
  static const surface2 = Color(0xFF1A2438); // elevated card
  static const surfaceActive = Color(0xFF1E2D45); // hover / active
  static const cardDark = Color(0xFF1E1E2E); // dark accent panel

  // ── Primary: Violet-Purple ────────────────────
  static const primary = Color(0xFF6C63FF);
  static const primaryMuted = Color(0x296C63FF); // 16 % fill
  static const primarySoft = Color(0xFF9B94FF); // light tint
  static const onPrimary = Color(0xFFFFFFFF);

  // ── Accent 1: Amber Gold ─────────────────────
  static const accent = Color(0xFFFFB703);
  static const accentMuted = Color(0x29FFB703); // 16 % fill
  static const onAccent = Color(0xFF1A1400);

  // ── Accent 2: Teal Mint ───────────────────────
  static const teal = Color(0xFF00D4AA);
  static const tealMuted = Color(0x2200D4AA); // 13 % fill
  static const onTeal = Color(0xFF001A15);

  // ── Text ─────────────────────────────────────
  static const textPrimary = Color(0xFFF0F4FF);
  static const textMuted = Color(0xFF7A8BA6);
  static const textSubtle = Color(0xFF4A5A72);

  // ── Neutral Greys ────────────────────────────
  static const grey100 = Color(0xFF1A2438);
  static const grey200 = Color(0xFF263347);
  static const grey400 = Color(0xFF3A5070);
  static const grey600 = Color(0xFF7A8BA6);

  // ── Strokes & Shadow ─────────────────────────
  static const stroke = Color(0xFF1F2E42);
  static const divider = Color(0x14FFFFFF);
  static const shadow = Color(0x22000000);
  static const shadowPrimary = Color(0x446C63FF);
  static const overlay = Color(0x99000000);
}

/// Ready-made gradients for cards and surfaces.
class AppGradients {
  static const primaryCard = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF9B8FFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const accentCard = LinearGradient(
    colors: [Color(0xFFFFB703), Color(0xFFFFCF40)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const tealCard = LinearGradient(
    colors: [Color(0xFF00D4AA), Color(0xFF00B894)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const darkSheet = LinearGradient(
    colors: [Color(0xFF111827), Color(0xFF0A0E1A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

// ─────────────────────────────────────────────
// HOME WIDGET TOKENS  (reference AppColors)
// ─────────────────────────────────────────────

class HomeColors {
  static const Color bg = AppColors.background;
  static const Color surface1 = AppColors.surface;
  static const Color surface2 = AppColors.surface2;
  static const Color textPrimary = AppColors.textPrimary;
  static const Color textMuted = AppColors.textMuted;
  static const Color stroke = AppColors.stroke;
  static const Color accentWhite = AppColors.textPrimary;
  static const Color shadow = AppColors.shadow;
  static const Color overlay = AppColors.overlay;
}

class HomeSpacing {
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
}

class HomeRadius {
  static const double r12 = 12;
  static const double r16 = 16;
  static const double r20 = 20;
  static const double r24 = 24;
}

class HomeTypography {
  static TextStyle get display => GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: -0.4,
    color: HomeColors.textPrimary,
  );

  static TextStyle get title => GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: HomeColors.textPrimary,
  );

  static TextStyle get body => GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.textMuted,
  );

  static TextStyle get caption => GoogleFonts.poppins(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: AppColors.textMuted,
  );

  static TextStyle get button => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AppColors.onPrimary,
  );
}

class HomeSizes {
  static const double iconSmall = 16;
  static const double iconMedium = 20;
  static const double iconLarge = 24;
  static const double avatar = 36;
  static const double chipHeight = 38;
  static const double heroCardHeight = 235;
  static const double quickActionHeight = 110;
  static const double footerTileSize = 52;
}

class HomeEffects {
  static const double blur = 12;
  static const double borderWidth = 1;
  static const double softElevation = 22;
  static const Offset shadowOffset = Offset(0, 10);
}
