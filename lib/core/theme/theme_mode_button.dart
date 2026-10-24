import 'package:flutter/material.dart';
import '../../theme/theme_mode_cubit.dart';

/// AppBar icon button that cycles through [ThemeMode] values.
///
/// Displays a sun, moon, or auto icon depending on the current mode and
/// delegates the toggle to [ThemeModeCubit].
class ThemeModeButton extends StatelessWidget {
  const ThemeModeButton({
    super.key,
    required this.cubit,
  });

  final ThemeModeCubit cubit;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: cubit,
      builder: (context, _) {
        return IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: child,
            ),
            child: _buildIcon(cubit.mode),
          ),
          tooltip: _tooltip(cubit.mode),
          onPressed: () => _onPressed(context),
        );
      },
    );
  }

  Widget _buildIcon(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => const Icon(
          Icons.light_mode_rounded,
          key: ValueKey(ThemeMode.light),
        ),
      ThemeMode.dark => const Icon(
          Icons.dark_mode_rounded,
          key: ValueKey(ThemeMode.dark),
        ),
      ThemeMode.system => const Icon(
          Icons.brightness_auto_rounded,
          key: ValueKey(ThemeMode.system),
        ),
    };
  }

  String _tooltip(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'Light mode (tap for dark)',
        ThemeMode.dark => 'Dark mode (tap for system)',
        ThemeMode.system => 'System theme (tap for light)',
      };

  void _onPressed(BuildContext context) {
    // Cycle: system → light → dark → system
    final next = switch (cubit.mode) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    cubit.setMode(next);
  }
}
