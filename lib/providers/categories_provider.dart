import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/category.dart';
import '../data/repositories/category_repository.dart';

final categoryRepositoryProvider = Provider((ref) => CategoryRepository());

// All categories (cached with keepAlive)
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  ref.keepAlive(); // Cache categories
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getAll();
});

// Category by ID
final categoryByIdProvider = FutureProvider.family<Category?, String>((ref, id) async {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getById(id);
});

// Categories notifier for CRUD
class CategoriesNotifier extends StateNotifier<AsyncValue<List<Category>>> {
  final Ref _ref;

  CategoriesNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadCategories();
  }

  Future<void> loadCategories() async {
    state = const AsyncValue.loading();
    try {
      final categories = await _ref.read(categoryRepositoryProvider).getAll();
      state = AsyncValue.data(categories);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addCategory(Category category) async {
    try {
      await _ref.read(categoryRepositoryProvider).insert(category);
      await loadCategories();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateCategory(Category category) async {
    try {
      await _ref.read(categoryRepositoryProvider).update(category);
      await loadCategories();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await _ref.read(categoryRepositoryProvider).delete(id);
      await loadCategories();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> reorderCategories(List<Category> categories) async {
    try {
      final categoryIds = categories.map((c) => c.id).toList();
      await _ref.read(categoryRepositoryProvider).updateSortOrder(categoryIds);
      await loadCategories();
    } catch (e) {
      rethrow;
    }
  }
}

final categoriesNotifierProvider = StateNotifierProvider<CategoriesNotifier, AsyncValue<List<Category>>>((ref) {
  return CategoriesNotifier(ref);
});

// Categories with "All" option for POS screen (cached)
final categoriesWithAllProvider = FutureProvider<List<Category>>((ref) async {
  ref.keepAlive(); // Cache for faster POS loading
  final categories = await ref.watch(categoriesProvider.future);
  return [Category.allCategory, ...categories];
});
