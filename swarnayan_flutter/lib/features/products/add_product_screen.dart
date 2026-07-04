import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/glass_dropdown.dart';
import '../../core/widgets/glass_input.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/utils/validators.dart';
import '../../models/product.dart';
import 'products_provider.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  final Product? product;

  const AddProductScreen({super.key, this.product});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _huidController = TextEditingController();
  final _hsnController = TextEditingController(text: '7113');
  final _weightController = TextEditingController();
  final _stockController = TextEditingController(text: '1');
  final _makingChargeController = TextEditingController();
  final _stoneTypeController = TextEditingController();
  final _stoneWeightController = TextEditingController();
  final _stoneValueController = TextEditingController();
  final _imageUrlController = TextEditingController();

  String? _selectedCategory;
  String? _selectedPurity;
  bool _isSaving = false;

  static const _categories = [
    DropdownMenuItem(value: 'GOLD', child: Text('Gold')),
    DropdownMenuItem(value: 'SILVER', child: Text('Silver')),
    DropdownMenuItem(value: 'PLATINUM', child: Text('Platinum')),
    DropdownMenuItem(value: 'DIAMOND', child: Text('Diamond')),
    DropdownMenuItem(value: 'GEMS', child: Text('Gems')),
  ];

  static const _purities = [
    DropdownMenuItem(value: '22K', child: Text('22K')),
    DropdownMenuItem(value: '18K', child: Text('18K')),
    DropdownMenuItem(value: 'SILVER', child: Text('Silver')),
  ];

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    if (product != null) {
      _nameController.text = product.name;
      _huidController.text = product.huidNumber ?? '';
      _hsnController.text = product.hsnCode;
      _weightController.text = product.weight.toStringAsFixed(3);
      _stockController.text = product.stockUnits.toString();
      _makingChargeController.text = product.makingChargeValue.toStringAsFixed(0);
      _stoneTypeController.text = product.stoneType ?? '';
      _stoneWeightController.text = product.stoneWeight.toStringAsFixed(3);
      _stoneValueController.text = product.stoneValue.toStringAsFixed(0);
      _imageUrlController.text = product.imageUrl ?? '';
      _selectedCategory = product.category;
      _selectedPurity = product.purity;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _huidController.dispose();
    _hsnController.dispose();
    _weightController.dispose();
    _stockController.dispose();
    _makingChargeController.dispose();
    _stoneTypeController.dispose();
    _stoneWeightController.dispose();
    _stoneValueController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      _showErrorSnackBar('Please select a category');
      return;
    }
    if (_selectedPurity == null) {
      _showErrorSnackBar('Please select purity');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final product = Product(
        id: widget.product?.id,
        name: _nameController.text.trim(),
        category: _selectedCategory!,
        purity: _selectedPurity!,
        huidNumber: _huidController.text.trim().isEmpty ? widget.product?.huidNumber : _huidController.text.trim(),
        hsnCode: _hsnController.text.trim(),
        weight: _weightController.text.trim().isEmpty ? 0.0 : double.parse(_weightController.text),
        stockUnits: int.parse(_stockController.text),
        makingChargeValue: _makingChargeController.text.trim().isEmpty ? 0.0 : double.parse(_makingChargeController.text),
        stoneType: _stoneTypeController.text.trim().isEmpty ? null : _stoneTypeController.text.trim(),
        stoneWeight: _stoneWeightController.text.trim().isEmpty ? 0.0 : double.parse(_stoneWeightController.text),
        stoneValue: _stoneValueController.text.trim().isEmpty ? 0.0 : double.parse(_stoneValueController.text),
        imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
        isActive: widget.product?.isActive ?? true,
      );

      if (_isEditing) {
        await ref.read(productsProvider.notifier).updateProduct(product);
      } else {
        await ref.read(productsProvider.notifier).addProduct(product);
      }

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
                        _isEditing ? 'Product updated successfully!' : 'Product created successfully!',
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
        String msg = 'Failed to save product';
        if (e is DioException) {
          msg = e.message ?? msg;
        } else {
          msg = e.toString();
        }
        _showErrorSnackBar(msg);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showErrorSnackBar(String message) {
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
                border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                   Icon(Icons.error_outline_rounded, color: AppColors.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: AppTextStyles.bodyMd.copyWith(color: AppColors.onBackground),
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
                        Icons.arrow_back_rounded,
                        color: AppColors.onSurface,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(_isEditing ? 'Edit Product' : 'Add Product', style: AppTextStyles.titleMd),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    GlassInput(
                      controller: _nameController,
                      label: 'Product Name',
                      hint: 'Enter product name',
                      validator: (v) => Validators.validateRequired(v, 'Product Name'),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: GlassDropdown<String>(
                            label: 'Category',
                            hint: 'Select',
                            value: _selectedCategory,
                            items: _categories,
                            onChanged: (val) => setState(() => _selectedCategory = val),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GlassDropdown<String>(
                            label: 'Purity',
                            hint: 'Select',
                            value: _selectedPurity,
                            items: _purities,
                            onChanged: (val) => setState(() => _selectedPurity = val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    GlassInput(
                      controller: _huidController,
                      label: 'HUID Number',
                      hint: _isEditing ? 'Preserved existing HUID' : 'Auto-generated when blank',
                      readOnly: _isEditing,
                    ),
                    const SizedBox(height: 20),
                    GlassInput(
                      controller: _hsnController,
                      label: 'HSN Code',
                      hint: 'e.g. 7113',
                      validator: (v) => Validators.validateRequired(v, 'HSN Code'),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: GlassInput(
                            controller: _weightController,
                            label: 'Weight (g)',
                            hint: '0.000',
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v != null && v.trim().isNotEmpty && double.tryParse(v) == null) {
                                  return 'Enter a valid number';
                                }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GlassInput(
                            controller: _stockController,
                            label: 'Stock Units',
                            hint: '1',
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Stock is required';
                              if (int.tryParse(v) == null) return 'Enter a valid integer';
                                return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: GlassInput(
                            controller: _makingChargeController,
                            label: 'Making Charge',
                            hint: '0',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GlassInput(
                            controller: _stoneTypeController,
                            label: 'Stone Type',
                            hint: 'Optional',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: GlassInput(
                            controller: _stoneWeightController,
                            label: 'Stone Weight (g)',
                            hint: '0.000',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GlassInput(
                            controller: _stoneValueController,
                            label: 'Stone Value (₹)',
                            hint: '0',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    GlassInput(
                      controller: _imageUrlController,
                      label: 'Image URL',
                      hint: 'Optional',
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
