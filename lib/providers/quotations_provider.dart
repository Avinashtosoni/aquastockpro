import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/quotation.dart';
import '../data/models/order.dart';
import '../data/repositories/quotation_repository.dart';

final quotationRepositoryProvider = Provider((ref) => QuotationRepository());

// All quotations (with limit for faster loading)
final quotationsProvider = FutureProvider<List<Quotation>>((ref) async {
  ref.keepAlive(); // Cache quotations
  final repository = ref.watch(quotationRepositoryProvider);
  return repository.getAll(limit: 50); // Limit to 50 for faster initial load
});

// Quotations by status
final quotationsByStatusProvider = FutureProvider.family<List<Quotation>, QuotationStatus>((ref, status) async {
  final repository = ref.watch(quotationRepositoryProvider);
  return repository.getByStatus(status);
});

// Recent quotations (latest 10)
final recentQuotationsProvider = FutureProvider.autoDispose<List<Quotation>>((ref) async {
  final repository = ref.watch(quotationRepositoryProvider);
  return repository.getAll(limit: 10);
});

// Quotation stats
final quotationStatsProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final repository = ref.watch(quotationRepositoryProvider);
  return repository.getQuotationStats();
});

// Expired quotations
final expiredQuotationsProvider = FutureProvider.autoDispose<List<Quotation>>((ref) async {
  final repository = ref.watch(quotationRepositoryProvider);
  return repository.getExpiredQuotations();
});

// Quotations notifier for CRUD
class QuotationsNotifier extends StateNotifier<AsyncValue<List<Quotation>>> {
  final Ref _ref;

  QuotationsNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadQuotations();
  }

  Future<void> loadQuotations() async {
    state = const AsyncValue.loading();
    try {
      final quotations = await _ref.read(quotationRepositoryProvider).getAll();
      state = AsyncValue.data(quotations);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createQuotation(Quotation quotation) async {
    try {
      await _ref.read(quotationRepositoryProvider).insert(quotation);
      await loadQuotations();
      // Invalidate stats
      _ref.invalidate(quotationStatsProvider);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateQuotation(Quotation quotation) async {
    try {
      await _ref.read(quotationRepositoryProvider).update(quotation);
      await loadQuotations();
      _ref.invalidate(quotationStatsProvider);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteQuotation(String id) async {
    try {
      await _ref.read(quotationRepositoryProvider).delete(id);
      await loadQuotations();
      _ref.invalidate(quotationStatsProvider);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateQuotationStatus(String quotationId, QuotationStatus status) async {
    try {
      final quotation = await _ref.read(quotationRepositoryProvider).getById(quotationId);
      if (quotation != null) {
        await _ref.read(quotationRepositoryProvider).update(quotation.copyWith(status: status));
      }
      await loadQuotations();
      _ref.invalidate(quotationStatsProvider);
    } catch (e) {
      rethrow;
    }
  }

  Future<Order> convertToOrder(Quotation quotation) async {
    try {
      final order = await _ref.read(quotationRepositoryProvider).convertToOrder(quotation);
      await loadQuotations();
      _ref.invalidate(quotationStatsProvider);
      return order;
    } catch (e) {
      rethrow;
    }
  }

  Future<String> generateQuotationNumber() async {
    return _ref.read(quotationRepositoryProvider).generateQuotationNumber();
  }
}

final quotationsNotifierProvider = StateNotifierProvider<QuotationsNotifier, AsyncValue<List<Quotation>>>((ref) {
  return QuotationsNotifier(ref);
});
