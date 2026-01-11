import '../services/supabase_service.dart';
import '../services/connectivity_service.dart';

/// Base repository that uses Supabase as the sole data source.
/// All CRUD operations go directly to Supabase cloud storage.
abstract class BaseRepository<T> {
  final ConnectivityService _connectivityService = ConnectivityService();
  
  String get supabaseTableName;
  
  T fromMap(Map<String, dynamic> map);
  Map<String, dynamic> toMap(T item);
  String getId(T item);

  /// Get all items from Supabase
  Future<List<T>> getAll() async {
    if (!_connectivityService.isOnline || !SupabaseService.isInitialized) {
      throw Exception('No internet connection. Please check your network and try again.');
    }
    
    final items = await SupabaseService.fetchAll(supabaseTableName);
    return items.map((map) => fromMap(map)).toList();
  }

  /// Get item by ID from Supabase
  Future<T?> getById(String id) async {
    if (!_connectivityService.isOnline || !SupabaseService.isInitialized) {
      throw Exception('No internet connection. Please check your network and try again.');
    }
    
    final item = await SupabaseService.fetchById(supabaseTableName, id);
    if (item == null) return null;
    return fromMap(item);
  }

  /// Insert item to Supabase
  Future<T> insert(T item) async {
    if (!_connectivityService.isOnline || !SupabaseService.isInitialized) {
      throw Exception('No internet connection. Please check your network and try again.');
    }
    
    final map = toMap(item);
    await SupabaseService.insert(supabaseTableName, map);
    return item;
  }

  /// Update item in Supabase
  Future<T> update(T item) async {
    if (!_connectivityService.isOnline || !SupabaseService.isInitialized) {
      throw Exception('No internet connection. Please check your network and try again.');
    }
    
    final map = toMap(item);
    map['updated_at'] = DateTime.now().toIso8601String();
    await SupabaseService.update(supabaseTableName, getId(item), map);
    return item;
  }

  /// Delete item from Supabase (soft delete by setting is_active = false)
  Future<void> delete(String id) async {
    if (!_connectivityService.isOnline || !SupabaseService.isInitialized) {
      throw Exception('No internet connection. Please check your network and try again.');
    }
    
    await SupabaseService.update(supabaseTableName, id, {
      'is_active': false,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
