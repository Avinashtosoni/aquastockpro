import '../models/supplier.dart';
import '../../core/constants/supabase_config.dart';
import '../services/supabase_service.dart';
import '../services/connectivity_service.dart';

class SupplierRepository {
  static final SupplierRepository _instance = SupplierRepository._internal();
  factory SupplierRepository() => _instance;
  SupplierRepository._internal();

  final ConnectivityService _connectivityService = ConnectivityService();
  String get supabaseTableName => SupabaseConfig.suppliersTable;

  void _checkConnection() {
    if (!_connectivityService.isOnline || !SupabaseService.isInitialized) {
      throw Exception('No internet connection. Please check your network and try again.');
    }
  }

  Future<List<Supplier>> getAll() async {
    _checkConnection();
    
    final response = await SupabaseService.client
        .from(supabaseTableName)
        .select()
        .eq('is_active', true)
        .order('name');
    
    return (response as List).map((map) => Supplier.fromMap(map)).toList();
  }

  Future<Supplier?> getById(String id) async {
    _checkConnection();
    
    final response = await SupabaseService.client
        .from(supabaseTableName)
        .select()
        .eq('id', id)
        .maybeSingle();
    
    if (response == null) return null;
    return Supplier.fromMap(response);
  }

  Future<void> insert(Supplier supplier) async {
    _checkConnection();
    
    await SupabaseService.client
        .from(supabaseTableName)
        .insert(supplier.toMap());
  }

  Future<void> update(Supplier supplier) async {
    _checkConnection();
    
    final map = supplier.toMap();
    map['updated_at'] = DateTime.now().toIso8601String();
    
    await SupabaseService.client
        .from(supabaseTableName)
        .update(map)
        .eq('id', supplier.id);
  }

  Future<void> delete(String id) async {
    _checkConnection();
    
    await SupabaseService.client.from(supabaseTableName).update({
      'is_active': false,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<List<Supplier>> search(String queryText) async {
    _checkConnection();
    
    final response = await SupabaseService.client
        .from(supabaseTableName)
        .select()
        .eq('is_active', true)
        .or('name.ilike.%$queryText%,phone.ilike.%$queryText%,contact_person.ilike.%$queryText%')
        .order('name');
    
    return (response as List).map((map) => Supplier.fromMap(map)).toList();
  }

  Future<double> getTotalOutstanding() async {
    _checkConnection();
    
    final response = await SupabaseService.client
        .from(supabaseTableName)
        .select('outstanding_amount')
        .eq('is_active', true);
    
    double total = 0;
    for (final item in response as List) {
      total += (item['outstanding_amount'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  Future<void> updateOutstanding(String supplierId, double amount, {bool add = true}) async {
    _checkConnection();
    
    final supplier = await getById(supplierId);
    if (supplier == null) throw Exception('Supplier not found');
    
    final newAmount = add 
        ? supplier.outstandingAmount + amount 
        : supplier.outstandingAmount - amount;
    
    await SupabaseService.client.from(supabaseTableName).update({
      'outstanding_amount': newAmount,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', supplierId);
  }
}
