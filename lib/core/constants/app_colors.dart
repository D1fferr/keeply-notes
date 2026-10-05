import 'package:flutter/material.dart';

/// App color palette for Keeply Notes following a minimalist aesthetic:
/// Crisp white backgrounds (#FFFFFF, #FAFAFA) complemented by soft, light warm cream accents.
class AppColors {
  AppColors._();

  // Light Theme Colors
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFFAFAFA);
  static const Color lightCardBackground = Color(0xFFF7F5F0);

  // Primary Warm Accents
  static const Color primaryWarm = Color(0xFFD4C3A3);
  static const Color primaryWarmDark = Color(0xFFB09E7E);
  static const Color primaryWarmLight = Color(0xFFF5EFE6);
  static const Color accentPastel = Color(0xFFE8DFD8);

  // Text Colors
  static const Color textPrimaryLight = Color(0xFF1A1A1A);
  static const Color textSecondaryLight = Color(0xFF757575);
  static const Color textHintLight = Color(0xFF9E9E9E);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCardBackground = Color(0xFF252525);
  static const Color textPrimaryDark = Color(0xFFE0E0E0);
  static const Color textSecondaryDark = Color(0xFFA0A0A0);

  // Status & Utility Colors
  static const Color protectedLock = Color(0xFFD32F2F);
  static const Color reminderActive = Color(0xFF388E3C);
  static const Color divider = Color(0xFFE0E0E0);
}
