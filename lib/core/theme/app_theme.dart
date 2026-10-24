import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

/// Central theme definition for Keeply Notes.
///
/// Design intent:
/// - Material 3 with flat, elevation-free surfaces.
/// - Crisp white (#FFFFFF / #FAFAFA) backgrounds in light mode.
/// - Warm cream (#F7F5F0, #F5EFE6) accents instead of cold greys.
/// - Deep near-black (#1A1A1A) typography for high legibility.
/// - True dark mode: deep charcoal (#121212) with warm-tinted surfaces.
/// - Rounded corners throughout (12 dp cards, 16 dp dialogs/sheets).
/// - No surface tint colour leaking into AppBars or Cards.
class AppTheme {
  AppTheme._();

  // ── Shared geometry constants ──────────────────────────────────────────────

  static const double _cardRadius = 14.0;
  static const double _dialogRadius = 20.0;
  static const double _inputRadius = 12.0;
  static const double _chipRadius = 8.0;

  // ─────────────────────────────────────────────────────────────────────────
  // LIGHT THEME
  // ─────────────────────────────────────────────────────────────────────────

  static ThemeData get lightTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      // Primary — warm caramel / sand
      primary: AppColors.primaryWarmDark,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryWarmLight,
      onPrimaryContainer: Color(0xFF3D2C0E),
      // Secondary — lighter warm tint
      secondary: AppColors.primaryWarm,
      onSecondary: Color(0xFF1A1A1A),
      secondaryContainer: AppColors.lightContainer,
      onSecondaryContainer: Color(0xFF3D2C0E),
      // Tertiary — soft pastel accent
      tertiary: AppColors.accentPastel,
      onTertiary: Color(0xFF1A1A1A),
      tertiaryContainer: AppColors.primaryWarmLight,
      onTertiaryContainer: Color(0xFF3D2C0E),
      // Error
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF410002),
      // Surfaces
      surface: AppColors.lightSurface,
      onSurface: AppColors.textPrimaryLight,
      surfaceContainerHighest: AppColors.lightCardBackground,
      onSurfaceVariant: AppColors.textSecondaryLight,
      // Outline
      outline: AppColors.divider,
      outlineVariant: Color(0xFFECE7DF),
      // Inverse
      inverseSurface: Color(0xFF313030),
      onInverseSurface: Color(0xFFF4F0EE),
      inversePrimary: AppColors.primaryWarm,
      // Shadow / scrim
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.lightBackground,

      // ── Typography ─────────────────────────────────────────────────────────
      textTheme: _buildTextTheme(AppColors.textPrimaryLight),

      // ── AppBar ─────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        surfaceTintColor: AppColors.transparent,
        shadowColor: AppColors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.textPrimaryLight,
          size: 24,
        ),
        actionsIconTheme: const IconThemeData(
          color: AppColors.textSecondaryLight,
          size: 24,
        ),
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimaryLight,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),

      // ── Card ───────────────────────────────────────────────────────────────
      cardTheme: CardTheme(
        color: AppColors.lightCardBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_cardRadius),
        ),
      ),

      // ── Dialog ─────────────────────────────────────────────────────────────
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_dialogRadius),
        ),
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimaryLight,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: const TextStyle(
          color: AppColors.textSecondaryLight,
          fontSize: 14,
          height: 1.5,
        ),
      ),

      // ── Bottom Sheet ────────────────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        modalElevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(_dialogRadius),
          ),
        ),
        showDragHandle: true,
        dragHandleColor: AppColors.divider,
      ),

      // ── FAB ────────────────────────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryWarmDark,
        foregroundColor: Colors.white,
        elevation: 2,
        highlightElevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        extendedTextStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          letterSpacing: 0.1,
        ),
      ),

      // ── Input Decoration ────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightContainer,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: const BorderSide(
            color: AppColors.primaryWarmDark,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: const TextStyle(
          color: AppColors.textHintLight,
          fontSize: 14,
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondaryLight,
          fontSize: 14,
        ),
      ),

      // ── Chip ───────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightContainer,
        selectedColor: AppColors.primaryWarmLight,
        disabledColor: AppColors.lightCardBackground,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimaryLight,
        ),
        secondaryLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.primaryWarmDark,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_chipRadius),
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      // ── Divider ────────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      // ── List Tile ──────────────────────────────────────────────────────────
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        minLeadingWidth: 24,
        style: ListTileStyle.list,
      ),

      // ── Icon Button ────────────────────────────────────────────────────────
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.textSecondaryLight,
          highlightColor: AppColors.primaryWarmLight,
        ),
      ),

      // ── Text Button ────────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryWarmDark,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),

      // ── Elevated Button ────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryWarmDark,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),

      // ── SnackBar ───────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF313030),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13,
        ),
        actionTextColor: AppColors.primaryWarm,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 4,
      ),

      // ── Switch ─────────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return AppColors.textHintLight;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryWarmDark;
          }
          return AppColors.lightContainer;
        }),
        trackOutlineColor:
            WidgetStateProperty.all(Colors.transparent),
      ),

      // ── Scrollbar ──────────────────────────────────────────────────────────
      scrollbarTheme: const ScrollbarThemeData(
        thickness: WidgetStatePropertyAll(3),
        radius: Radius.circular(4),
      ),

      // ── Navigation ─────────────────────────────────────────────────────────
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DARK THEME
  // ─────────────────────────────────────────────────────────────────────────

  static ThemeData get darkTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      // Primary
      primary: AppColors.primaryWarm,
      onPrimary: Color(0xFF1A1A1A),
      primaryContainer: Color(0xFF3D2C0E),
      onPrimaryContainer: AppColors.primaryWarmLight,
      // Secondary
      secondary: AppColors.primaryWarmDark,
      onSecondary: Color(0xFF1A1A1A),
      secondaryContainer: Color(0xFF2E2A25),
      onSecondaryContainer: AppColors.primaryWarmLight,
      // Tertiary
      tertiary: AppColors.accentPastel,
      onTertiary: Color(0xFF1A1A1A),
      tertiaryContainer: Color(0xFF3D2C0E),
      onTertiaryContainer: AppColors.primaryWarmLight,
      // Error
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      // Surfaces
      surface: AppColors.darkSurface,
      onSurface: AppColors.textPrimaryDark,
      surfaceContainerHighest: AppColors.darkCardBackground,
      onSurfaceVariant: AppColors.textSecondaryDark,
      // Outline
      outline: AppColors.dividerDark,
      outlineVariant: Color(0xFF3A3530),
      // Inverse
      inverseSurface: AppColors.lightSurface,
      onInverseSurface: AppColors.textPrimaryLight,
      inversePrimary: AppColors.primaryWarmDark,
      // Shadow / scrim
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBackground,

      // ── Typography ─────────────────────────────────────────────────────────
      textTheme: _buildTextTheme(AppColors.textPrimaryDark),

      // ── AppBar ─────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        surfaceTintColor: AppColors.transparent,
        shadowColor: AppColors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.textPrimaryDark,
          size: 24,
        ),
        actionsIconTheme: const IconThemeData(
          color: AppColors.textSecondaryDark,
          size: 24,
        ),
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimaryDark,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),

      // ── Card ───────────────────────────────────────────────────────────────
      cardTheme: CardTheme(
        color: AppColors.darkCardBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_cardRadius),
        ),
      ),

      // ── Dialog ─────────────────────────────────────────────────────────────
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: Colors.black54,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_dialogRadius),
        ),
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimaryDark,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: const TextStyle(
          color: AppColors.textSecondaryDark,
          fontSize: 14,
          height: 1.5,
        ),
      ),

      // ── Bottom Sheet ────────────────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 12,
        modalElevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(_dialogRadius),
          ),
        ),
        showDragHandle: true,
        dragHandleColor: AppColors.dividerDark,
      ),

      // ── FAB ────────────────────────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryWarm,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 2,
        highlightElevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        extendedTextStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          letterSpacing: 0.1,
        ),
      ),

      // ── Input Decoration ────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkContainer,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: const BorderSide(
            color: AppColors.primaryWarm,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: const BorderSide(
            color: Color(0xFFFFB4AB),
            width: 1.5,
          ),
        ),
        hintStyle: const TextStyle(
          color: AppColors.textHintDark,
          fontSize: 14,
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondaryDark,
          fontSize: 14,
        ),
      ),

      // ── Chip ───────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkContainer,
        selectedColor: const Color(0xFF3D2C0E),
        disabledColor: AppColors.darkSurface,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimaryDark,
        ),
        secondaryLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.primaryWarm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_chipRadius),
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      // ── Divider ────────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerDark,
        thickness: 1,
        space: 1,
      ),

      // ── List Tile ──────────────────────────────────────────────────────────
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        minLeadingWidth: 24,
        style: ListTileStyle.list,
      ),

      // ── Icon Button ────────────────────────────────────────────────────────
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.textSecondaryDark,
          highlightColor: AppColors.darkContainer,
        ),
      ),

      // ── Text Button ────────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryWarm,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),

      // ── Elevated Button ────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryWarm,
          foregroundColor: const Color(0xFF1A1A1A),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),

      // ── SnackBar ───────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkCardBackground,
        contentTextStyle: const TextStyle(
          color: AppColors.textPrimaryDark,
          fontSize: 13,
        ),
        actionTextColor: AppColors.primaryWarm,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 4,
      ),

      // ── Switch ─────────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF1A1A1A);
          }
          return AppColors.textHintDark;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryWarm;
          }
          return AppColors.darkContainer;
        }),
        trackOutlineColor:
            WidgetStateProperty.all(Colors.transparent),
      ),

      // ── Scrollbar ──────────────────────────────────────────────────────────
      scrollbarTheme: const ScrollbarThemeData(
        thickness: WidgetStatePropertyAll(3),
        radius: Radius.circular(4),
      ),

      // ── Page transitions ────────────────────────────────────────────────────
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TYPOGRAPHY HELPER
  // ─────────────────────────────────────────────────────────────────────────

  /// Builds a [TextTheme] using the system default font with the given primary
  /// text [color].  All sizes follow the Material 3 type scale.
  static TextTheme _buildTextTheme(Color color) {
    final secondary = color.withOpacity(0.6);
    final hint = color.withOpacity(0.38);

    return TextTheme(
      // Display — large hero text (rare in this app)
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        color: color,
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        color: color,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: color,
      ),

      // Headline — section titles, sheet titles
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: color,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: color,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: color,
      ),

      // Title — AppBar titles, card headings, dialog titles
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: color,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: color,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: color,
      ),

      // Body — main readable content
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        height: 1.5,
        color: color,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        height: 1.5,
        color: color,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
        height: 1.4,
        color: secondary,
      ),

      // Label — chips, buttons, metadata, small caps
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: color,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: secondary,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: hint,
      ),
    );
  }
}
