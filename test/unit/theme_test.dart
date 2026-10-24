import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keeply_notes/core/constants/app_colors.dart';
import 'package:keeply_notes/core/theme/app_theme.dart';
import 'package:keeply_notes/core/theme/theme_mode_cubit.dart';

void main() {
  group('AppColors', () {
    test('defines required light and dark palette constants', () {
      expect(AppColors.lightBackground, const Color(0xFFFFFFFF));
      expect(AppColors.lightSurface, const Color(0xFFFAFAFA));
      expect(AppColors.darkBackground, const Color(0xFF121212));
      expect(AppColors.darkSurface, const Color(0xFF1E1E1E));
      expect(AppColors.primaryWarm, isNotNull);
      expect(AppColors.primaryWarmDark, isNotNull);
    });
  });

  group('AppTheme', () {
    test('lightTheme has Material 3 enabled and correct brightness', () {
      final theme = AppTheme.lightTheme;
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.light);
      expect(theme.scaffoldBackgroundColor, AppColors.lightBackground);
      expect(theme.colorScheme.primary, AppColors.primaryWarmDark);
      expect(theme.colorScheme.surface, AppColors.lightSurface);
      expect(theme.cardTheme.elevation, 0);
    });

    test('darkTheme has Material 3 enabled and correct brightness', () {
      final theme = AppTheme.darkTheme;
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, AppColors.darkBackground);
      expect(theme.colorScheme.primary, AppColors.primaryWarm);
      expect(theme.colorScheme.surface, AppColors.darkSurface);
      expect(theme.cardTheme.elevation, 0);
    });

    test('themes have configured textTheme and component themes', () {
      final light = AppTheme.lightTheme;
      expect(light.textTheme.titleMedium, isNotNull);
      expect(light.inputDecorationTheme.filled, isTrue);
      expect(light.floatingActionButtonTheme.backgroundColor, AppColors.primaryWarmDark);
      expect(light.dialogTheme.shape, isNotNull);

      final dark = AppTheme.darkTheme;
      expect(dark.textTheme.titleMedium, isNotNull);
      expect(dark.inputDecorationTheme.filled, isTrue);
      expect(dark.floatingActionButtonTheme.backgroundColor, AppColors.primaryWarm);
    });
  });

  group('ThemeModeCubit', () {
    test('defaults to ThemeMode.system', () {
      final cubit = ThemeModeCubit();
      expect(cubit.mode, ThemeMode.system);
    });

    test('switching modes notifies listeners', () {
      final cubit = ThemeModeCubit();
      int callCount = 0;
      cubit.addListener(() => callCount++);

      cubit.setDark();
      expect(cubit.mode, ThemeMode.dark);
      expect(callCount, 1);

      cubit.setLight();
      expect(cubit.mode, ThemeMode.light);
      expect(callCount, 2);

      cubit.setSystem();
      expect(cubit.mode, ThemeMode.system);
      expect(callCount, 3);

      // Setting same mode does not re-notify
      cubit.setSystem();
      expect(callCount, 3);
    });
  });
}
