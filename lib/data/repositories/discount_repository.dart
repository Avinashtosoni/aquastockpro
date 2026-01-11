import '../models/discount.dart';
import '../../core/constants/supabase_config.dart';
import '../services/supabase_service.dart';
import '../services/connectivity_service.dart';
import 'base_repository.dart';

class DiscountRepository extends BaseRepository<Discount> {
  static final DiscountRepository _instance = DiscountRepository._internal();
  factory DiscountRepository() => _instance;
  DiscountRepository._internal();

  final ConnectivityService _connectivityService = ConnectivityService();

  @override
  String get supabaseTableName => SupabaseConfig.discountsTable;

  @override
  Discount fromMap(Map<String, dynamic> map) => Discount.fromMap(map);

  @override
  Map<String, dynamic> toMap(Discount item) => item.toMap();

  @override
  String getId(Discount item) => item.id;

  void _checkConnection() {
    if (!_connectivityService.isOnline || !SupabaseService.isInitialized) {
      throw Exception('No internet connection. Please check your network and try again.');
    }
  }

  /// Get all active discounts
  Future<List<Discount>> getActiveDiscounts() async {
    _checkConnection();
    
    final now = DateTime.now().toIso8601String();
    
    // Get all discounts and filter in Dart for complex date logic
    final response = await SupabaseService.client
        .from(supabaseTableName)
        .select()
        .eq('is_active', true)
        .order('created_at', ascending: false);
    
    return (response as List)
        .map((map) => Discount.fromMap(map))
        .where((d) => d.isValid)
        .toList();
  }

  /// Validate and get discount by code
  Future<Discount?> validateCode(String code) async {
    _checkConnection();
    
    final response = await SupabaseService.client
        .from(supabaseTableName)
        .select()
        .eq('code', code.toUpperCase())
        .eq('is_active', true)
        .maybeSingle();
    
    if (response == null) return null;
    
    final discount = Discount.fromMap(response);
    return discount.isValid ? discount : null;
  }

  /// Get discounts applicable to a product
  Future<List<Discount>> getForProduct(String productId, String categoryId) async {
    final activeDiscounts = await getActiveDiscounts();
    
    return activeDiscounts
        .where((d) => d.appliesToProduct(productId, categoryId))
        .toList();
  }

  /// Increment usage count
  Future<void> incrementUsage(String discountId) async {
    _checkConnection();
    
    final discount = await getById(discountId);
    if (discount == null) return;
    
    await SupabaseService.client.from(supabaseTableName).update({
      'usage_count': discount.usageCount + 1,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', discountId);
  }

  /// Get discounts by type
  Future<List<Discount>> getByType(DiscountType type) async {
    _checkConnection();
    
    final response = await SupabaseService.client
        .from(supabaseTableName)
        .select()
        .eq('type', type.name)
        .order('created_at', ascending: false);
    
    return (response as List).map((map) => Discount.fromMap(map)).toList();
  }

  /// Get expired discounts
  Future<List<Discount>> getExpiredDiscounts() async {
    _checkConnection();
    
    final now = DateTime.now().toIso8601String();
    
    final response = await SupabaseService.client
        .from(supabaseTableName)
        .select()
        .not('valid_until', 'is', null)
        .lt('valid_until', now)
        .order('valid_until', ascending: false);
    
    return (response as List).map((map) => Discount.fromMap(map)).toList();
  }

  /// Get discounts expiring soon (within days)
  Future<List<Discount>> getExpiringSoon({int days = 7}) async {
    _checkConnection();
    
    final now = DateTime.now();
    final threshold = now.add(Duration(days: days)).toIso8601String();
    
    final response = await SupabaseService.client
        .from(supabaseTableName)
        .select()
        .eq('is_active', true)
        .not('valid_until', 'is', null)
        .gte('valid_until', now.toIso8601String())
        .lte('valid_until', threshold)
        .order('valid_until');
    
    return (response as List).map((map) => Discount.fromMap(map)).toList();
  }

  /// Deactivate discount
  Future<void> deactivate(String discountId) async {
    _checkConnection();
    
    await SupabaseService.client.from(supabaseTableName).update({
      'is_active': false,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', discountId);
  }

  /// Get discount statistics
  Future<Map<String, dynamic>> getStats() async {
    _checkConnection();
    
    final allResponse = await SupabaseService.client
        .from(supabaseTableName)
        .select('is_active, usage_count');
    
    final all = allResponse as List;
    int total = all.length;
    int active = all.where((d) => d['is_active'] == true).length;
    int totalUsage = 0;
    for (final d in all) {
      totalUsage += (d['usage_count'] as int?) ?? 0;
    }
    
    return {
      'total': total,
      'active': active,
      'totalUsage': totalUsage,
    };
  }
}
