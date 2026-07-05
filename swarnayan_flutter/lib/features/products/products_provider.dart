import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/product.dart';

class ProductsNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  ProductsNotifier() : super(const AsyncValue.loading()) {
    loadProducts();
  }

  final _client = Supabase.instance.client;

  Product _mapProduct(Map<String, dynamic> data) {
    return Product(
      id: data['id'],
      name: data['name'] ?? '',
      category: data['category'] ?? 'GOLD',
      purity: data['purity'] ?? '22K',
      huidNumber: data['huid_number'],
      hsnCode: data['hsn_code'] ?? '7113',
      stockUnits: data['stock_units'] ?? 1,
      weight: (data['weight'] as num?)?.toDouble() ?? 0.0,
      stoneType: data['stone_type'],
      stoneWeight: (data['stone_weight'] as num?)?.toDouble() ?? 0.0,
      stoneValue: (data['stone_value'] as num?)?.toDouble() ?? 0.0,
      imageUrl: data['image_url'],
      isActive: data['is_active'] ?? true,
    );
  }

  Map<String, dynamic> _unmapProduct(Product product) {
    return {
      'name': product.name,
      'category': product.category,
      'purity': product.purity,
      if (product.huidNumber != null) 'huid_number': product.huidNumber,
      'hsn_code': product.hsnCode,
      'stock_units': product.stockUnits,
      'weight': product.weight,
      'stone_type': product.stoneType ?? 'NONE',
      'stone_weight': product.stoneWeight,
      'stone_value': product.stoneValue,
      'image_url': product.imageUrl ?? '',
      'is_active': product.isActive,
    };
  }

  Future<String> generateNextHuid() async {
    try {
      final response = await _client
          .from('products')
          .select('huid_number')
          .not('huid_number', 'is', null);

      if (response != null && response is List) {
        int maxVal = -1;
        int maxLen = 3;

        for (final item in response) {
          final String? huid = item['huid_number'];
          if (huid != null && huid.isNotEmpty) {
            final numericOnly = huid.replaceAll(RegExp(r'\D'), '');
            if (numericOnly.isNotEmpty) {
              final val = int.tryParse(numericOnly);
              if (val != null) {
                if (val > maxVal) {
                  maxVal = val;
                  maxLen = numericOnly.length;
                }
              }
            }
          }
        }

        if (maxVal != -1) {
          final nextNum = maxVal + 1;
          return nextNum.toString().padLeft(maxLen, '0');
        }
      }
    } catch (_) {}
    return '001';
  }

  Future<void> loadProducts() async {
    try {
      state = const AsyncValue.loading();
      // Show only active products
      final data = await _client.from('products').select().eq('is_active', true).order('created_at', ascending: false);
      final products = (data as List).map((item) => _mapProduct(item)).toList();
      state = AsyncValue.data(products);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addProduct(Product product) async {
    try {
      var payload = _unmapProduct(product);
      if (product.huidNumber == null || product.huidNumber!.trim().isEmpty) {
        final nextHuid = await generateNextHuid();
        payload['huid_number'] = nextHuid;
      }
      final data = await _client.from('products').insert(payload).select().single();
      final newProd = _mapProduct(data);
      final list = state.value ?? [];
      state = AsyncValue.data([newProd, ...list]);
    } catch (e) {
      await loadProducts();
      rethrow;
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      if (product.id == null) {
        throw Exception('Product ID is required for update');
      }
      var payload = _unmapProduct(product);
      final data = await _client
          .from('products')
          .update(payload)
          .eq('id', product.id!)
          .select()
          .single();
      final updatedProduct = _mapProduct(data);
      final list = state.value ?? [];
      final index = list.indexWhere((p) => p.id == updatedProduct.id);
      if (index != -1) {
        final updated = List<Product>.from(list);
        updated[index] = updatedProduct;
        state = AsyncValue.data(updated);
      } else {
        await loadProducts();
      }
    } catch (e) {
      await loadProducts();
      rethrow;
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      // Soft-delete: set is_active to false
      await _client.from('products').update({'is_active': false}).eq('id', id);
      final list = state.value ?? [];
      state = AsyncValue.data(list.where((p) => p.id != id).toList());
    } catch (e) {
      await loadProducts();
      rethrow;
    }
  }
}

final productsProvider =
    StateNotifierProvider<ProductsNotifier, AsyncValue<List<Product>>>((ref) {
  return ProductsNotifier();
});
