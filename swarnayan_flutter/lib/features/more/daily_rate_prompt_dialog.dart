import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/glass_input.dart';
import '../../core/widgets/primary_button.dart';
import '../../models/daily_rate.dart';
import 'daily_rates_provider.dart';

class DailyRatePromptDialog extends ConsumerStatefulWidget {
  final bool isDismissible;
  final DailyRate? initialRate;
  const DailyRatePromptDialog({super.key, this.isDismissible = false, this.initialRate});

  @override
  ConsumerState<DailyRatePromptDialog> createState() => _DailyRatePromptDialogState();
}

class _DailyRatePromptDialogState extends ConsumerState<DailyRatePromptDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _gold22Controller;
  late TextEditingController _gold18Controller;
  late TextEditingController _silverController;
  late TextEditingController _dateController;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialRate != null) {
      _selectedDate = widget.initialRate!.date;
    }
    // Pre-populate with latest available rates
    final rates = ref.read(dailyRatesProvider).value ?? [];
    final latestRate = widget.initialRate ?? (rates.isNotEmpty ? rates.first : null);

    _gold22Controller = TextEditingController(
      text: latestRate != null ? latestRate.rateGold22K.toStringAsFixed(0) : '6850',
    );
    _gold18Controller = TextEditingController(
      text: latestRate != null ? latestRate.rateGold18K.toStringAsFixed(0) : '5610',
    );
    _silverController = TextEditingController(
      text: latestRate != null ? latestRate.rateSilver.toStringAsFixed(1) : '82.4',
    );
    _dateController = TextEditingController(
      text: DateFormat('dd MMM yyyy').format(_selectedDate),
    );
  }

  @override
  void dispose() {
    _gold22Controller.dispose();
    _gold18Controller.dispose();
    _silverController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final g22 = double.parse(_gold22Controller.text);
      final g18 = double.parse(_gold18Controller.text);
      final silver = double.parse(_silverController.text);

      final rate = DailyRate(
        id: widget.initialRate?.id ?? 'RATE-${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}',
        date: DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day),
        rateGold22K: g22,
        rateGold18K: g18,
        rateSilver: silver,
        enteredBy: widget.initialRate?.enteredBy,
      );

      await ref.read(dailyRatesProvider.notifier).addDailyRate(rate);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            content: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  ),
                  child: Row(
                    children: [
                       Icon(Icons.check_circle_rounded, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Text(
                        'Daily rates updated successfully!',
                        style: AppTextStyles.bodyMd.copyWith(color: AppColors.onBackground),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            content: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  ),
                  child: Row(
                    children: [
                       Icon(Icons.error_outline_rounded, color: AppColors.error),
                      const SizedBox(width: 12),
                      Text(
                        'Failed to update rates: $e',
                        style: AppTextStyles.bodyMd.copyWith(color: AppColors.onBackground),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(color: AppColors.glassBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Daily Metal Rates',
                        style: AppTextStyles.titleLg.copyWith(color: AppColors.primary),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: AppColors.onSurfaceDim),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Set the standard selling rates for today. Transactions will calculate charges based on these rates.',
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDate = picked;
                          _dateController.text = DateFormat('dd MMM yyyy').format(picked);
                        });
                      }
                    },
                    child: AbsorbPointer(
                      child: GlassInput(
                        controller: _dateController,
                        label: 'Rate Date',
                        hint: 'Select date',
                        prefixIcon:  Icon(Icons.calendar_today_rounded, color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GlassInput(
                    controller: _gold22Controller,
                    label: 'Gold 22K (per gram)',
                    hint: '6850',
                    prefixIcon:  Icon(Icons.trending_up_rounded, color: AppColors.primary),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Rate is required';
                      if (double.tryParse(v) == null) return 'Enter a valid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  GlassInput(
                    controller: _gold18Controller,
                    label: 'Gold 18K (per gram)',
                    hint: '5610',
                    prefixIcon:  Icon(Icons.trending_up_rounded, color: AppColors.primary),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Rate is required';
                      if (double.tryParse(v) == null) return 'Enter a valid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  GlassInput(
                    controller: _silverController,
                    label: 'Silver (per gram)',
                    hint: '82.4',
                    prefixIcon:  Icon(Icons.trending_up_rounded, color: AppColors.primary),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Rate is required';
                      if (double.tryParse(v) == null) return 'Enter a valid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    label: 'Save Changes',
                    icon: Icons.check_rounded,
                    isLoading: _isSaving,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        widget.isDismissible ? 'Cancel' : 'Skip for now',
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.onSurfaceMuted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
