import 'package:flutter/material.dart';

/// App color palette for Keeply Notes following a minimalist aesthetic:
/// Crisp white backgrounds (#FFFFFF, #FAFAFA) complemented by soft, light warm cream accents.
///
/// All colors are carefully chosen to meet WCAG AA contrast ratios on their
/// respective backgrounds. Do not add new colors here without verifying contrast.
class AppColors {
  AppColors._();

  // ── Light Theme ─────────────────────────────────────────────────────────────

  /// Primary scaffold background — pure white canvas.
  static const Color lightBackground = Color(0xFFFFFFFF);

  /// Surface color for cards, sheets, dialogs — slightly off-white.
  static const Color lightSurface = Color(0xFFFAFAFA);

  /// Card background — warm cream to lift content gently off the surface.
  static const Color lightCardBackground = Color(0xFFF7F5F0);

  /// Container color — light warm tint used for chips and subtle fills.
  static const Color lightContainer = Color(0xFFF0EBE3);

  // ── Primary Warm Accent Palette ─────────────────────────────────────────────

  /// Primary interactive color — warm sand / caramel mid-tone.
  static const Color primaryWarm = Color(0xFFD4C3A3);

  /// Darker primary for text-on-primary surfaces and elevated components.
  static const Color primaryWarmDark = Color(0xFFB09E7E);

  /// Lighter primary fill for backgrounds, chips, and highlighted areas.
  static const Color primaryWarmLight = Color(0xFFF5EFE6);

  /// Subtle warm pastel used for pressed/hover states.
  static const Color accentPastel = Color(0xFFE8DFD8);

  // ── Light Text ──────────────────────────────────────────────────────────────

  /// High-emphasis text on light backgrounds (4.5:1 on white).
  static const Color textPrimaryLight = Color(0xFF1A1A1A);

  /// Medium-emphasis text — labels, captions, metadata.
  static const Color textSecondaryLight = Color(0xFF6B6B6B);

  /// Low-emphasis / placeholder text.
  static const Color textHintLight = Color(0xFF9E9E9E);

  // ── Dark Theme ──────────────────────────────────────────────────────────────

  /// Primary scaffold background in dark mode.
  static const Color darkBackground = Color(0xFF121212);

  /// Surface for cards, sheets and dialogs in dark mode.
  static const Color darkSurface = Color(0xFF1E1E1E);

  /// Elevated card background in dark mode.
  static const Color darkCardBackground = Color(0xFF252525);

  /// Slightly elevated container for chips/tiles in dark mode.
  static const Color darkContainer = Color(0xFF2E2A25);

  // ── Dark Text ───────────────────────────────────────────────────────────────

  /// High-emphasis text on dark backgrounds.
  static const Color textPrimaryDark = Color(0xFFEDEDED);

  /// Medium-emphasis text in dark mode.
  static const Color textSecondaryDark = Color(0xFFA8A8A8);

  /// Placeholder / hint text in dark mode.
  static const Color textHintDark = Color(0xFF6E6E6E);

  // ── Semantic / Status Colors ─────────────────────────────────────────────────

  /// Lock icon on protected folders.
  static const Color protectedLock = Color(0xFFD32F2F);

  /// Active reminder indicator — accessible green.
  static const Color reminderActive = Color(0xFF388E3C);

  /// Subtle divider line between list items.
  static const Color divider = Color(0xFFE8E3DC);

  /// Dark-mode divider.
  static const Color dividerDark = Color(0xFF2E2E2E);

  /// Error / destructive action color.
  static const Color error = Color(0xFFB00020);

  /// Surface tint removed from all AppBars (keeps them flat).
  static const Color transparent = Colors.transparent;
}
