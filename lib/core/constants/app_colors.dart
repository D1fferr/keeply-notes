import 'package:flutter/material.dart';

/// App color palette for Keeply Notes following a minimalist aesthetic:
/// Crisp white backgrounds (#FFFFFF, #FAFAFA) complemented by soft, light warm cream accents.
class AppColors {
  AppColors._();

  // Light Theme Colors
  static const Color lightBackground = Color(#FFFFFF);
  static const Color lightSurface = Color(#FAFAFA);
  static const Color lightCardBackground = Color(#F7F5F0);
  
  // Primary Warm Accents
  static const Color primaryWarm = Color(#D4C3A3);
  static const Color primaryWarmDark = Color(#B09E7E);
  static const Color primaryWarmLight = Color(#F5EFE6);
  static const Color accentPastel = Color(#E8DFD8);

  // Text Colors
  static const Color textPrimaryLight = Color(#1A1A1A);
  static const Color textSecondaryLight = Color(#757575);
  static const Color textHintLight = Color(#9E9E9E);

  // Dark Theme Colors
  static const Color darkBackground = Color(#121212);
  static const Color darkSurface = Color(#1E1E1E);
  static const Color darkCardBackground = Color(#252525);
  static const Color textPrimaryDark = Color(#E0E0E0);
  static const Color textSecondaryDark = Color(#A0A0A0);

  // Status & Utility Colors
  static const Color protectedLock = Color(#D32F2F);
  static const Color reminderActive = Color(#388E3C);
  static const Color divider = Color(#E0E0E0);
}
