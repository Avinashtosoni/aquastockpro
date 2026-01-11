import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'orders_provider.dart';
import 'products_provider.dart';
import 'customers_provider.dart';

// Dashboard date range
enum DashboardDateRange { today, week, month, year }

final dashboardDateRangeProvider = StateProvider<DashboardDateRange>((ref) => DashboardDateRange.today);

// Dashboard stats
class DashboardStats {
  final double periodSales;      // Changed from todaySales
  final int periodOrders;        // Changed from todayOrders
  final double averageOrderValue;
  final int totalProducts;
  final int lowStockCount;
  final int totalCustomers;
  final double inventoryValue;
  final List<Map<String, dynamic>> recentSales;
  final List<Map<String, dynamic>> topProducts;
  // Credit stats
  final double totalPendingCredit;
  final int customersWithCreditCount;
  final String periodLabel;      // New: to display which period

  DashboardStats({
    this.periodSales = 0,
    this.periodOrders = 0,
    this.averageOrderValue = 0,
    this.totalProducts = 0,
    this.lowStockCount = 0,
    this.totalCustomers = 0,
    this.inventoryValue = 0,
    this.recentSales = const [],
    this.topProducts = const [],
    this.totalPendingCredit = 0,
    this.customersWithCreditCount = 0,
    this.periodLabel = "Today's",
  });
}

// Helper to get days count for the range
int _getDaysForRange(DashboardDateRange range) {
  switch (range) {
    case DashboardDateRange.today:
      return 1;
    case DashboardDateRange.week:
      return 7;
    case DashboardDateRange.month:
      return 30;
    case DashboardDateRange.year:
      return 365;
  }
}

// Helper to get label for the range
String _getLabelForRange(DashboardDateRange range) {
  switch (range) {
    case DashboardDateRange.today:
      return "Today's";
    case DashboardDateRange.week:
      return "This Week's";
    case DashboardDateRange.month:
      return "This Month's";
    case DashboardDateRange.year:
      return "This Year's";
  }
}

final dashboardStatsProvider = FutureProvider.autoDispose<DashboardStats>((ref) async {
  try {
    // Watch the date range so stats update when it changes
    final dateRange = ref.watch(dashboardDateRangeProvider);
    final days = _getDaysForRange(dateRange);
    final periodLabel = _getLabelForRange(dateRange);
    
    // Debug logging removed for performance
    
    // Get stats for the selected period
    final periodStats = await ref.watch(periodStatsProvider(days).future);

    

    // Get product stats (these don't change with date range)
    final productCount = await ref.watch(productCountProvider.future);
    final lowStockProducts = await ref.watch(lowStockProductsProvider.future);
    final inventoryValue = await ref.watch(inventoryValueProvider.future);

    

    // Get customer count
    final customers = await ref.watch(customersProvider.future);
    final customerCount = customers.length;

    
    // Get sales by date for the selected range
    final recentSales = await ref.watch(salesByDateProvider(days).future);
    
    // Get top products for the selected range
    final topProducts = await ref.watch(topProductsProvider(5).future);
    
    // Get credit stats
    final customersWithCredit = await ref.watch(customersWithCreditProvider.future);
    final totalPendingCredit = await ref.watch(totalOutstandingCreditProvider.future);
    


    return DashboardStats(
      periodSales: (periodStats['totalSales'] as num?)?.toDouble() ?? 0.0,
      periodOrders: (periodStats['orderCount'] as num?)?.toInt() ?? 0,
      averageOrderValue: (periodStats['averageOrder'] as num?)?.toDouble() ?? 0.0,
      totalProducts: productCount,
      lowStockCount: lowStockProducts.length,
      totalCustomers: customerCount,
      inventoryValue: inventoryValue,
      recentSales: recentSales,
      topProducts: topProducts,
      totalPendingCredit: totalPendingCredit,
      customersWithCreditCount: customersWithCredit.length,
      periodLabel: periodLabel,
    );
  } catch (e, stack) {
    debugPrint('Error loading dashboard stats: $e');
    debugPrint('Stack trace: $stack');
    // Rethrow so UI can handle and display the error
    rethrow;
  }
});

// Sales data for charts (already uses date range)
final salesChartDataProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final range = ref.watch(dashboardDateRangeProvider);
  final repository = ref.watch(orderRepositoryProvider);
  final days = _getDaysForRange(range);
  return repository.getSalesByDate(days);
});
