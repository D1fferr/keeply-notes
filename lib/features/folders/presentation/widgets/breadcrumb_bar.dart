import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../cubit/folder_state.dart';

/// Horizontal scrollable breadcrumb navigation bar.
///
/// Renders the trail as: `Home  ›  Work  ›  Projects`
/// Each crumb is tappable. The current (last) crumb is non-tappable and bold.
class BreadcrumbBar extends StatelessWidget {
  const BreadcrumbBar({
    super.key,
    required this.breadcrumb,
    required this.onCrumbTap,
  });

  final List<BreadcrumbItem> breadcrumb;

  /// Called with the index in [breadcrumb] when a crumb is tapped.
  final void Function(int index) onCrumbTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final activeColor =
        isLight ? AppColors.textPrimaryLight : AppColors.textPrimaryDark;
    final inactiveColor =
        isLight ? AppColors.textSecondaryLight : AppColors.textSecondaryDark;

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: breadcrumb.length,
        separatorBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(
            Icons.chevron_right_rounded,
            size: 16,
            color: inactiveColor,
          ),
        ),
        itemBuilder: (context, index) {
          final crumb = breadcrumb[index];
          final isLast = index == breadcrumb.length - 1;

          if (isLast) {
            // Current folder — non-interactive, emphasised
            return Align(
              alignment: Alignment.centerLeft,
              child: Text(
                crumb.name,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: activeColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }

          return Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () => onCrumbTap(index),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                child: Text(
                  crumb.name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: inactiveColor,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
