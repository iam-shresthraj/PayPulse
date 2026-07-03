import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glass_input.dart';
import '../../../core/widgets/glass_dropdown.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/utils/validators.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/user.dart' as model_user;
import '../../../models/coupon.dart' as model_coupon;
import '../../../models/company_settings.dart' as model_settings;
import '../company_provider.dart';
import '../coupons_provider.dart';
import '../staff_provider.dart';
import '../../auth/auth_provider.dart';

// -----------------------------------------------------------
// Base Glass Dialog Wrapper
// -----------------------------------------------------------
class GlassDialogWrapper extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;

  const GlassDialogWrapper({
    super.key,
    required this.title,
    required this.child,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 500,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.titleLg.copyWith(color: AppColors.primary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.onSurfaceMuted),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppColors.border, height: 1),
                // Scrollable Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    physics: const BouncingScrollPhysics(),
                    child: child,
                  ),
                ),
                if (actions != null) ...[
                  const Divider(color: AppColors.border, height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: actions!,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------
// 1. Edit Profile Dialog
// -----------------------------------------------------------
class EditProfileDialog extends ConsumerStatefulWidget {
  const EditProfileDialog({super.key});

  @override
  ConsumerState<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _addressController = TextEditingController(text: user?.address ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).updateProfile(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            address: _addressController.text.trim(),
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassDialogWrapper(
      title: 'Edit Profile',
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceDim)),
        ),
        const SizedBox(width: 12),
        PrimaryButton(
          label: 'Save Changes',
          isLoading: _isLoading,
          onPressed: _submit,
        ),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassInput(
              controller: _nameController,
              label: 'Full Name',
              hint: 'Enter your name',
              validator: (v) => Validators.validateRequired(v, 'Name'),
            ),
            const SizedBox(height: 16),
            GlassInput(
              controller: _phoneController,
              label: 'Phone Number',
              hint: 'Enter phone number',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            GlassInput(
              controller: _addressController,
              label: 'Address',
              hint: 'Enter your address',
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------
// 2. Company Settings Dialog
// -----------------------------------------------------------
class CompanySettingsDialog extends ConsumerStatefulWidget {
  const CompanySettingsDialog({super.key});

  @override
  ConsumerState<CompanySettingsDialog> createState() => _CompanySettingsDialogState();
}

class _CompanySettingsDialogState extends ConsumerState<CompanySettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _line1Controller;
  late TextEditingController _line2Controller;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _postalCodeController;
  late TextEditingController _gstinController;
  late TextEditingController _mobileController;
  late TextEditingController _emailController;
  late TextEditingController _taglineController;
  late TextEditingController _notesController;
  late TextEditingController _stateWithCodeController;
  late TextEditingController _logoUrlController;
  late TextEditingController _termsController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(companyProvider).value;
    _nameController = TextEditingController(text: settings?.companyName ?? '');
    _line1Controller = TextEditingController(text: settings?.address.line1 ?? '');
    _line2Controller = TextEditingController(text: settings?.address.line2 ?? '');
    _cityController = TextEditingController(text: settings?.address.city ?? '');
    _stateController = TextEditingController(text: settings?.address.state ?? '');
    _postalCodeController = TextEditingController(text: settings?.address.postalCode ?? '');
    _gstinController = TextEditingController(text: settings?.gstin ?? '');
    _mobileController = TextEditingController(text: settings?.mobile ?? '');
    _emailController = TextEditingController(text: settings?.email ?? '');
    _taglineController = TextEditingController(text: settings?.tagline ?? '');
    _notesController = TextEditingController(text: settings?.notes ?? '');
    _stateWithCodeController = TextEditingController(text: settings?.stateWithCode ?? '');
    _logoUrlController = TextEditingController(text: settings?.logoUrl ?? '');
    _termsController = TextEditingController(text: (settings?.termsAndConditions ?? []).join('\n'));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _line1Controller.dispose();
    _line2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _gstinController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _taglineController.dispose();
    _notesController.dispose();
    _stateWithCodeController.dispose();
    _logoUrlController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final current = ref.read(companyProvider).value;
      final settings = model_settings.CompanySettings(
        id: current?.id,
        companyName: _nameController.text.trim(),
        address: model_settings.CompanyAddress(
          line1: _line1Controller.text.trim(),
          line2: _line2Controller.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          postalCode: _postalCodeController.text.trim(),
        ),
        gstin: _gstinController.text.trim().toUpperCase(),
        mobile: _mobileController.text.trim(),
        email: _emailController.text.trim(),
        tagline: _taglineController.text.trim(),
        notes: _notesController.text.trim(),
        stateWithCode: _stateWithCodeController.text.trim(),
        logoUrl: _logoUrlController.text.trim(),
        invoiceConfig: current?.invoiceConfig ?? const model_settings.InvoiceConfig(),
        termsAndConditions: _termsController.text
            .split('\n')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
      );

      await ref.read(companyProvider.notifier).updateSettings(settings);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Company settings saved successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassDialogWrapper(
      title: 'Company Settings',
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceDim)),
        ),
        const SizedBox(width: 12),
        PrimaryButton(
          label: 'Save Changes',
          isLoading: _isLoading,
          onPressed: _submit,
        ),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            GlassInput(
              controller: _nameController,
              label: 'Company Name',
              hint: 'Enter jewellers company name',
              validator: (v) => Validators.validateRequired(v, 'Company Name'),
            ),
            const SizedBox(height: 16),
            GlassInput(
              controller: _taglineController,
              label: 'Tagline',
              hint: 'Slogan displayed on invoices',
            ),
            const SizedBox(height: 16),
            GlassInput(
              controller: _logoUrlController,
              label: 'Logo URL',
              hint: 'Enter direct image URL for logo',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GlassInput(
                    controller: _mobileController,
                    label: 'Contact Mobile',
                    hint: 'Enter mobile number',
                    keyboardType: TextInputType.phone,
                    validator: Validators.validateMobile,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GlassInput(
                    controller: _emailController,
                    label: 'Email Address',
                    hint: 'company@email.com',
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.validateEmail,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GlassInput(
                    controller: _gstinController,
                    label: 'GSTIN',
                    hint: '22AAAAA0000A1Z5',
                    validator: Validators.validateGSTIN,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GlassInput(
                    controller: _stateWithCodeController,
                    label: 'State With Code',
                    hint: 'West Bengal (19)',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GlassInput(
              controller: _line1Controller,
              label: 'Address Line 1',
              hint: 'Street, Shop No.',
              validator: (v) => Validators.validateRequired(v, 'Address Line 1'),
            ),
            const SizedBox(height: 16),
            GlassInput(
              controller: _line2Controller,
              label: 'Address Line 2 (Optional)',
              hint: 'Locality, landmark',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GlassInput(
                    controller: _cityController,
                    label: 'City',
                    hint: 'City',
                    validator: (v) => Validators.validateRequired(v, 'City'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GlassInput(
                    controller: _stateController,
                    label: 'State',
                    hint: 'State',
                    validator: (v) => Validators.validateRequired(v, 'State'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GlassInput(
                    controller: _postalCodeController,
                    label: 'Postal Code',
                    hint: 'PIN Code',
                    keyboardType: TextInputType.number,
                    validator: (v) => Validators.validateRequired(v, 'PIN Code'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GlassInput(
              controller: _notesController,
              label: 'Invoice Footer Note',
              hint: 'e.g. Goods once sold will not be taken back.',
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            GlassInput(
              controller: _termsController,
              label: 'Terms & Conditions (One per line)',
              hint: 'Enter each term on a new line',
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------
// 3. Coupons Management Dialog
// -----------------------------------------------------------
class CouponsManagementDialog extends ConsumerStatefulWidget {
  const CouponsManagementDialog({super.key});

  @override
  ConsumerState<CouponsManagementDialog> createState() => _CouponsManagementDialogState();
}

class _CouponsManagementDialogState extends ConsumerState<CouponsManagementDialog> {
  final _formKey = GlobalKey<FormState>();

  final _codeController = TextEditingController();
  final _valueController = TextEditingController();
  final _minBillController = TextEditingController(text: '0');
  final _maxDiscountController = TextEditingController(text: '0');
  final _limitController = TextEditingController(text: '0');
  final _startsController = TextEditingController();
  final _expiryController = TextEditingController();

  bool _showForm = false;
  String _discountType = 'FIXED';
  String _statusFilter = 'ALL';
  DateTime? _selectedExpiry;
  DateTime? _selectedStarts;
  model_coupon.Coupon? _editingCoupon;
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    _valueController.dispose();
    _minBillController.dispose();
    _maxDiscountController.dispose();
    _limitController.dispose();
    _startsController.dispose();
    _expiryController.dispose();
    super.dispose();
  }

  String _couponStatus(model_coupon.Coupon coupon) {
    final now = DateTime.now();
    final startsAt = coupon.startsAt;
    if (startsAt != null && startsAt.isAfter(now)) {
      return 'UPCOMING';
    }
    if (!coupon.isActive) {
      return 'INACTIVE';
    }
    if (!coupon.expiryDate.isAfter(now)) {
      return 'INACTIVE';
    }
    return 'ACTIVE';
  }

  void _beginCreate() {
    _editingCoupon = null;
    _showForm = true;
    _codeController.clear();
    _valueController.clear();
    _minBillController.text = '0';
    _maxDiscountController.text = '0';
    _limitController.text = '0';
    _startsController.clear();
    _expiryController.clear();
    _selectedStarts = null;
    _selectedExpiry = null;
    _discountType = 'FIXED';
    setState(() {});
  }

  void _beginEdit(model_coupon.Coupon coupon) {
    _editingCoupon = coupon;
    _showForm = true;
    _codeController.text = coupon.code;
    _valueController.text = coupon.discountValue.toStringAsFixed(0);
    _minBillController.text = coupon.minBillAmount.toStringAsFixed(0);
    _maxDiscountController.text = coupon.maxDiscount.toStringAsFixed(0);
    _limitController.text = (coupon.usageLimit ?? 0).toString();
    _discountType = coupon.discountType;
    _selectedStarts = coupon.startsAt;
    _selectedExpiry = coupon.expiryDate;
    _startsController.text = coupon.startsAt == null ? '' : DateFormat('dd MMM yyyy').format(coupon.startsAt!);
    _expiryController.text = DateFormat('dd MMM yyyy').format(coupon.expiryDate);
    setState(() {});
  }

  Future<void> _submitCoupon() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedExpiry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an expiry date')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final isEditing = _editingCoupon != null;
      final startsAt = _selectedStarts ?? DateTime.now();
      final expiryWithTime = DateTime(
        _selectedExpiry!.year,
        _selectedExpiry!.month,
        _selectedExpiry!.day,
        23,
        59,
        59,
      );

      final coupon = model_coupon.Coupon(
        code: _codeController.text.trim().toUpperCase(),
        discountType: _discountType,
        discountValue: double.tryParse(_valueController.text) ?? 0.0,
        minBillAmount: double.tryParse(_minBillController.text) ?? 0.0,
        maxDiscount: double.tryParse(_maxDiscountController.text) ?? 0.0,
        usageLimit: int.tryParse(_limitController.text) ?? 0,
        startsAt: startsAt,
        expiryDate: expiryWithTime,
        isActive: _editingCoupon?.isActive ?? true,
      );

      if (_editingCoupon == null) {
        await ref.read(couponsProvider.notifier).addCoupon(coupon);
      } else {
        await ref.read(couponsProvider.notifier).updateCoupon(coupon);
      }

      setState(() {
        _showForm = false;
        _editingCoupon = null;
      });
      _beginCreate();
      setState(() => _showForm = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Coupon updated successfully!' : 'Coupon added successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add coupon: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final couponsState = ref.watch(couponsProvider);
    final now = DateTime.now();

    return GlassDialogWrapper(
      title: 'Coupons & Offers',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _showForm ? (_editingCoupon != null ? 'Edit Coupon' : 'Add New Coupon') : 'Coupons',
                style: AppTextStyles.titleSm.copyWith(color: AppColors.primary),
              ),
              SecondaryButton(
                label: _showForm ? 'View List' : '+ Add Coupon',
                onPressed: () {
                  if (_showForm) {
                    _showForm = false;
                    _editingCoupon = null;
                    setState(() {});
                  } else {
                    _beginCreate();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_showForm)
            Form(
              key: _formKey,
              child: Column(
                children: [
                  GlassInput(
                    controller: _codeController,
                    label: 'Coupon Code',
                    hint: 'SUMMER500',
                    validator: (v) => Validators.validateRequired(v, 'Coupon Code'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GlassDropdown<String>(
                          label: 'Discount Type',
                          value: _discountType,
                          items: const [
                            DropdownMenuItem(value: 'FIXED', child: Text('Fixed ₹')),
                            DropdownMenuItem(value: 'PERCENTAGE', child: Text('Percent %')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _discountType = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlassInput(
                          controller: _valueController,
                          label: 'Discount Value',
                          hint: '0',
                          keyboardType: TextInputType.number,
                          validator: (v) => Validators.validateRequired(v, 'Discount Value'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GlassInput(
                          controller: _minBillController,
                          label: 'Min Bill (₹)',
                          hint: '0',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlassInput(
                          controller: _maxDiscountController,
                          label: 'Max Discount (₹)',
                          hint: '0',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GlassInput(
                          controller: _limitController,
                          label: 'Usage Limit',
                          hint: '0 (unlimited)',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().add(const Duration(days: 30)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setState(() {
                                _selectedExpiry = picked;
                                _expiryController.text = DateFormat('dd MMM yyyy').format(picked);
                              });
                            }
                          },
                          child: AbsorbPointer(
                            child: GlassInput(
                              controller: _expiryController,
                              label: 'Expiry Date',
                              hint: 'Select date',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedStarts ?? DateTime.now(),
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedStarts = picked;
                          _startsController.text = DateFormat('dd MMM yyyy').format(picked);
                        });
                      }
                    },
                    child: AbsorbPointer(
                      child: GlassInput(
                        controller: _startsController,
                        label: 'Starts At',
                        hint: 'Optional future start',
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Save Changes',
                    isLoading: _isLoading,
                    onPressed: _submitCoupon,
                  ),
                ],
              ),
            )
          else
            couponsState.when(
              data: (list) {
                final filtered = list.where((item) {
                  if (_statusFilter == 'ALL') return true;
                  return _couponStatus(item) == _statusFilter;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text('No coupons available.', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted)),
                    ),
                  );
                }

                final chips = const ['ALL', 'ACTIVE', 'INACTIVE', 'UPCOMING'];
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: chips.map((chip) {
                          final isSelected = chip == _statusFilter;
                          return GestureDetector(
                            onTap: () => setState(() => _statusFilter = chip),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : AppColors.glassBackground,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: isSelected ? AppColors.primary : AppColors.glassBorder),
                              ),
                              child: Text(
                                chip,
                                style: AppTextStyles.labelSm.copyWith(
                                  color: isSelected ? Colors.black : AppColors.onSurfaceMuted,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    }

                    final item = filtered[index - 1];
                    final status = _couponStatus(item);
                    return GlassCard(
                      animationIndex: index - 1,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item.code,
                                  style: AppTextStyles.titleSm.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: status == 'ACTIVE'
                                          ? AppColors.success.withValues(alpha: 0.12)
                                          : status == 'UPCOMING'
                                              ? AppColors.warning.withValues(alpha: 0.12)
                                              : AppColors.error.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      status,
                                      style: AppTextStyles.labelSm.copyWith(
                                        color: status == 'ACTIVE'
                                            ? AppColors.success
                                            : status == 'UPCOMING'
                                                ? AppColors.warning
                                                : AppColors.error,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_rounded, size: 18, color: AppColors.primary),
                                    onPressed: () => setState(() => _beginEdit(item)),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.toggle_off_rounded, size: 18, color: AppColors.error),
                                    onPressed: item.isActive
                                        ? () async {
                                            await ref.read(couponsProvider.notifier).deactivateCoupon(item.id!);
                                          }
                                        : null,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _couponDetail('Discount', item.discountType == 'FIXED' ? '₹${item.discountValue}' : '${item.discountValue}%'),
                          _couponDetail('Min Purchase', '₹${item.minBillAmount}'),
                          _couponDetail('Max Discount', '₹${item.maxDiscount}'),
                          _couponDetail('Limit / Used', '${item.usageLimit == 0 ? 'Unlimited' : item.usageLimit} / ${item.usedCount}'),
                          _couponDetail('Starts At', item.startsAt == null ? 'Immediate' : DateFormat('dd MMM yyyy').format(item.startsAt!)),
                          _couponDetail('Expiry', DateFormat('dd MMM yyyy').format(item.expiryDate)),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, _) => Text('Error: $err', style: AppTextStyles.bodySm.copyWith(color: AppColors.error)),
            ),
        ],
      ),
    );
  }

  Widget _couponDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceMuted)),
          Text(value, style: AppTextStyles.bodySm.copyWith(color: AppColors.onBackground, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------
// 4. Staff Management Dialog
// -----------------------------------------------------------
class StaffManagementDialog extends ConsumerStatefulWidget {
  const StaffManagementDialog({super.key});

  @override
  ConsumerState<StaffManagementDialog> createState() => _StaffManagementDialogState();
}

class _StaffManagementDialogState extends ConsumerState<StaffManagementDialog> {
  bool _showAddForm = false;
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _role = 'STAFF';
  bool _isLoading = false;
  model_user.User? _editingUser;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _beginEdit(model_user.User user) {
    setState(() {
      _editingUser = user;
      _showAddForm = true;
      _nameController.text = user.name;
      _emailController.text = user.email;
      _role = user.role;
      _passwordController.clear();
    });
  }

  Future<void> _submitStaff() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      if (_editingUser != null) {
        await ref.read(staffProvider.notifier).updateStaff(
              _editingUser!.id,
              _nameController.text.trim(),
              _role,
            );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Staff member updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        await ref.read(staffProvider.notifier).addStaff(
              _nameController.text.trim(),
              _emailController.text.trim(),
              _passwordController.text,
              _role,
            );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Staff member registered successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }

      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
      setState(() {
        _role = 'STAFF';
        _showAddForm = false;
        _editingUser = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save staff changes: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final staffState = ref.watch(staffProvider);

    return GlassDialogWrapper(
      title: 'Staff Management',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _showAddForm ? (_editingUser != null ? 'Edit Staff Member' : 'Add Staff Member') : 'All Staff Members',
                style: AppTextStyles.titleSm.copyWith(color: AppColors.primary),
              ),
              SecondaryButton(
                label: _showAddForm ? 'View List' : '+ Add Staff',
                onPressed: () {
                  setState(() {
                    _showAddForm = !_showAddForm;
                    if (!_showAddForm) {
                      _editingUser = null;
                      _nameController.clear();
                      _emailController.clear();
                      _passwordController.clear();
                      _role = 'STAFF';
                    }
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_showAddForm)
            Form(
              key: _formKey,
              child: Column(
                children: [
                  GlassInput(
                    controller: _nameController,
                    label: 'Name',
                    hint: 'Enter full name',
                    validator: (v) => Validators.validateRequired(v, 'Name'),
                  ),
                  const SizedBox(height: 16),
                  GlassInput(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'staff@swarnayan.com',
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.validateEmail,
                    readOnly: _editingUser != null,
                  ),
                  if (_editingUser == null) ...[
                    const SizedBox(height: 16),
                    GlassInput(
                      controller: _passwordController,
                      label: 'Password',
                      hint: '••••••••',
                      obscureText: true,
                      validator: (v) => Validators.validateRequired(v, 'Password'),
                    ),
                  ],
                  const SizedBox(height: 16),
                  GlassDropdown<String>(
                    label: 'Role',
                    value: _role,
                    items: const [
                      DropdownMenuItem(value: 'STAFF', child: Text('Staff')),
                      DropdownMenuItem(value: 'CO_OWNER', child: Text('Co-owner')),
                      DropdownMenuItem(value: 'OWNER', child: Text('Owner')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _role = val);
                    },
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Save Changes',
                    isLoading: _isLoading,
                    onPressed: _submitStaff,
                  ),
                ],
              ),
            )
          else
            staffState.when(
              data: (list) {
                if (list.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text('No staff members registered.', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted)),
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = list[index];
                    return GlassCard(
                      animationIndex: index,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name, style: AppTextStyles.cardTitle),
                                const SizedBox(height: 2),
                                Text('${item.email} • ${item.role}', style: AppTextStyles.cardSubtitle),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_rounded, size: 18, color: AppColors.primary),
                            onPressed: () => _beginEdit(item),
                          ),
                          Switch(
                            value: item.isActive,
                            activeColor: AppColors.primary,
                            onChanged: (val) async {
                              await ref.read(staffProvider.notifier).toggleUserStatus(item);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, _) => Text('Error: $err', style: AppTextStyles.bodySm.copyWith(color: AppColors.error)),
            ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------
// 5. Change Password Dialog
// -----------------------------------------------------------
class ChangePasswordDialog extends ConsumerStatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  ConsumerState<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match!'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _newPasswordController.text),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to change password: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassDialogWrapper(
      title: 'Change Password',
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceDim)),
        ),
        const SizedBox(width: 12),
        PrimaryButton(
          label: 'Save Changes',
          isLoading: _isLoading,
          onPressed: _submit,
        ),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            GlassInput(
              controller: _oldPasswordController,
              label: 'Current Password',
              hint: '••••••••',
              obscureText: true,
              validator: (v) => Validators.validateRequired(v, 'Current Password'),
            ),
            const SizedBox(height: 16),
            GlassInput(
              controller: _newPasswordController,
              label: 'New Password',
              hint: '••••••••',
              obscureText: true,
              validator: (v) => Validators.validateRequired(v, 'New Password'),
            ),
            const SizedBox(height: 16),
            GlassInput(
              controller: _confirmPasswordController,
              label: 'Confirm New Password',
              hint: '••••••••',
              obscureText: true,
              validator: (v) => Validators.validateRequired(v, 'Confirm Password'),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------
// 6. About Dialog
// -----------------------------------------------------------
class AboutDetailsDialog extends StatelessWidget {
  const AboutDetailsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassDialogWrapper(
      title: 'About System',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 40),
                ),
                const SizedBox(height: 16),
                Text('PayPulse', style: AppTextStyles.titleLg.copyWith(fontWeight: FontWeight.bold)),
                Text('Billing & Inventory Management System', style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceMuted)),
                const SizedBox(height: 8),
                Text('Version 1.0.0', style: AppTextStyles.bodySm.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Divider(color: AppColors.border),
          const SizedBox(height: 16),
          Text('DEVELOPED BY', style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceMuted, letterSpacing: 1.0)),
          const SizedBox(height: 6),
          Text('Advanced Agentic Coding Team', style: AppTextStyles.bodyLg.copyWith(color: AppColors.onBackground, fontWeight: FontWeight.w500)),
          Text('Google DeepMind', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted)),
          const SizedBox(height: 16),
          Text('LICENSE', style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceMuted, letterSpacing: 1.0)),
          const SizedBox(height: 6),
          Text('Proprietary Software. All rights reserved.', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceDim)),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------
// 7. Help & Support Dialog
// -----------------------------------------------------------
class HelpSupportDialog extends StatelessWidget {
  const HelpSupportDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassDialogWrapper(
      title: 'Help & Support',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Need assistance? Our support desk is available to help you with invoice issues, inventory setup, or system queries.',
              style: AppTextStyles.bodyLg.copyWith(color: AppColors.onBackground)),
          const SizedBox(height: 24),
          _supportRow(Icons.email_outlined, 'Email Support', 'support@swarnayanjewellers.com'),
          const SizedBox(height: 16),
          _supportRow(Icons.phone_outlined, 'Phone Support', '+91 98765 43210'),
          const SizedBox(height: 16),
          _supportRow(Icons.access_time_rounded, 'Operational Hours', '10:00 AM - 08:00 PM (Mon - Sat)'),
          const SizedBox(height: 24),
          const Divider(color: AppColors.border),
          const SizedBox(height: 16),
          Text(
            'In case of server connectivity issues, please check your network connection or verify settings with the administrator.',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted),
          ),
        ],
      ),
    );
  }

  Widget _supportRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurfaceMuted)),
              const SizedBox(height: 2),
              Text(value, style: AppTextStyles.bodyLg.copyWith(color: AppColors.onBackground, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}
