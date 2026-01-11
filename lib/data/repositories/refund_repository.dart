import '../models/refund.dart';
import '../models/refund_item.dart';
import '../../core/constants/supabase_config.dart';
import '../services/supabase_service.dart';
import '../services/connectivity_service.dart';
import 'base_repository.dart';

class RefundRepository extends BaseRepository<Refund> {
  static final RefundRepository _instance = RefundRepository._internal();
  factory RefundRepository() => _instance;
  RefundRepository._internal();

  final ConnectivityService _connectivityService = ConnectivityService();

  @override
  String get supabaseTableName => SupabaseConfig.refundsTable;

  @override
  Refund fromMap(Map<String, dynamic> map) => Refund.fromMap(map);

  @override
  Map<String, dynamic> toMap(Refund item) => item.toMap();

  @override
  String getId(Refund item) => item.id;

  void _checkConnection() {
    if (!_connectivityService.isOnline || !SupabaseService.isInitialized) {
      throw Exception('No internet connection. Please check your network and try again.');
    }
  }

  /// Get refund with its items
  Future<Refund?> getByIdWithItems(String id) async {
    _checkConnection();
    
    final refundResponse = await SupabaseService.client
        .from(supabaseTableName)
        .select()
        .eq('id', id)
        .maybeSingle();
    
    if (refundResponse == null) return null;
    
    final itemsResponse = await SupabaseService.client
        .from(SupabaseConfig.refundItemsTable)
        .select()
        .eq('refund_id', id);
    
    final items = (itemsResponse as List).map((map) => RefundItem.fromMap(map)).toList();
    return Refund.fromMap(refundResponse, items: items);
  }

  /// Get all refunds for an order
  Future<List<Refund>> getByOrderId(String orderId) async {
    _checkConnection();
    
    final response = await SupabaseService.client
        .from(supabaseTableName)
        .select()
        .eq('order_id', orderId)
        .order('created_at', ascending: false);
    
    return (response as List).map((map) => Refund.fromMap(map)).toList();
  }

  /// Get refund with items for an order
  Future<Refund?> getByOrderIdWithItems(String orderId) async {
    _checkConnection();
    
    final refundResponse = await SupabaseService.client
        .from(supabaseTableName)
        .select()
        .eq('order_id', orderId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    
    if (refundResponse == null) return null;
    
    final refundId = refundResponse['id'];
    final itemsResponse = await SupabaseService.client
        .from(SupabaseConfig.refundItemsTable)
        .select()
        .eq('refund_id', refundId);
    
    final items = (itemsResponse as List).map((map) => RefundItem.fromMap(map)).toList();
    return Refund.fromMap(refundResponse, items: items);
  }

  /// Get all refunds for a customer
  Future<List<Refund>> getByCustomerId(String customerId) async {
    _checkConnection();
    
    final response = await SupabaseService.client
        .from(supabaseTableName)
        .select()
        .eq('customer_id', customerId)
        .order('created_at', ascending: false);
    
    return (response as List).map((map) => Refund.fromMap(map)).toList();
  }

  /// Get refunds by status
  Future<List<Refund>> getByStatus(RefundStatus status) async {
    _checkConnection();
    
    final response = await SupabaseService.client
        .from(supabaseTableName)
        .select()
        .eq('status', status.name)
        .order('created_at', ascending: false);
    
    return (response as List).map((map) => Refund.fromMap(map)).toList();
  }

  /// Get refunds within a date range
  Future<List<Refund>> getByDateRange(DateTime start, DateTime end) async {
    _checkConnection();
    
    final response = await SupabaseService.client
        .from(supabaseTableName)
        .select()
        .gte('created_at', start.toIso8601String())
        .lte('created_at', end.toIso8601String())
        .order('created_at', ascending: false);
    
    return (response as List).map((map) => Refund.fromMap(map)).toList();
  }

  /// Create refund with items
  Future<Refund> createWithItems(Refund refund, List<RefundItem> items) async {
    _checkConnection();
    
    try {
      // Insert refund
      await SupabaseService.client
          .from(supabaseTableName)
          .insert(refund.toMap());
      
      // Insert refund items
      for (final item in items) {
        await SupabaseService.client
            .from(SupabaseConfig.refundItemsTable)
            .insert(item.toMap());
      }
      
      return refund.copyWith(items: items);
    } catch (e) {
      // Provide helpful error message
      throw Exception('Failed to create refund: $e. Make sure to run the database migration for refunds table.');
    }
  }

  /// Update refund status
  Future<void> updateStatus(String refundId, RefundStatus status, {DateTime? processedAt}) async {
    _checkConnection();
    
    final updates = <String, dynamic>{
      'status': status.name,
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    if (processedAt != null || status == RefundStatus.completed) {
      updates['processed_at'] = (processedAt ?? DateTime.now()).toIso8601String();
    }
    
    await SupabaseService.client
        .from(supabaseTableName)
        .update(updates)
        .eq('id', refundId);
  }

  /// Update refund item restock status
  Future<void> updateItemRestockStatus(String itemId, RestockStatus status) async {
    _checkConnection();
    
    await SupabaseService.client
        .from(SupabaseConfig.refundItemsTable)
        .update({'restock_status': status.name})
        .eq('id', itemId);
  }

  /// Get items for a refund
  Future<List<RefundItem>> getRefundItems(String refundId) async {
    _checkConnection();
    
    final response = await SupabaseService.client
        .from(SupabaseConfig.refundItemsTable)
        .select()
        .eq('refund_id', refundId);
    
    return (response as List).map((map) => RefundItem.fromMap(map)).toList();
  }

  /// Get total refund amount for date range
  Future<double> getTotalRefundAmount(DateTime start, DateTime end) async {
    _checkConnection();
    
    final response = await SupabaseService.client
        .from(supabaseTableName)
        .select('amount')
        .eq('status', 'completed')
        .gte('created_at', start.toIso8601String())
        .lte('created_at', end.toIso8601String());
    
    double total = 0;
    for (final row in response as List) {
      total += (row['amount'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  /// Get refund count by status
  Future<Map<RefundStatus, int>> getCountByStatus() async {
    _checkConnection();
    
    final response = await SupabaseService.client
        .from(supabaseTableName)
        .select('status');
    
    final counts = <RefundStatus, int>{};
    for (final row in response as List) {
      final status = RefundStatus.values.firstWhere(
        (e) => e.name == row['status'],
        orElse: () => RefundStatus.pending,
      );
      counts[status] = (counts[status] ?? 0) + 1;
    }
    return counts;
  }
}
