import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/product.dart';
import '../data/repositories/product_repository.dart';

final productRepositoryProvider = Provider((ref) => ProductRepository());

// All products (auto-dispose for proper refresh)
final productsProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getAll();
});

// Products by category (auto-dispose for proper refresh)
final productsByCategoryProvider = FutureProvider.autoDispose.family<List<Product>, String>((ref, categoryId) async {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getByCategory(categoryId);
});

// Search products
final productSearchProvider = FutureProvider.family<List<Product>, String>((ref, query) async {
  final repository = ref.watch(productRepositoryProvider);
  if (query.isEmpty) {
    return repository.getAll();
  }
  return repository.search(query);
});

// Low stock products
final lowStockProductsProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getLowStockProducts();
});

// Out of stock products
final outOfStockProductsProvider = FutureProvider<List<Product>>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getOutOfStockProducts();
});

// Product by ID
final productByIdProvider = FutureProvider.family<Product?, String>((ref, id) async {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getById(id);
});

// Product by barcode
final productByBarcodeProvider = FutureProvider.family<Product?, String>((ref, barcode) async {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getByBarcode(barcode);
});

// Product count
final productCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getTotalProductCount();
});

// Total inventory value
final inventoryValueProvider = FutureProvider.autoDispose<double>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getTotalInventoryValue();
});

// Selected category for POS
final selectedCategoryProvider = StateProvider<String>((ref) => 'all');

// Search query for POS
final productSearchQueryProvider = StateProvider<String>((ref) => '');

// Filtered products for POS
final filteredProductsProvider = FutureProvider<List<Product>>((ref) async {
  final categoryId = ref.watch(selectedCategoryProvider);
  final searchQuery = ref.watch(productSearchQueryProvider);
  final repository = ref.watch(productRepositoryProvider);
  
  if (searchQuery.isNotEmpty) {
    return repository.search(searchQuery);
  }
  return repository.getByCategory(categoryId);
});

// Product state notifier for CRUD operations
class ProductsNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  final Ref _ref;

  ProductsNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadProducts();
  }

  /// Invalidate all cached product providers to ensure fresh data everywhere
  void _invalidateAllProductProviders() {
    _ref.invalidate(productsProvider);
    _ref.invalidate(filteredProductsProvider);
    _ref.invalidate(lowStockProductsProvider);
    _ref.invalidate(outOfStockProductsProvider);
    _ref.invalidate(productCountProvider);
    _ref.invalidate(inventoryValueProvider);
    // Note: productsByCategoryProvider is family provider, invalidated on next access
  }

  Future<void> loadProducts() async {
    state = const AsyncValue.loading();
    try {
      final products = await _ref.read(productRepositoryProvider).getAll();
      state = AsyncValue.data(products);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addProduct(Product product) async {
    try {
      await _ref.read(productRepositoryProvider).insert(product);
      await loadProducts();
      _invalidateAllProductProviders(); // Refresh POS and other screens
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      await _ref.read(productRepositoryProvider).update(product);
      await loadProducts();
      _invalidateAllProductProviders(); // Refresh POS and other screens
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _ref.read(productRepositoryProvider).delete(id);
      await loadProducts();
      _invalidateAllProductProviders(); // Refresh POS and other screens
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateStock(String productId, int quantityChange) async {
    try {
      await _ref.read(productRepositoryProvider).updateStock(productId, quantityChange);
      await loadProducts();
      _invalidateAllProductProviders(); // Refresh POS and other screens
    } catch (e) {
      rethrow;
    }
  }
}

final productsNotifierProvider = StateNotifierProvider<ProductsNotifier, AsyncValue<List<Product>>>((ref) {
  return ProductsNotifier(ref);
});
