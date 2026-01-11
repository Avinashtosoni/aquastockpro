import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/customer.dart';
import '../data/models/credit_transaction.dart';
import '../data/repositories/customer_repository.dart';

final customerRepositoryProvider = Provider((ref) => CustomerRepository());

// All customers
final customersProvider = FutureProvider<List<Customer>>((ref) async {
  final repository = ref.watch(customerRepositoryProvider);
  return repository.getAll();
});

// Search customers
final customerSearchProvider = FutureProvider.family<List<Customer>, String>((ref, query) async {
  final repository = ref.watch(customerRepositoryProvider);
  if (query.isEmpty) {
    return repository.getAll();
  }
  return repository.search(query);
});

// Selected customer for POS
final selectedCustomerProvider = StateProvider<Customer?>((ref) => null);

// Customers notifier for CRUD - using AsyncNotifier like EmployeesNotifier
final customersNotifierProvider = AsyncNotifierProvider<CustomersNotifier, List<Customer>>(() {
  return CustomersNotifier();
});

class CustomersNotifier extends AsyncNotifier<List<Customer>> {
  @override
  Future<List<Customer>> build() async {
    try {
      return await CustomerRepository().getAll();
    } catch (e, _) {
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final customers = await CustomerRepository().getAll();
      state = AsyncData(customers);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> addCustomer(Customer customer) async {
    await CustomerRepository().insert(customer);
    await refresh();
  }

  Future<void> updateCustomer(Customer customer) async {
    await CustomerRepository().update(customer);
    await refresh();
  }

  Future<void> deleteCustomer(String id) async {
    await CustomerRepository().delete(id);
    await refresh();
  }

  // ================== CREDIT SYSTEM METHODS ==================

  Future<CreditTransaction> addCredit({
    required String customerId,
    required double amount,
    String? orderId,
    String? notes,
    String? collectedBy,
  }) async {
    final transaction = await CustomerRepository().addCredit(
      customerId: customerId,
      amount: amount,
      orderId: orderId,
      notes: notes,
      collectedBy: collectedBy,
    );
    await refresh();
    return transaction;
  }

  Future<CreditTransaction> receivePayment({
    required String customerId,
    required double amount,
    String? notes,
    String? collectedBy,
  }) async {
    final transaction = await CustomerRepository().receivePayment(
      customerId: customerId,
      amount: amount,
      notes: notes,
      collectedBy: collectedBy,
    );
    await refresh();
    return transaction;
  }

  Future<void> updateCreditLimit(String customerId, double newLimit) async {
    await CustomerRepository().updateCreditLimit(customerId, newLimit);
    await refresh();
  }
}

// Customers with outstanding credit
final customersWithCreditProvider = FutureProvider<List<Customer>>((ref) async {
  return await CustomerRepository().getCustomersWithCredit();
});

// Total outstanding credit
final totalOutstandingCreditProvider = FutureProvider<double>((ref) async {
  return await CustomerRepository().getTotalOutstandingCredit();
});

// Credit history for a specific customer
final creditHistoryProvider = FutureProvider.family<List<CreditTransaction>, String>((ref, customerId) async {
  return await CustomerRepository().getCreditHistory(customerId);
});

// Top customers by purchase
final topCustomersProvider = FutureProvider<List<Customer>>((ref) async {
  return await CustomerRepository().getTopCustomers(limit: 10);
});

// Customers by type
final customersByTypeProvider = FutureProvider.family<List<Customer>, CustomerType>((ref, type) async {
  return await CustomerRepository().getByType(type);
});
