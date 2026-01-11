import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../../core/constants/supabase_config.dart';
import '../services/supabase_service.dart';
import '../services/connectivity_service.dart';
import 'base_repository.dart';

class ProductRepository extends BaseRepository<Product> {
  static final ProductRepository _instance = ProductRepository._internal();
  factory ProductRepository() => _instance;
  ProductRepository._internal();

  final ConnectivityService _connectivityService = ConnectivityService();

  @override
  String get supabaseTableName => SupabaseConfig.productsTable;

  @override
  Product fromMap(Map<String, dynamic> map) => Product.fromMap(map);

  @override
  Map<String, dynamic> toMap(Product item) => item.toMap();

  @override
  String getId(Product item) => item.id;

  /// Override getAll to only fetch active products
  @override
  Future<List<Product>> getAll() async {
    if (!_connectivityService.isOnline || !SupabaseService.isInitialized) {
      throw Exception('No internet connection. Please check your network and try again.');
    }
    
    try {
      final response = await SupabaseService.client
          .from(supabaseTableName)
          .select()
          .eq('is_active', true)
          .order('name');
      
      return (response as List).map((map) => Product.fromMap(map)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Product>> getByCategory(String categoryId) async {
    if (!_connectivityService.isOnline || !SupabaseService.isInitialized) {
      throw Exception('No internet connection. Please check your network and try again.');
    }
    
    final query = SupabaseService.client.from(supabaseTableName).select();
    
    if (categoryId == 'all') {
      final response = await query.eq('is_active', true).order('name');
      return (response as List).map((map) => Product.fromMap(map)).toList();
    } else {
      final response = await query.eq('is_active', true).eq('category_id', categoryId).order('name');
      return (response as List).map((map) => Product.fromMap(map)).toList();
    }
  }

  Future<List<Product>> search(String queryText) async {
    if (!_connectivityService.isOnline || !SupabaseService.isInitialized) {
      throw Exception('No internet connection. Please check your network and try again.');
    }
    
    final response = await SupabaseService.client
        .from(supabaseTableName)
        .select()
        .eq('is_active', true)
        .or('name.ilike.%$queryText%,sku.ilike.%$queryText%,barcode.ilike.%$queryText%')
        .order('name');
    
    return (response as List).map((map) => Product.fromMap(map)).toList();
  }

  Future<Product?> getByBarcode(String barcode) async {
    if (!_connectivityService.isOnline || !SupabaseService.isInitialized) {
      throw Exception('No internet connection. Please check your network and try again.');
    }
    
    final response = await SupabaseService.client
        .from(supabaseTableName)
        .select()
        .eq('barcode', barcode)
        .eq('is_active', true)
        .maybeSingle();
    
    if (response == null) return null;
    return Product.fromMap(response);
  }

  Future<List<Product>> getLowStockProducts() async {
    if (!_connectivityService.isOnline || !SupabaseService.isInitialized) {
      throw Exception('No internet connection. Please check your network and try again.');
    }
    
    // Get all active products that track inventory and filter low stock in Dart
    final response = await SupabaseService.client
        .from(supabaseTableName)
        .select()
        .eq('is_active', true)
        .eq('track_inventory', true)
        .order('stock_quantity');
    
    return (response as List)
        .map((map) => Product.fromMap(map))
        .where((p) => p.stockQuantity <= p.lowStockThreshold)
        .toList();
  }

  Future<List<Product>> getOutOfStockProducts() async {
    if (!_connectivityService.isOnline || !SupabaseService.isInitialized) {
      throw Exception('No internet connection. Please check your network and try again.');
    }
    
    final response = await SupabaseService.client
        .from(supabaseTableName)
        .select()
        .eq('is_active', true)
        .eq('track_inventory', true)
        .lte('stock_quantity', 0)
        .order('name');
    
    return (response as List).map((map) => Product.fromMap(map)).toList();
  }

  Future<void> updateStock(String productId, int quantityChange) async {
    if (!_connectivityService.isOnline || !SupabaseService.isInitialized) {
      throw Exception('No internet connection. Please check your network and try again.');
    }
    
    // Get current product, update stock, and save
    final product = await getById(productId);
    if (product == null) throw Exception('Product not found');
    
    await SupabaseService.client.from(supabaseTableName).update({
      'stock_quantity': product.stockQuantity + quantityChange,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', productId);
  }

  Future<int> getTotalProductCount() async {
    if (!_connectivityService.isOnline || !SupabaseService.isInitialized) {
      throw Exception('No internet connection. Please check your network and try again.');
    }
    
    final response = await SupabaseService.client
        .from(supabaseTableName)
        .select('id')
        .eq('is_active', true);
    
    return (response as List).length;
  }

  Future<double> getTotalInventoryValue() async {
    if (!_connectivityService.isOnline || !SupabaseService.isInitialized) {
      throw Exception('No internet connection. Please check your network and try again.');
    }
    
    final response = await SupabaseService.client
        .from(supabaseTableName)
        .select('price, stock_quantity')
        .eq('is_active', true)
        .eq('track_inventory', true);
    
    double total = 0;
    for (final item in response as List) {
      final price = (item['price'] as num?)?.toDouble() ?? 0;
      final quantity = (item['stock_quantity'] as num?)?.toInt() ?? 0;
      total += price * quantity;
    }
    return total;
  }

  /// Upload product image to Supabase storage
  Future<String?> uploadProductImage(List<int> imageBytes, String fileName) async {
    if (!_connectivityService.isOnline) {
      debugPrint('ProductRepository.uploadProductImage: No internet connection');
      return null;
    }
    
    if (!SupabaseService.isInitialized) {
      debugPrint('ProductRepository.uploadProductImage: Supabase not initialized');
      return null;
    }

    try {
      final path = 'products/$fileName';
      debugPrint('ProductRepository.uploadProductImage: Uploading to ${SupabaseConfig.productImagesBucket}/$path');
      
      final publicUrl = await SupabaseService.uploadImage(
        SupabaseConfig.productImagesBucket,
        path,
        imageBytes,
      );
      
      debugPrint('ProductRepository.uploadProductImage: SUCCESS - $publicUrl');
      return publicUrl;
    } catch (e, stackTrace) {
      debugPrint('ProductRepository.uploadProductImage ERROR: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Check if a product name already exists (for duplicate validation)
  /// Returns true if duplicate exists, false otherwise
  Future<bool> checkDuplicateName(String name, {String? excludeId}) async {
    if (!_connectivityService.isOnline || !SupabaseService.isInitialized) {
      return false; // Return false to not block form when offline
    }
    
    try {
      final response = await SupabaseService.client
          .from(supabaseTableName)
          .select('id')
          .ilike('name', name.trim());
      
      // Filter out the current product if editing
      final duplicates = (response as List).where((item) => 
        excludeId == null || item['id'] != excludeId
      ).toList();
      
      return duplicates.isNotEmpty;
    } catch (e) {
      debugPrint('ProductRepository.checkDuplicateName ERROR: $e');
      return false;
    }
  }

  /// Check if a SKU already exists (for duplicate validation)
  /// Returns true if duplicate exists, false otherwise
  Future<bool> checkDuplicateSku(String sku, {String? excludeId}) async {
    if (!_connectivityService.isOnline || !SupabaseService.isInitialized) {
      return false;
    }
    
    if (sku.trim().isEmpty) return false;
    
    try {
      final response = await SupabaseService.client
          .from(supabaseTableName)
          .select('id')
          .ilike('sku', sku.trim());
      
      final duplicates = (response as List).where((item) => 
        excludeId == null || item['id'] != excludeId
      ).toList();
      
      return duplicates.isNotEmpty;
    } catch (e) {
      debugPrint('ProductRepository.checkDuplicateSku ERROR: $e');
      return false;
    }
  }

  /// Check if a barcode already exists (for duplicate validation)
  /// Returns true if duplicate exists, false otherwise
  Future<bool> checkDuplicateBarcode(String barcode, {String? excludeId}) async {
    if (!_connectivityService.isOnline || !SupabaseService.isInitialized) {
      return false;
    }
    
    if (barcode.trim().isEmpty) return false;
    
    try {
      final response = await SupabaseService.client
          .from(supabaseTableName)
          .select('id')
          .eq('barcode', barcode.trim());
      
      final duplicates = (response as List).where((item) => 
        excludeId == null || item['id'] != excludeId
      ).toList();
      
      return duplicates.isNotEmpty;
    } catch (e) {
      debugPrint('ProductRepository.checkDuplicateBarcode ERROR: $e');
      return false;
    }
  }

  /// Delete product image from Supabase storage
  Future<bool> deleteProductImage(String imageUrl) async {
    if (!_connectivityService.isOnline || !SupabaseService.isInitialized) {
      return false;
    }

    try {
      // Extract path from URL
      // URL format: https://xxxx.supabase.co/storage/v1/object/public/product-images/products/filename.jpg
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      final bucketIndex = pathSegments.indexOf(SupabaseConfig.productImagesBucket);
      if (bucketIndex == -1) return false;
      
      final imagePath = pathSegments.sublist(bucketIndex + 1).join('/');
      debugPrint('ProductRepository.deleteProductImage: Deleting $imagePath');
      
      await SupabaseService.deleteImage(SupabaseConfig.productImagesBucket, imagePath);
      debugPrint('ProductRepository.deleteProductImage: SUCCESS');
      return true;
    } catch (e) {
      debugPrint('ProductRepository.deleteProductImage ERROR: $e');
      return false;
    }
  }
}
