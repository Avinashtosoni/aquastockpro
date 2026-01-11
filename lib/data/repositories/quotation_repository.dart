import '../models/quotation.dart';
import '../models/quotation_item.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../../core/constants/supabase_config.dart';
import '../services/supabase_service.dart';
import '../services/connectivity_service.dart';
import 'order_repository.dart';

class QuotationRepository {
  static final QuotationRepository _instance = QuotationRepository._internal();
  final ConnectivityService _connectivityService = ConnectivityService();

  factory QuotationRepository() => _instance;
  QuotationRepository._internal();

  void _checkConnection() {
    if (!_connectivityService.isOnline || !SupabaseService.isInitialized) {
      throw Exception('No internet connection. Please check your network and try again.');
    }
  }

  Future<List<Quotation>> getAll({int? limit, int? offset}) async {
    _checkConnection();
    
    var query = SupabaseService.client
        .from(SupabaseConfig.quotationsTable)
        .select()
        .order('created_at', ascending: false);
    
    if (limit != null) {
      query = query.limit(limit);
    }
    
    final quotationMaps = await query;
    final quotations = <Quotation>[];
    
    if ((quotationMaps as List).isEmpty) return quotations;
    
    // Fetch ALL quotation items in ONE query (fixes N+1 problem)
    final quotationIds = quotationMaps.map((q) => q['id'] as String).toList();
    final allItemsResponse = await SupabaseService.client
        .from(SupabaseConfig.quotationItemsTable)
        .select()
        .inFilter('quotation_id', quotationIds);
    
    // Group items by quotation_id
    final itemsByQuotationId = <String, List<QuotationItem>>{};
    for (final itemMap in allItemsResponse as List) {
      final quotationId = itemMap['quotation_id'] as String;
      itemsByQuotationId.putIfAbsent(quotationId, () => []);
      itemsByQuotationId[quotationId]!.add(QuotationItem.fromMap(itemMap));
    }
    
    // Build quotations with their items
    for (final quotationMap in quotationMaps) {
      final quotationId = quotationMap['id'] as String;
      final items = itemsByQuotationId[quotationId] ?? [];
      quotations.add(Quotation.fromMap(quotationMap, items: items));
    }
    
    return quotations;
  }

  Future<Quotation?> getById(String id) async {
    _checkConnection();
    
    final response = await SupabaseService.client
        .from(SupabaseConfig.quotationsTable)
        .select()
        .eq('id', id)
        .maybeSingle();
    
    if (response == null) return null;
    
    final items = await getQuotationItems(id);
    return Quotation.fromMap(response, items: items);
  }

  Future<List<QuotationItem>> getQuotationItems(String quotationId) async {
    _checkConnection();
    
    final response = await SupabaseService.client
        .from(SupabaseConfig.quotationItemsTable)
        .select()
        .eq('quotation_id', quotationId);
    
    return (response as List).map((map) => QuotationItem.fromMap(map)).toList();
  }

  Future<Quotation> insert(Quotation quotation) async {
    _checkConnection();
    
    // Insert quotation
    await SupabaseService.client
        .from(SupabaseConfig.quotationsTable)
        .insert(quotation.toMap());
    
    // Insert quotation items with correct quotationId
    for (final item in quotation.items) {
      final itemMap = item.toMap();
      itemMap['quotation_id'] = quotation.id; // Ensure quotationId is set correctly
      await SupabaseService.client
          .from(SupabaseConfig.quotationItemsTable)
          .insert(itemMap);
    }
    
    return quotation;
  }

  Future<Quotation> update(Quotation quotation) async {
    _checkConnection();
    
    final quotationMap = quotation.toMap();
    quotationMap['updated_at'] = DateTime.now().toIso8601String();
    
    await SupabaseService.client
        .from(SupabaseConfig.quotationsTable)
        .update(quotationMap)
        .eq('id', quotation.id);
    
    // Delete existing items and re-insert
    await SupabaseService.client
        .from(SupabaseConfig.quotationItemsTable)
        .delete()
        .eq('quotation_id', quotation.id);
    
    for (final item in quotation.items) {
      await SupabaseService.client
          .from(SupabaseConfig.quotationItemsTable)
          .insert(item.toMap());
    }
    
    return quotation;
  }

  Future<void> delete(String id) async {
    _checkConnection();
    
    // Delete quotation items first
    await SupabaseService.client
        .from(SupabaseConfig.quotationItemsTable)
        .delete()
        .eq('quotation_id', id);
    
    // Delete quotation
    await SupabaseService.client
        .from(SupabaseConfig.quotationsTable)
        .delete()
        .eq('id', id);
  }

  Future<String> generateQuotationNumber() async {
    _checkConnection();
    
    final today = DateTime.now();
    final datePrefix = '${today.year.toString().substring(2)}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';
    
    final response = await SupabaseService.client
        .from(SupabaseConfig.quotationsTable)
        .select('quotation_number')
        .like('quotation_number', 'QT-$datePrefix%');
    
    final count = (response as List).length + 1;
    return 'QT-$datePrefix-${count.toString().padLeft(4, '0')}';
  }

  Future<List<Quotation>> getByStatus(QuotationStatus status) async {
    _checkConnection();
    
    final quotationMaps = await SupabaseService.client
        .from(SupabaseConfig.quotationsTable)
        .select()
        .eq('status', status.name)
        .order('created_at', ascending: false);
    
    if ((quotationMaps as List).isEmpty) return [];
    
    // Batch fetch quotation items
    final quotationIds = quotationMaps.map((q) => q['id'] as String).toList();
    final allItemsResponse = await SupabaseService.client
        .from(SupabaseConfig.quotationItemsTable)
        .select()
        .inFilter('quotation_id', quotationIds);
    
    final itemsByQuotationId = <String, List<QuotationItem>>{};
    for (final itemMap in allItemsResponse as List) {
      final quotationId = itemMap['quotation_id'] as String;
      itemsByQuotationId.putIfAbsent(quotationId, () => []);
      itemsByQuotationId[quotationId]!.add(QuotationItem.fromMap(itemMap));
    }
    
    return quotationMaps.map((quotationMap) {
      final quotationId = quotationMap['id'] as String;
      return Quotation.fromMap(quotationMap, items: itemsByQuotationId[quotationId] ?? []);
    }).toList();
  }

  Future<List<Quotation>> getByCustomer(String customerId) async {
    _checkConnection();
    
    final quotationMaps = await SupabaseService.client
        .from(SupabaseConfig.quotationsTable)
        .select()
        .eq('customer_id', customerId)
        .order('created_at', ascending: false);
    
    final quotations = <Quotation>[];
    for (final quotationMap in quotationMaps as List) {
      final items = await getQuotationItems(quotationMap['id'] as String);
      quotations.add(Quotation.fromMap(quotationMap, items: items));
    }
    return quotations;
  }

  Future<List<Quotation>> getExpiredQuotations() async {
    _checkConnection();
    
    final now = DateTime.now().toIso8601String();
    
    final quotationMaps = await SupabaseService.client
        .from(SupabaseConfig.quotationsTable)
        .select()
        .lt('valid_until', now)
        .neq('status', QuotationStatus.expired.name)
        .neq('status', QuotationStatus.converted.name)
        .neq('status', QuotationStatus.rejected.name)
        .order('created_at', ascending: false);
    
    if ((quotationMaps as List).isEmpty) return [];
    
    final quotationIds = quotationMaps.map((q) => q['id'] as String).toList();
    final allItemsResponse = await SupabaseService.client
        .from(SupabaseConfig.quotationItemsTable)
        .select()
        .inFilter('quotation_id', quotationIds);
    
    final itemsByQuotationId = <String, List<QuotationItem>>{};
    for (final itemMap in allItemsResponse as List) {
      final quotationId = itemMap['quotation_id'] as String;
      itemsByQuotationId.putIfAbsent(quotationId, () => []);
      itemsByQuotationId[quotationId]!.add(QuotationItem.fromMap(itemMap));
    }
    
    return quotationMaps.map((quotationMap) {
      final quotationId = quotationMap['id'] as String;
      return Quotation.fromMap(quotationMap, items: itemsByQuotationId[quotationId] ?? []);
    }).toList();
  }

  /// Convert a quotation to an order
  Future<Order> convertToOrder(Quotation quotation) async {
    _checkConnection();
    
    final orderRepository = OrderRepository();
    final orderNumber = await orderRepository.generateOrderNumber();
    
    // Create order items from quotation items
    final orderItems = quotation.items.map((qi) => OrderItem(
      orderId: '', // Will be set after order is created
      productId: qi.productId,
      productName: qi.productName,
      unitPrice: qi.unitPrice,
      quantity: qi.quantity,
      discount: qi.discount,
      taxRate: qi.taxRate,
      total: qi.total,
    )).toList();
    
    // Create order
    final order = Order(
      orderNumber: orderNumber,
      customerId: quotation.customerId,
      customerName: quotation.customerName,
      employeeId: quotation.employeeId,
      employeeName: quotation.employeeName,
      items: orderItems.map((item) => item.copyWith(orderId: '')).toList(),
      subtotal: quotation.subtotal,
      taxAmount: quotation.taxAmount,
      discountAmount: quotation.discountAmount,
      totalAmount: quotation.totalAmount,
      status: OrderStatus.pending,
      notes: 'Converted from Quotation: ${quotation.quotationNumber}',
    );
    
    // Update order items with correct orderId
    final finalOrderItems = order.items.map((item) => item.copyWith(orderId: order.id)).toList();
    final finalOrder = order.copyWith(items: finalOrderItems);
    
    // Insert the order
    await orderRepository.insert(finalOrder);
    
    // Update quotation status to converted
    await update(quotation.copyWith(status: QuotationStatus.converted));
    
    return finalOrder;
  }

  // Statistics
  Future<Map<String, int>> getQuotationStats() async {
    _checkConnection();
    
    final response = await SupabaseService.client
        .from(SupabaseConfig.quotationsTable)
        .select('status');
    
    final quotations = response as List;
    
    int draft = 0, sent = 0, accepted = 0, rejected = 0, expired = 0, converted = 0;
    
    for (final q in quotations) {
      switch (q['status']) {
        case 'draft': draft++; break;
        case 'sent': sent++; break;
        case 'accepted': accepted++; break;
        case 'rejected': rejected++; break;
        case 'expired': expired++; break;
        case 'converted': converted++; break;
      }
    }
    
    return {
      'total': quotations.length,
      'draft': draft,
      'sent': sent,
      'accepted': accepted,
      'rejected': rejected,
      'expired': expired,
      'converted': converted,
    };
  }
}
