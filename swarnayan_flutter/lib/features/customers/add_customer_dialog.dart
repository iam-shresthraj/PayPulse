import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/glass_input.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/formatters.dart';
import '../../models/customer.dart';
import 'package:dio/dio.dart';
import 'customers_provider.dart';
import '../billing/billing_provider.dart';

class AddCustomerDialog extends ConsumerStatefulWidget {
  final Customer? customerToEdit;
  const AddCustomerDialog({super.key, this.customerToEdit});

  @override
  ConsumerState<AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends ConsumerState<AddCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _panController = TextEditingController();
  final _gstController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.customerToEdit != null) {
      final customer = widget.customerToEdit!;
      _nameController.text = customer.name;
      _mobileController.text = customer.mobile;
      _emailController.text = customer.email ?? '';
      _addressController.text = customer.address ?? '';
      _pincodeController.text = customer.pincode ?? '';
      _cityController.text = customer.city ?? '';
      _stateController.text = customer.state ?? '';
      _panController.text = customer.panCard ?? '';
      _gstController.text = customer.gstNumber ?? '';
      _noteController.text = customer.additionalNote ?? '';
      if (customer.createdAt != null) {
        _selectedDate = customer.createdAt!;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _panController.dispose();
    _gstController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme:  ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.black,
              surface: AppColors.surfaceContainer,
              onSurface: AppColors.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _lookupPincode(String pincode) async {
    if (pincode.trim().length != 6) return;
    
    try {
      final response = await Dio().get(
        'https://api.postalpincode.in/pincode/${pincode.trim()}',
      );
      if (response.data != null && response.data is List && (response.data as List).isNotEmpty) {
        final res = response.data[0];
        if (res['Status'] == 'Success' && res['PostOffice'] != null && (res['PostOffice'] as List).isNotEmpty) {
          final office = res['PostOffice'][0];
          setState(() {
            _cityController.text = office['District'] ?? '';
            _stateController.text = office['State'] ?? '';
          });
        }
      }
    } catch (e) {
      debugPrint('Error looking up pincode: $e');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final isEditing = widget.customerToEdit != null;
      final customer = Customer(
        id: isEditing ? widget.customerToEdit!.id : 'CUST-${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        mobile: _mobileController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        address: _addressController.text.trim(),
        pincode: _pincodeController.text.trim().isEmpty ? null : _pincodeController.text.trim(),
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        state: _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
        panCard: _panController.text.trim().isEmpty ? null : _panController.text.trim().toUpperCase(),
        gstNumber: _gstController.text.trim().isEmpty ? null : _gstController.text.trim().toUpperCase(),
        additionalNote: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        totalPurchaseAmount: isEditing ? widget.customerToEdit!.totalPurchaseAmount : 0.0,
        totalInvoices: isEditing ? widget.customerToEdit!.totalInvoices : 0,
        lastVisitDate: isEditing ? widget.customerToEdit!.lastVisitDate : null,
        createdAt: _selectedDate,
      );

      final Customer savedCustomer;
      if (isEditing) {
        savedCustomer = await ref.read(customersProvider.notifier).updateCustomer(widget.customerToEdit!.id!, customer);
      } else {
        savedCustomer = await ref.read(customersProvider.notifier).addCustomer(customer);
      }
      ref.read(billingProvider.notifier).setCustomer(savedCustomer);

      if (mounted) {
        Navigator.pop(context);
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
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                       Icon(Icons.check_circle_rounded, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Text(
                        widget.customerToEdit != null ? 'Customer updated successfully!' : 'Customer created successfully!',
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
            backgroundColor: AppColors.error,
            content: Text('Failed to save customer: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            SizedBox(height: topPadding + 8),

            // ── Header ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child:  Icon(
                        Icons.close_rounded,
                        color: AppColors.onSurface,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(widget.customerToEdit != null ? 'Edit Customer' : 'Add Customer', style: AppTextStyles.titleMd),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: 24),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    GlassInput(
                      controller: _nameController,
                      label: 'Full Name',
                      hint: 'Enter customer name',
                      prefixIcon:  Icon(Icons.person_outline_rounded, color: AppColors.primary),
                      validator: (v) => Validators.validateRequired(v, 'Name'),
                    ).animate().fadeIn(duration: 300.ms, delay: 100.ms),

                    const SizedBox(height: 20),

                    GlassInput(
                      controller: _mobileController,
                      label: 'Mobile Number',
                      hint: 'Enter 10-digit number',
                      prefixIcon:  Icon(Icons.phone_rounded, color: AppColors.primary),
                      keyboardType: TextInputType.phone,
                      validator: Validators.validateMobile,
                    ).animate().fadeIn(duration: 300.ms, delay: 150.ms),

                    const SizedBox(height: 20),

                    GlassInput(
                      controller: _emailController,
                      label: 'Email (Optional)',
                      hint: 'Enter email address',
                      prefixIcon:  Icon(Icons.email_outlined, color: AppColors.primary),
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.validateEmail,
                    ).animate().fadeIn(duration: 300.ms, delay: 200.ms),

                    const SizedBox(height: 20),

                    GlassInput(
                      controller: _addressController,
                      label: 'Address',
                      hint: 'Enter full address',
                      prefixIcon:  Icon(Icons.location_on_outlined, color: AppColors.primary),
                      maxLines: 3,
                      validator: (v) => Validators.validateRequired(v, 'Address'),
                    ).animate().fadeIn(duration: 300.ms, delay: 250.ms),

                    const SizedBox(height: 20),

                    GlassInput(
                      controller: _pincodeController,
                      label: 'Pincode',
                      hint: 'Enter 6-digit pincode',
                      prefixIcon:  Icon(Icons.pin_drop_outlined, color: AppColors.primary),
                      keyboardType: TextInputType.number,
                      onChanged: _lookupPincode,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Pincode is required';
                        if (v.trim().length != 6 || int.tryParse(v) == null) {
                          return 'Enter a valid 6-digit pincode';
                        }
                        return null;
                      },
                    ).animate().fadeIn(duration: 300.ms, delay: 270.ms),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: GlassInput(
                            controller: _cityController,
                            label: 'City / District',
                            hint: 'Auto-filled City',
                            prefixIcon:  Icon(Icons.location_city_outlined, color: AppColors.primary),
                            validator: (v) => Validators.validateRequired(v, 'City'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GlassInput(
                            controller: _stateController,
                            label: 'State',
                            hint: 'Auto-filled State',
                            prefixIcon:  Icon(Icons.map_outlined, color: AppColors.primary),
                            validator: (v) => Validators.validateRequired(v, 'State'),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 300.ms, delay: 290.ms),

                    const SizedBox(height: 20),

                    GlassInput(
                      controller: _panController,
                      label: 'PAN Card (Optional)',
                      hint: 'ABCDE1234F',
                      prefixIcon:  Icon(Icons.credit_card_rounded, color: AppColors.primary),
                      validator: Validators.validatePAN,
                    ).animate().fadeIn(duration: 300.ms, delay: 300.ms),

                    const SizedBox(height: 20),

                    GlassInput(
                      controller: _gstController,
                      label: 'GST Number (Optional)',
                      hint: '22AAAAA1111A1Z1',
                      prefixIcon:  Icon(Icons.receipt_long_rounded, color: AppColors.primary),
                    ).animate().fadeIn(duration: 300.ms, delay: 320.ms),

                    const SizedBox(height: 20),

                    GlassInput(
                      controller: _noteController,
                      label: 'Additional Note (Optional)',
                      hint: 'Add custom notes',
                      prefixIcon:  Icon(Icons.notes_rounded, color: AppColors.primary),
                      maxLines: 2,
                    ).animate().fadeIn(duration: 300.ms, delay: 340.ms),

                    const SizedBox(height: 20),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Text(
                            'Join Date',
                            style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurfaceMuted),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _selectDate(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceDim,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                              border: Border.all(color: AppColors.glassBorder),
                            ),
                            child: Row(
                              children: [
                                 Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 20),
                                const SizedBox(width: 12),
                                Text(
                                  Formatters.formatDate(_selectedDate),
                                  style: AppTextStyles.bodyMd.copyWith(color: AppColors.onBackground),
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(duration: 300.ms, delay: 350.ms),
                      ],
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: PrimaryButton(
            label: 'Save Changes',
            icon: Icons.check_rounded,
            isLoading: _isSaving,
            onPressed: _save,
          ),
        ),
      ),
    );
  }
}
