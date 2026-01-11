import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/stock_adjustment.dart';
import '../data/models/product.dart';
import '../data/repositories/stock_adjustment_repository.dart';

// Stock adjustment repository provider
final stockAdjustmentRepositoryProvider = Provider<StockAdjustmentRepository>((ref) {
  return StockAdjustmentRepository();
});

// Recent stock adjustments provider
final recentStockAdjustmentsProvider = FutureProvider<List<StockAdjustment>>((ref) async {
  return await StockAdjustmentRepository().getAll(limit: 50);
});

// Stock adjustments by product provider
final stockAdjustmentsByProductProvider = FutureProvider.family<List<StockAdjustment>, String>((ref, productId) async {
  return await StockAdjustmentRepository().getByProduct(productId);
});

// Stock adjustment notifier for creating adjustments
final stockAdjustmentNotifierProvider = AsyncNotifierProvider<StockAdjustmentNotifier, List<StockAdjustment>>(() {
  return StockAdjustmentNotifier();
});

class StockAdjustmentNotifier extends AsyncNotifier<List<StockAdjustment>> {
  @override
  Future<List<StockAdjustment>> build() async {
    return await StockAdjustmentRepository().getAll(limit: 100);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await StockAdjustmentRepository().getAll(limit: 100));
  }

  Future<StockAdjustment> createAdjustment({
    required Product product,
    required int adjustedQuantity,
    required StockAdjustmentReason reason,
    required String employeeId,
    required String employeeName,
    String? notes,
  }) async {
    final adjustment = await StockAdjustmentRepository().createAdjustment(
      product: product,
      adjustedQuantity: adjustedQuantity,
      reason: reason,
      employeeId: employeeId,
      employeeName: employeeName,
      notes: notes,
    );
    await refresh();
    return adjustment;
  }
}

// Summary by reason provider
final stockAdjustmentSummaryProvider = FutureProvider.family<Map<String, int>, ({DateTime? startDate, DateTime? endDate})>((ref, params) async {
  return await StockAdjustmentRepository().getSummaryByReason(
    startDate: params.startDate,
    endDate: params.endDate,
  );
});
