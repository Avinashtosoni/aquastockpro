import '../models/order.dart';
import '../models/order_item.dart';
import '../../core/constants/supabase_config.dart';
import '../services/supabase_service.dart';
import '../services/connectivity_service.dart';

class OrderRepository {
  static final OrderRepository _instance = OrderRepository._internal();
  final ConnectivityService _connectivityService = ConnectivityService();

  factory OrderRepository() => _instance;
  OrderRepository._internal();

  void _checkConnection() {
    if (!_connectivityService.isOnline || !SupabaseService.isInitialized) {
      throw Exception('No internet connection. Please check your network and try again.');
    }
  }

  Future<List<Order>> getAll({int? limit, int? offset}) async {
    _checkConnection();
    
    var query = SupabaseService.client
        .from(SupabaseConfig.ordersTable)
        .select()
        .order('created_at', ascending: false);
    
    if (limit != null) {
      query = query.limit(limit);
    }
    
    final orderMaps = await query;
    final orders = <Order>[];
    
    if ((orderMaps as List).isEmpty) return orders;
    
    // Fetch ALL order items in ONE query (fixes N+1 problem)
    final orderIds = orderMaps.map((o) => o['id'] as String).toList();
    final allItemsResponse = await SupabaseService.client
        .from(SupabaseConfig.orderItemsTable)
        .select()
        .inFilter('order_id', orderIds);
    
    // Group items by order_id
    final itemsByOrderId = <String, List<OrderItem>>{};
    for (final itemMap in allItemsResponse as List) {
      final orderId = itemMap['order_id'] as String;
      itemsByOrderId.putIfAbsent(orderId, () => []);
      itemsByOrderId[orderId]!.add(OrderItem.fromMap(itemMap));
    }
    
    // Build orders with their items
    for (final orderMap in orderMaps) {
      final orderId = orderMap['id'] as String;
      final items = itemsByOrderId[orderId] ?? [];
      orders.add(Order.fromMap(orderMap, items: items));
    }
    
    return orders;
  }

  Future<Order?> getById(String id) async {
    _checkConnection();
    
    final response = await SupabaseService.client
        .from(SupabaseConfig.ordersTable)
        .select()
        .eq('id', id)
        .maybeSingle();
    
    if (response == null) return null;
    
    final items = await getOrderItems(id);
    return Order.fromMap(response, items: items);
  }

  Future<List<OrderItem>> getOrderItems(String orderId) async {
    _checkConnection();
    
    final response = await SupabaseService.client
        .from(SupabaseConfig.orderItemsTable)
        .select()
        .eq('order_id', orderId);
    
    return (response as List).map((map) => OrderItem.fromMap(map)).toList();
  }

  Future<Order> insert(Order order) async {
    _checkConnection();
    
    // Insert order
    await SupabaseService.client
        .from(SupabaseConfig.ordersTable)
        .insert(order.toMap());
    
    // Insert order items with correct orderId
    for (final item in order.items) {
      final itemMap = item.toMap();
      itemMap['order_id'] = order.id; // Ensure orderId is set correctly
      await SupabaseService.client
          .from(SupabaseConfig.orderItemsTable)
          .insert(itemMap);
    }
    
    return order;
  }

  Future<Order> update(Order order) async {
    _checkConnection();
    
    final orderMap = order.toMap();
    orderMap['updated_at'] = DateTime.now().toIso8601String();
    
    await SupabaseService.client
        .from(SupabaseConfig.ordersTable)
        .update(orderMap)
        .eq('id', order.id);
    
    // Delete existing items and re-insert
    await SupabaseService.client
        .from(SupabaseConfig.orderItemsTable)
        .delete()
        .eq('order_id', order.id);
    
    for (final item in order.items) {
      await SupabaseService.client
          .from(SupabaseConfig.orderItemsTable)
          .insert(item.toMap());
    }
    
    return order;
  }

  Future<void> delete(String id) async {
    _checkConnection();
    
    // Delete order items first
    await SupabaseService.client
        .from(SupabaseConfig.orderItemsTable)
        .delete()
        .eq('order_id', id);
    
    // Delete order
    await SupabaseService.client
        .from(SupabaseConfig.ordersTable)
        .delete()
        .eq('id', id);
  }

  Future<String> generateOrderNumber() async {
    _checkConnection();
    
    final today = DateTime.now();
    final datePrefix = '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';
    
    final response = await SupabaseService.client
        .from(SupabaseConfig.ordersTable)
        .select('order_number')
        .like('order_number', 'ORD-$datePrefix%');
    
    final count = (response as List).length + 1;
    return 'ORD-$datePrefix-${count.toString().padLeft(4, '0')}';
  }

  Future<List<Order>> getByDateRange(DateTime startDate, DateTime endDate) async {
    _checkConnection();
    
    final orderMaps = await SupabaseService.client
        .from(SupabaseConfig.ordersTable)
        .select()
        .gte('created_at', startDate.toIso8601String())
        .lte('created_at', endDate.toIso8601String())
        .order('created_at', ascending: false);
    
    if ((orderMaps as List).isEmpty) return [];
    
    // Batch fetch order items
    final orderIds = orderMaps.map((o) => o['id'] as String).toList();
    final allItemsResponse = await SupabaseService.client
        .from(SupabaseConfig.orderItemsTable)
        .select()
        .inFilter('order_id', orderIds);
    
    final itemsByOrderId = <String, List<OrderItem>>{};
    for (final itemMap in allItemsResponse as List) {
      final orderId = itemMap['order_id'] as String;
      itemsByOrderId.putIfAbsent(orderId, () => []);
      itemsByOrderId[orderId]!.add(OrderItem.fromMap(itemMap));
    }
    
    return orderMaps.map((orderMap) {
      final orderId = orderMap['id'] as String;
      return Order.fromMap(orderMap, items: itemsByOrderId[orderId] ?? []);
    }).toList();
  }

  Future<List<Order>> getByStatus(OrderStatus status) async {
    _checkConnection();
    
    final orderMaps = await SupabaseService.client
        .from(SupabaseConfig.ordersTable)
        .select()
        .eq('status', status.name)
        .order('created_at', ascending: false);
    
    if ((orderMaps as List).isEmpty) return [];
    
    // Batch fetch order items
    final orderIds = orderMaps.map((o) => o['id'] as String).toList();
    final allItemsResponse = await SupabaseService.client
        .from(SupabaseConfig.orderItemsTable)
        .select()
        .inFilter('order_id', orderIds);
    
    final itemsByOrderId = <String, List<OrderItem>>{};
    for (final itemMap in allItemsResponse as List) {
      final orderId = itemMap['order_id'] as String;
      itemsByOrderId.putIfAbsent(orderId, () => []);
      itemsByOrderId[orderId]!.add(OrderItem.fromMap(itemMap));
    }
    
    return orderMaps.map((orderMap) {
      final orderId = orderMap['id'] as String;
      return Order.fromMap(orderMap, items: itemsByOrderId[orderId] ?? []);
    }).toList();
  }

  Future<List<Order>> getByCustomer(String customerId) async {
    _checkConnection();
    
    final orderMaps = await SupabaseService.client
        .from(SupabaseConfig.ordersTable)
        .select()
        .eq('customer_id', customerId)
        .order('created_at', ascending: false);
    
    final orders = <Order>[];
    for (final orderMap in orderMaps as List) {
      final items = await getOrderItems(orderMap['id'] as String);
      orders.add(Order.fromMap(orderMap, items: items));
    }
    return orders;
  }

  // Dashboard Statistics
  Future<Map<String, dynamic>> getTodayStats() async {
    _checkConnection();
    
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final response = await SupabaseService.client
        .from(SupabaseConfig.ordersTable)
        .select('total_amount')
        .eq('status', 'completed')
        .gte('created_at', startOfDay.toIso8601String())
        .lt('created_at', endOfDay.toIso8601String());
    
    final orders = response as List;
    double totalSales = 0;
    for (final order in orders) {
      totalSales += (order['total_amount'] as num?)?.toDouble() ?? 0;
    }
    
    return {
      'orderCount': orders.length,
      'totalSales': totalSales,
      'averageOrder': orders.isEmpty ? 0.0 : totalSales / orders.length,
    };
  }

  /// Get stats for a specific number of days (for dashboard date range filter)
  Future<Map<String, dynamic>> getStatsByRange(int days) async {
    _checkConnection();
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = days == 1 ? today : today.subtract(Duration(days: days - 1));
    final endDate = today.add(const Duration(days: 1));
    
    final response = await SupabaseService.client
        .from(SupabaseConfig.ordersTable)
        .select('total_amount')
        .eq('status', 'completed')
        .gte('created_at', startDate.toIso8601String())
        .lt('created_at', endDate.toIso8601String());
    
    final orders = response as List;
    double totalSales = 0;
    for (final order in orders) {
      totalSales += (order['total_amount'] as num?)?.toDouble() ?? 0;
    }
    
    return {
      'orderCount': orders.length,
      'totalSales': totalSales,
      'averageOrder': orders.isEmpty ? 0.0 : totalSales / orders.length,
    };
  }

  Future<List<Map<String, dynamic>>> getSalesByDate(int days) async {
    _checkConnection();
    
    final startDate = DateTime.now().subtract(Duration(days: days));
    
    final response = await SupabaseService.client
        .from(SupabaseConfig.ordersTable)
        .select('created_at, total_amount')
        .eq('status', 'completed')
        .gte('created_at', startDate.toIso8601String())
        .order('created_at');
    
    // Group by date in Dart
    final Map<String, Map<String, dynamic>> groupedByDate = {};
    for (final item in response as List) {
      final date = DateTime.parse(item['created_at']).toIso8601String().substring(0, 10);
      if (!groupedByDate.containsKey(date)) {
        groupedByDate[date] = {'date': date, 'order_count': 0, 'total_sales': 0.0};
      }
      groupedByDate[date]!['order_count'] = (groupedByDate[date]!['order_count'] as int) + 1;
      groupedByDate[date]!['total_sales'] = (groupedByDate[date]!['total_sales'] as double) + 
          ((item['total_amount'] as num?)?.toDouble() ?? 0);
    }
    
    return groupedByDate.values.toList();
  }

  Future<List<Map<String, dynamic>>> getTopProducts(int limit) async {
    _checkConnection();
    
    // Get completed order IDs
    final ordersResponse = await SupabaseService.client
        .from(SupabaseConfig.ordersTable)
        .select('id')
        .eq('status', 'completed');
    
    final orderIds = (ordersResponse as List).map((o) => o['id'] as String).toList();
    
    if (orderIds.isEmpty) return [];
    
    // Get items for those orders
    final itemsResponse = await SupabaseService.client
        .from(SupabaseConfig.orderItemsTable)
        .select('product_id, product_name, quantity, total_price')
        .inFilter('order_id', orderIds);
    
    // Group by product
    final Map<String, Map<String, dynamic>> productStats = {};
    for (final item in itemsResponse as List) {
      final productId = item['product_id'] as String;
      if (!productStats.containsKey(productId)) {
        productStats[productId] = {
          'product_id': productId,
          'product_name': item['product_name'],
          'total_quantity': 0,
          'total_revenue': 0.0,
        };
      }
      productStats[productId]!['total_quantity'] = 
          (productStats[productId]!['total_quantity'] as int) + (item['quantity'] as int);
      productStats[productId]!['total_revenue'] = 
          (productStats[productId]!['total_revenue'] as double) + 
          ((item['total_price'] as num?)?.toDouble() ?? 0);
    }
    
    final sortedProducts = productStats.values.toList()
      ..sort((a, b) => (b['total_quantity'] as int).compareTo(a['total_quantity'] as int));
    
    return sortedProducts.take(limit).toList();
  }
}
