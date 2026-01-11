import 'package:flutter/foundation.dart';
import '../models/customer.dart';
import '../models/credit_transaction.dart';
import '../../core/constants/supabase_config.dart';
import '../services/supabase_service.dart';
import '../services/connectivity_service.dart';
import 'base_repository.dart';

class CustomerRepository extends BaseRepository<Customer> {
  static final CustomerRepository _instance = CustomerRepository._internal();
  factory CustomerRepository() => _instance;
  CustomerRepository._internal();

  final ConnectivityService _connectivityService = ConnectivityService();

  @override
  String get supabaseTableName => SupabaseConfig.customersTable;

  @override
  Customer fromMap(Map<String, dynamic> map) {
    try {
      return Customer.fromMap(map);
    } catch (e) {
      // Handle missing columns by providing defaults
      return Customer(
        id: map['id'] as String? ?? '',
        name: map['name'] as String? ?? 'Unknown',
        email: map['email'] as String?,
        phone: map['phone'] as String?,
        address: map['address'] as String?,
        gstin: map['gstin'] as String?,
        notes: map['notes'] as String?,
        isActive: map['is_active'] == 1 || map['is_active'] == true,
        createdAt: map['created_at'] != null 
            ? DateTime.parse(map['created_at'] as String) 
            : DateTime.now(),
        updatedAt: map['updated_at'] != null 
            ? DateTime.parse(map['updated_at'] as String) 
            : DateTime.now(),
      );
    }
  }

  @override
  Map<String, dynamic> toMap(Customer item) => item.toInsertMap();

  @override
  String getId(Customer item) => item.id;

  Future<List<Customer>> search(String queryText) async {
    if (!_connectivityService.isOnline || !SupabaseService.isInitialized) {
      throw Exception('No internet connection. Please check your network and try again.');
    }
    
    final response = await SupabaseService.client
        .from(supabaseTableName)
        .select()
        .eq('is_active', true)
        .or('name.ilike.%$queryText%,phone.ilike.%$queryText%,email.ilike.%$queryText%')
        .order('name');
    
    return (response as List).map((map) => Customer.fromMap(map)).toList();
  }

  Future<Customer?> getByPhone(String phone) async {
    if (!_connectivityService.isOnline || !SupabaseService.isInitialized) {
      throw Exception('No internet connection. Please check your network and try again.');
    }
    
    final response = await SupabaseService.client
        .from(supabaseTableName)
        .select()
        .eq('phone', phone)
        .eq('is_active', true)
        .maybeSingle();
    
    if (response == null) return null;
    return Customer.fromMap(response);
  }

  Future<void> updatePurchaseStats(String customerId, double orderTotal) async {
    if (!_connectivityService.isOnline || !SupabaseService.isInitialized) {
      debugPrint('updatePurchaseStats: No connectivity');
      return; // Just return instead of throwing to not block order save
    }
    
    try {
      final customer = await getById(customerId);
      if (customer == null) {
        debugPrint('updatePurchaseStats: Customer not found: $customerId');
        return;
      }
      
      debugPrint('updatePurchaseStats: Updating customer ${customer.name} with order total: $orderTotal');
      
      await SupabaseService.client.from(supabaseTableName).update({
        'total_purchases': customer.totalPurchases + orderTotal,
        'visit_count': customer.visitCount + 1,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', customerId);
      
      debugPrint('updatePurchaseStats: Success');
    } catch (e) {
      // If columns don't exist, try without them
      debugPrint('updatePurchaseStats: Error $e, trying minimal update');
      try {
        await SupabaseService.client.from(supabaseTableName).update({
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', customerId);
      } catch (e2) {
        debugPrint('updatePurchaseStats: Minimal update also failed: $e2');
      }
    }
  }

  Future<void> addLoyaltyPoints(String customerId, double points) async {
    if (!_connectivityService.isOnline || !SupabaseService.isInitialized) {
      throw Exception('No internet connection. Please check your network and try again.');
    }
    
    final customer = await getById(customerId);
    if (customer == null) throw Exception('Customer not found');
    
    await SupabaseService.client.from(supabaseTableName).update({
      'loyalty_points': customer.loyaltyPoints + points,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', customerId);
  }

  Future<void> redeemLoyaltyPoints(String customerId, double points) async {
    if (!_connectivityService.isOnline || !SupabaseService.isInitialized) {
      throw Exception('No internet connection. Please check your network and try again.');
    }
    
    final customer = await getById(customerId);
    if (customer == null) throw Exception('Customer not found');
    
    await SupabaseService.client.from(supabaseTableName).update({
      'loyalty_points': customer.loyaltyPoints - points,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', customerId);
  }

  Future<List<Customer>> getTopCustomers({int limit = 10}) async {
    if (!_connectivityService.isOnline || !SupabaseService.isInitialized) {
      throw Exception('No internet connection. Please check your network and try again.');
    }
    
    try {
      final response = await SupabaseService.client
          .from(supabaseTableName)
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false) // Use created_at if total_purchases doesn't exist
          .limit(limit);
      
      return (response as List).map((map) => Customer.fromMap(map)).toList();
    } catch (e) {
      // Fallback: just get customers without ordering by purchases
      final response = await SupabaseService.client
          .from(supabaseTableName)
          .select()
          .eq('is_active', true)
          .limit(limit);
      return (response as List).map((map) => Customer.fromMap(map)).toList();
    }
  }

  Future<int> getTotalCustomerCount() async {
    if (!_connectivityService.isOnline || !SupabaseService.isInitialized) {
      throw Exception('No internet connection. Please check your network and try again.');
    }
    
    final response = await SupabaseService.client
        .from(supabaseTableName)
        .select('id')
        .eq('is_active', true);
    
    return (response as List).length;
  }

  // ================== CREDIT SYSTEM METHODS ==================

  /// Add credit (udhar) to customer
  Future<CreditTransaction> addCredit({
    required String customerId,
    required double amount,
    String? orderId,
    String? notes,
    String? collectedBy,
  }) async {
    if (!_connectivityService.isOnline || !SupabaseService.isInitialized) {
      throw Exception('No internet connection. Please check your network and try again.');
    }
    
    final customer = await getById(customerId);
    if (customer == null) throw Exception('Customer not found');

    final previousBalance = customer.creditBalance;
    final newBalance = previousBalance + amount;

    // Update customer credit balance
    await SupabaseService.client.from(supabaseTableName).update({
      'credit_balance': newBalance,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', customerId);

    // Create credit transaction record
    final transaction = CreditTransaction(
      customerId: customerId,
      orderId: orderId,
      amount: amount,
      type: CreditTransactionType.creditGiven,
      previousBalance: previousBalance,
      newBalance: newBalance,
      notes: notes,
      collectedBy: collectedBy,
    );

    await SupabaseService.client
        .from(SupabaseConfig.creditTransactionsTable)
        .insert(transaction.toMap());
    
    return transaction;
  }

  /// Receive payment from customer
  Future<CreditTransaction> receivePayment({
    required String customerId,
    required double amount,
    String? notes,
    String? collectedBy,
  }) async {
    if (!_connectivityService.isOnline || !SupabaseService.isInitialized) {
      throw Exception('No internet connection. Please check your network and try again.');
    }
    
    final customer = await getById(customerId);
    if (customer == null) throw Exception('Customer not found');

    final previousBalance = customer.creditBalance;
    final newBalance = (previousBalance - amount).clamp(0.0, double.maxFinite);

    // Update customer credit balance
    await SupabaseService.client.from(supabaseTableName).update({
      'credit_balance': newBalance,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', customerId);

    // Create credit transaction record
    final transaction = CreditTransaction(
      customerId: customerId,
      amount: amount,
      type: CreditTransactionType.paymentReceived,
      previousBalance: previousBalance,
      newBalance: newBalance,
      notes: notes,
      collectedBy: collectedBy,
    );

    await SupabaseService.client
        .from(SupabaseConfig.creditTransactionsTable)
        .insert(transaction.toMap());
    
    return transaction;
  }

  /// Process refund credit - reduces customer's dues when refund is given
  Future<CreditTransaction> processRefundCredit({
    required String customerId,
    required double amount,
    String? orderId,
    String? refundNumber,
    String? notes,
    String? processedBy,
  }) async {
    if (!_connectivityService.isOnline || !SupabaseService.isInitialized) {
      throw Exception('No internet connection. Please check your network and try again.');
    }
    
    final customer = await getById(customerId);
    if (customer == null) throw Exception('Customer not found');

    final previousBalance = customer.creditBalance;
    final newBalance = (previousBalance - amount).clamp(0.0, double.maxFinite);

    // Update customer credit balance
    await SupabaseService.client.from(supabaseTableName).update({
      'credit_balance': newBalance,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', customerId);

    // Create credit transaction record for refund
    final transaction = CreditTransaction(
      customerId: customerId,
      orderId: orderId,
      amount: amount,
      type: CreditTransactionType.refundCredit,
      previousBalance: previousBalance,
      newBalance: newBalance,
      notes: notes ?? 'Refund: ${refundNumber ?? 'N/A'}',
      collectedBy: processedBy,
    );

    await SupabaseService.client
        .from(SupabaseConfig.creditTransactionsTable)
        .insert(transaction.toMap());
    
    return transaction;
  }

  /// Get credit history for a customer
  Future<List<CreditTransaction>> getCreditHistory(String customerId) async {
    if (!_connectivityService.isOnline || !SupabaseService.isInitialized) {
      throw Exception('No internet connection. Please check your network and try again.');
    }
    
    final response = await SupabaseService.client
        .from(SupabaseConfig.creditTransactionsTable)
        .select()
        .eq('customer_id', customerId)
        .order('created_at', ascending: false);
    
    return (response as List).map((map) => CreditTransaction.fromMap(map)).toList();
  }

  /// Get all customers with outstanding credit
  Future<List<Customer>> getCustomersWithCredit() async {
    if (!_connectivityService.isOnline || !SupabaseService.isInitialized) {
      throw Exception('No internet connection. Please check your network and try again.');
    }
    
    try {
      final response = await SupabaseService.client
          .from(supabaseTableName)
          .select()
          .eq('is_active', true)
          .gt('credit_balance', 0)
          .order('credit_balance', ascending: false);
      
      return (response as List).map((map) => Customer.fromMap(map)).toList();
    } catch (e) {
      // Column may not exist - return empty list
      return [];
    }
  }

  /// Get total outstanding credit across all customers
  Future<double> getTotalOutstandingCredit() async {
    if (!_connectivityService.isOnline || !SupabaseService.isInitialized) {
      throw Exception('No internet connection. Please check your network and try again.');
    }
    
    try {
      final response = await SupabaseService.client
          .from(supabaseTableName)
          .select('credit_balance')
          .eq('is_active', true);
      
      double total = 0;
      for (final item in response as List) {
        total += (item['credit_balance'] as num?)?.toDouble() ?? 0;
      }
      return total;
    } catch (e) {
      // Column may not exist
      return 0;
    }
  }

  /// Update customer credit limit
  Future<void> updateCreditLimit(String customerId, double newLimit) async {
    if (!_connectivityService.isOnline || !SupabaseService.isInitialized) {
      throw Exception('No internet connection. Please check your network and try again.');
    }
    
    await SupabaseService.client.from(supabaseTableName).update({
      'credit_limit': newLimit,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', customerId);
  }

  /// Get customers by type (retail/wholesale)
  Future<List<Customer>> getByType(CustomerType type) async {
    if (!_connectivityService.isOnline || !SupabaseService.isInitialized) {
      throw Exception('No internet connection. Please check your network and try again.');
    }
    
    final response = await SupabaseService.client
        .from(supabaseTableName)
        .select()
        .eq('is_active', true)
        .eq('customer_type', type.name)
        .order('name');
    
    return (response as List).map((map) => Customer.fromMap(map)).toList();
  }
}
