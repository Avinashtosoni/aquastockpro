import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/order.dart';
import '../data/repositories/order_repository.dart';

final orderRepositoryProvider = Provider((ref) => OrderRepository());

// All orders (with limit for faster loading)
final ordersProvider = FutureProvider<List<Order>>((ref) async {
  ref.keepAlive(); // Cache orders
  final repository = ref.watch(orderRepositoryProvider);
  return repository.getAll(limit: 50); // Limit to 50 for faster initial load
});

// Orders by status
final ordersByStatusProvider = FutureProvider.family<List<Order>, OrderStatus>((ref, status) async {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.getByStatus(status);
});

// Recent orders (latest 10, cached)
final recentOrdersProvider = FutureProvider.autoDispose<List<Order>>((ref) async {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.getAll(limit: 5); // Only 5 for dashboard
});

// Today's orders (using date range for today)
final todaysOrdersProvider = FutureProvider.autoDispose<List<Order>>((ref) async {
  final repository = ref.watch(orderRepositoryProvider);
  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));
  return repository.getByDateRange(startOfDay, endOfDay);
});

// Orders count
final ordersCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(orderRepositoryProvider);
  final orders = await repository.getAll();
  return orders.length;
});

// Today's stats (sales, order count, etc)
final todayStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.getTodayStats();
});

// Stats for any period (accepts number of days)
final periodStatsProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, int>((ref, days) async {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.getStatsByRange(days);
});

// Today's sales (extracted from stats)
final todaysSalesProvider = FutureProvider<double>((ref) async {
  final stats = await ref.watch(todayStatsProvider.future);
  return (stats['totalSales'] as num?)?.toDouble() ?? 0.0;
});

// Sales by date range
final salesByDateProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, int>((ref, days) async {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.getSalesByDate(days);
});

// Top products
final topProductsProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, int>((ref, limit) async {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.getTopProducts(limit);
});

// Orders by customer (for customer history)
final customerOrdersProvider = FutureProvider.autoDispose.family<List<Order>, String>((ref, customerId) async {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.getByCustomer(customerId);
});

// Orders notifier for CRUD
class OrdersNotifier extends StateNotifier<AsyncValue<List<Order>>> {
  final Ref _ref;

  OrdersNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadOrders();
  }

  Future<void> loadOrders() async {
    state = const AsyncValue.loading();
    try {
      final orders = await _ref.read(orderRepositoryProvider).getAll();
      state = AsyncValue.data(orders);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createOrder(Order order) async {
    try {
      await _ref.read(orderRepositoryProvider).insert(order);
      await loadOrders();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      final order = await _ref.read(orderRepositoryProvider).getById(orderId);
      if (order != null) {
        await _ref.read(orderRepositoryProvider).update(order.copyWith(status: status));
      }
      await loadOrders();
    } catch (e) {
      rethrow;
    }
  }

  Future<String> generateOrderNumber() async {
    return _ref.read(orderRepositoryProvider).generateOrderNumber();
  }
}

final ordersNotifierProvider = StateNotifierProvider<OrdersNotifier, AsyncValue<List<Order>>>((ref) {
  return OrdersNotifier(ref);
});

// Paginated orders state
class PaginatedOrdersState {
  final List<Order> orders;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? error;

  const PaginatedOrdersState({
    this.orders = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.error,
  });

  PaginatedOrdersState copyWith({
    List<Order>? orders,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return PaginatedOrdersState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
    );
  }
}

// Paginated orders notifier
class PaginatedOrdersNotifier extends StateNotifier<PaginatedOrdersState> {
  final Ref _ref;
  static const int _pageSize = 20;

  PaginatedOrdersNotifier(this._ref) : super(const PaginatedOrdersState()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final orders = await _ref.read(orderRepositoryProvider).getAll(limit: _pageSize);
      state = PaginatedOrdersState(
        orders: orders,
        isLoading: false,
        hasMore: orders.length >= _pageSize,
        currentPage: 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);
    try {
      final offset = state.orders.length;
      final newOrders = await _ref.read(orderRepositoryProvider).getAll(
        limit: _pageSize,
        offset: offset,
      );
      
      state = state.copyWith(
        orders: [...state.orders, ...newOrders],
        isLoading: false,
        hasMore: newOrders.length >= _pageSize,
        currentPage: state.currentPage + 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    state = const PaginatedOrdersState();
    await loadInitial();
  }
}

final paginatedOrdersProvider = StateNotifierProvider<PaginatedOrdersNotifier, PaginatedOrdersState>((ref) {
  return PaginatedOrdersNotifier(ref);
});
