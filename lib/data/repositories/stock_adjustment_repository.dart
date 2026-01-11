import '../models/stock_adjustment.dart';
import '../models/product.dart';
import '../../core/constants/supabase_config.dart';
import '../services/supabase_service.dart';
import '../services/connectivity_service.dart';

class StockAdjustmentRepository {
  static final StockAdjustmentRepository _instance = StockAdjustmentRepository._internal();
  factory StockAdjustmentRepository() => _instance;
  StockAdjustmentRepository._internal();

  final ConnectivityService _connectivityService = ConnectivityService();
  String get supabaseTableName => SupabaseConfig.stockAdjustmentsTable;

  void _checkConnection() {
    if (!_connectivityService.isOnline || !SupabaseService.isInitialized) {
      throw Exception('No internet connection. Please check your network and try again.');
    }
  }

  Future<List<StockAdjustment>> getAll({int? limit}) async {
    _checkConnection();
    
    var query = SupabaseService.client
        .from(supabaseTableName)
        .select()
        .order('created_at', ascending: false);
    
    if (limit != null) {
      query = query.limit(limit);
    }
    
    final response = await query;
    return (response as List).map((map) => StockAdjustment.fromMap(map)).toList();
  }

  Future<List<StockAdjustment>> getByProduct(String productId) async {
    _checkConnection();
    
    final response = await SupabaseService.client
        .from(supabaseTableName)
        .select()
        .eq('product_id', productId)
        .order('created_at', ascending: false);
    
    return (response as List).map((map) => StockAdjustment.fromMap(map)).toList();
  }

  Future<List<StockAdjustment>> getByDateRange(DateTime start, DateTime end) async {
    _checkConnection();
    
    final response = await SupabaseService.client
        .from(supabaseTableName)
        .select()
        .gte('created_at', start.toIso8601String())
        .lte('created_at', end.toIso8601String())
        .order('created_at', ascending: false);
    
    return (response as List).map((map) => StockAdjustment.fromMap(map)).toList();
  }

  /// Create stock adjustment and update product quantity
  Future<StockAdjustment> createAdjustment({
    required Product product,
    required int adjustedQuantity,
    required StockAdjustmentReason reason,
    required String employeeId,
    required String employeeName,
    String? notes,
  }) async {
    _checkConnection();
    
    final previousQuantity = product.stockQuantity;
    final newQuantity = previousQuantity + adjustedQuantity;

    // Create adjustment record
    final adjustment = StockAdjustment(
      productId: product.id,
      productName: product.name,
      previousQuantity: previousQuantity,
      adjustedQuantity: adjustedQuantity,
      newQuantity: newQuantity,
      reason: reason,
      notes: notes,
      employeeId: employeeId,
      employeeName: employeeName,
    );

    await SupabaseService.client
        .from(supabaseTableName)
        .insert(adjustment.toMap());

    // Update product stock
    await SupabaseService.client
        .from(SupabaseConfig.productsTable)
        .update({
          'stock_quantity': newQuantity,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', product.id);

    return adjustment;
  }

  Future<List<StockAdjustment>> getByReason(StockAdjustmentReason reason) async {
    _checkConnection();
    
    final response = await SupabaseService.client
        .from(supabaseTableName)
        .select()
        .eq('reason', reason.name)
        .order('created_at', ascending: false);
    
    return (response as List).map((map) => StockAdjustment.fromMap(map)).toList();
  }

  Future<Map<String, int>> getSummaryByReason({DateTime? startDate, DateTime? endDate}) async {
    _checkConnection();
    
    var query = SupabaseService.client
        .from(supabaseTableName)
        .select('reason, adjusted_quantity');
    
    if (startDate != null && endDate != null) {
      query = query
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());
    }
    
    final response = await query;
    
    Map<String, int> summary = {};
    for (final row in response as List) {
      final reason = row['reason'] as String;
      final qty = ((row['adjusted_quantity'] as int?) ?? 0).abs();
      summary[reason] = (summary[reason] ?? 0) + qty;
    }
    return summary;
  }
}
