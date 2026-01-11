import '../models/purchase_order.dart';
import '../../core/constants/supabase_config.dart';
import '../services/supabase_service.dart';
import '../services/connectivity_service.dart';

class PurchaseOrderRepository {
  static final PurchaseOrderRepository _instance = PurchaseOrderRepository._internal();
  final ConnectivityService _connectivityService = ConnectivityService();

  factory PurchaseOrderRepository() => _instance;
  PurchaseOrderRepository._internal();

  void _checkConnection() {
    if (!_connectivityService.isOnline || !SupabaseService.isInitialized) {
      throw Exception('No internet connection. Please check your network and try again.');
    }
  }

  Future<List<PurchaseOrder>> getAll({int? limit, int? offset}) async {
    _checkConnection();
    
    var query = SupabaseService.client
        .from(SupabaseConfig.purchaseOrdersTable)
        .select()
        .order('created_at', ascending: false);
    
    if (limit != null) {
      query = query.limit(limit);
    }
    
    final orderMaps = await query;
    final orders = <PurchaseOrder>[];
    
    for (final orderMap in orderMaps as List) {
      final items = await getOrderItems(orderMap['id'] as String);
      orders.add(PurchaseOrder.fromJson({...orderMap, 'items': items.map((i) => i.toJson()).toList()}));
    }
    
    return orders;
  }

  Future<PurchaseOrder?> getById(String id) async {
    _checkConnection();
    
    final response = await SupabaseService.client
        .from(SupabaseConfig.purchaseOrdersTable)
        .select()
        .eq('id', id)
        .maybeSingle();
    
    if (response == null) return null;
    
    final items = await getOrderItems(id);
    return PurchaseOrder.fromJson({...response, 'items': items.map((i) => i.toJson()).toList()});
  }

  Future<List<PurchaseOrderItem>> getOrderItems(String orderId) async {
    _checkConnection();
    
    final response = await SupabaseService.client
        .from(SupabaseConfig.purchaseOrderItemsTable)
        .select()
        .eq('purchase_order_id', orderId);
    
    return (response as List).map((map) => PurchaseOrderItem.fromJson(map)).toList();
  }

  Future<PurchaseOrder> insert(PurchaseOrder order) async {
    _checkConnection();
    
    // Insert order
    final orderMap = order.toJson();
    orderMap.remove('items');
    await SupabaseService.client
        .from(SupabaseConfig.purchaseOrdersTable)
        .insert(orderMap);
    
    // Insert order items
    for (final item in order.items) {
      final itemMap = item.toJson();
      itemMap['purchase_order_id'] = order.id;
      await SupabaseService.client
          .from(SupabaseConfig.purchaseOrderItemsTable)
          .insert(itemMap);
    }
    
    return order;
  }

  Future<PurchaseOrder> update(PurchaseOrder order) async {
    _checkConnection();
    
    final orderMap = order.toJson();
    orderMap.remove('items');
    orderMap['updated_at'] = DateTime.now().toIso8601String();
    
    await SupabaseService.client
        .from(SupabaseConfig.purchaseOrdersTable)
        .update(orderMap)
        .eq('id', order.id);
    
    // Update order items - delete and re-insert
    await SupabaseService.client
        .from(SupabaseConfig.purchaseOrderItemsTable)
        .delete()
        .eq('purchase_order_id', order.id);
    
    for (final item in order.items) {
      final itemMap = item.toJson();
      itemMap['purchase_order_id'] = order.id;
      await SupabaseService.client
          .from(SupabaseConfig.purchaseOrderItemsTable)
          .insert(itemMap);
    }
    
    return order;
  }

  Future<void> delete(String id) async {
    _checkConnection();
    
    // Delete order items first
    await SupabaseService.client
        .from(SupabaseConfig.purchaseOrderItemsTable)
        .delete()
        .eq('purchase_order_id', id);
    
    // Delete order
    await SupabaseService.client
        .from(SupabaseConfig.purchaseOrdersTable)
        .delete()
        .eq('id', id);
  }

  Future<List<PurchaseOrder>> getByStatus(PurchaseOrderStatus status) async {
    _checkConnection();
    
    final orderMaps = await SupabaseService.client
        .from(SupabaseConfig.purchaseOrdersTable)
        .select()
        .eq('status', status.name)
        .order('created_at', ascending: false);
    
    final orders = <PurchaseOrder>[];
    for (final orderMap in orderMaps as List) {
      final items = await getOrderItems(orderMap['id'] as String);
      orders.add(PurchaseOrder.fromJson({...orderMap, 'items': items.map((i) => i.toJson()).toList()}));
    }
    return orders;
  }

  Future<List<PurchaseOrder>> getBySupplier(String supplierId) async {
    _checkConnection();
    
    final orderMaps = await SupabaseService.client
        .from(SupabaseConfig.purchaseOrdersTable)
        .select()
        .eq('supplier_id', supplierId)
        .order('created_at', ascending: false);
    
    final orders = <PurchaseOrder>[];
    for (final orderMap in orderMaps as List) {
      final items = await getOrderItems(orderMap['id'] as String);
      orders.add(PurchaseOrder.fromJson({...orderMap, 'items': items.map((i) => i.toJson()).toList()}));
    }
    return orders;
  }

  Future<String> generateOrderNumber() async {
    _checkConnection();
    
    final today = DateTime.now();
    final datePrefix = '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';
    
    final response = await SupabaseService.client
        .from(SupabaseConfig.purchaseOrdersTable)
        .select('order_number')
        .like('order_number', 'PO-$datePrefix%');
    
    final count = (response as List).length + 1;
    return 'PO-$datePrefix-${count.toString().padLeft(3, '0')}';
  }
}
