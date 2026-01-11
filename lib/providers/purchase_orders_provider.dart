import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/purchase_order.dart';
import '../data/repositories/purchase_order_repository.dart';

final purchaseOrderRepositoryProvider = Provider((ref) => PurchaseOrderRepository());

/// Purchase Orders State
class PurchaseOrdersState {
  final List<PurchaseOrder> orders;
  final bool isLoading;
  final String? error;

  PurchaseOrdersState({
    this.orders = const [],
    this.isLoading = false,
    this.error,
  });

  PurchaseOrdersState copyWith({
    List<PurchaseOrder>? orders,
    bool? isLoading,
    String? error,
  }) {
    return PurchaseOrdersState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Purchase Orders Provider
class PurchaseOrdersNotifier extends StateNotifier<PurchaseOrdersState> {
  final Ref _ref;
  
  PurchaseOrdersNotifier(this._ref) : super(PurchaseOrdersState()) {
    loadOrders();
  }

  Future<void> loadOrders() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final orders = await _ref.read(purchaseOrderRepositoryProvider).getAll();
      state = state.copyWith(orders: orders, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addOrder(PurchaseOrder order) async {
    try {
      await _ref.read(purchaseOrderRepositoryProvider).insert(order);
      await loadOrders();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateOrder(PurchaseOrder order) async {
    try {
      await _ref.read(purchaseOrderRepositoryProvider).update(order);
      await loadOrders();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteOrder(String orderId) async {
    try {
      await _ref.read(purchaseOrderRepositoryProvider).delete(orderId);
      await loadOrders();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateStatus(String orderId, PurchaseOrderStatus status) async {
    try {
      final order = await _ref.read(purchaseOrderRepositoryProvider).getById(orderId);
      if (order != null) {
        final updatedOrder = order.copyWith(status: status);
        await _ref.read(purchaseOrderRepositoryProvider).update(updatedOrder);
        await loadOrders();
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

/// Provider instances
final purchaseOrdersProvider = StateNotifierProvider<PurchaseOrdersNotifier, PurchaseOrdersState>((ref) {
  return PurchaseOrdersNotifier(ref);
});

/// Filtered orders by status
final filteredPurchaseOrdersProvider = Provider.family<List<PurchaseOrder>, PurchaseOrderStatus?>((ref, status) {
  final ordersState = ref.watch(purchaseOrdersProvider);
  if (status == null) return ordersState.orders;
  return ordersState.orders.where((o) => o.status == status).toList();
});

/// Pending orders count
final pendingOrdersCountProvider = Provider<int>((ref) {
  final ordersState = ref.watch(purchaseOrdersProvider);
  return ordersState.orders
      .where((o) => o.status == PurchaseOrderStatus.pending || o.status == PurchaseOrderStatus.ordered)
      .length;
});
