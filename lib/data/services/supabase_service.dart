import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/supabase_config.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  static SupabaseClient? _client;
  static bool _isInitialized = false;

  factory SupabaseService() => _instance;

  SupabaseService._internal();

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
      );
      _client = Supabase.instance.client;
      _isInitialized = true;
      debugPrint('SupabaseService: Initialized successfully');
    } catch (e) {
      debugPrint('SupabaseService: Initialization failed - $e');
      rethrow;
    }
  }

  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase not initialized. Call SupabaseService.initialize() first.');
    }
    return _client!;
  }

  static bool get isInitialized => _isInitialized;

  // Auth methods
  static Future<AuthResponse> signIn(String email, String password) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<AuthResponse> signUp(String email, String password, {Map<String, dynamic>? data}) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  static User? get currentUser => client.auth.currentUser;

  static Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  // Generic CRUD operations
  static Future<List<Map<String, dynamic>>> fetchAll(String table) async {
    final response = await client.from(table).select();
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>?> fetchById(String table, String id) async {
    final response = await client.from(table).select().eq('id', id).maybeSingle();
    return response;
  }

  static Future<Map<String, dynamic>> insert(String table, Map<String, dynamic> data) async {
    final response = await client.from(table).insert(data).select().single();
    return response;
  }

  static Future<Map<String, dynamic>> update(String table, String id, Map<String, dynamic> data) async {
    final response = await client.from(table).update(data).eq('id', id).select().single();
    return response;
  }

  static Future<void> delete(String table, String id) async {
    await client.from(table).delete().eq('id', id);
  }

  // Storage methods
  static Future<String> uploadImage(String bucket, String path, List<int> bytes) async {
    try {
      debugPrint('SupabaseService.uploadImage: Uploading to bucket=$bucket, path=$path');
      
      // Convert List<int> to Uint8List
      final uint8List = Uint8List.fromList(bytes);
      
      // Upload with upsert to overwrite if exists
      await client.storage.from(bucket).uploadBinary(
        path,
        uint8List,
        fileOptions: const FileOptions(upsert: true),
      );
      
      final publicUrl = client.storage.from(bucket).getPublicUrl(path);
      debugPrint('SupabaseService.uploadImage: SUCCESS - $publicUrl');
      return publicUrl;
    } catch (e, stackTrace) {
      debugPrint('SupabaseService.uploadImage ERROR: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Future<void> deleteImage(String bucket, String path) async {
    await client.storage.from(bucket).remove([path]);
  }
}
