import 'package:flutter/foundation.dart' show debugPrint;
import '../models/category.dart';
import '../../core/constants/supabase_config.dart';
import '../services/supabase_service.dart';
import '../services/connectivity_service.dart';
import 'base_repository.dart';

class CategoryRepository extends BaseRepository<Category> {
  static final CategoryRepository _instance = CategoryRepository._internal();
  factory CategoryRepository() => _instance;
  CategoryRepository._internal();

  final ConnectivityService _connectivityService = ConnectivityService();

  @override
  String get supabaseTableName => SupabaseConfig.categoriesTable;

  @override
  Category fromMap(Map<String, dynamic> map) => Category.fromMap(map);

  @override
  Map<String, dynamic> toMap(Category item) => item.toMap();

  @override
  String getId(Category item) => item.id;

  @override
  Future<List<Category>> getAll() async {
    if (!_connectivityService.isOnline || !SupabaseService.isInitialized) {
      throw Exception('No internet connection. Please check your network and try again.');
    }
    
    try {
      debugPrint('CategoryRepository: Fetching all categories from Supabase...');
      final response = await SupabaseService.client
          .from(supabaseTableName)
          .select()
          .eq('is_active', true)
          .order('sort_order')
          .order('name');
      
      debugPrint('CategoryRepository: Got ${(response as List).length} categories');
      return (response).map((map) => Category.fromMap(map)).toList();
    } catch (e) {
      debugPrint('CategoryRepository ERROR: $e');
      rethrow;
    }
  }

  Future<List<Category>> getAllWithProductCount() async {
    if (!_connectivityService.isOnline || !SupabaseService.isInitialized) {
      throw Exception('No internet connection. Please check your network and try again.');
    }
    
    // Get categories
    final categories = await getAll();
    
    // Get product counts per category from Supabase
    final productsResponse = await SupabaseService.client
        .from(SupabaseConfig.productsTable)
        .select('category_id')
        .eq('is_active', true);
    
    // Count products per category
    final Map<String, int> productCounts = {};
    for (final product in productsResponse as List) {
      final catId = product['category_id'] as String?;
      if (catId != null) {
        productCounts[catId] = (productCounts[catId] ?? 0) + 1;
      }
    }
    
    // Return categories (product_count field will be handled in UI if needed)
    return categories;
  }

  Future<int> getProductCount(String categoryId) async {
    if (!_connectivityService.isOnline || !SupabaseService.isInitialized) {
      throw Exception('No internet connection. Please check your network and try again.');
    }
    
    final response = await SupabaseService.client
        .from(SupabaseConfig.productsTable)
        .select('id')
        .eq('category_id', categoryId)
        .eq('is_active', true);
    
    return (response as List).length;
  }

  Future<void> updateSortOrder(List<String> categoryIds) async {
    if (!_connectivityService.isOnline || !SupabaseService.isInitialized) {
      throw Exception('No internet connection. Please check your network and try again.');
    }
    
    for (var i = 0; i < categoryIds.length; i++) {
      await SupabaseService.client.from(supabaseTableName).update({
        'sort_order': i,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', categoryIds[i]);
    }
  }
}
