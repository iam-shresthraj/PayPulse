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

  List<Customer> _suggestions = [];
  bool _showSuggestions = false;
  bool _isGenerating = false;
  bool _isValidatingCoupon = false;
  String? _couponError;

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
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _couponController.dispose();
    _cashController.dispose();
    _upiController.dispose();
    _cardController.dispose();
    _nameController.dispose();
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
    if (billing.balanceDue > 0.05) {
      _showError('Invoice cannot be generated with balance due. Complete payment splits.');
      return;
    }

    setState(() => _isGenerating = true);
    try {
      final isTemporary = billing.customerId == '';
      Customer customer;
      if (isTemporary) {
        customer = Customer(
          id: '',
          mobile: billing.customerPhone ?? '',
          name: billing.customerName ?? 'Temporary Customer',
          address: '',
          totalPurchaseAmount: 0.0,
          totalInvoices: 0,
        );
      } else {
        final customers = ref.read(customersProvider).value!;
        customer = customers.firstWhere((c) => c.id == billing.customerId);
      }

      final todayRate = ref.read(dailyRatesProvider.notifier).getTodayRate();

      final isEditing = billing.editingInvoice != null;
      final invoiceId = isEditing ? billing.editingInvoice!.id! : 'INV-${DateTime.now().millisecondsSinceEpoch}';
      final invoiceNum = isEditing ? billing.editingInvoice!.invoiceNumber! : 'INV/${DateTime.now().year}/${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

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

      final invoice = Invoice(
        id: invoiceId,
        invoiceNumber: invoiceNum,
        customerId: isTemporary ? null : billing.customerId,
        tempCustomerName: isTemporary ? billing.customerName : null,
        tempCustomerMobile: isTemporary ? billing.customerPhone : null,
        tempCustomerAddress: isTemporary ? '' : null,
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
        payments: [
          Payment(method: 'CASH', amount: billing.cashAmount),
          Payment(method: 'UPI', amount: billing.upiAmount),
          Payment(method: 'CARD', amount: billing.cardAmount),
        ],
        totalAmountPaid: billing.totalPaid,
        balanceDue: billing.balanceDue,
        invoiceDate: billing.invoiceDate,
        status: 'PAID',
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
      ref.read(billingProvider.notifier).reset();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Invoice updated successfully!' : 'Invoice generated successfully!'),
          backgroundColor: AppColors.success,
        ),
      );

      // Launch PDF & print dialog
      final company = ref.read(companyProvider).value;
      await PdfHelper.generateAndPrintInvoice(
        invoice: savedInvoice,
        customer: customer,
        company: company,
      );
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
          GlassCard(
            animationIndex: 1,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.phone_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    onChanged: (val) => _onPhoneChanged(val, ref),
                    decoration: const InputDecoration(
                      hintText: 'Enter 10-digit mobile number',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    style: AppTextStyles.bodyLg.copyWith(color: AppColors.onBackground),
                    keyboardType: TextInputType.phone,
                  ),
                ),
                if (billing.customerName != null)
                  IconButton(
                    icon: const Icon(Icons.clear, color: AppColors.onSurfaceDim, size: 18),
                    onPressed: () {
                      _phoneController.clear();
                      _nameController.clear();
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

          // Suggestions list
          if (_showSuggestions) ...[
            const SizedBox(height: 8),
            GlassCard(
              animationIndex: 2,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  children: [
                    ..._suggestions.map((c) => ListTile(
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
                        )),
                    ListTile(
                      leading: const Icon(Icons.person_add_rounded, color: AppColors.primary, size: 20),
                      title: Text('+ Register New Customer', style: AppTextStyles.bodyMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      onTap: () {
                        setState(() {
                          _showSuggestions = false;
                        });
                        showDialog(
                          context: context,
                          builder: (context) => const Dialog(
                            backgroundColor: Colors.transparent,
                            child: AddCustomerDialog(),
                          ),
                        ).then((_) {
                          final billingVal = ref.read(billingProvider);
                          if (billingVal.customerPhone != null) {
                            _phoneController.text = billingVal.customerPhone!;
                          }
                        });
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.assignment_ind_outlined, color: AppColors.primary, size: 20),
                      title: Text('+ Temporary Bill Only', style: AppTextStyles.bodyMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      onTap: () {
                        ref.read(billingProvider.notifier).setTemporaryCustomer('', _phoneController.text);
                        _nameController.clear();
                        setState(() {
                          _showSuggestions = false;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],

          if (billing.customerName != null && billing.customerId == '') ...[
            const SizedBox(height: 12),
            // Name input for temporary customer
            GlassCard(
              animationIndex: 2,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.assignment_ind_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      onChanged: (val) {
                        ref.read(billingProvider.notifier).setTemporaryCustomer(val, _phoneController.text);
                      },
                      decoration: const InputDecoration(
                        hintText: 'Enter Customer Name (Temporary)',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      style: AppTextStyles.bodyLg.copyWith(color: AppColors.onBackground),
                    ),
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
    } else {
      final settings = companyState.value;
      invoiceTag = 'Next Invoice: ${getNextInvoiceNumber(settings)}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
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
              ],
            ),
          ),
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
        ],
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
            },
            index: 8,
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

  Product? _selectedProduct;
  String _makingChargeType = 'FIXED';

  @override
  void dispose() {
    _qtyController.dispose();
    _rateController.dispose();
    _weightController.dispose();
    _makingChargeController.dispose();
    _stoneWeightController.dispose();
    _stoneValueController.dispose();
    _discountController.dispose();
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
                      GlassDropdown<Product>(
                        label: 'Select Product',
                        hint: 'Choose product item',
                        value: _selectedProduct,
                        items: activeProducts.map((p) {
                          return DropdownMenuItem<Product>(
                            value: p,
                            child: Text('${p.name} (${p.purity} • ${p.stockUnits} left)'),
                          );
                        }).toList(),
                        onChanged: _onProductSelected,
                      ),
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
                          margin: const EdgeInsets.only(right: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _ChargeToggle(
                                label: 'Fixed',
                                isActive: _makingChargeType == 'FIXED',
                                onTap: () => setState(() => _makingChargeType = 'FIXED'),
                              ),
                              const SizedBox(width: 4),
                              _ChargeToggle(
                                label: '/g',
                                isActive: _makingChargeType == 'PER_GRAM',
                                onTap: () => setState(() => _makingChargeType = 'PER_GRAM'),
                              ),
                              const SizedBox(width: 4),
                              _ChargeToggle(
                                label: '%',
                                isActive: _makingChargeType == 'PERCENTAGE',
                                onTap: () => setState(() => _makingChargeType = 'PERCENTAGE'),
                              ),
                            ],
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
