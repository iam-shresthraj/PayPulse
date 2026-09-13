import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/invoice.dart';
import '../../core/utils/formatters.dart';
import '../products/products_provider.dart';
import '../customers/customers_provider.dart';
import '../more/company_provider.dart';
import '../more/coupons_provider.dart';

class InvoicesNotifier extends StateNotifier<AsyncValue<List<Invoice>>> {
  final Ref _ref;

  InvoicesNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadInvoices();
  }

  final _client = Supabase.instance.client;

  Invoice _mapInvoice(Map<String, dynamic> data) {
    final itemsList = (data['items'] as List?) ?? [];
    final items = itemsList.map((item) => InvoiceItem.fromJson(Map<String, dynamic>.from(item))).toList();
    
    final paymentsList = (data['payments'] as List?) ?? [];
    final payments = paymentsList.map((p) => Payment.fromJson(Map<String, dynamic>.from(p))).toList();

    return Invoice(
      id: data['id'],
      invoiceNumber: data['invoice_number'],
      customerId: data['customer_id'],
      tempCustomerName: data['temp_customer_name'],
      tempCustomerMobile: data['temp_customer_mobile'],
      tempCustomerAddress: data['temp_customer_address'],
      tempCustomerPincode: data['temp_customer_pincode'],
      tempCustomerCity: data['temp_customer_city'],
      tempCustomerState: data['temp_customer_state'],
      items: items,
      grossAmount: (data['gross_amount'] as num).toDouble(),
      couponCode: data['coupon_code'],
      couponDiscount: (data['coupon_discount'] as num?)?.toDouble() ?? 0.0,
      manualDiscount: (data['manual_discount'] as num?)?.toDouble() ?? 0.0,
      oldGold: data['old_gold_adjustment_weight'] != null && (data['old_gold_adjustment_weight'] as num) > 0
          ? OldGoldAdjustment(
              weight: (data['old_gold_adjustment_weight'] as num).toDouble(),
              purity: data['old_gold_adjustment_purity'] ?? '',
              rate: (data['old_gold_adjustment_rate_applied'] as num).toDouble(),
              metalValue: (data['old_gold_adjustment_total_value'] as num).toDouble(),
            )
          : null,
      taxableAmount: (data['taxable_amount'] as num).toDouble(),
      cgst: (data['cgst'] as num).toDouble(),
      sgst: (data['sgst'] as num).toDouble(),
      totalTax: (data['total_tax'] as num).toDouble(),
      netAmount: (data['net_amount'] as num).toDouble(),
      finalPayable: (data['final_payable'] as num).toDouble(),
      payments: payments,
      totalAmountPaid: (data['total_amount_paid'] as num?)?.toDouble() ?? 0.0,
      balanceDue: (data['balance_due'] as num?)?.toDouble() ?? 0.0,
      invoiceDate: DateTime.parse(data['invoice_date']),
      generatedBy: data['generated_by'],
      status: data['status'] ?? 'PAID',
      ratesSnapshot: RatesSnapshot(
        rateGold22K: (data['rates_snapshot_gold_22k'] as num?)?.toDouble() ?? 0.0,
        rateGold18K: (data['rates_snapshot_gold_18k'] as num?)?.toDouble() ?? 0.0,
        rateSilver: (data['rates_snapshot_silver'] as num?)?.toDouble() ?? 0.0,
      ),
      deletedAt: data['deleted_at'] != null ? DateTime.parse(data['deleted_at']) : null,
      pdfBase64: null, // Always rendered dynamically with the latest layout
    );
  }

  Map<String, dynamic> _unmapInvoice(Invoice invoice) {
    return {
      'invoice_number': invoice.invoiceNumber,
      'customer_id': (invoice.customerId != null && invoice.customerId!.isNotEmpty) ? invoice.customerId : null,
      'temp_customer_name': invoice.tempCustomerName != null ? Formatters.toTitleCase(invoice.tempCustomerName!) : '',
      'temp_customer_mobile': invoice.tempCustomerMobile ?? '',
      'temp_customer_address': invoice.tempCustomerAddress ?? '',
      'temp_customer_pincode': invoice.tempCustomerPincode ?? '',
      'temp_customer_city': invoice.tempCustomerCity ?? '',
      'temp_customer_state': invoice.tempCustomerState ?? '',
      'items': invoice.items.map((item) => item.toJson()).toList(),
      'gross_amount': invoice.grossAmount,
      'coupon_code': invoice.couponCode ?? '',
      'coupon_discount': invoice.couponDiscount,
      'manual_discount': invoice.manualDiscount,
      'old_gold_adjustment_weight': invoice.oldGold?.weight ?? 0.0,
      'old_gold_adjustment_purity': invoice.oldGold?.purity ?? '',
      'old_gold_adjustment_rate_applied': invoice.oldGold?.rate ?? 0.0,
      'old_gold_adjustment_total_value': invoice.oldGold?.metalValue ?? 0.0,
      'taxable_amount': invoice.taxableAmount,
      'cgst': invoice.cgst,
      'sgst': invoice.sgst,
      'total_tax': invoice.totalTax,
      'net_amount': invoice.netAmount,
      'final_payable': invoice.finalPayable,
      'payments': invoice.payments.map((p) => p.toJson()).toList(),
      'total_amount_paid': invoice.totalAmountPaid,
      'balance_due': invoice.balanceDue,
      'invoice_date': invoice.invoiceDate.toIso8601String(),
      'generated_by': invoice.generatedBy ?? _client.auth.currentUser!.id,
      'status': invoice.status,
      'rates_snapshot_gold_22k': invoice.ratesSnapshot.rateGold22K,
      'rates_snapshot_gold_18k': invoice.ratesSnapshot.rateGold18K,
      'rates_snapshot_silver': invoice.ratesSnapshot.rateSilver,
      'pdf_base64': null, // Store invoice purely as text/JSON to save database storage
    };
  }

  Future<String> _generateInvoiceNumber() async {
    final settingsData = await _client
        .from('company_settings')
        .select()
        .maybeSingle();
        
    if (settingsData != null) {
      final prefix = settingsData['invoice_prefix'] ?? 'S';
      final separator = settingsData['invoice_separator'] ?? '-';
      final padding = settingsData['invoice_padding_length'] ?? 6;

      // Fetch all active invoice numbers to find gaps
      final List<dynamic> activeInvoicesData = await _client
          .from('invoices')
          .select('invoice_number')
          .isFilter('deleted_at', null);

      final Set<int> usedCounters = {};
      final regex = RegExp('^${RegExp.escape(prefix)}${RegExp.escape(separator)}(\\d+)\$');

      for (final row in activeInvoicesData) {
        final numStr = row['invoice_number'] as String?;
        if (numStr != null) {
          final match = regex.firstMatch(numStr);
          if (match != null) {
            final counter = int.tryParse(match.group(1)!);
            if (counter != null) {
              usedCounters.add(counter);
            }
          }
        }
      }

      // Find the smallest missing positive integer
      int smallestGap = 1;
      while (usedCounters.contains(smallestGap)) {
        smallestGap++;
      }

      final paddedNumber = smallestGap.toString().padLeft(padding, '0');
      return '$prefix$separator$paddedNumber';
    }
    
    final count = await _client
        .from('invoices')
        .count(CountOption.exact);
    return 'INV-${(count + 1).toString().padLeft(4, '0')}';
  }

  Future<void> loadInvoices() async {
    try {
      state = const AsyncValue.loading();
      final data = await _client
          .from('invoices')
          .select()
          .isFilter('deleted_at', null)
          .order('invoice_date', ascending: false);

      final invoices = (data as List).map((item) => _mapInvoice(item)).toList();
      state = AsyncValue.data(invoices);

      // Asynchronously wipe legacy base64 PDF blobs from database to reduce storage
      _client
          .from('invoices')
          .update({'pdf_base64': null})
          .not('pdf_base64', 'is', null)
          .then((_) {}, onError: (_) {});
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<Invoice> addInvoice(Invoice invoice) async {
    try {
      final String invoiceNum;
      if (invoice.invoiceNumber != null &&
          invoice.invoiceNumber!.isNotEmpty &&
          !invoice.invoiceNumber!.startsWith('INV/')) {
        invoiceNum = invoice.invoiceNumber!;
      } else {
        invoiceNum = await _generateInvoiceNumber();
      }
      
      var payload = _unmapInvoice(invoice);
      payload['invoice_number'] = invoiceNum;
      
      // 3. Save to database as lightweight text
      final data = await _client.from('invoices').insert(payload).select().single();
      final savedInvoice = _mapInvoice(data);

      // 4. Revert inventory stock levels
      for (final item in invoice.items) {
        final prodData = await _client
            .from('products')
            .select('stock_units')
            .eq('id', item.productId)
            .single();
        final int currentStock = prodData['stock_units'] ?? 0;
        await _client
            .from('products')
            .update({'stock_units': (currentStock - item.quantity).clamp(0, 99999)})
            .eq('id', item.productId);
      }

      // 5. Update Customer Purchase Info
      if (invoice.customerId != null && invoice.customerId!.isNotEmpty) {
        final custData = await _client
            .from('customers')
            .select('total_purchase_amount, total_invoices')
            .eq('id', invoice.customerId!)
            .single();
            
        final double totalPurchase = (custData['total_purchase_amount'] as num?)?.toDouble() ?? 0.0;
        final int totalInvoices = custData['total_invoices'] ?? 0;
        
        await _client.from('customers').update({
          'total_purchase_amount': totalPurchase + invoice.finalPayable,
          'total_invoices': totalInvoices + 1,
          'last_visit_date': DateTime.now().toIso8601String(),
        }).eq('id', invoice.customerId!);
      }
      
      // Increment coupon usage count if a coupon was applied
      if (invoice.couponCode != null && invoice.couponCode!.isNotEmpty) {
        await _ref.read(couponsProvider.notifier).incrementUsage(invoice.couponCode!);
      }

      // Trigger reload for products and customers so they get updated stock/spend values
      _ref.read(productsProvider.notifier).loadProducts();
      _ref.read(customersProvider.notifier).loadCustomers();

      // Store invoice details purely as text in the database (consumes minimal storage, no heavy base64 PDF)
      final list = state.value ?? [];
      state = AsyncValue.data([savedInvoice, ...list]);
      return savedInvoice;
    } catch (e) {
      await loadInvoices();
      rethrow;
    }
  }

  Future<List<Invoice>> bulkAddInvoices(List<Invoice> invoices) async {
    if (invoices.isEmpty) return [];
    try {
      final List<Map<String, dynamic>> payloads = [];
      for (final inv in invoices) {
        final payload = _unmapInvoice(inv);
        payload['invoice_number'] = inv.invoiceNumber;
        payload['pdf_base64'] = null; // Store purely as text to save database space
        payloads.add(payload);
      }

      final List<Invoice> savedInvoices = [];
      // Insert in chunks of 50 for stability
      for (int i = 0; i < payloads.length; i += 50) {
        final chunk = payloads.sublist(i, (i + 50).clamp(0, payloads.length));
        final data = await _client.from('invoices').insert(chunk).select();
        final mapped = (data as List).map((d) => _mapInvoice(d)).toList();
        savedInvoices.addAll(mapped);
      }

      await loadInvoices();
      return savedInvoices;
    } catch (e) {
      debugPrint('Error during bulkAddInvoices: $e');
      rethrow;
    }
  }

  Future<void> bulkDeleteInvoices(List<String> invoiceIds) async {
    if (invoiceIds.isEmpty) return;
    try {
      await _client.from('invoices').delete().inFilter('id', invoiceIds);
      await loadInvoices();
    } catch (e) {
      debugPrint('Error during bulkDeleteInvoices: $e');
      rethrow;
    }
  }

  Future<void> cancelInvoice(String id) async {
    try {
      final data = await _client
          .from('invoices')
          .update({'status': 'CANCELLED', 'cancellation_reason': 'Cancelled by operator'})
          .eq('id', id)
          .select()
          .single();
      final cancelledInvoice = _mapInvoice(data);
      
      // Revert stock levels
      for (final item in cancelledInvoice.items) {
        final prodData = await _client
            .from('products')
            .select('stock_units')
            .eq('id', item.productId)
            .single();
        final int currentStock = prodData['stock_units'] ?? 0;
        await _client
            .from('products')
            .update({'stock_units': currentStock + item.quantity})
            .eq('id', item.productId);
      }

      // Revert customer statistics
      if (cancelledInvoice.customerId != null && cancelledInvoice.customerId!.isNotEmpty) {
        final custData = await _client
            .from('customers')
            .select('total_purchase_amount, total_invoices')
            .eq('id', cancelledInvoice.customerId!)
            .single();
            
        final double totalPurchase = (custData['total_purchase_amount'] as num?)?.toDouble() ?? 0.0;
        final int totalInvoices = custData['total_invoices'] ?? 0;
        
        await _client.from('customers').update({
          'total_purchase_amount': (totalPurchase - cancelledInvoice.finalPayable).clamp(0.0, double.infinity),
          'total_invoices': (totalInvoices - 1).clamp(0, 99999),
        }).eq('id', cancelledInvoice.customerId!);
      }
      
      final invoiceWithPdf = cancelledInvoice;

      // Reload products and customers
      _ref.read(productsProvider.notifier).loadProducts();
      _ref.read(customersProvider.notifier).loadCustomers();

      final list = state.value ?? [];
      final index = list.indexWhere((inv) => inv.id == id);
      if (index != -1) {
        final updatedList = List<Invoice>.from(list);
        updatedList[index] = invoiceWithPdf;
        state = AsyncValue.data(updatedList);
      } else {
        await loadInvoices();
      }
    } catch (e) {
      await loadInvoices();
      rethrow;
    }
  }

  Future<void> deleteInvoice(String id) async {
    try {
      // First fetch the invoice to revert stocks/stats if active
      final invData = await _client.from('invoices').select().eq('id', id).single();
      final invoice = _mapInvoice(invData);

      if (invoice.status != 'CANCELLED') {
        // Revert stock levels
        for (final item in invoice.items) {
          final prodData = await _client
              .from('products')
              .select('stock_units')
              .eq('id', item.productId)
              .single();
          final int currentStock = prodData['stock_units'] ?? 0;
          await _client
              .from('products')
              .update({'stock_units': currentStock + item.quantity})
              .eq('id', item.productId);
        }

        // Revert customer stats
        if (invoice.customerId != null && invoice.customerId!.isNotEmpty) {
          final custData = await _client
              .from('customers')
              .select('total_purchase_amount, total_invoices')
              .eq('id', invoice.customerId!)
              .single();
              
          final double totalPurchase = (custData['total_purchase_amount'] as num?)?.toDouble() ?? 0.0;
          final int totalInvoices = custData['total_invoices'] ?? 0;
          
          await _client.from('customers').update({
            'total_purchase_amount': (totalPurchase - invoice.finalPayable).clamp(0.0, double.infinity),
            'total_invoices': (totalInvoices - 1).clamp(0, 99999),
          }).eq('id', invoice.customerId!);
        }
      }

      // Check if it's the latest active invoice to rollback the counter
      await _recalculateCurrentCounter();

      // Soft delete in DB
      await _client
          .from('invoices')
          .update({'deleted_at': DateTime.now().toIso8601String(), 'status': 'DELETED'})
          .eq('id', id);
      
      // Reload products and customers
      _ref.read(productsProvider.notifier).loadProducts();
      _ref.read(customersProvider.notifier).loadCustomers();
      _ref.read(companyProvider.notifier).loadCompanySettings();

      final list = state.value ?? [];
      state = AsyncValue.data(list.where((inv) => inv.id != id).toList());
      
      // Force refresh the deleted invoices provider
      _ref.invalidate(deletedInvoicesProvider);
    } catch (e) {
      await loadInvoices();
      rethrow;
    }
  }

  Future<void> deleteInvoicePermanently(String id) async {
    try {
      // First fetch the invoice to revert stocks/stats if active
      final invData = await _client.from('invoices').select().eq('id', id).single();
      final invoice = _mapInvoice(invData);

      if (invoice.status != 'CANCELLED') {
        // Revert stock levels
        for (final item in invoice.items) {
          final prodData = await _client
              .from('products')
              .select('stock_units')
              .eq('id', item.productId)
              .single();
          final int currentStock = prodData['stock_units'] ?? 0;
          await _client
              .from('products')
              .update({'stock_units': currentStock + item.quantity})
              .eq('id', item.productId);
        }

        // Revert customer stats
        if (invoice.customerId != null && invoice.customerId!.isNotEmpty) {
          final custData = await _client
              .from('customers')
              .select('total_purchase_amount, total_invoices')
              .eq('id', invoice.customerId!)
              .single();
              
          final double totalPurchase = (custData['total_purchase_amount'] as num?)?.toDouble() ?? 0.0;
          final int totalInvoices = custData['total_invoices'] ?? 0;
          
          await _client.from('customers').update({
            'total_purchase_amount': (totalPurchase - invoice.finalPayable).clamp(0.0, double.infinity),
            'total_invoices': (totalInvoices - 1).clamp(0, 99999),
          }).eq('id', invoice.customerId!);
        }
      }

      // Hard delete in DB
      await _client
          .from('invoices')
          .delete()
          .eq('id', id);

      // Check if it's the latest active invoice to rollback the counter
      await _recalculateCurrentCounter();
      
      // Reload products, customers, and company settings
      _ref.read(productsProvider.notifier).loadProducts();
      _ref.read(customersProvider.notifier).loadCustomers();
      _ref.read(companyProvider.notifier).loadCompanySettings();

      final list = state.value ?? [];
      state = AsyncValue.data(list.where((inv) => inv.id != id).toList());
      
      // Force refresh the deleted invoices provider
      _ref.invalidate(deletedInvoicesProvider);
    } catch (e) {
      await loadInvoices();
      rethrow;
    }
  }

  Future<void> restoreInvoice(String id) async {
    try {
      final invData = await _client.from('invoices').select().eq('id', id).single();
      final invoice = _mapInvoice(invData);

      // Re-apply stocks and customer stats
      for (final item in invoice.items) {
        final prodData = await _client
            .from('products')
            .select('stock_units')
            .eq('id', item.productId)
            .single();
        final int currentStock = prodData['stock_units'] ?? 0;
        await _client
            .from('products')
            .update({'stock_units': (currentStock - item.quantity).clamp(0, 99999)})
            .eq('id', item.productId);
      }

      if (invoice.customerId != null && invoice.customerId!.isNotEmpty) {
        final custData = await _client
            .from('customers')
            .select('total_purchase_amount, total_invoices')
            .eq('id', invoice.customerId!)
            .single();
            
        final double totalPurchase = (custData['total_purchase_amount'] as num?)?.toDouble() ?? 0.0;
        final int totalInvoices = custData['total_invoices'] ?? 0;
        
        await _client.from('customers').update({
          'total_purchase_amount': totalPurchase + invoice.finalPayable,
          'total_invoices': totalInvoices + 1,
        }).eq('id', invoice.customerId!);
      }

      // Generate a new latest invoice number
      final newInvoiceNum = await _generateInvoiceNumber();

      final data = await _client
          .from('invoices')
          .update({
            'deleted_at': null,
            'status': 'PAID',
            'invoice_number': newInvoiceNum,
            'invoice_date': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .select()
          .single();
      final restoredInvoice = _mapInvoice(data);
      
      final restoredWithPdf = restoredInvoice;
      
      // Reload products and customers
      _ref.read(productsProvider.notifier).loadProducts();
      _ref.read(customersProvider.notifier).loadCustomers();

      final list = state.value ?? [];
      state = AsyncValue.data([restoredWithPdf, ...list]);
      
      // Force refresh the deleted invoices provider
      _ref.invalidate(deletedInvoicesProvider);
    } catch (e) {
      await loadInvoices();
      rethrow;
    }
  }

  Future<Invoice> updateInvoice(String id, Invoice invoice) async {
    try {
      // Revert previous invoice stock/stats first before applying new ones
      final oldInvData = await _client.from('invoices').select().eq('id', id).single();
      final oldInvoice = _mapInvoice(oldInvData);

      if (oldInvoice.status != 'CANCELLED') {
        for (final item in oldInvoice.items) {
          final prodData = await _client
              .from('products')
              .select('stock_units')
              .eq('id', item.productId)
              .single();
          final int currentStock = prodData['stock_units'] ?? 0;
          await _client
              .from('products')
              .update({'stock_units': currentStock + item.quantity})
              .eq('id', item.productId);
        }

        if (oldInvoice.customerId != null && oldInvoice.customerId!.isNotEmpty) {
          final custData = await _client
              .from('customers')
              .select('total_purchase_amount, total_invoices')
              .eq('id', oldInvoice.customerId!)
              .single();
              
          final double totalPurchase = (custData['total_purchase_amount'] as num?)?.toDouble() ?? 0.0;
          final int totalInvoices = custData['total_invoices'] ?? 0;
          
          await _client.from('customers').update({
            'total_purchase_amount': (totalPurchase - oldInvoice.finalPayable).clamp(0.0, double.infinity),
            'total_invoices': (totalInvoices - 1).clamp(0, 99999),
          }).eq('id', oldInvoice.customerId!);
        }
      }

      // Apply new stock and customer stats
      for (final item in invoice.items) {
        final prodData = await _client
            .from('products')
            .select('stock_units')
            .eq('id', item.productId)
            .single();
        final int currentStock = prodData['stock_units'] ?? 0;
        await _client
            .from('products')
            .update({'stock_units': (currentStock - item.quantity).clamp(0, 99999)})
            .eq('id', item.productId);
      }

      if (invoice.customerId != null && invoice.customerId!.isNotEmpty) {
        final custData = await _client
            .from('customers')
            .select('total_purchase_amount, total_invoices')
            .eq('id', invoice.customerId!)
            .single();
            
        final double totalPurchase = (custData['total_purchase_amount'] as num?)?.toDouble() ?? 0.0;
        final int totalInvoices = custData['total_invoices'] ?? 0;
        
        await _client.from('customers').update({
          'total_purchase_amount': totalPurchase + invoice.finalPayable,
          'total_invoices': totalInvoices + 1,
        }).eq('id', invoice.customerId!);
      }

      var payload = _unmapInvoice(invoice);
      final data = await _client
          .from('invoices')
          .update(payload)
          .eq('id', id)
          .select()
          .single();
          
      final updatedInvoice = _mapInvoice(data);
      
      _ref.read(productsProvider.notifier).loadProducts();
      _ref.read(customersProvider.notifier).loadCustomers();

      final list = state.value ?? [];
      final index = list.indexWhere((inv) => inv.id == id);
      if (index != -1) {
        final updatedList = List<Invoice>.from(list);
        updatedList[index] = updatedInvoice;
        state = AsyncValue.data(updatedList);
      } else {
        await loadInvoices();
      }
      return updatedInvoice;
    } catch (e) {
      await loadInvoices();
      rethrow;
    }
  }

  Future<Invoice?> findInvoiceByNumber(String number) async {
    try {
      // 1. Exact match
      var data = await _client
          .from('invoices')
          .select()
          .eq('invoice_number', number)
          .isFilter('deleted_at', null)
          .maybeSingle();
          
      if (data != null) return _mapInvoice(data);

      // 2. Trailing match or case-insensitive match
      final response = await _client
          .from('invoices')
          .select()
          .ilike('invoice_number', '%$number')
          .isFilter('deleted_at', null);

      if (response.isNotEmpty) {
        for (final item in response) {
          final inv = _mapInvoice(item);
          final invNum = inv.invoiceNumber;
          if (invNum != null) {
            final cleanInv = invNum.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
            final cleanQuery = number.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
            if (cleanInv == cleanQuery || cleanInv.endsWith(cleanQuery)) {
              return inv;
            }
            final invDigits = invNum.replaceAll(RegExp(r'\D'), '');
            final queryDigits = number.replaceAll(RegExp(r'\D'), '');
            if (invDigits.isNotEmpty && queryDigits.isNotEmpty) {
              final invVal = int.tryParse(invDigits);
              final queryVal = int.tryParse(queryDigits);
              if (invVal != null && queryVal != null && invVal == queryVal) {
                return inv;
              }
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  int? _parseCounter(String invoiceNum, Map<String, dynamic> settings) {
    final prefix = (settings['invoice_prefix'] ?? '') as String;
    final separator = (settings['invoice_separator'] ?? '-') as String;
    final financialYear = (settings['invoice_financial_year'] ?? '') as String;
    final suffix = (settings['invoice_suffix'] ?? '') as String;
    
    var temp = invoiceNum;
    // Strip financial year
    if (financialYear.isNotEmpty && temp.startsWith('$financialYear$separator')) {
      temp = temp.substring(financialYear.length + separator.length);
    }
    // Strip prefix
    if (prefix.isNotEmpty && temp.startsWith('$prefix$separator')) {
      temp = temp.substring(prefix.length + separator.length);
    } else if (prefix.isNotEmpty && temp.startsWith(prefix)) {
      temp = temp.substring(prefix.length);
    }
    // Strip suffix
    if (suffix.isNotEmpty && temp.endsWith('$separator$suffix')) {
      temp = temp.substring(0, temp.length - suffix.length - separator.length);
    }
    
    // Clean any remaining separators at the beginning/end
    if (separator.isNotEmpty) {
      if (temp.startsWith(separator)) temp = temp.substring(separator.length);
      if (temp.endsWith(separator)) temp = temp.substring(0, temp.length - separator.length);
    }
    
    return int.tryParse(temp);
  }

  Future<void> _recalculateCurrentCounter() async {
    try {
      final settingsData = await _client.from('company_settings').select().maybeSingle();
      if (settingsData == null) return;
      
      // Fetch all active invoice numbers
      final List<dynamic> activeInvoicesData = await _client
          .from('invoices')
          .select('invoice_number')
          .isFilter('deleted_at', null);
          
      int maxCounter = 0;
      for (final inv in activeInvoicesData) {
        final String? invNum = inv['invoice_number'];
        if (invNum != null) {
          final counter = _parseCounter(invNum, settingsData);
          if (counter != null && counter > maxCounter) {
            maxCounter = counter;
          }
        }
      }
      
      // Update the counter in company settings
      await _client
          .from('company_settings')
          .update({'invoice_current_counter': maxCounter})
          .eq('id', settingsData['id']);
          
    } catch (_) {}
  }
}

final invoicesProvider =
    StateNotifierProvider<InvoicesNotifier, AsyncValue<List<Invoice>>>((ref) {
  return InvoicesNotifier(ref);
});

final deletedInvoicesProvider = FutureProvider<List<Invoice>>((ref) async {
  final client = Supabase.instance.client;
  final data = await client
      .from('invoices')
      .select()
      .not('deleted_at', 'is', null)
      .order('invoice_date', ascending: false);

  final notifier = ref.read(invoicesProvider.notifier);
  final invoices = (data as List).map((item) => notifier._mapInvoice(item)).toList();
  return invoices;
});
