import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../../../core/constants/app_colors.dart';

/// Minimalist rich text formatting toolbar for Keeply Notes.
///
/// Supports:
/// - Undo / Redo
/// - Bold, Italic
/// - Header 1, Header 2
/// - Bullet list, Numbered list
/// - Checkbox / To-do list
/// - Blockquote
///
/// Designed with warm cream highlights and rounded pill styling.
class NoteFormattingToolbar extends StatefulWidget {
  const NoteFormattingToolbar({
    super.key,
    required this.controller,
  });

  final QuillController controller;

  @override
  State<NoteFormattingToolbar> createState() => _NoteFormattingToolbarState();
}

class _NoteFormattingToolbarState extends State<NoteFormattingToolbar> {
  QuillController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant NoteFormattingToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  // ─── Format toggle helper ─────────────────────────────────────────────────

  void _toggleAttribute(Attribute attribute) {
    final style = _controller.getSelectionStyle();
    final isPresent = style.containsKey(attribute.key) &&
        style.attributes[attribute.key]?.value == attribute.value;

    if (isPresent) {
      _controller.formatSelection(Attribute.clone(attribute, null));
    } else {
      _controller.formatSelection(attribute);
    }
  }

  bool _isAttributeActive(Attribute attribute) {
    final style = _controller.getSelectionStyle();
    return style.containsKey(attribute.key) &&
        style.attributes[attribute.key]?.value == attribute.value;
  }

  bool _isHeaderActive(int level) {
    final style = _controller.getSelectionStyle();
    final attr = style.attributes[Attribute.header.key];
    return attr != null && attr.value == level;
  }

  void _toggleHeader(int level) {
    if (_isHeaderActive(level)) {
      _controller.formatSelection(Attribute.clone(Attribute.header, null));
    } else {
      final headerAttr = switch (level) {
        1 => Attribute.h1,
        2 => Attribute.h2,
        3 => Attribute.h3,
        _ => Attribute.header,
      };
      _controller.formatSelection(headerAttr);
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.darkCardBackground : AppColors.lightSurface;
    final borderColor =
        isDark ? Colors.white.withOpacity(0.08) : AppColors.divider;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          top: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Undo
            _ToolbarIconButton(
              icon: Icons.undo_rounded,
              tooltip: 'Undo',
              enabled: _controller.hasUndo,
              onPressed: _controller.undo,
            ),
            // Redo
            _ToolbarIconButton(
              icon: Icons.redo_rounded,
              tooltip: 'Redo',
              enabled: _controller.hasRedo,
              onPressed: _controller.redo,
            ),
            const _ToolbarDivider(),
            // Bold
            _ToolbarIconButton(
              icon: Icons.format_bold_rounded,
              tooltip: 'Bold',
              isActive: _isAttributeActive(Attribute.bold),
              onPressed: () => _toggleAttribute(Attribute.bold),
            ),
            // Italic
            _ToolbarIconButton(
              icon: Icons.format_italic_rounded,
              tooltip: 'Italic',
              isActive: _isAttributeActive(Attribute.italic),
              onPressed: () => _toggleAttribute(Attribute.italic),
            ),
            const _ToolbarDivider(),
            // Header 1
            _ToolbarTextButton(
              label: 'H1',
              tooltip: 'Header 1',
              isActive: _isHeaderActive(1),
              onPressed: () => _toggleHeader(1),
            ),
            // Header 2
            _ToolbarTextButton(
              label: 'H2',
              tooltip: 'Header 2',
              isActive: _isHeaderActive(2),
              onPressed: () => _toggleHeader(2),
            ),
            const _ToolbarDivider(),
            // Bullet List
            _ToolbarIconButton(
              icon: Icons.format_list_bulleted_rounded,
              tooltip: 'Bullet List',
              isActive: _isAttributeActive(Attribute.ul),
              onPressed: () => _toggleAttribute(Attribute.ul),
            ),
            // Numbered List
            _ToolbarIconButton(
              icon: Icons.format_list_numbered_rounded,
              tooltip: 'Numbered List',
              isActive: _isAttributeActive(Attribute.ol),
              onPressed: () => _toggleAttribute(Attribute.ol),
            ),
            // Checkbox / To-Do
            _ToolbarIconButton(
              icon: Icons.check_box_outlined,
              tooltip: 'Checkbox List',
              isActive: _isAttributeActive(Attribute.unchecked) ||
                  _isAttributeActive(Attribute.checked),
              onPressed: () => _toggleAttribute(Attribute.unchecked),
            ),
            const _ToolbarDivider(),
            // Blockquote
            _ToolbarIconButton(
              icon: Icons.format_quote_rounded,
              tooltip: 'Quote',
              isActive: _isAttributeActive(Attribute.blockQuote),
              onPressed: () => _toggleAttribute(Attribute.blockQuote),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Button components ────────────────────────────────────────────────────────

class _ToolbarIconButton extends StatelessWidget {
  const _ToolbarIconButton({
    required this.icon,
    required this.tooltip,
    this.isActive = false,
    this.enabled = true,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool isActive;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeBg = isDark
        ? AppColors.primaryWarm.withOpacity(0.25)
        : AppColors.primaryWarmLight;
    final activeColor =
        isDark ? AppColors.primaryWarm : AppColors.primaryWarmDark;
    final inactiveColor = enabled
        ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
        : (isDark ? AppColors.textSecondaryDark : AppColors.textHintLight);

    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: enabled ? onPressed : null,
        child: Container(
          width: 38,
          height: 38,
          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
          decoration: BoxDecoration(
            color: isActive ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 20,
            color: isActive ? activeColor : inactiveColor,
          ),
        ),
      ),
    );
  }
}

class _ToolbarTextButton extends StatelessWidget {
  const _ToolbarTextButton({
    required this.label,
    required this.tooltip,
    this.isActive = false,
    required this.onPressed,
  });

  final String label;
  final String tooltip;
  final bool isActive;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeBg = isDark
        ? AppColors.primaryWarm.withOpacity(0.25)
        : AppColors.primaryWarmLight;
    final activeColor =
        isDark ? AppColors.primaryWarm : AppColors.primaryWarmDark;
    final inactiveColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Container(
          width: 38,
          height: 38,
          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
          decoration: BoxDecoration(
            color: isActive ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isActive ? activeColor : inactiveColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolbarDivider extends StatelessWidget {
  const _ToolbarDivider();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: isDark ? Colors.white.withOpacity(0.12) : AppColors.divider,
    );
  }
}
