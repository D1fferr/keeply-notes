import 'package:flutter/material.dart';

/// Cubit that manages the application [ThemeMode] (light / dark / system).
///
/// The cubit exposes a simple [ThemeMode] value state and three convenience
/// methods for switching modes.  Persistence (e.g. to SharedPreferences or
/// secure storage) can be plugged in via [onChanged] if needed in the future.
class ThemeModeCubit extends ChangeNotifier {
  ThemeModeCubit({ThemeMode initial = ThemeMode.system})
      : _mode = initial;

  ThemeMode _mode;

  /// The currently active [ThemeMode].
  ThemeMode get mode => _mode;

  /// Switch to the given [mode] and notify listeners.
  void setMode(ThemeMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
  }

  /// Convenience: switch to light mode.
  void setLight() => setMode(ThemeMode.light);

  /// Convenience: switch to dark mode.
  void setDark() => setMode(ThemeMode.dark);

  /// Convenience: follow the system setting.
  void setSystem() => setMode(ThemeMode.system);

  /// Toggle between light and dark (ignoring system for a manual override).
  void toggle(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final effectiveBrightness = _mode == ThemeMode.system
        ? brightness
        : (_mode == ThemeMode.light ? Brightness.light : Brightness.dark);

    if (effectiveBrightness == Brightness.dark) {
      setLight();
    } else {
      setDark();
    }
  }
}
