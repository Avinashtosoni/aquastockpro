import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/supplier.dart';
import '../data/repositories/supplier_repository.dart';

// Supplier repository provider
final supplierRepositoryProvider = Provider<SupplierRepository>((ref) {
  return SupplierRepository();
});

// All suppliers provider
final suppliersNotifierProvider = AsyncNotifierProvider<SuppliersNotifier, List<Supplier>>(() {
  return SuppliersNotifier();
});

class SuppliersNotifier extends AsyncNotifier<List<Supplier>> {
  @override
  Future<List<Supplier>> build() async {
    try {
      return await SupplierRepository().getAll();
    } catch (e, _) {
      // Re-throw to let AsyncValue handle the error state
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final suppliers = await SupplierRepository().getAll();
      state = AsyncData(suppliers);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> addSupplier(Supplier supplier) async {
    await SupplierRepository().insert(supplier);
    await refresh();
  }

  Future<void> updateSupplier(Supplier supplier) async {
    await SupplierRepository().update(supplier);
    await refresh();
  }

  Future<void> deleteSupplier(String id) async {
    await SupplierRepository().delete(id);
    await refresh();
  }
}

// Total outstanding to suppliers
final totalOutstandingToSuppliersProvider = FutureProvider<double>((ref) async {
  return await SupplierRepository().getTotalOutstanding();
});

// Search suppliers
final supplierSearchProvider = FutureProvider.family<List<Supplier>, String>((ref, query) async {
  if (query.isEmpty) return await SupplierRepository().getAll();
  return await SupplierRepository().search(query);
});
