import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
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
import '../more/daily_rates_provider.dart';
import '../more/company_provider.dart';
import '../more/coupons_provider.dart';
import 'billing_provider.dart';
import 'invoices_provider.dart';
import '../../core/utils/pdf_helper.dart';
import '../../core/utils/whatsapp_helper.dart';
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
  final _cashController = TextEditingController();
  final _upiController = TextEditingController();
  final _cardController = TextEditingController();
  final _nameController = TextEditingController();
  final _receivedAmountController = TextEditingController();
  final _dueAmountController = TextEditingController();
  final _addressController = TextEditingController();
  final _panController = TextEditingController();
  final _receivedAmountFocusNode = FocusNode();

  List<Customer> _suggestions = [];
  bool _showSuggestions = false;
  bool _isGenerating = false;
  bool _isValidatingCoupon = false;
  String? _couponError;
  bool _receivedFullAmount = false;
  bool _registerNewCustomer = false;

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
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _couponController.dispose();
    _cashController.dispose();
    _upiController.dispose();
    _cardController.dispose();
    _nameController.dispose();
    _receivedAmountController.dispose();
    _dueAmountController.dispose();
    _addressController.dispose();
    _panController.dispose();
    _receivedAmountFocusNode.dispose();
    super.dispose();
  }

  void _onPhoneChanged(String val, WidgetRef ref) {
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
          name: billing.customerName ?? _nameController.text.trim(),
          address: _addressController.text.trim(),
          panCard: _panController.text.trim(),
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
        couponDiscount: billing.discountAmount,
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
        await ref.read(invoicesProvider.notifier).addInvoice(invoice);
        savedInvoice = invoice;
      }

      // Reset form
      _phoneController.clear();
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
        showDialog(
          context: context,
          builder: (context) => BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: AlertDialog(
              backgroundColor: AppColors.surfaceContainer.withValues(alpha: 0.9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                side: const BorderSide(color: AppColors.glassBorder),
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
                    foregroundColor: Colors.black,
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
                    await WhatsAppHelper.shareInvoice(
                      customerName: customer.name,
                      customerPhone: customer.mobile,
                      invoiceNumber: savedInvoice.invoiceNumber ?? '',
                      totalAmount: savedInvoice.finalPayable,
                      balanceDue: savedInvoice.balanceDue,
                      date: savedInvoice.invoiceDate,
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
                border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.error),
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
    final billing = ref.watch(billingProvider);
    final topPadding = MediaQuery.of(context).padding.top;

    // Listen to billing updates to keep text fields in sync
    ref.listen<BillingState>(billingProvider, (prev, next) {
      if (next.customerPhone == null && _phoneController.text.isNotEmpty) {
        _phoneController.clear();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
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
                ],
              ),
            ),
          ),

          // ── Grand Total & Generate Invoice (Fixed Bottom) ──
          _buildBottomBar(billing),
        ],
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
          GlassInput(
            controller: _phoneController,
            label: 'Search Customer By Phone/Name',
            hint: 'Type mobile number or customer name...',
            prefixIcon: const Icon(Icons.phone_rounded, color: AppColors.primary),
            keyboardType: TextInputType.phone,
            onChanged: (val) => _onPhoneChanged(val, ref),
            suffixIcon: (billing.customerName != null || _phoneController.text.isNotEmpty)
                ? IconButton(
                    icon: const Icon(Icons.clear, color: AppColors.onSurfaceDim, size: 18),
                    onPressed: () {
                      _phoneController.clear();
                      _nameController.clear();
                      _addressController.clear();
                      _panController.clear();
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
                  children: _suggestions.map((c) => ListTile(
                    leading: const Icon(Icons.person, color: AppColors.primary, size: 20),
                    title: Text(c.name, style: AppTextStyles.bodyMd.copyWith(color: AppColors.onBackground)),
                    subtitle: Text(c.mobile, style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted)),
                    onTap: () {
                      ref.read(billingProvider.notifier).setCustomer(c);
                      _phoneController.text = c.mobile;
                      setState(() {
                        _showSuggestions = false;
                        _suggestions = [];
                      });
                    },
                  )).toList(),
                ),
              ),
            ),
          ],

          // Auto-shown New Customer Registration fields
          if (billing.customerId == null && _phoneController.text.isNotEmpty) ...[
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
                    controller: _nameController,
                    label: 'Customer Name',
                    hint: 'Enter customer name',
                    onChanged: (val) {
                      ref.read(billingProvider.notifier).setTemporaryCustomer(val, _phoneController.text);
                    },
                  ),
                  const SizedBox(height: 12),
                  GlassInput(
                    controller: _addressController,
                    label: 'Address',
                    hint: 'Enter address (e.g. Thakurbari Road, Patna)',
                  ),
                  const SizedBox(height: 12),
                  GlassInput(
                    controller: _panController,
                    label: 'PAN Card (Optional)',
                    hint: 'Enter PAN card number',
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
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Products', style: AppTextStyles.sectionTitle),
              Row(
                children: [
                  SecondaryButton(
                    label: 'Scan Barcode',
                    icon: Icons.qr_code_scanner_rounded,
                    onPressed: () => _showBarcodeDialog(context),
                  ),
                  const SizedBox(width: 8),
                  SecondaryButton(
                    label: '+ Add Item',
                    onPressed: () => _showAddProductSheet(context),
                  ),
                ],
              ),
            ],
          ).animate().fadeIn(duration: 300.ms, delay: 200.ms),

          const SizedBox(height: 12),

          // Product List
          if (billing.products.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'No products added yet.',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted),
              ),
            )
          else
            ...billing.products.asMap().entries.map((entry) {
              final i = entry.key;
              final product = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: i < billing.products.length - 1 ? 10 : 0),
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
                              product.name,
                              style: AppTextStyles.cardTitle,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Code: ${product.productId} | Weight: ${product.grossWeight.toStringAsFixed(2)}g',
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
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                        onPressed: () => ref.read(billingProvider.notifier).removeProduct(i),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
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
                  const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 16),
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
                    const Icon(Icons.edit_rounded, color: AppColors.primary, size: 12),
                  ],
                ],
              ),
            ),
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
                          colorScheme: const ColorScheme.dark(
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
                      const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 16),
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
                icon: const Icon(Icons.refresh_rounded, color: AppColors.primary, size: 20),
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

  void _showEditInvoiceNumberDialog(BuildContext context, BillingState billing) {
    final companyState = ref.read(companyProvider);
    final defaultNum = billing.customInvoiceNumber ?? getNextInvoiceNumber(companyState.value);
    final controller = TextEditingController(text: defaultNum);

    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: AppColors.surfaceContainer.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            side: const BorderSide(color: AppColors.glassBorder),
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
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final newNum = controller.text.trim();
                if (newNum.isNotEmpty) {
                  ref.read(billingProvider.notifier).setCustomInvoiceNumber(newNum);
                }
                Navigator.pop(context);
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponSection(BillingState billing) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Coupons & Offers', style: AppTextStyles.sectionTitle)
              .animate().fadeIn(duration: 300.ms, delay: 300.ms),
          const SizedBox(height: 12),

          if (billing.appliedCoupon == null) ...[
            Row(
              children: [
                Expanded(
                  child: GlassInput(
                    controller: _couponController,
                    label: 'Coupon Code',
                    hint: 'ENTER CODE',
                    onChanged: (val) {
                      if (_couponError != null) {
                        setState(() => _couponError = null);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: SizedBox(
                    height: 52,
                    child: _isValidatingCoupon
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          )
                        : SecondaryButton(
                            label: 'Apply',
                            isOutlined: true,
                            onPressed: () async {
                        final code = _couponController.text.trim().toUpperCase();
                        if (code.isEmpty) return;
                        setState(() {
                          _isValidatingCoupon = true;
                          _couponError = null;
                        });
                        try {
                          final coupon = await ref.read(couponsProvider.notifier).validateCouponCode(code, billing.subtotal);
                          ref.read(billingProvider.notifier).applyCoupon(coupon);
                          _couponController.clear();
                        } catch (e) {
                          setState(() {
                            _couponError = 'Invalid coupon or minimum purchase not met.';
                          });
                        } finally {
                          setState(() => _isValidatingCoupon = false);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            if (_couponError != null) ...[
              const SizedBox(height: 8),
              Text(
                _couponError!,
                style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
              ),
            ],
          ] else ...[
            GlassCard(
              animationIndex: 3,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.local_offer_rounded, color: AppColors.primary, size: 20),
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
                    '-₹${billing.discountAmount.toStringAsFixed(0)}',
                    style: AppTextStyles.amountMd.copyWith(color: AppColors.success),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.cancel_rounded, color: AppColors.onSurfaceDim, size: 20),
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
    ).animate().fadeIn(duration: 300.ms, delay: 350.ms);
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

          // Cash
          _buildPaymentCard(
            controller: _cashController,
            icon: Icons.account_balance_wallet_rounded,
            label: 'CASH',
            onChanged: (val) {
              final amt = double.tryParse(val) ?? 0.0;
              ref.read(billingProvider.notifier).setCashAmount(amt);
              setState(() {
                _receivedFullAmount = false;
              });
            },
            index: 6,
          ),
          const SizedBox(height: 12),

          // UPI
          _buildPaymentCard(
            controller: _upiController,
            icon: Icons.qr_code_rounded,
            label: 'UPI',
            onChanged: (val) {
              final amt = double.tryParse(val) ?? 0.0;
              ref.read(billingProvider.notifier).setUpiAmount(amt);
              setState(() {
                _receivedFullAmount = false;
              });
            },
            index: 7,
          ),
          const SizedBox(height: 12),

          // Card
          _buildPaymentCard(
            controller: _cardController,
            icon: Icons.credit_card_rounded,
            label: 'CARD',
            onChanged: (val) {
              final amt = double.tryParse(val) ?? 0.0;
              ref.read(billingProvider.notifier).setCardAmount(amt);
              setState(() {
                _receivedFullAmount = false;
              });
            },
            index: 8,
          ),

          const SizedBox(height: 20),
          const Divider(color: AppColors.border, height: 1),
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
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: InputBorder.none,
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

  Widget _buildPaymentCard({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    required void Function(String) onChanged,
    required int index,
  }) {
    return GlassCard(
      animationIndex: index,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.labelMd.copyWith(
                  color: AppColors.onSurfaceMuted,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              style: AppTextStyles.amountMd.copyWith(color: AppColors.onBackground),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                prefixText: '₹',
                prefixStyle: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BillingState billing) {
    final hasProductDiscounts = billing.products.any((p) => p.discountValue > 0);
    final productDiscountTotal = billing.products.fold(0.0, (sum, p) => sum + p.discountValue);
    final rawSubtotal = billing.products.fold(0.0, (sum, p) => sum + p.metalValue + p.makingChargeTotal + p.stoneValue);

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer.withValues(alpha: 0.9),
            border: const Border(
              top: BorderSide(color: AppColors.glassBorder, width: 1),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Breakdown Section
                _summaryRow('Subtotal', rawSubtotal),
                if (hasProductDiscounts)
                  _summaryRow('Product Discounts', -productDiscountTotal, isDiscount: true),
                if (billing.discountAmount > 0)
                  _summaryRow('Coupon Discount', -billing.discountAmount, isDiscount: true),
                _summaryRow('Estimated GST (3%)', billing.totalTax),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: AppColors.border, height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'GRAND TOTAL',
                      style: AppTextStyles.labelMd.copyWith(
                        color: AppColors.onSurfaceMuted,
                        letterSpacing: 1,
                      ),
                    ),
                    if (billing.balanceDue > 0.05)
                      Text(
                        'DUE: ₹${_formatAmount(billing.balanceDue)}',
                        style: AppTextStyles.labelMd.copyWith(color: AppColors.error, fontWeight: FontWeight.bold),
                      )
                    else
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        color: AppColors.success,
                        size: 16,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '₹${_formatAmount(billing.finalPayable)}',
                          style: AppTextStyles.amountXl.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        TextSpan(
                          text: '.00',
                          style: AppTextStyles.amountMd.copyWith(
                            color: AppColors.onSurfaceMuted,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Generate & Print Invoice',
                  icon: Icons.receipt_long_rounded,
                  isLoading: _isGenerating,
                  onPressed: _generateInvoice,
                ),
              ],
            ),
          ),
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

  void _showAddProductSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddProductSheet(),
    );
  }

  void _showBarcodeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const BarcodeScannerDialog(),
    );
  }

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }
}

class _AddProductSheet extends ConsumerStatefulWidget {
  const _AddProductSheet();

  @override
  ConsumerState<_AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends ConsumerState<_AddProductSheet> {
  final _qtyController = TextEditingController(text: '1');
  final _rateController = TextEditingController();
  final _weightController = TextEditingController();
  final _makingChargeController = TextEditingController();
  final _stoneWeightController = TextEditingController(text: '0');
  final _stoneValueController = TextEditingController(text: '0');
  final _discountController = TextEditingController(text: '0');
  final _searchController = TextEditingController();

  Product? _selectedProduct;
  String _makingChargeType = 'FIXED';
  List<Product> _suggestions = [];
  bool _showSuggestions = false;

  @override
  void dispose() {
    _qtyController.dispose();
    _rateController.dispose();
    _weightController.dispose();
    _makingChargeController.dispose();
    _stoneWeightController.dispose();
    _stoneValueController.dispose();
    _discountController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onProductSelected(Product? p) {
    if (p == null) return;
    setState(() {
      _selectedProduct = p;
      _weightController.text = p.weight.toStringAsFixed(3);
      _makingChargeController.text = p.makingChargeValue.toStringAsFixed(0);

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

  void _submit() {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a product.'), backgroundColor: AppColors.error),
      );
      return;
    }

    final qty = int.tryParse(_qtyController.text) ?? 0;
    final rate = double.tryParse(_rateController.text) ?? 0.0;
    final weight = double.tryParse(_weightController.text) ?? 0.0;
    final mcVal = double.tryParse(_makingChargeController.text) ?? 0.0;
    final stoneW = double.tryParse(_stoneWeightController.text) ?? 0.0;
    final stoneV = double.tryParse(_stoneValueController.text) ?? 0.0;
    final discount = double.tryParse(_discountController.text) ?? 0.0;

    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantity must be greater than 0.'), backgroundColor: AppColors.error),
      );
      return;
    }
    if (weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gross weight must be greater than 0.'), backgroundColor: AppColors.error),
      );
      return;
    }

    // Verify stock
    if (_selectedProduct!.stockUnits < qty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient stock. Only ${_selectedProduct!.stockUnits} available.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final bp = BillingProduct(
      productId: _selectedProduct!.id ?? 'PROD',
      name: _selectedProduct!.name,
      hsnCode: _selectedProduct!.hsnCode,
      category: _selectedProduct!.category,
      purity: _selectedProduct!.purity,
      rate: rate,
      quantity: qty,
      grossWeight: weight,
      stoneWeight: stoneW,
      stoneValue: stoneV,
      makingChargeType: _makingChargeType,
      makingChargeValue: mcVal,
      discountValue: discount,
    );

    ref.read(billingProvider.notifier).addProduct(bp);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(productsProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.glassBorder),
          left: BorderSide(color: AppColors.glassBorder),
          right: BorderSide(color: AppColors.glassBorder),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.onSurfaceDim,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text('Product Entry', style: AppTextStyles.titleMd),
          const SizedBox(height: 20),
          Expanded(
            child: productsState.when(
              data: (productsList) {
                // Only show active products with stock
                final activeProducts = productsList.where((p) => p.isActive && p.stockUnits > 0).toList();

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      GlassInput(
                        controller: _searchController,
                        label: 'Select Product',
                        hint: 'Type product name to search...',
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                        onChanged: (val) {
                          final query = val.trim().toLowerCase();
                          if (query.isEmpty) {
                            setState(() {
                              _suggestions = [];
                              _showSuggestions = false;
                            });
                            return;
                          }
                          final filtered = activeProducts.where((p) =>
                            p.name.toLowerCase().contains(query) ||
                            (p.id?.toLowerCase().contains(query) ?? false) ||
                            (p.huidNumber?.toLowerCase().contains(query) ?? false) ||
                            (p.purity.toLowerCase().contains(query)) ||
                            (p.category.toLowerCase().contains(query))
                          ).toList();
                          setState(() {
                            _suggestions = filtered;
                            _showSuggestions = true;
                          });
                        },
                      ),
                      if (_showSuggestions && _suggestions.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        GlassCard(
                          animationIndex: 0,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: ListView(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              children: _suggestions.map((p) => ListTile(
                                leading: const Icon(Icons.grid_on_rounded, color: AppColors.primary, size: 20),
                                title: Text(p.name, style: AppTextStyles.bodyMd.copyWith(color: AppColors.onBackground)),
                                subtitle: Text('${p.purity} • ${p.category} • ${p.stockUnits} left', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted)),
                                onTap: () {
                                  _onProductSelected(p);
                                  _searchController.text = p.name;
                                  setState(() {
                                    _suggestions = [];
                                    _showSuggestions = false;
                                  });
                                },
                              )).toList(),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: GlassInput(
                              controller: _qtyController,
                              label: 'Quantity',
                              hint: '1',
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GlassInput(
                              controller: _rateController,
                              label: 'Metal Rate (₹/g)',
                              hint: '5,400',
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: GlassInput(
                              controller: _weightController,
                              label: 'Gross Weight (g)',
                              hint: '0.000',
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: GlassInput(
                              controller: _stoneWeightController,
                              label: 'Stone Weight (g)',
                              hint: '0.000',
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GlassInput(
                              controller: _stoneValueController,
                              label: 'Stone Value (₹)',
                              hint: '0',
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      GlassInput(
                        controller: _makingChargeController,
                        label: 'Making Charge',
                        hint: 'Enter value',
                        keyboardType: TextInputType.number,
                        suffixIcon: Container(
                          padding: const EdgeInsets.only(right: 8),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _makingChargeType,
                              dropdownColor: AppColors.surfaceContainer,
                              icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primary),
                              style: AppTextStyles.bodyMd.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'PER_GRAM',
                                  child: Text('/gm'),
                                ),
                                DropdownMenuItem(
                                  value: 'FIXED',
                                  child: Text('pcs'),
                                ),
                                DropdownMenuItem(
                                  value: 'PERCENTAGE',
                                  child: Text('%'),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _makingChargeType = val);
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      GlassInput(
                        controller: _discountController,
                        label: 'Product Discount (₹)',
                        hint: '0',
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 32),
                      PrimaryButton(
                        label: '+ Add to Bill',
                        icon: Icons.add_rounded,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, _) => Center(child: Text('Error loading inventory: $err', style: AppTextStyles.bodyMd.copyWith(color: AppColors.error))),
            ),
          ),
        ],
      ),
    );
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
        if (p.huidNumber == trimmed || p.id == trimmed) {
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
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.success),
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
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error),
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
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 450,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary, size: 44),
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
