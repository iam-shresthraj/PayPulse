import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Dark input field with glass-compatible styling.
/// Matches the billing form inputs from the designs.
/// Auto-selects all text when focused for fast editing.
class GlassInput extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool readOnly;
  final int maxLines;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function()? onTap;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final EdgeInsets? contentPadding;
  final TextAlign textAlign;

  const GlassInput({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.readOnly = false,
    this.maxLines = 1,
    this.validator,
    this.onChanged,
    this.onTap,
    this.focusNode,
    this.textInputAction,
    this.onFieldSubmitted,
    this.contentPadding,
    this.textAlign = TextAlign.start,
  });

  @override
  State<GlassInput> createState() => _GlassInputState();
}

class _GlassInputState extends State<GlassInput> {
  FocusNode? _internalFocusNode;

  FocusNode get _effectiveFocusNode => widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _effectiveFocusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(GlassInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode?.removeListener(_handleFocusChange);
      _effectiveFocusNode.addListener(_handleFocusChange);
    }
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_handleFocusChange);
    _internalFocusNode?.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_effectiveFocusNode.hasFocus) {
      final controller = widget.controller;
      if (controller != null && controller.text.isNotEmpty) {
        Future.microtask(() {
          if (controller.text.isNotEmpty && _effectiveFocusNode.hasFocus) {
            controller.selection = TextSelection(
              baseOffset: 0,
              extentOffset: controller.text.length,
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget inputField = TextFormField(
      controller: widget.controller,
      focusNode: _effectiveFocusNode,
      keyboardType: widget.keyboardType,
      obscureText: widget.obscureText,
      readOnly: widget.readOnly,
      maxLines: widget.maxLines,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onTap: widget.onTap,
      textInputAction: widget.textInputAction ?? (widget.maxLines > 1 ? TextInputAction.newline : TextInputAction.next),
      onFieldSubmitted: widget.onFieldSubmitted ?? (value) {
        FocusScope.of(context).nextFocus();
      },
      textAlign: widget.textAlign,
      style: AppTextStyles.bodyLg.copyWith(color: AppColors.onBackground),
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.suffixIcon,
        isDense: widget.maxLines == 1,
        contentPadding: widget.contentPadding ??
            (widget.maxLines == 1
                ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
                : const EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
        filled: true,
        fillColor: AppColors.surfaceContainer.withValues(alpha: 0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          borderSide:  BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          borderSide:  BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          borderSide:
               BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );

    if (widget.maxLines == 1) {
      inputField = SizedBox(
        height: 50,
        child: inputField,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!.toUpperCase(),
            style: AppTextStyles.labelMd.copyWith(
              color: AppColors.onSurfaceMuted,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
        ],
        inputField,
      ],
    );
  }
}
