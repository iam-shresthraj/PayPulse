import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/daily_rate.dart';

class DailyRatesNotifier extends StateNotifier<AsyncValue<List<DailyRate>>> {
  DailyRatesNotifier() : super(const AsyncValue.loading()) {
    loadRates();
  }

  final _client = Supabase.instance.client;

  DailyRate _mapDailyRate(Map<String, dynamic> data) {
    return DailyRate(
      id: data['id'],
      date: DateTime.parse(data['date']),
      rateGold22K: (data['rate_gold_22k'] as num).toDouble(),
      rateGold18K: (data['rate_gold_18k'] as num).toDouble(),
      rateSilver: (data['rate_silver'] as num).toDouble(),
      enteredBy: data['entered_by'],
    );
  }

  Map<String, dynamic> _unmapDailyRate(DailyRate rate) {
    final formattedDateStr = '${rate.date.year}-${rate.date.month.toString().padLeft(2, '0')}-${rate.date.day.toString().padLeft(2, '0')}';
    return {
      'date': formattedDateStr,
      'rate_gold_22k': rate.rateGold22K,
      'rate_gold_18k': rate.rateGold18K,
      'rate_silver': rate.rateSilver,
      'entered_by': rate.enteredBy ?? _client.auth.currentUser?.id,
    };
  }

  Future<void> loadRates() async {
    try {
      state = const AsyncValue.loading();
      final data = await _client.from('daily_rates').select().order('date', ascending: false);
      final rates = (data as List).map((item) => _mapDailyRate(item)).toList();
      state = AsyncValue.data(rates);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addDailyRate(DailyRate rate) async {
    try {
      final payload = _unmapDailyRate(rate);
      final data = await _client.from('daily_rates').upsert(payload, onConflict: 'date').select().single();
      final newRate = _mapDailyRate(data);
      final list = state.value ?? [];
      
      // Look if targeted date's rate is already present
      final index = list.indexWhere((r) =>
          r.date.year == newRate.date.year &&
          r.date.month == newRate.date.month &&
          r.date.day == newRate.date.day);
          
      if (index != -1) {
        final updated = List<DailyRate>.from(list);
        updated[index] = newRate;
        state = AsyncValue.data(updated);
      } else {
        // Add to front and sort
        final newList = [newRate, ...list];
        newList.sort((a, b) => b.date.compareTo(a.date));
        state = AsyncValue.data(newList);
      }
    } catch (e) {
      await loadRates();
      rethrow;
    }
  }

  DailyRate? getTodayRate() {
    final list = state.value;
    if (list == null || list.isEmpty) return null;
    final now = DateTime.now();
    try {
      return list.firstWhere(
        (r) =>
            r.date.year == now.year &&
            r.date.month == now.month &&
            r.date.day == now.day,
      );
    } catch (_) {
      // Fallback: return the most recent rate entered
      return list.first;
    }
  }
  
  bool isTodayRateEntered() {
    final list = state.value;
    if (list == null || list.isEmpty) return false;
    final now = DateTime.now();
    return list.any(
      (r) =>
          r.date.year == now.year &&
          r.date.month == now.month &&
          r.date.day == now.day,
    );
  }
}

final dailyRatesProvider =
    StateNotifierProvider<DailyRatesNotifier, AsyncValue<List<DailyRate>>>((ref) {
  return DailyRatesNotifier();
});
