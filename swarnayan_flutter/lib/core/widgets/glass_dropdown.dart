import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Dropdown with glass styling.
/// Uses a PopupMenuButton for inline selection instead of a bottom sheet.
class GlassDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final String? label;
  final String? hint;
  final FocusNode? focusNode;

  const GlassDropdown({
    super.key,
    this.value,
    required this.items,
    this.onChanged,
    this.label,
    this.hint,
    this.focusNode,
  });

  String _displayText() {
    for (final item in items) {
      if (item.value == value) {
        final child = item.child;
        if (child is Text) return child.data ?? '';
        return value?.toString() ?? '';
      }
    }
    if (value == null) return hint ?? 'Select...';
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final hasNullItem = items.any((item) => item.value == null);
    final isPlaceholder = value == null && !hasNullItem;
    final effectiveFocusNode = focusNode ?? FocusNode();
    final GlobalKey triggerKey = GlobalKey();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!.toUpperCase(),
            style: AppTextStyles.labelMd.copyWith(
              color: AppColors.onSurfaceMuted,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Focus(
          focusNode: effectiveFocusNode,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent &&
                (event.logicalKey == LogicalKeyboardKey.enter ||
                 event.logicalKey == LogicalKeyboardKey.numpadEnter ||
                 event.logicalKey == LogicalKeyboardKey.space)) {
              _showPopup(context, triggerKey);
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: GestureDetector(
            key: triggerKey,
            onTap: () => _showPopup(context, triggerKey),
            behavior: HitTestBehavior.opaque,
            child: Builder(
              builder: (ctx) {
                final focused = Focus.of(ctx).hasFocus;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDim,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    border: Border.all(
                      color: focused ? AppColors.primary : AppColors.border,
                      width: focused ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _displayText(),
                          style: AppTextStyles.bodyMd.copyWith(
                            color: isPlaceholder
                                ? AppColors.onSurfaceDim
                                : AppColors.onBackground,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.onSurfaceMuted,
                        size: 18,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _showPopup(BuildContext context, GlobalKey triggerKey) {
    final RenderBox? renderBox = triggerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    showMenu<T>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + size.height + 4,
        offset.dx + size.width,
        0,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppColors.surfaceContainer,
      elevation: 8,
      items: items.map((item) {
        final isSelected = item.value == value;
        return PopupMenuItem<T>(
          value: item.value,
          height: 42,
          child: Row(
            children: [
              Expanded(
                child: DefaultTextStyle(
                  style: AppTextStyles.bodyMd.copyWith(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.onBackground,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  child: item.child,
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
            ],
          ),
        );
      }).toList(),
    ).then((selected) {
      if (selected != null) {
        onChanged?.call(selected);
      }
    });
  }
}
