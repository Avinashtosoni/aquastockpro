import '../models/employee.dart';
import '../../core/constants/supabase_config.dart';
import '../services/supabase_service.dart';
import '../services/connectivity_service.dart';

class EmployeeRepository {
  static final EmployeeRepository _instance = EmployeeRepository._internal();
  factory EmployeeRepository() => _instance;
  EmployeeRepository._internal();

  final ConnectivityService _connectivityService = ConnectivityService();
  String get supabaseTableName => SupabaseConfig.employeesTable;

  void _checkConnection() {
    if (!_connectivityService.isOnline || !SupabaseService.isInitialized) {
      throw Exception('No internet connection. Please check your network and try again.');
    }
  }

  Future<List<Employee>> getAll() async {
    _checkConnection();
    
    final response = await SupabaseService.client
        .from(supabaseTableName)
        .select()
        .eq('is_active', true)
        .order('name');
    
    return (response as List).map((map) => Employee.fromMap(map)).toList();
  }

  Future<List<Employee>> getAllIncludingInactive() async {
    _checkConnection();
    
    final response = await SupabaseService.client
        .from(supabaseTableName)
        .select()
        .order('name');
    
    return (response as List).map((map) => Employee.fromMap(map)).toList();
  }

  Future<Employee?> getById(String id) async {
    _checkConnection();
    
    final response = await SupabaseService.client
        .from(supabaseTableName)
        .select()
        .eq('id', id)
        .maybeSingle();
    
    if (response == null) return null;
    return Employee.fromMap(response);
  }

  Future<Employee?> getByPin(String pin) async {
    _checkConnection();
    
    final response = await SupabaseService.client
        .from(supabaseTableName)
        .select()
        .eq('pin', pin)
        .eq('is_active', true)
        .maybeSingle();
    
    if (response == null) return null;
    return Employee.fromMap(response);
  }

  Future<Employee?> getByPhone(String phone) async {
    _checkConnection();
    
    final response = await SupabaseService.client
        .from(supabaseTableName)
        .select()
        .eq('phone', phone)
        .eq('is_active', true)
        .maybeSingle();
    
    if (response == null) return null;
    return Employee.fromMap(response);
  }

  Future<void> insert(Employee employee) async {
    _checkConnection();
    
    await SupabaseService.client
        .from(supabaseTableName)
        .insert(employee.toMap());
  }

  Future<void> update(Employee employee) async {
    _checkConnection();
    
    final map = employee.toMap();
    map['updated_at'] = DateTime.now().toIso8601String();
    
    await SupabaseService.client
        .from(supabaseTableName)
        .update(map)
        .eq('id', employee.id);
  }

  Future<void> delete(String id) async {
    _checkConnection();
    
    await SupabaseService.client.from(supabaseTableName).update({
      'is_active': false,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> hardDelete(String id) async {
    _checkConnection();
    
    await SupabaseService.client
        .from(supabaseTableName)
        .delete()
        .eq('id', id);
  }

  Future<List<Employee>> getByRole(EmployeeRole role) async {
    _checkConnection();
    
    final response = await SupabaseService.client
        .from(supabaseTableName)
        .select()
        .eq('role', role.name)
        .eq('is_active', true)
        .order('name');
    
    return (response as List).map((map) => Employee.fromMap(map)).toList();
  }

  Future<bool> validatePin(String pin) async {
    final employee = await getByPin(pin);
    return employee != null;
  }

  Future<int> getActiveEmployeeCount() async {
    _checkConnection();
    
    final response = await SupabaseService.client
        .from(supabaseTableName)
        .select('id')
        .eq('is_active', true);
    
    return (response as List).length;
  }

  Future<bool> isPinUnique(String pin, {String? excludeId}) async {
    _checkConnection();
    
    var query = SupabaseService.client
        .from(supabaseTableName)
        .select('id')
        .eq('pin', pin)
        .eq('is_active', true);
    
    if (excludeId != null) {
      query = query.neq('id', excludeId);
    }
    
    final response = await query;
    return (response as List).isEmpty;
  }
}
