import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_header.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_input.dart';
import '../../core/widgets/glass_dropdown.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/secondary_button.dart';
import '../customers/customers_provider.dart';
import '../customers/add_customer_dialog.dart';
import '../products/products_provider.dart';
import '../../core/utils/dialog_helper.dart';
import '../more/daily_rates_provider.dart';
import '../more/company_provider.dart';
import '../more/coupons_provider.dart';
import 'billing_provider.dart';
import 'invoices_provider.dart';
import '../../core/utils/pdf_helper.dart';
import '../../core/utils/whatsapp_helper.dart';
import '../../core/utils/formatters.dart';
import '../../models/invoice.dart';
import '../../models/product.dart';
import '../../models/coupon.dart';
import '../../models/company_settings.dart';
import '../../models/customer.dart';

class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  final _phoneController = TextEditingController();
  final _couponController = TextEditingController();
  final _customDiscountController = TextEditingController();
  final _cashController = TextEditingController();
  final _upiController = TextEditingController();
  final _cardController = TextEditingController();
  final _nameController = TextEditingController();
  final _receivedAmountController = TextEditingController();
  final _dueAmountController = TextEditingController();
  final _addressController = TextEditingController();
  final _panController = TextEditingController();
  final _emailController = TextEditingController();
  final _gstController = TextEditingController();

  final _customerPhoneFocusNode = FocusNode();
  final _customerNameFocusNode = FocusNode();
  final _customerAddressFocusNode = FocusNode();
  final _customerPanFocusNode = FocusNode();
  final _customerEmailFocusNode = FocusNode();
  final _customerGstFocusNode = FocusNode();
  final _addItemButtonFocusNode = FocusNode();
  final _cashFocusNode = FocusNode();
  final _upiFocusNode = FocusNode();
  final _cardFocusNode = FocusNode();
  final _receivedAmountFocusNode = FocusNode();
  final _generateButtonFocusNode = FocusNode();
  List<FocusNode> _customerSuggestionFocusNodes = [];

  List<Customer> _suggestions = [];
  bool _showSuggestions = false;
  bool _isGenerating = false;
  bool _isValidatingCoupon = false;
  String? _couponError;
  bool _receivedFullAmount = false;
  bool _registerNewCustomer = false;
  bool _isPopping = false;

  // Inline Product Search / Details
  final _qtyController = TextEditingController(text: '1');
  final _rateController = TextEditingController();
  final _weightController = TextEditingController();
  final _makingChargeController = TextEditingController();
  final _stoneWeightController = TextEditingController(text: '0');
  final _stoneValueController = TextEditingController(text: '0');
  final _discountController = TextEditingController(text: '0');
  final _searchController = TextEditingController();

  Product? _selectedProduct;
  String _makingChargeType = 'PER_GRAM';
  List<Product> _productSuggestions = [];
  bool _showProductSuggestions = false;

  final _searchFocusNode = FocusNode();
  final _qtyFocusNode = FocusNode();
  final _rateFocusNode = FocusNode();
  final _weightFocusNode = FocusNode();
  final _stoneWeightFocusNode = FocusNode();
  final _stoneValueFocusNode = FocusNode();
  final _makingChargeFocusNode = FocusNode();
  final _unitFocusNode = FocusNode();
  final _discountFocusNode = FocusNode();
  final _generalDiscountFocusNode = FocusNode();
  final _couponCodeFocusNode = FocusNode();
  final _applyButtonFocusNode = FocusNode();
  List<FocusNode> _productSuggestionFocusNodes = [];

  // New Product Inline Fields
  bool _showInlineNewProductForm = false;
  bool _isSavingProduct = false;
  String _newProductCategory = 'GOLD';
  String _newProductPurity = '22K';
  bool _saveDetailsToInventory = false;
  final _newProductNameController = TextEditingController();
  final _newProductStockController = TextEditingController(text: '10');
  final _newProductHuidController = TextEditingController();
  final _newProductWeightController = TextEditingController();
  final _newProductMakingChargeController = TextEditingController();
  final _newProductNameFocusNode = FocusNode();
  final _newProductStockFocusNode = FocusNode();
  final _newProductHuidFocusNode = FocusNode();
  final _newProductWeightFocusNode = FocusNode();
  final _newProductMakingChargeFocusNode = FocusNode();

  final _itemHuidController = TextEditingController();
  final _itemHuidFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final billing = ref.read(billingProvider);
    if (billing.customerPhone != null) {
      _phoneController.text = billing.customerPhone!;
    }
    if (billing.customerId == '' && billing.customerName != null) {
      _nameController.text = billing.customerName!;
    }
    _cashController.text = billing.cashAmount > 0 ? billing.cashAmount.toStringAsFixed(0) : '';
    _upiController.text = billing.upiAmount > 0 ? billing.upiAmount.toStringAsFixed(0) : '';
    _cardController.text = billing.cardAmount > 0 ? billing.cardAmount.toStringAsFixed(0) : '';

    if (billing.editingInvoice != null) {
      _receivedFullAmount = billing.editingInvoice!.balanceDue <= 0.05;
      _receivedAmountController.text = billing.editingInvoice!.totalAmountPaid.toStringAsFixed(0);
      _dueAmountController.text = billing.editingInvoice!.balanceDue.toStringAsFixed(0);
      if (billing.customDiscount > 0) {
        _customDiscountController.text = billing.customDiscount.toStringAsFixed(0);
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _customerPhoneFocusNode.requestFocus();
    });

    void addAutoSelectListener(FocusNode node, TextEditingController controller) {
      node.addListener(() {
        if (node.hasFocus && controller.text.isNotEmpty) {
          Future.microtask(() {
            if (node.hasFocus && controller.text.isNotEmpty) {
              controller.selection = TextSelection(
                baseOffset: 0,
                extentOffset: controller.text.length,
              );
            }
          });
        }
      });
    }

    addAutoSelectListener(_cashFocusNode, _cashController);
    addAutoSelectListener(_upiFocusNode, _upiController);
    addAutoSelectListener(_cardFocusNode, _cardController);
    addAutoSelectListener(_receivedAmountFocusNode, _receivedAmountController);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _couponController.dispose();
    _customDiscountController.dispose();
    _cashController.dispose();
    _upiController.dispose();
    _cardController.dispose();
    _nameController.dispose();
    _receivedAmountController.dispose();
    _dueAmountController.dispose();
    _addressController.dispose();
    _panController.dispose();
    _emailController.dispose();
    _gstController.dispose();
    _customerPhoneFocusNode.dispose();
    _customerNameFocusNode.dispose();
    _customerAddressFocusNode.dispose();
    _customerPanFocusNode.dispose();
    _customerEmailFocusNode.dispose();
    _customerGstFocusNode.dispose();
    _addItemButtonFocusNode.dispose();
    _cashFocusNode.dispose();
    _upiFocusNode.dispose();
    _cardFocusNode.dispose();
    _receivedAmountFocusNode.dispose();
    _generateButtonFocusNode.dispose();
    for (final node in _customerSuggestionFocusNodes) {
      node.dispose();
    }

    _qtyController.dispose();
    _rateController.dispose();
    _weightController.dispose();
    _makingChargeController.dispose();
    _stoneWeightController.dispose();
    _stoneValueController.dispose();
    _discountController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _qtyFocusNode.dispose();
    _rateFocusNode.dispose();
    _weightFocusNode.dispose();
    _stoneWeightFocusNode.dispose();
    _stoneValueFocusNode.dispose();
    _makingChargeFocusNode.dispose();
    _unitFocusNode.dispose();
    _discountFocusNode.dispose();
    _generalDiscountFocusNode.dispose();
    _couponCodeFocusNode.dispose();
    _applyButtonFocusNode.dispose();
    for (final node in _productSuggestionFocusNodes) {
      node.dispose();
    }

    _newProductNameController.dispose();
    _newProductStockController.dispose();
    _newProductHuidController.dispose();
    _newProductWeightController.dispose();
    _newProductMakingChargeController.dispose();
    _newProductNameFocusNode.dispose();
    _newProductStockFocusNode.dispose();
    _newProductHuidFocusNode.dispose();
    _newProductWeightFocusNode.dispose();
    _newProductMakingChargeFocusNode.dispose();
    _itemHuidController.dispose();
    _itemHuidFocusNode.dispose();

    super.dispose();
  }

  void _onPhoneChanged(String val, WidgetRef ref) {
    final billing = ref.read(billingProvider);
    if (billing.customerId != null && billing.customerId != '' && billing.customerPhone != val.trim()) {
      ref.read(billingProvider.notifier).clearCustomer();
    }

    final customersState = ref.read(customersProvider);
    if (customersState is AsyncData) {
      final customers = customersState.value!;
      final trimmed = val.trim();
      
      // Auto-select exact match on 10 digits
      final matchIndex = customers.indexWhere((c) => c.mobile == trimmed);
      if (matchIndex != -1) {
        ref.read(billingProvider.notifier).setCustomer(customers[matchIndex]);
        setState(() {
          _suggestions = [];
          _showSuggestions = false;
        });
        _searchFocusNode.requestFocus();
        return;
      }
      
      if (trimmed.isEmpty) {
        ref.read(billingProvider.notifier).clearCustomer();
        setState(() {
          _suggestions = [];
          _showSuggestions = false;
        });
        return;
      }

      final filtered = customers.where((c) =>
        c.mobile.contains(trimmed) ||
        c.name.toLowerCase().contains(trimmed.toLowerCase())
      ).toList();

      setState(() {
        _suggestions = filtered;
        _showSuggestions = true;
        for (final node in _customerSuggestionFocusNodes) {
          node.dispose();
        }
        _customerSuggestionFocusNodes = List.generate(filtered.length, (_) => FocusNode());
      });
    }
  }

  Future<void> _generateInvoice() async {
    final billing = ref.read(billingProvider);
    if (billing.customerName == null || billing.customerName!.trim().isEmpty) {
      _showError('Please select a customer or enter temporary details.');
      return;
    }
    if (billing.products.isEmpty) {
      _showError('Cart is empty. Please add products.');
      return;
    }

    setState(() => _isGenerating = true);
    try {
      final isTemporary = billing.customerId == '';
      Customer customer;
      String? customerIdForInvoice = billing.customerId;
      
      if (isTemporary) {
        final newCust = Customer(
          id: '',
          mobile: billing.customerPhone ?? _phoneController.text.trim(),
          name: Formatters.toTitleCase(billing.customerName ?? _nameController.text.trim()),
          address: _addressController.text.trim(),
          panCard: _panController.text.trim(),
          email: _emailController.text.trim(),
          gstNumber: _gstController.text.trim().toUpperCase(),
          totalPurchaseAmount: 0.0,
          totalInvoices: 0,
        );
        final savedCust = await ref.read(customersProvider.notifier).addCustomer(newCust);
        customer = savedCust;
        customerIdForInvoice = savedCust.id;
        // Select this customer
        ref.read(billingProvider.notifier).setCustomer(savedCust);
      } else {
        final customers = ref.read(customersProvider).value!;
        customer = customers.firstWhere((c) => c.id == billing.customerId);
        customerIdForInvoice = customer.id;
      }

      final todayRate = ref.read(dailyRatesProvider.notifier).getTodayRate();

      final isEditing = billing.editingInvoice != null;
      final invoiceId = isEditing ? billing.editingInvoice!.id! : 'INV-${DateTime.now().millisecondsSinceEpoch}';
      final invoiceNum = isEditing
          ? billing.editingInvoice!.invoiceNumber!
          : (billing.customInvoiceNumber != null && billing.customInvoiceNumber!.isNotEmpty)
              ? billing.customInvoiceNumber!
              : 'INV/${DateTime.now().year}/${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

      final List<InvoiceItem> invoiceItems = billing.products.map((bp) {
        return InvoiceItem(
          productId: bp.productId,
          productName: bp.name,
          huidNumber: bp.huidNumber,
          hsnCode: bp.hsnCode,
          category: bp.category,
          purity: bp.purity,
          quantity: bp.quantity,
          grossWeight: bp.grossWeight,
          netWeight: bp.netWeight,
          rate: bp.rate,
          metalValue: bp.metalValue,
          makingChargeType: bp.makingChargeType,
          makingChargeValue: bp.makingChargeValue,
          makingChargeTotal: bp.makingChargeTotal,
          stoneType: bp.stoneWeight > 0 ? 'Stone' : null,
          stoneWeight: bp.stoneWeight,
          stoneValue: bp.stoneValue,
          discountValue: bp.discountValue,
          itemTotal: bp.itemTotal,
        );
      }).toList();

      double totalPaid;
      double balanceDueVal;
      final List<Payment> paymentsList = [];

      if (_receivedFullAmount) {
        totalPaid = billing.finalPayable;
        balanceDueVal = 0.0;
        
        if (billing.cashAmount > 0) paymentsList.add(Payment(method: 'CASH', amount: billing.cashAmount));
        if (billing.upiAmount > 0) paymentsList.add(Payment(method: 'UPI', amount: billing.upiAmount));
        if (billing.cardAmount > 0) paymentsList.add(Payment(method: 'CARD', amount: billing.cardAmount));
      } else {
        final manualRec = double.tryParse(_receivedAmountController.text) ?? 0.0;
        final splitRec = billing.cashAmount + billing.upiAmount + billing.cardAmount;
        
        if (manualRec > 0 && splitRec == 0) {
          totalPaid = manualRec;
          balanceDueVal = (billing.finalPayable - manualRec).clamp(0.0, double.infinity);
        } else {
          totalPaid = splitRec;
          balanceDueVal = (billing.finalPayable - splitRec).clamp(0.0, double.infinity);
          
          if (billing.cashAmount > 0) paymentsList.add(Payment(method: 'CASH', amount: billing.cashAmount));
          if (billing.upiAmount > 0) paymentsList.add(Payment(method: 'UPI', amount: billing.upiAmount));
          if (billing.cardAmount > 0) paymentsList.add(Payment(method: 'CARD', amount: billing.cardAmount));
        }
      }

      final invoice = Invoice(
        id: invoiceId,
        invoiceNumber: invoiceNum,
        customerId: isTemporary && !_registerNewCustomer ? null : customerIdForInvoice,
        tempCustomerName: isTemporary && !_registerNewCustomer ? (billing.customerName ?? _nameController.text.trim()) : null,
        tempCustomerMobile: isTemporary && !_registerNewCustomer ? (billing.customerPhone ?? _phoneController.text.trim()) : null,
        tempCustomerAddress: isTemporary && !_registerNewCustomer ? _addressController.text.trim() : null,
        items: invoiceItems,
        grossAmount: billing.subtotal,
        couponDiscount: _getCouponDiscountOnly(billing),
        manualDiscount: billing.customDiscount,
        couponCode: billing.couponCode,
        taxableAmount: billing.taxableAmount,
        cgst: billing.cgst,
        sgst: billing.sgst,
        totalTax: billing.totalTax,
        netAmount: billing.grandTotal,
        finalPayable: billing.finalPayable,
        payments: paymentsList,
        totalAmountPaid: totalPaid,
        balanceDue: balanceDueVal,
        invoiceDate: billing.invoiceDate,
        status: balanceDueVal <= 0.05 ? 'PAID' : 'PARTIALLY_PAID',
        ratesSnapshot: RatesSnapshot(
          rateGold22K: todayRate?.rateGold22K ?? 6850.0,
          rateGold18K: todayRate?.rateGold18K ?? 5610.0,
          rateSilver: todayRate?.rateSilver ?? 82.4,
        ),
      );

      Invoice savedInvoice;
      if (isEditing) {
        savedInvoice = await ref.read(invoicesProvider.notifier).updateInvoice(invoiceId, invoice);
      } else {
        savedInvoice = await ref.read(invoicesProvider.notifier).addInvoice(invoice);
      }

      // Reset form
      _phoneController.clear();
      _nameController.clear();
      _addressController.clear();
      _panController.clear();
      _emailController.clear();
      _gstController.clear();
      _cashController.clear();
      _upiController.clear();
      _cardController.clear();
      _receivedAmountController.clear();
      _dueAmountController.clear();
      _receivedFullAmount = false;
      ref.read(billingProvider.notifier).reset();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Invoice updated successfully!' : 'Invoice generated successfully!'),
          backgroundColor: AppColors.success,
        ),
      );

      // Launch choice dialog
      final company = ref.read(companyProvider).value;
      if (mounted) {
        showSingleDialog(
          context: context,
          useRootNavigator: false,
          builder: (context) => BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: AlertDialog(
              backgroundColor: AppColors.surfaceContainer.withValues(alpha: 0.9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                side:  BorderSide(color: AppColors.glassBorder),
              ),
              title: Text(
                'Invoice Ready',
                style: AppTextStyles.titleLg.copyWith(color: AppColors.primary),
              ),
              content: Text(
                'Invoice "${savedInvoice.invoiceNumber}" has been created successfully. Choose an action below.',
                style: AppTextStyles.bodyLg.copyWith(color: AppColors.onBackground),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close', style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceMuted)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.print_rounded),
                  label: const Text('Print PDF'),
                  onPressed: () {
                    PdfHelper.generateAndPrintInvoice(
                      invoice: savedInvoice,
                      customer: customer,
                      company: company,
                    );
                  },
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: const Text('WhatsApp Share'),
                  onPressed: () async {
                    final company = ref.read(companyProvider).value;
                    await WhatsAppHelper.shareInvoice(
                      invoice: savedInvoice,
                      customer: customer,
                      company: company,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      _showError('Failed to generate invoice: $e');
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _showError(String message) {
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

  bool _hasUnsavedChanges(BillingState billing) {
    if (billing.products.isNotEmpty) return true;
    if (billing.customerPhone != null && billing.customerPhone!.isNotEmpty) return true;
    if (billing.customerName != null && billing.customerName!.isNotEmpty) return true;
    if (billing.editingInvoice != null) return true;
    if (billing.cashAmount > 0 || billing.upiAmount > 0 || billing.cardAmount > 0) return true;
    return false;
  }

  Future<bool?> _showDraftDialog(BuildContext context) async {
    return showSingleDialog<bool?>(
      context: context,
      useRootNavigator: false,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        title: const Text('Unsaved Invoice Draft'),
        content: const Text('Do you want to save this invoice as a draft or discard it?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null), // Cancel
            child: Text('Cancel', style: TextStyle(color: AppColors.onSurfaceDim)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Discard
            child: const Text('Discard', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true), // Save Draft
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBackPress(BillingState billing) async {
    if (_hasUnsavedChanges(billing)) {
      final res = await _showDraftDialog(context);
      if (res == null) return; // User cancelled
      if (res == false) {
        ref.read(billingProvider.notifier).reset(); // Discard draft
      }
    }
    if (context.mounted) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final billing = ref.watch(billingProvider);
    final companyState = ref.watch(companyProvider);
    final topPadding = MediaQuery.of(context).padding.top;

    // Listen to billing updates to keep text fields in sync
    ref.listen<BillingState>(billingProvider, (prev, next) {
      // 1. Customer detail changes
      if (prev?.editingInvoice?.id != next.editingInvoice?.id ||
          prev?.customerId != next.customerId ||
          prev?.customerPhone != next.customerPhone) {
        
        _phoneController.text = next.customerPhone ?? '';
        
        final custId = next.customerId;
        if (custId != null && custId.isNotEmpty) {
          final customers = ref.read(customersProvider).value ?? [];
          final cIdx = customers.indexWhere((c) => c.id == custId);
          if (cIdx != -1) {
            final c = customers[cIdx];
            _nameController.text = c.name;
            _addressController.text = c.address ?? '';
            _panController.text = c.panCard ?? '';
            _emailController.text = c.email ?? '';
            _gstController.text = c.gstNumber ?? '';
          } else {
            _nameController.text = next.customerName ?? '';
            _addressController.text = next.editingInvoice?.tempCustomerAddress ?? '';
            _panController.text = '';
            _emailController.text = '';
            _gstController.text = '';
          }
        } else {
          _nameController.text = next.customerName ?? '';
          _addressController.text = next.editingInvoice?.tempCustomerAddress ?? '';
          _panController.text = '';
          _emailController.text = '';
          _gstController.text = '';
        }
      }

      // 2. Custom Discount sync (keeps field in sync if coupon clears it or state changes)
      if (!_generalDiscountFocusNode.hasFocus) {
        final userCustomDiscount = next.customDiscount;
        final currentParsedDiscount = double.tryParse(_customDiscountController.text.trim()) ?? 0.0;
        if (currentParsedDiscount != userCustomDiscount) {
          _customDiscountController.text = userCustomDiscount > 0 ? userCustomDiscount.toStringAsFixed(0) : '';
        }
      }

      // 3. Coupon sync
      if (!_couponCodeFocusNode.hasFocus) {
        final stateCoupon = next.couponCode ?? '';
        if (stateCoupon.isNotEmpty && _couponController.text != stateCoupon) {
          _couponController.text = stateCoupon;
        } else if (stateCoupon.isEmpty && (prev?.couponCode?.isNotEmpty ?? false)) {
          _couponController.text = '';
        }
      }

      // 4. Payment splits sync
      if (!_cashFocusNode.hasFocus) {
        final currentCash = double.tryParse(_cashController.text.trim()) ?? 0.0;
        if (currentCash != next.cashAmount) {
          _cashController.text = next.cashAmount > 0 ? next.cashAmount.toStringAsFixed(0) : '';
        }
      }
      if (!_upiFocusNode.hasFocus) {
        final currentUpi = double.tryParse(_upiController.text.trim()) ?? 0.0;
        if (currentUpi != next.upiAmount) {
          _upiController.text = next.upiAmount > 0 ? next.upiAmount.toStringAsFixed(0) : '';
        }
      }
      if (!_cardFocusNode.hasFocus) {
        final currentCard = double.tryParse(_cardController.text.trim()) ?? 0.0;
        if (currentCard != next.cardAmount) {
          _cardController.text = next.cardAmount > 0 ? next.cardAmount.toStringAsFixed(0) : '';
        }
      }

      // 5. Invoice edit status sync & payment details sync
      if (next.editingInvoice != null) {
        _receivedFullAmount = next.editingInvoice!.balanceDue <= 0.05;
        if (!_receivedAmountFocusNode.hasFocus) {
          _receivedAmountController.text = next.editingInvoice!.totalAmountPaid.toStringAsFixed(0);
        }
        _dueAmountController.text = next.editingInvoice!.balanceDue.toStringAsFixed(0);
      } else {
        _receivedFullAmount = next.manualReceivedAmount != null || (next.totalPaid >= next.finalPayable && next.finalPayable > 0);
        if (!_receivedAmountFocusNode.hasFocus) {
          final currentParsedReceived = double.tryParse(_receivedAmountController.text.trim());
          if (next.totalPaid != currentParsedReceived) {
            _receivedAmountController.text = next.totalPaid > 0 ? next.totalPaid.toStringAsFixed(0) : '';
          }
        }
        final currentParsedDue = double.tryParse(_dueAmountController.text.trim());
        if (next.balanceDue != currentParsedDue) {
          _dueAmountController.text = next.balanceDue >= 0 ? next.balanceDue.toStringAsFixed(0) : '0';
        }
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_hasUnsavedChanges(billing)) {
          final res = await _showDraftDialog(context);
          if (res == null) return; // User cancelled, stay on screen
          if (res == false) {
            ref.read(billingProvider.notifier).reset(); // Discard draft
          }
          // If res is true (Save Draft), we keep the state intact
        }
        if (context.mounted) {
          context.go('/');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: topPadding + 8),

              // ── Top Bar ──
              const AppHeader(),

              const SizedBox(height: 16),

              // ── Invoice Meta (Date & Next Invoice Number) ──
              _buildInvoiceMetaSection(billing),

              const SizedBox(height: 24),

              // ── Customer Details ──
              _buildCustomerSection(billing),

              const SizedBox(height: 24),

              // ── Products Section ──
              _buildProductsSection(billing, context),

              const SizedBox(height: 24),

              // ── Coupons & Offers Section ──
              _buildCouponSection(billing),

              const SizedBox(height: 24),

              // ── Payment Split ──
              _buildPaymentSplit(billing),

              const SizedBox(height: 24),

              // ── Grand Total & Generate Invoice (Inline Bottom) ──
              _buildBottomBar(billing),

              const SizedBox(height: 110),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildCustomerSection(BillingState billing) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Customer Details', style: AppTextStyles.sectionTitle)
              .animate()
              .fadeIn(duration: 300.ms, delay: 100.ms),
          const SizedBox(height: 12),

          // Phone Input
          Focus(
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowDown) {
                if (_customerSuggestionFocusNodes.isNotEmpty) {
                  _customerSuggestionFocusNodes.first.requestFocus();
                  return KeyEventResult.handled;
                }
              }
              return KeyEventResult.ignored;
            },
            child: GlassInput(
              focusNode: _customerPhoneFocusNode,
              controller: _phoneController,
              label: 'Search Customer By Phone/Name',
              hint: 'Type mobile number or customer name...',
              prefixIcon:  Icon(Icons.phone_rounded, color: AppColors.primary),
              keyboardType: TextInputType.phone,
              onChanged: (val) => _onPhoneChanged(val, ref),
              onFieldSubmitted: (val) {
                if (_showSuggestions && _suggestions.isNotEmpty) {
                  final c = _suggestions.first;
                  ref.read(billingProvider.notifier).setCustomer(c);
                  _phoneController.text = c.mobile;
                  setState(() {
                    _showSuggestions = false;
                    _suggestions = [];
                  });
                  _searchFocusNode.requestFocus();
                } else if (billing.customerId == null || billing.customerId == '') {
                  _customerNameFocusNode.requestFocus();
                } else {
                  _searchFocusNode.requestFocus();
                }
              },
              suffixIcon: (billing.customerName != null || _phoneController.text.isNotEmpty)
                  ? IconButton(
                      icon:  Icon(Icons.clear, color: AppColors.onSurfaceDim, size: 18),
                      onPressed: () {
                        _phoneController.clear();
                        _nameController.clear();
                        _addressController.clear();
                        _panController.clear();
                        _emailController.clear();
                        _gstController.clear();
                        ref.read(billingProvider.notifier).clearCustomer();
                        setState(() {
                          _showSuggestions = false;
                          _suggestions = [];
                          _registerNewCustomer = false;
                        });
                      },
                    )
                  : null,
            ),
          ),

          // Suggestions list
          if (_showSuggestions && _suggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            GlassCard(
              animationIndex: 2,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  children: _suggestions.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final c = entry.value;
                    final node = _customerSuggestionFocusNodes[idx];
                    return Focus(
                      focusNode: node,
                      onFocusChange: (focused) {
                        if (focused) {
                          Scrollable.ensureVisible(
                            context,
                            duration: const Duration(milliseconds: 100),
                            alignment: 0.5,
                          );
                        }
                        setState(() {});
                      },
                      onKeyEvent: (fNode, event) {
                        if (event is KeyDownEvent) {
                          if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter) {
                            _searchFocusNode.requestFocus();
                            ref.read(billingProvider.notifier).setCustomer(c);
                            _phoneController.text = c.mobile;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(() {
                                  _showSuggestions = false;
                                  _suggestions = [];
                                });
                              }
                            });
                            return KeyEventResult.handled;
                          } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                            if (idx < _suggestions.length - 1) {
                              _customerSuggestionFocusNodes[idx + 1].requestFocus();
                            }
                            return KeyEventResult.handled;
                          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                            if (idx > 0) {
                              _customerSuggestionFocusNodes[idx - 1].requestFocus();
                            } else {
                              _customerPhoneFocusNode.requestFocus();
                            }
                            return KeyEventResult.handled;
                          }
                        }
                        return KeyEventResult.ignored;
                      },
                      child: Container(
                        color: node.hasFocus ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
                        child: ListTile(
                          leading:  Icon(Icons.person, color: AppColors.primary, size: 20),
                          title: Text(c.name, style: AppTextStyles.bodyMd.copyWith(color: AppColors.onBackground)),
                          subtitle: Text(c.mobile, style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted)),
                          onTap: () {
                            _searchFocusNode.requestFocus();
                            ref.read(billingProvider.notifier).setCustomer(c);
                            _phoneController.text = c.mobile;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(() {
                                  _showSuggestions = false;
                                  _suggestions = [];
                                });
                              }
                            });
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],

          // Auto-shown New Customer Registration fields
          if ((billing.customerId == null || billing.customerId == '') && _phoneController.text.isNotEmpty) ...[
            const SizedBox(height: 12),
            GlassCard(
              animationIndex: 2,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NEW CUSTOMER DETAILS',
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GlassInput(
                    focusNode: _customerNameFocusNode,
                    controller: _nameController,
                    label: 'Customer Name',
                    hint: 'Enter customer name',
                    onChanged: (val) {
                      ref.read(billingProvider.notifier).setTemporaryCustomer(val, _phoneController.text);
                    },
                    onFieldSubmitted: (_) => _customerAddressFocusNode.requestFocus(),
                  ),
                  const SizedBox(height: 12),
                  GlassInput(
                    focusNode: _customerAddressFocusNode,
                    controller: _addressController,
                    label: 'Address',
                    hint: 'Enter address (e.g. Thakurbari Road, Patna)',
                    onFieldSubmitted: (_) => _customerPanFocusNode.requestFocus(),
                  ),
                  const SizedBox(height: 12),
                  GlassInput(
                    focusNode: _customerPanFocusNode,
                    controller: _panController,
                    label: 'PAN Card (Optional)',
                    hint: 'Enter PAN card number',
                    onFieldSubmitted: (_) => _customerEmailFocusNode.requestFocus(),
                  ),
                  const SizedBox(height: 12),
                  GlassInput(
                    focusNode: _customerEmailFocusNode,
                    controller: _emailController,
                    label: 'Email (Optional)',
                    hint: 'customer@email.com',
                    keyboardType: TextInputType.emailAddress,
                    onFieldSubmitted: (_) => _customerGstFocusNode.requestFocus(),
                  ),
                  const SizedBox(height: 12),
                  GlassInput(
                    focusNode: _customerGstFocusNode,
                    controller: _gstController,
                    label: 'GST Number (Optional)',
                    hint: '10AQOPK4039R1ZF',
                    onFieldSubmitted: (_) => _addItemButtonFocusNode.requestFocus(),
                  ),
                ],
              ),
            ),
          ],

          if (billing.customerName != null && billing.customerId != '') ...[
            const SizedBox(height: 10),
            // Customer Card (registered members)
            GlassCard(
              animationIndex: 2,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          billing.customerName!,
                          style: AppTextStyles.titleSm,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              'Tier: ',
                              style: AppTextStyles.bodySm.copyWith(
                                color: AppColors.onSurfaceMuted,
                              ),
                            ),
                            Text(
                              billing.customerTier ?? '',
                              style: AppTextStyles.bodySm.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon:  Icon(Icons.cancel_rounded, color: AppColors.error, size: 22),
                    onPressed: () {
                      _phoneController.clear();
                      _nameController.clear();
                      _addressController.clear();
                      _panController.clear();
                      _emailController.clear();
                      _gstController.clear();
                      ref.read(billingProvider.notifier).clearCustomer();
                      setState(() {
                        _showSuggestions = false;
                        _suggestions = [];
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductsSection(BillingState billing, BuildContext context) {
    final productsState = ref.watch(productsProvider);
    final productsList = productsState.value ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Products', style: AppTextStyles.sectionTitle),
              SecondaryButton(
                label: 'Scan Barcode',
                icon: Icons.qr_code_scanner_rounded,
                onPressed: () => _showBarcodeDialog(context),
              ),
            ],
          ).animate().fadeIn(duration: 300.ms, delay: 200.ms),

          const SizedBox(height: 8),

          // Collapsed list of already added products
          if (billing.products.isNotEmpty) ...[
            ...billing.products.asMap().entries.map((entry) {
              final i = entry.key;
              final product = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  animationIndex: 3 + i,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${product.huidNumber != null && product.huidNumber!.isNotEmpty ? "HUID: ${product.huidNumber} - " : ""}${product.name}',
                              style: AppTextStyles.cardTitle,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${product.purity} | Weight: ${product.grossWeight.toStringAsFixed(2)}g',
                              style: AppTextStyles.cardSubtitle,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '₹${_formatAmount(product.itemTotal)}',
                        style: AppTextStyles.amountMd,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                        onPressed: () => ref.read(billingProvider.notifier).removeProduct(i),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
          ],

          // Inline Active Form for Product Selection / Creation

          _buildActiveProductForm(productsList),

          const SizedBox(height: 16),

          Center(
            child: _isSavingProduct
                ? const CircularProgressIndicator()
                : Focus(
                    focusNode: _addItemButtonFocusNode,
                    onKeyEvent: (node, event) {
                      if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
                        _onAddProductItemPressed();
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: Builder(
                      builder: (context) {
                        final isFocused = Focus.of(context).hasFocus;
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: isFocused ? Border.all(color: AppColors.primary, width: 2) : null,
                          ),
                          padding: const EdgeInsets.all(4),
                          child: SecondaryButton(
                            label: _showInlineNewProductForm ? '+ Save & Add Item' : '+ Add Item',
                            onPressed: _onAddProductItemPressed,
                          ),
                        );
                      }
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveProductForm(List<Product> productsList) {
    if (_showInlineNewProductForm) {
      return GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'New Product Details',
                  style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _showInlineNewProductForm = false);
                  },
                  child: const Text('Search Existing'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GlassInput(
              focusNode: _newProductNameFocusNode,
              controller: _newProductNameController,
              label: 'Product Name',
              hint: 'e.g. Gold Bangle Plain',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _newProductCategory,
                    dropdownColor: AppColors.surfaceContainer,
                    decoration: InputDecoration(
                      fillColor: AppColors.surfaceDim,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.glassBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.glassBorder)),
                    ),
                    style: AppTextStyles.bodyMd.copyWith(color: AppColors.onBackground),
                    items: const [
                      DropdownMenuItem(value: 'GOLD', child: Text('Gold')),
                      DropdownMenuItem(value: 'SILVER', child: Text('Silver')),
                      DropdownMenuItem(value: 'DIAMOND', child: Text('Diamond')),
                      DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _newProductCategory = val;
                          if (val == 'SILVER') {
                            _newProductPurity = '925';
                          } else {
                            _newProductPurity = '22K';
                          }
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _newProductPurity,
                    dropdownColor: AppColors.surfaceContainer,
                    decoration: InputDecoration(
                      fillColor: AppColors.surfaceDim,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.glassBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.glassBorder)),
                    ),
                    style: AppTextStyles.bodyMd.copyWith(color: AppColors.onBackground),
                    items: _newProductCategory == 'GOLD'
                        ? const [
                            DropdownMenuItem(value: '22K', child: Text('22K')),
                            DropdownMenuItem(value: '18K', child: Text('18K')),
                            DropdownMenuItem(value: '24K', child: Text('24K')),
                            DropdownMenuItem(value: '14K', child: Text('14K')),
                          ]
                        : _newProductCategory == 'SILVER'
                            ? const [
                                DropdownMenuItem(value: '925', child: Text('925 Sterling')),
                                DropdownMenuItem(value: '999', child: Text('999 Pure')),
                              ]
                            : const [
                                DropdownMenuItem(value: '18K', child: Text('18K')),
                                DropdownMenuItem(value: '22K', child: Text('22K')),
                                DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                              ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _newProductPurity = val);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GlassInput(
                    focusNode: _newProductStockFocusNode,
                    controller: _newProductStockController,
                    label: 'Stock Units',
                    hint: '10',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GlassInput(
                    focusNode: _newProductHuidFocusNode,
                    controller: _newProductHuidController,
                    label: 'HUID Number (Optional)',
                    hint: 'HUID123456',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _saveDetailsToInventory,
                    onChanged: (val) {
                      setState(() {
                        _saveDetailsToInventory = val ?? false;
                      });
                    },
                    activeColor: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Save weight & making charge to inventory template',
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted),
                  ),
                ),
              ],
            ),
            if (_saveDetailsToInventory) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GlassInput(
                      focusNode: _newProductWeightFocusNode,
                      controller: _newProductWeightController,
                      label: 'Template Weight (g)',
                      hint: '0.000',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassInput(
                      focusNode: _newProductMakingChargeFocusNode,
                      controller: _newProductMakingChargeController,
                      label: 'Template Making Charge',
                      hint: '0',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            _buildSharedDetailInputs(),
          ],
        ),
      );
    }

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Search Product', style: TextStyle(fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showInlineNewProductForm = true;
                    _selectedProduct = null;
                    _searchController.clear();
                    _rateController.clear();
                    _weightController.clear();
                    _makingChargeController.clear();
                  });
                },
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add New Product'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Focus(
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowDown) {
                if (_productSuggestionFocusNodes.isNotEmpty) {
                  _productSuggestionFocusNodes.first.requestFocus();
                  return KeyEventResult.handled;
                }
              }
              return KeyEventResult.ignored;
            },
            child: GlassInput(
              focusNode: _searchFocusNode,
              controller: _searchController,
              label: 'Product Search',
              hint: 'Search by name, ID, HUID, purity...',
              prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary),
              onChanged: (val) => _onProductSearchChanged(val, productsList),
              onFieldSubmitted: (val) {
                if (_showProductSuggestions && _productSuggestions.isNotEmpty) {
                  final p = _productSuggestions.first;
                  _onProductSelected(p);
                  _searchController.text = p.name;
                  setState(() {
                    _showProductSuggestions = false;
                  });
                  _qtyFocusNode.requestFocus();
                } else if (_selectedProduct != null) {
                  _qtyFocusNode.requestFocus();
                } else {
                  FocusScope.of(context).nextFocus();
                }
              },
              suffixIcon: (_selectedProduct != null || _searchController.text.isNotEmpty)
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _selectedProduct = null;
                          _productSuggestions = [];
                          _showProductSuggestions = false;
                          _weightController.clear();
                          _rateController.clear();
                          _makingChargeController.clear();
                        });
                      },
                    )
                  : null,
            ),
          ),
          if (_showProductSuggestions && _productSuggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _productSuggestions.length,
                  itemBuilder: (context, idx) {
                    final p = _productSuggestions[idx];
                    final node = _productSuggestionFocusNodes[idx];
                    return Focus(
                      focusNode: node,
                      onFocusChange: (focused) {
                        if (focused) {
                          Scrollable.ensureVisible(
                            context,
                            duration: const Duration(milliseconds: 100),
                            alignment: 0.5,
                          );
                        }
                        setState(() {});
                      },
                      onKeyEvent: (fNode, event) {
                        if (event is KeyDownEvent) {
                          if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter) {
                            _qtyFocusNode.requestFocus();
                            _onProductSelected(p);
                            _searchController.text = p.name;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(() {
                                  _showProductSuggestions = false;
                                  _productSuggestions = [];
                                });
                              }
                            });
                            return KeyEventResult.handled;
                          } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                            if (idx < _productSuggestions.length - 1) {
                              _productSuggestionFocusNodes[idx + 1].requestFocus();
                            }
                            return KeyEventResult.handled;
                          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                            if (idx > 0) {
                              _productSuggestionFocusNodes[idx - 1].requestFocus();
                            } else {
                              _searchFocusNode.requestFocus();
                            }
                            return KeyEventResult.handled;
                          }
                        }
                        return KeyEventResult.ignored;
                      },
                      child: Container(
                        color: node.hasFocus ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
                        child: ListTile(
                          leading: const Icon(Icons.inventory_2_outlined),
                          title: Text(p.name, style: AppTextStyles.bodyMd.copyWith(color: AppColors.onBackground)),
                          subtitle: Text('${p.purity} • ${p.category} • stock: ${p.stockUnits}', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted)),
                          onTap: () {
                            _qtyFocusNode.requestFocus();
                            _onProductSelected(p);
                            _searchController.text = p.name;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(() {
                                  _showProductSuggestions = false;
                                  _productSuggestions = [];
                                });
                              }
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
          if (_selectedProduct != null) ...[
            const SizedBox(height: 8),
            Text(
              'Selected: ${_selectedProduct!.name} (${_selectedProduct!.purity}, ${_selectedProduct!.category})',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ],
          const SizedBox(height: 16),
          _buildSharedDetailInputs(),
        ],
      ),
    );
  }

  Widget _buildSharedDetailInputs() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GlassInput(
                focusNode: _qtyFocusNode,
                controller: _qtyController,
                label: 'Quantity',
                hint: '1',
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                onFieldSubmitted: (_) => _rateFocusNode.requestFocus(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GlassInput(
                focusNode: _rateFocusNode,
                controller: _rateController,
                label: 'Rate (₹/g)',
                hint: '6,850',
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                onFieldSubmitted: (_) => _weightFocusNode.requestFocus(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GlassInput(
                focusNode: _weightFocusNode,
                controller: _weightController,
                label: 'Gross Weight (g)',
                hint: '0.000',
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                onFieldSubmitted: (_) => _discountFocusNode.requestFocus(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GlassInput(
                focusNode: _discountFocusNode,
                controller: _discountController,
                label: 'Product Discount (₹)',
                hint: '0',
                keyboardType: TextInputType.number,
                onFieldSubmitted: (_) => _makingChargeFocusNode.requestFocus(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: GlassInput(
                focusNode: _makingChargeFocusNode,
                controller: _makingChargeController,
                label: 'Making Charge',
                hint: '0',
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                onFieldSubmitted: (_) => _stoneWeightFocusNode.requestFocus(),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 90,
              child: GlassDropdown<String>(
                focusNode: _unitFocusNode,
                label: 'Unit',
                value: _makingChargeType == 'PER_GRAM'
                    ? '/gm'
                    : (_makingChargeType == 'FIXED' ? '/pcs' : '%'),
                items: const [
                  DropdownMenuItem(value: '/gm', child: Text('/gm')),
                  DropdownMenuItem(value: '/pcs', child: Text('/pcs')),
                  DropdownMenuItem(value: '%', child: Text('%')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      if (val == '/gm') {
                        _makingChargeType = 'PER_GRAM';
                      } else if (val == '/pcs') {
                        _makingChargeType = 'FIXED';
                      } else {
                        _makingChargeType = 'PERCENTAGE';
                      }
                    });
                    _stoneWeightFocusNode.requestFocus();
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GlassInput(
                focusNode: _stoneWeightFocusNode,
                controller: _stoneWeightController,
                label: 'Stone Weight (g)',
                hint: '0.0',
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                onFieldSubmitted: (_) => _stoneValueFocusNode.requestFocus(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GlassInput(
                focusNode: _stoneValueFocusNode,
                controller: _stoneValueController,
                label: 'Stone Value (₹)',
                hint: '0',
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                onFieldSubmitted: (_) => _itemHuidFocusNode.requestFocus(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GlassInput(
          focusNode: _itemHuidFocusNode,
          controller: _itemHuidController,
          label: 'HUID Number (Optional)',
          hint: 'e.g. HUID123456',
          onFieldSubmitted: (_) => _addItemButtonFocusNode.requestFocus(),
        ),
      ],
    );
  }

  void _onProductSearchChanged(String val, List<Product> products) {
    final query = val.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _productSuggestions = [];
        _showProductSuggestions = false;
      });
      return;
    }
    final activeProducts = products.where((p) => p.isActive && p.stockUnits > 0).toList();
    final filtered = activeProducts.where((p) =>
      p.name.toLowerCase().contains(query) ||
      (p.id?.toLowerCase().contains(query) ?? false) ||
      (p.serialNumber?.toLowerCase().contains(query) ?? false) ||
      (p.huidNumber?.toLowerCase().contains(query) ?? false) ||
      (p.purity.toLowerCase().contains(query)) ||
      (p.category.toLowerCase().contains(query))
    ).toList();
    setState(() {
      _productSuggestions = filtered;
      _showProductSuggestions = true;
      for (final node in _productSuggestionFocusNodes) {
        node.dispose();
      }
      _productSuggestionFocusNodes = List.generate(filtered.length, (_) => FocusNode());
    });
  }

  void _onProductSelected(Product? p) {
    if (p == null) return;
    setState(() {
      _selectedProduct = p;
      _weightController.text = p.weight.toStringAsFixed(3);
      _makingChargeController.text = p.makingChargeValue.toStringAsFixed(0);
      _itemHuidController.text = p.huidNumber ?? '';

      // Auto-compute rate based on today's daily rate snapshot
      final rates = ref.read(dailyRatesProvider).value ?? [];
      final latestRate = rates.isNotEmpty ? rates.first : null;

      double calculatedRate = 0.0;
      if (p.category.toUpperCase() == 'GOLD') {
        if (p.purity.toUpperCase() == '22K') {
          calculatedRate = latestRate?.rateGold22K ?? 6850.0;
        } else if (p.purity.toUpperCase() == '18K') {
          calculatedRate = latestRate?.rateGold18K ?? 5610.0;
        } else {
          calculatedRate = latestRate?.rateGold22K ?? 6850.0;
        }
      } else if (p.category.toUpperCase() == 'SILVER') {
        calculatedRate = latestRate?.rateSilver ?? 82.4;
      }

      _rateController.text = calculatedRate > 0 ? calculatedRate.toStringAsFixed(0) : '0';
    });
  }

  Future<void> _onAddProductItemPressed() async {
    Product? selected = _selectedProduct;
    if (_showInlineNewProductForm) {
      final name = _newProductNameController.text.trim();
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Please enter a product name'), backgroundColor: AppColors.error),
        );
        return;
      }
      final stock = int.tryParse(_newProductStockController.text) ?? 10;
      final huid = _newProductHuidController.text.trim();
      
      setState(() => _isSavingProduct = true);
      try {
        final product = Product(
          name: Formatters.toTitleCase(name),
          category: _newProductCategory,
          purity: _newProductPurity,
          huidNumber: huid.isEmpty ? null : huid,
          hsnCode: '7113', // default HSN for jewellery
          weight: _saveDetailsToInventory ? (double.tryParse(_newProductWeightController.text) ?? 0.0) : 0.0,
          stockUnits: stock,
          makingChargeValue: _saveDetailsToInventory ? (double.tryParse(_newProductMakingChargeController.text) ?? 0.0) : 0.0,
          isActive: true,
        );
        await ref.read(productsProvider.notifier).addProduct(product);
        final updatedList = ref.read(productsProvider).value ?? [];
        if (updatedList.isNotEmpty) {
          selected = updatedList.firstWhere((p) => p.name.toLowerCase() == name.toLowerCase(), orElse: () => updatedList.first);
        }
        // Cleanup inline product form
        _newProductNameController.clear();
        _newProductStockController.text = '10';
        _newProductHuidController.clear();
        _newProductWeightController.clear();
        _newProductMakingChargeController.clear();
        _saveDetailsToInventory = false;
        _showInlineNewProductForm = false;
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create new product: $e'), backgroundColor: AppColors.error),
        );
        return;
      } finally {
        setState(() => _isSavingProduct = false);
      }
    }

    if (selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Please select or create a product first'), backgroundColor: AppColors.error),
      );
      return;
    }

    final qty = int.tryParse(_qtyController.text) ?? 1;
    final rate = double.tryParse(_rateController.text) ?? 0.0;
    final weight = double.tryParse(_weightController.text) ?? 0.0;
    final mcVal = double.tryParse(_makingChargeController.text) ?? 0.0;
    final stoneW = double.tryParse(_stoneWeightController.text) ?? 0.0;
    final stoneV = double.tryParse(_stoneValueController.text) ?? 0.0;
    final discount = double.tryParse(_discountController.text) ?? 0.0;

    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Quantity must be greater than 0.'), backgroundColor: AppColors.error),
      );
      return;
    }
    if (weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Gross weight must be greater than 0.'), backgroundColor: AppColors.error),
      );
      return;
    }

    // Verify stock
    if (selected.stockUnits < qty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient stock. Only ${selected.stockUnits} available.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final billingProduct = BillingProduct(
      productId: selected.id ?? '',
      name: selected.name,
      hsnCode: selected.hsnCode,
      category: selected.category,
      purity: selected.purity,
      huidNumber: _itemHuidController.text.trim().isEmpty ? null : _itemHuidController.text.trim(),
      rate: rate,
      quantity: qty,
      grossWeight: weight,
      stoneWeight: stoneW,
      stoneValue: stoneV,
      makingChargeType: _makingChargeType,
      makingChargeValue: mcVal,
      discountValue: discount,
    );

    ref.read(billingProvider.notifier).addProduct(billingProduct);
    HapticFeedback.mediumImpact();

    // Reset controllers for next product entry
    _searchController.clear();
    _itemHuidController.clear();
    _qtyController.text = '1';
    _rateController.clear();
    _weightController.clear();
    _makingChargeController.clear();
    _stoneWeightController.text = '0';
    _stoneValueController.text = '0';
    _discountController.text = '0';
    _newProductNameController.clear();
    _newProductHuidController.clear();
    _newProductStockController.text = '10';

    setState(() {
      _selectedProduct = null;
      _showInlineNewProductForm = false;
      _productSuggestions = [];
      _showProductSuggestions = false;
      _makingChargeType = 'PER_GRAM';
    });

    _couponCodeFocusNode.requestFocus();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Product added to invoice'), duration: Duration(seconds: 1)),
    );
  }

  String getNextInvoiceNumber(CompanySettings? settings) {
    if (settings == null) return 'SW/XXXXX';
    final config = settings.invoiceConfig;
    final nextCounter = config.currentCounter + 1;
    final padded = nextCounter.toString().padLeft(config.paddingLength, '0');
    var numStr = '${config.prefix}${config.separator}$padded';
    if (config.financialYear.isNotEmpty) {
      numStr = '${config.financialYear}${config.separator}$numStr';
    }
    if (config.suffix.isNotEmpty) {
      numStr = '$numStr${config.separator}${config.suffix}';
    }
    return numStr;
  }

  Widget _buildInvoiceMetaSection(BillingState billing) {
    final companyState = ref.watch(companyProvider);
    final isEditing = billing.editingInvoice != null;
    
    String invoiceTag;
    if (isEditing) {
      invoiceTag = 'Editing Invoice: ${billing.editingInvoice!.invoiceNumber}';
    } else if (billing.customInvoiceNumber != null) {
      invoiceTag = 'Custom Invoice: ${billing.customInvoiceNumber}';
    } else {
      final settings = companyState.value;
      invoiceTag = 'Next Invoice: ${getNextInvoiceNumber(settings)}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (kIsWeb && MediaQuery.of(context).size.width >= 850) ...[
                GestureDetector(
                  onTap: () => _handleBackPress(billing),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.glassBorder, width: 0.5),
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.primary,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              GestureDetector(
                onTap: isEditing ? null : () => _showEditInvoiceNumberDialog(context, billing),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.glassBorder, width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        invoiceTag,
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.onBackground,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (!isEditing) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.edit_rounded, color: AppColors.primary, size: 12),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: billing.invoiceDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (context, child) {
                      return Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: ColorScheme.dark(
                            primary: AppColors.primary,
                            onPrimary: AppColors.onBackground,
                            surface: AppColors.background,
                            onSurface: AppColors.onBackground,
                          ),
                          dialogBackgroundColor: AppColors.surfaceContainer,
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    ref.read(billingProvider.notifier).setInvoiceDate(picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.glassBorder, width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('dd MMM yyyy').format(billing.invoiceDate),
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.onBackground,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
                icon: Icon(Icons.refresh_rounded, color: AppColors.primary, size: 20),
                tooltip: 'Refresh Billing Session',
                onPressed: () {
                  ref.read(billingProvider.notifier).reset();
                  _phoneController.clear();
                  _nameController.clear();
                  _cashController.clear();
                  _upiController.clear();
                  _cardController.clear();
                  _receivedAmountController.clear();
                  _dueAmountController.clear();
                  ref.invalidate(dailyRatesProvider);
                  ref.invalidate(companyProvider);
                  ref.invalidate(customersProvider);
                  ref.invalidate(invoicesProvider);
                  setState(() {
                    _receivedFullAmount = false;
                    _showSuggestions = false;
                    _suggestions = [];
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Billing session refreshed.'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _matchInvoiceNumber(String? invoiceNumber, String query) {
    if (invoiceNumber == null) return false;
    
    final cleanInv = invoiceNumber.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
    final cleanQuery = query.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
    
    if (cleanInv.isEmpty || cleanQuery.isEmpty) return false;

    // 1. Alphanumeric suffix or exact match
    if (cleanInv == cleanQuery || cleanInv.endsWith(cleanQuery)) {
      return true;
    }
    
    // 2. Trailing digit matching (e.g. "000643" matches "643")
    final invDigits = invoiceNumber.replaceAll(RegExp(r'\D'), '');
    final queryDigits = query.replaceAll(RegExp(r'\D'), '');
    if (invDigits.isNotEmpty && queryDigits.isNotEmpty) {
      final invVal = int.tryParse(invDigits);
      final queryVal = int.tryParse(queryDigits);
      if (invVal != null && queryVal != null && invVal == queryVal) {
        return true;
      }
    }
    
    return false;
  }

  void _showEditInvoiceNumberDialog(BuildContext context, BillingState billing) {
    final companyState = ref.read(companyProvider);
    final defaultNum = billing.customInvoiceNumber ?? getNextInvoiceNumber(companyState.value);
    final controller = TextEditingController(text: defaultNum);

    showSingleDialog(
      context: context,
      useRootNavigator: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: AppColors.surfaceContainer.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            side:  BorderSide(color: AppColors.glassBorder),
          ),
          title: Text(
            'Edit Invoice Number',
            style: AppTextStyles.titleLg.copyWith(color: AppColors.primary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter the custom invoice number you want to assign to this bill.',
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceMuted),
              ),
              const SizedBox(height: 16),
              GlassInput(
                controller: controller,
                label: 'Invoice Number',
                hint: 'e.g. S-000003',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                ref.read(billingProvider.notifier).setCustomInvoiceNumber(null);
                Navigator.pop(context);
              },
              child: Text('Reset to Default', style: AppTextStyles.bodyMd.copyWith(color: AppColors.error)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final newNum = controller.text.trim();
                if (newNum.isNotEmpty) {
                  final inv = await ref.read(invoicesProvider.notifier).findInvoiceByNumber(newNum);
                  if (inv != null) {
                    final customers = ref.read(customersProvider).value ?? [];
                    final customerIndex = customers.indexWhere((c) => c.id == inv.customerId);
                    final customer = customerIndex != -1 
                        ? customers[customerIndex] 
                        : Customer(
                            name: inv.tempCustomerName ?? 'Customer',
                            mobile: inv.tempCustomerMobile ?? '',
                            address: inv.tempCustomerAddress ?? '',
                          );
                    ref.read(billingProvider.notifier).loadInvoiceToEdit(inv, customer);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Existing invoice "${inv.invoiceNumber}" loaded for editing.'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  } else {
                    ref.read(billingProvider.notifier).setCustomInvoiceNumber(newNum);
                  }
                }
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _applyDiscountAndCoupon(BillingState billing) async {
    final code = _couponController.text.trim().toUpperCase();
    final customDiscText = _customDiscountController.text.trim();
    
    List<String> errors = [];
    double? customDisc;

    // 1. Validate discount value
    if (customDiscText.isNotEmpty) {
      customDisc = double.tryParse(customDiscText);
      if (customDisc == null) {
        errors.add('Discount value must be a number (written in digits).');
      } else if (customDisc < 0) {
        errors.add('Discount value cannot be negative.');
      }
    }

    // 2. Validate coupon code
    Coupon? validCoupon;
    if (code.isNotEmpty) {
      setState(() {
        _isValidatingCoupon = true;
        _couponError = null;
      });
      try {
        final coupon = await ref.read(couponsProvider.notifier).validateCouponCode(
          code,
          billing.subtotal,
          date: billing.invoiceDate,
        );
        validCoupon = coupon;
      } catch (e) {
        errors.add('Coupon Error: ${e.toString().replaceAll('Exception: ', '')}');
      } finally {
        setState(() => _isValidatingCoupon = false);
      }
    }

    if (errors.isNotEmpty) {
      setState(() {
        _couponError = errors.join('\n');
      });
    } else {
      setState(() {
        _couponError = null;
      });
    }

    // Apply the valid custom discount
    if (customDiscText.isEmpty) {
      ref.read(billingProvider.notifier).setCustomDiscount(0.0);
    } else if (customDisc != null && customDisc >= 0) {
      ref.read(billingProvider.notifier).setCustomDiscount(customDisc);
    }

    // Apply the valid coupon
    if (validCoupon != null) {
      ref.read(billingProvider.notifier).applyCoupon(validCoupon);
    }

    // Move focus to payment split (UPI -> CASH -> CARD)
    _upiFocusNode.requestFocus();
  }

  Widget _buildCouponSection(BillingState billing) {
    final couponsAsync = ref.watch(couponsProvider);
    final couponsList = couponsAsync.value ?? [];
    final now = DateTime.now();
    final eligibleCoupons = couponsList.where((coupon) {
      if (!coupon.isActive) return false;
      if (coupon.expiryDate.isBefore(now)) return false;
      if (coupon.startsAt != null && coupon.startsAt!.isAfter(now)) return false;
      if (coupon.usageLimit != null && coupon.usageLimit! > 0 && coupon.usedCount >= coupon.usageLimit!) return false;
      if (billing.subtotal < coupon.minBillAmount) return false;
      return true;
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: GlassInput(
                  controller: _couponController,
                  focusNode: _couponCodeFocusNode,
                  label: 'Coupon Code',
                  hint: 'ENTER CODE',
                  onChanged: (val) {
                    if (_couponError != null) {
                      setState(() => _couponError = null);
                    }
                  },
                  onFieldSubmitted: (_) => _generalDiscountFocusNode.requestFocus(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GlassInput(
                  focusNode: _generalDiscountFocusNode,
                  controller: _customDiscountController,
                  label: 'Discount (₹)',
                  hint: 'e.g. 500',
                  keyboardType: TextInputType.number,
                  onChanged: (val) {
                    final trimmed = val.trim();
                    if (trimmed.isEmpty) {
                      ref.read(billingProvider.notifier).setCustomDiscount(0.0);
                    } else {
                      final customDisc = double.tryParse(trimmed);
                      if (customDisc != null && customDisc >= 0) {
                        ref.read(billingProvider.notifier).setCustomDiscount(customDisc);
                      }
                    }
                  },
                  onFieldSubmitted: (_) => _applyButtonFocusNode.requestFocus(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: _isValidatingCoupon
                ? Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : Focus(
                    focusNode: _applyButtonFocusNode,
                    onKeyEvent: (node, event) {
                      if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
                        _applyDiscountAndCoupon(billing);
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: SecondaryButton(
                      label: 'Apply',
                      isOutlined: true,
                      onPressed: () => _applyDiscountAndCoupon(billing),
                    ),
                  ),
          ),
          if (_couponError != null) ...[
            const SizedBox(height: 8),
            Text(
              _couponError!,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
            ),
          ],
          if (eligibleCoupons.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Eligible Coupons Available',
              style: AppTextStyles.bodySm.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            ...eligibleCoupons.map((coupon) {
              final isApplied = billing.couponCode == coupon.code;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_offer_rounded,
                        color: isApplied ? AppColors.success : AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  coupon.code,
                                  style: AppTextStyles.cardTitle.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isApplied ? AppColors.success : AppColors.onBackground,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: (isApplied ? AppColors.success : AppColors.primary).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    coupon.discountType == 'FIXED'
                                        ? '₹${coupon.discountValue.toStringAsFixed(0)} OFF'
                                        : '${coupon.discountValue.toStringAsFixed(0)}% OFF',
                                    style: AppTextStyles.labelSm.copyWith(
                                      color: isApplied ? AppColors.success : AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              coupon.discountType == 'FIXED'
                                  ? 'Save ₹${coupon.discountValue.toStringAsFixed(0)} on your order'
                                  : 'Save ${coupon.discountValue.toStringAsFixed(0)}% up to ₹${coupon.maxDiscount.toStringAsFixed(0)}',
                              style: AppTextStyles.cardSubtitle.copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (isApplied)
                        Row(
                          children: [
                            Text(
                              'Applied',
                              style: AppTextStyles.bodySm.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
                          ],
                        )
                      else
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          onPressed: () {
                            ref.read(billingProvider.notifier).applyCoupon(coupon);
                            _couponController.text = coupon.code;
                            setState(() {
                              _couponError = null;
                            });
                          },
                          child: Text(
                            'Apply',
                            style: AppTextStyles.bodySm.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.1, end: 0, duration: 200.ms);
            }).toList(),
          ],
          if (billing.appliedCoupon != null) ...[
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.local_offer_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Applied Coupon: ${billing.appliedCoupon!.code}',
                          style: AppTextStyles.cardTitle.copyWith(color: AppColors.primary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          billing.appliedCoupon!.discountType == 'FIXED'
                              ? 'Fixed discount of ₹${billing.appliedCoupon!.discountValue}'
                              : 'Discount of ${billing.appliedCoupon!.discountValue}% (Max ₹${billing.appliedCoupon!.maxDiscount})',
                          style: AppTextStyles.cardSubtitle,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '-₹${(billing.discountAmount - billing.customDiscount).toStringAsFixed(0)}',
                    style: AppTextStyles.amountMd.copyWith(color: AppColors.success),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.cancel_rounded, color: AppColors.onSurfaceDim, size: 20),
                    onPressed: () {
                      ref.read(billingProvider.notifier).removeCoupon();
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  Widget _buildPaymentRow({
    required TextEditingController controller,
    required String label,
    required void Function(String) onChanged,
    FocusNode? focusNode,
    void Function(String)? onFieldSubmitted,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onBackground,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 40,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                focusNode: focusNode,
                onSubmitted: onFieldSubmitted,
                keyboardType: TextInputType.number,
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.onBackground, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  prefixText: '₹',
                  prefixStyle: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSplit(BillingState billing) {
    final totalPaid = billing.manualReceivedAmount ?? (billing.cashAmount + billing.upiAmount + billing.cardAmount);

    if (_receivedFullAmount) {
      final val = billing.finalPayable.toStringAsFixed(0);
      if (_receivedAmountController.text != val) {
        _receivedAmountController.text = val;
        _dueAmountController.text = '0';
      }
    } else {
      final expectedRec = totalPaid > 0.05 ? totalPaid.toStringAsFixed(0) : '';
      if (_receivedAmountController.text != expectedRec && !_receivedAmountFocusNode.hasFocus) {
        _receivedAmountController.text = expectedRec;
      }
      final expectedDue = (billing.finalPayable - totalPaid).toStringAsFixed(0);
      if (_dueAmountController.text != expectedDue) {
        _dueAmountController.text = expectedDue;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment Split', style: AppTextStyles.sectionTitle)
              .animate().fadeIn(duration: 300.ms, delay: 400.ms),
          const SizedBox(height: 16),

          // UPI
          _buildPaymentRow(
            controller: _upiController,
            label: 'UPI',
            onChanged: (val) {
              final amt = double.tryParse(val) ?? 0.0;
              ref.read(billingProvider.notifier).setUpiAmount(amt);
              setState(() {
                _receivedFullAmount = false;
              });
            },
            focusNode: _upiFocusNode,
            onFieldSubmitted: (_) => _cashFocusNode.requestFocus(),
          ),
          const SizedBox(height: 6),

          // Cash
          _buildPaymentRow(
            controller: _cashController,
            label: 'CASH',
            onChanged: (val) {
              final amt = double.tryParse(val) ?? 0.0;
              ref.read(billingProvider.notifier).setCashAmount(amt);
              setState(() {
                _receivedFullAmount = false;
              });
            },
            focusNode: _cashFocusNode,
            onFieldSubmitted: (_) => _cardFocusNode.requestFocus(),
          ),
          const SizedBox(height: 6),

          // Card
          _buildPaymentRow(
            controller: _cardController,
            label: 'CARD',
            onChanged: (val) {
              final amt = double.tryParse(val) ?? 0.0;
              ref.read(billingProvider.notifier).setCardAmount(amt);
              setState(() {
                _receivedFullAmount = false;
              });
            },
            focusNode: _cardFocusNode,
            onFieldSubmitted: (_) => _receivedAmountFocusNode.requestFocus(),
          ),

          const SizedBox(height: 20),
          Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 16),

          Row(
            children: [
              Checkbox(
                value: _receivedFullAmount,
                activeColor: AppColors.primary,
                checkColor: AppColors.onBackground,
                onChanged: (val) {
                  setState(() {
                    _receivedFullAmount = val ?? false;
                    if (_receivedFullAmount) {
                      ref.read(billingProvider.notifier).setManualReceivedAmount(billing.finalPayable);
                      _receivedAmountController.text = billing.finalPayable.toStringAsFixed(0);
                      _dueAmountController.text = '0';
                    } else {
                      ref.read(billingProvider.notifier).setManualReceivedAmount(null);
                      _receivedAmountController.clear();
                      _dueAmountController.clear();
                    }
                  });
                },
              ),
              const SizedBox(width: 8),
              Text(
                'Received full amount?',
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onBackground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amount Received (₹)',
                      style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: TextField(
                        controller: _receivedAmountController,
                        focusNode: _receivedAmountFocusNode,
                        keyboardType: TextInputType.number,
                        style: AppTextStyles.bodyLg.copyWith(color: AppColors.onBackground),
                        onChanged: (val) {
                          final rec = double.tryParse(val) ?? 0.0;
                          ref.read(billingProvider.notifier).setManualReceivedAmount(rec);
                          setState(() {
                            if (rec < billing.finalPayable) {
                              _receivedFullAmount = false;
                            }
                          });
                        },
                        onSubmitted: (_) => _generateButtonFocusNode.requestFocus(),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          hintText: '0',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amount Due (₹)',
                      style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: TextField(
                        controller: _dueAmountController,
                        enabled: false,
                        style: AppTextStyles.bodyLg.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          hintText: '0',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BillingState billing) {
    final hasProductDiscounts = billing.products.any((p) => p.discountValue > 0);
    final productDiscountTotal = billing.products.fold(0.0, (sum, p) => sum + p.discountValue);
    final rawSubtotal = billing.products.fold(0.0, (sum, p) => sum + p.metalValue + p.makingChargeTotal + p.stoneValue);
    final couponDiscOnly = _getCouponDiscountOnly(billing);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: GlassCard(
        animationIndex: 10,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _summaryRow('Subtotal', rawSubtotal),
            if (hasProductDiscounts)
              _summaryRow('Product Discounts', -productDiscountTotal, isDiscount: true),
            if (couponDiscOnly > 0)
              _summaryRow('Coupon Discount', -couponDiscOnly, isDiscount: true),
            if (billing.customDiscount > 0)
              _summaryRow('Manual Discount', -billing.customDiscount, isDiscount: true),
            _summaryRow('Estimated GST (3%)', billing.totalTax),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Grand Total:',
                  style: AppTextStyles.titleMd.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '₹${_formatAmount(billing.finalPayable)}.00',
                  style: AppTextStyles.amountLg.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (billing.balanceDue > 0.05) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Balance Due:',
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
                  ),
                  Text(
                    '₹${_formatAmount(billing.balanceDue)}.00',
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.error, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            Focus(
              focusNode: _generateButtonFocusNode,
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
                  if (!_isGenerating) {
                    _generateInvoice();
                  }
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isGenerating ? null : _generateInvoice,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.receipt_long_rounded),
                label: Text(
                  _isGenerating ? 'Generating...' : 'Generate Invoice',
                  style: AppTextStyles.titleSm.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, double amount, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted),
          ),
          Text(
            amount < 0 
                ? '-₹${_formatAmount(amount.abs())}' 
                : '₹${_formatAmount(amount)}',
            style: AppTextStyles.bodySm.copyWith(
              color: isDiscount ? AppColors.success : AppColors.onBackground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showBarcodeDialog(BuildContext context) {
    showSingleDialog(
      context: context,
      useRootNavigator: false,
      builder: (context) => const BarcodeScannerDialog(),
    );
  }

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }

  double _getCouponDiscountOnly(BillingState billing) {
    double couponDisc = 0.0;
    final coupon = billing.appliedCoupon;
    if (coupon != null && billing.subtotal >= coupon.minBillAmount) {
      if (coupon.discountType == 'FIXED') {
        couponDisc = coupon.discountValue;
      } else if (coupon.discountType == 'PERCENTAGE') {
        couponDisc = billing.subtotal * (coupon.discountValue / 100);
        if (coupon.maxDiscount > 0.0) {
          couponDisc = couponDisc.clamp(0.0, coupon.maxDiscount);
        }
      }
    }
    return couponDisc;
  }
}


class _ChargeToggle extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ChargeToggle({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.surfaceContainerHigh : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? AppColors.border : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySm.copyWith(
            color: isActive ? AppColors.onBackground : AppColors.onSurfaceDim,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class BarcodeScannerDialog extends ConsumerStatefulWidget {
  const BarcodeScannerDialog({super.key});

  @override
  ConsumerState<BarcodeScannerDialog> createState() => _BarcodeScannerDialogState();
}

class _BarcodeScannerDialogState extends ConsumerState<BarcodeScannerDialog> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }



  void _onSubmitted(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;

    final productsState = ref.read(productsProvider);
    if (productsState is AsyncData) {
      final products = productsState.value!;
      Product? matched;
      for (final p in products) {
        if (p.serialNumber == trimmed || p.huidNumber == trimmed || p.id == trimmed) {
          matched = p;
          break;
        }
      }

      if (matched != null) {
        if (matched.stockUnits <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Product "${matched.name}" is out of stock.'),
              backgroundColor: AppColors.error,
            ),
          );
          Navigator.pop(context);
          return;
        }

        // Auto-calculate rate based on today's daily rate snapshot
        final rates = ref.read(dailyRatesProvider).value ?? [];
        final latestRate = rates.isNotEmpty ? rates.first : null;

        double calculatedRate = 0.0;
        if (matched.category.toUpperCase() == 'GOLD') {
          if (matched.purity.toUpperCase() == '22K') {
            calculatedRate = latestRate?.rateGold22K ?? 6850.0;
          } else if (matched.purity.toUpperCase() == '18K') {
            calculatedRate = latestRate?.rateGold18K ?? 5610.0;
          } else {
            calculatedRate = latestRate?.rateGold22K ?? 6850.0;
          }
        } else if (matched.category.toUpperCase() == 'SILVER') {
          calculatedRate = latestRate?.rateSilver ?? 82.4;
        }

        final bp = BillingProduct(
          productId: matched.id ?? 'PROD',
          name: matched.name,
          hsnCode: matched.hsnCode,
          category: matched.category,
          purity: matched.purity,
          rate: calculatedRate,
          quantity: 1,
          grossWeight: matched.weight,
          stoneWeight: matched.stoneWeight,
          stoneValue: matched.stoneValue,
          makingChargeType: 'FIXED',
          makingChargeValue: matched.makingChargeValue,
        );

        ref.read(billingProvider.notifier).addProduct(bp);
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
                    color: AppColors.success.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  ),
                  child: Row(
                    children: [
                       Icon(Icons.check_circle_rounded, color: AppColors.success),
                      const SizedBox(width: 12),
                      Text(
                        'Added "${matched.name}" to bill!',
                        style: AppTextStyles.bodyMd.copyWith(color: AppColors.onBackground),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        Navigator.pop(context);
      } else {
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
                        'HUID/ID "$trimmed" not found in inventory.',
                        style: AppTextStyles.bodyMd.copyWith(color: AppColors.onBackground),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        _controller.clear();
        _focusNode.requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 500 ? 400.0 : (screenWidth * 0.92);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: dialogWidth,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary, size: 44),
              const SizedBox(height: 16),
              Text('Barcode / HUID Scanner', style: AppTextStyles.titleLg),
              const SizedBox(height: 8),
              Text(
                'Scan barcode with a physical reader or type the HUID/Product ID below.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceMuted),
              ),
              const SizedBox(height: 20),
              GlassInput(
                controller: _controller,
                focusNode: _focusNode,
                label: 'Barcode Value',
                hint: 'Waiting for scan...',
                textInputAction: TextInputAction.done,
                onChanged: (val) {
                  if (val.endsWith('\n') || val.endsWith('\r')) {
                    _onSubmitted(val.trim());
                  }
                },
                onFieldSubmitted: (val) => _onSubmitted(val.trim()),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceDim)),
                  ),
                  const SizedBox(width: 12),
                  PrimaryButton(
                    label: 'Search & Add',
                    onPressed: () => _onSubmitted(_controller.text),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
