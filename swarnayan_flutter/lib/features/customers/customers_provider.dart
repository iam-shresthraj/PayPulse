import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/customer.dart';
import '../../core/utils/formatters.dart';

class CustomersNotifier extends StateNotifier<AsyncValue<List<Customer>>> {
  CustomersNotifier() : super(const AsyncValue.loading()) {
    loadCustomers();
  }

  final _client = Supabase.instance.client;

  Customer _mapCustomer(Map<String, dynamic> data) {
    return Customer(
      id: data['id'],
      mobile: data['mobile'] ?? '',
      name: data['name'] ?? '',
      email: data['email'],
      address: data['address'],
      pincode: data['pincode'],
      city: data['city'],
      state: data['state'],
      panCard: data['pan_card'],
      gstNumber: data['gst_number'],
      additionalNote: data['additional_note'],
      totalPurchaseAmount: (data['total_purchase_amount'] as num?)?.toDouble() ?? 0.0,
      totalInvoices: data['total_invoices'] ?? 0,
      lastVisitDate: data['last_visit_date'] != null ? DateTime.parse(data['last_visit_date']) : null,
      createdAt: data['created_at'] != null ? DateTime.parse(data['created_at']) : null,
    );
  }

  Map<String, dynamic> _unmapCustomer(Customer customer) {
    return {
      'mobile': customer.mobile,
      'name': Formatters.toTitleCase(customer.name),
      'email': customer.email ?? '',
      'address': customer.address ?? '',
      'pincode': customer.pincode ?? '',
      'city': customer.city ?? '',
      'state': customer.state ?? '',
      'pan_card': customer.panCard ?? '',
      'gst_number': customer.gstNumber ?? '',
      'additional_note': customer.additionalNote ?? '',
      'total_purchase_amount': customer.totalPurchaseAmount,
      'total_invoices': customer.totalInvoices,
      'last_visit_date': customer.lastVisitDate?.toIso8601String(),
    };
  }

  Future<void> loadCustomers() async {
    try {
      state = const AsyncValue.loading();
      final data = await _client.from('customers').select().order('name', ascending: true);
      final customers = (data as List).map((item) => _mapCustomer(item)).toList();
      state = AsyncValue.data(customers);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<Customer> addCustomer(Customer customer) async {
    try {
      final payload = _unmapCustomer(customer);
      final data = await _client.from('customers').insert(payload).select().single();
      final newCust = _mapCustomer(data);
      final list = state.value ?? [];
      final index = list.indexWhere((c) => c.id == newCust.id);
      if (index != -1) {
        final updated = List<Customer>.from(list);
        updated[index] = newCust;
        state = AsyncValue.data(updated);
      } else {
        state = AsyncValue.data([...list, newCust]);
      }
      return newCust;
    } catch (e) {
      await loadCustomers();
      rethrow;
    }
  }

  Future<Customer> updateCustomer(String id, Customer customer) async {
    try {
      final payload = _unmapCustomer(customer);
      final data = await _client
          .from('customers')
          .update(payload)
          .eq('id', id)
          .select()
          .single();
      final updatedCust = _mapCustomer(data);
      final list = state.value ?? [];
      final index = list.indexWhere((c) => c.id == updatedCust.id);
      if (index != -1) {
        final updated = List<Customer>.from(list);
        updated[index] = updatedCust;
        state = AsyncValue.data(updated);
      } else {
        state = AsyncValue.data([...list, updatedCust]);
      }
      return updatedCust;
    } catch (e) {
      await loadCustomers();
      rethrow;
    }
  }

  Future<void> deleteCustomer(String id) async {
    try {
      await _client.from('customers').delete().eq('id', id);
      final list = state.value ?? [];
      state = AsyncValue.data(list.where((c) => c.id != id).toList());
    } catch (e) {
      await loadCustomers();
      rethrow;
    }
  }
}

final customersProvider =
    StateNotifierProvider<CustomersNotifier, AsyncValue<List<Customer>>>((ref) {
  return CustomersNotifier();
});
