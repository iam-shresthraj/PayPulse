import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/coupon.dart';

class CouponsNotifier extends StateNotifier<AsyncValue<List<Coupon>>> {
  CouponsNotifier() : super(const AsyncValue.loading()) {
    loadCoupons();
  }

  final _client = Supabase.instance.client;

  Coupon _mapCoupon(Map<String, dynamic> data) {
    return Coupon(
      id: data['id'],
      code: data['code'],
      discountType: data['discount_type'],
      discountValue: (data['discount_value'] as num).toDouble(),
      minBillAmount: (data['min_bill_amount'] as num?)?.toDouble() ?? 0.0,
      maxDiscount: (data['max_discount'] as num?)?.toDouble() ?? 0.0,
      expiryDate: DateTime.parse(data['expiry_date']),
      startsAt: data['starts_at'] != null ? DateTime.parse(data['starts_at']) : null,
      isActive: data['is_active'] ?? true,
      usageLimit: data['usage_limit'],
      usedCount: data['used_count'] ?? 0,
    );
  }

  Map<String, dynamic> _unmapCoupon(Coupon coupon) {
    return {
      'code': coupon.code.toUpperCase(),
      'discount_type': coupon.discountType,
      'discount_value': coupon.discountValue,
      'min_bill_amount': coupon.minBillAmount,
      'max_discount': coupon.maxDiscount,
      'expiry_date': coupon.expiryDate.toUtc().toIso8601String(),
      'starts_at': coupon.startsAt?.toUtc().toIso8601String(),
      'is_active': coupon.isActive,
      'usage_limit': coupon.usageLimit,
      'used_count': coupon.usedCount,
    };
  }

  Future<void> loadCoupons({String? status, String? discountType}) async {
    try {
      state = const AsyncValue.loading();
      var query = _client.from('coupons').select();

      if (status != null && status.isNotEmpty) {
        if (status == 'ACTIVE') {
          query = query.eq('is_active', true);
        } else if (status == 'INACTIVE') {
          query = query.eq('is_active', false);
        }
      }
      if (discountType != null && discountType.isNotEmpty) {
        query = query.eq('discount_type', discountType);
      }

      final data = await query.order('created_at', ascending: false);
      final coupons = (data as List).map((item) => _mapCoupon(item)).toList();
      state = AsyncValue.data(coupons);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addCoupon(Coupon coupon) async {
    try {
      final payload = _unmapCoupon(coupon);
      final data = await _client.from('coupons').insert(payload).select().single();
      final newCoupon = _mapCoupon(data);
      final list = state.value ?? [];
      state = AsyncValue.data([newCoupon, ...list]);
    } catch (e) {
      await loadCoupons();
      rethrow;
    }
  }

  Future<void> updateCoupon(Coupon coupon) async {
    try {
      if (coupon.id == null) {
        throw Exception('Coupon ID is required for update');
      }
      final payload = _unmapCoupon(coupon);
      final data = await _client
          .from('coupons')
          .update(payload)
          .eq('id', coupon.id!)
          .select()
          .single();
      final updatedCoupon = _mapCoupon(data);
      final list = state.value ?? [];
      final index = list.indexWhere((c) => c.id == updatedCoupon.id);
      if (index != -1) {
        final updated = List<Coupon>.from(list);
        updated[index] = updatedCoupon;
        state = AsyncValue.data(updated);
      } else {
        await loadCoupons();
      }
    } catch (e) {
      await loadCoupons();
      rethrow;
    }
  }

  Future<void> deactivateCoupon(String id) async {
    try {
      final data = await _client
          .from('coupons')
          .update({'is_active': false})
          .eq('id', id)
          .select()
          .single();
      final updatedCoupon = _mapCoupon(data);
      final list = state.value ?? [];
      final index = list.indexWhere((c) => c.id == id);
      if (index != -1) {
        final updated = List<Coupon>.from(list);
        updated[index] = updatedCoupon;
        state = AsyncValue.data(updated);
      } else {
        await loadCoupons();
      }
    } catch (e) {
      await loadCoupons();
      rethrow;
    }
  }

  Future<void> activateCoupon(String id) async {
    try {
      final data = await _client
          .from('coupons')
          .update({'is_active': true})
          .eq('id', id)
          .select()
          .single();
      final updatedCoupon = _mapCoupon(data);
      final list = state.value ?? [];
      final index = list.indexWhere((c) => c.id == id);
      if (index != -1) {
        final updated = List<Coupon>.from(list);
        updated[index] = updatedCoupon;
        state = AsyncValue.data(updated);
      } else {
        await loadCoupons();
      }
    } catch (e) {
      await loadCoupons();
      rethrow;
    }
  }

  Future<void> deleteCoupon(String id) async {
    try {
      await _client.from('coupons').delete().eq('id', id);
      final list = state.value ?? [];
      state = AsyncValue.data(list.where((c) => c.id != id).toList());
    } catch (e) {
      await loadCoupons();
      rethrow;
    }
  }

  Future<Coupon> validateCouponCode(String code, double billAmount, {DateTime? date}) async {
    final data = await _client
        .from('coupons')
        .select()
        .eq('code', code.toUpperCase())
        .maybeSingle();

    if (data == null) {
      throw Exception('Invalid coupon code.');
    }

    final coupon = _mapCoupon(data);
    if (!coupon.isActive) {
      throw Exception('Coupon is inactive.');
    }

    final validationDate = date ?? DateTime.now();

    if (coupon.expiryDate.isBefore(validationDate)) {
      throw Exception('Coupon has expired.');
    }

    if (coupon.startsAt != null && coupon.startsAt!.isAfter(validationDate)) {
      throw Exception('Coupon campaign has not started yet.');
    }

    if (coupon.usageLimit != null && coupon.usageLimit! > 0 && coupon.usedCount >= coupon.usageLimit!) {
      throw Exception('Coupon usage limit reached.');
    }

    if (billAmount < coupon.minBillAmount) {
      throw Exception('Minimum bill amount of ₹${coupon.minBillAmount} not met.');
    }

    return coupon;
  }

  /// Increments used_count for the given coupon code after a successful invoice save.
  Future<void> incrementUsage(String code) async {
    try {
      // Use a raw RPC or update with current value from DB to avoid race conditions
      final data = await _client
          .from('coupons')
          .select('id, used_count')
          .eq('code', code.toUpperCase())
          .maybeSingle();
      if (data == null) return;
      final String id = data['id'];
      final int currentUsed = (data['used_count'] as num?)?.toInt() ?? 0;
      await _client
          .from('coupons')
          .update({'used_count': currentUsed + 1})
          .eq('id', id);
      // Refresh local state
      final list = state.value ?? [];
      final index = list.indexWhere((c) => c.id == id);
      if (index != -1) {
        final updated = List<Coupon>.from(list);
        updated[index] = updated[index].copyWith(usedCount: currentUsed + 1);
        state = AsyncValue.data(updated);
      }
    } catch (_) {
      // Non-critical: don't fail the invoice save if this errors
    }
  }
}

final couponsProvider =
    StateNotifierProvider<CouponsNotifier, AsyncValue<List<Coupon>>>((ref) {
  return CouponsNotifier();
});
