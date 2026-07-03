import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Dropdown with glass styling.
/// Uses a bottom-sheet selector instead of DropdownButton to avoid
/// Flutter Web CanvasKit hit-testing issues.
class GlassDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final String? label;
  final String? hint;

  const GlassDropdown({
    super.key,
    this.value,
    required this.items,
    this.onChanged,
    this.label,
    this.hint,
  });

  String _displayText() {
    if (value == null) return hint ?? 'Select...';
    // Find the matching item and extract its child text
    for (final item in items) {
      if (item.value == value) {
        final child = item.child;
        if (child is Text) return child.data ?? '';
        // For complex children, use the value's toString
        return value.toString();
      }
    }
    return value.toString();
  }

  void _openSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _GlassDropdownSheet<T>(
        items: items,
        currentValue: value,
        label: label,
        onSelected: (selected) {
          Navigator.pop(ctx);
          onChanged?.call(selected);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPlaceholder = value == null;

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
        GestureDetector(
          onTap: () => _openSelector(context),
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceDim,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _displayText(),
                    style: AppTextStyles.bodyLg.copyWith(
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
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet listing dropdown items with glassmorphism styling.
class _GlassDropdownSheet<T> extends StatelessWidget {
  final List<DropdownMenuItem<T>> items;
  final T? currentValue;
  final String? label;
  final void Function(T?) onSelected;

  const _GlassDropdownSheet({
    required this.items,
    this.currentValue,
    this.label,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final sheetHeight = (items.length * 56.0 + 80).clamp(200.0, MediaQuery.of(context).size.height * 0.6);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: sheetHeight,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer.withValues(alpha: 0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border:  Border(
              top: BorderSide(color: AppColors.glassBorder),
              left: BorderSide(color: AppColors.glassBorder),
              right: BorderSide(color: AppColors.glassBorder),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.onSurfaceDim,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              // Title
              if (label != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      label!,
                      style: AppTextStyles.titleMd.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
               Divider(color: AppColors.border, height: 1),
              // Items
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  physics: const BouncingScrollPhysics(),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isSelected = item.value == currentValue;

                    return GestureDetector(
                      onTap: () => onSelected(item.value),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : Colors.transparent,
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.border.withValues(alpha: 0.5),
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: DefaultTextStyle(
                                style: AppTextStyles.bodyLg.copyWith(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.onBackground,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                                child: item.child,
                              ),
                            ),
                            if (isSelected)
                               Icon(
                                Icons.check_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
