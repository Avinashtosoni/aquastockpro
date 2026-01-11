import 'dart:typed_data';
import '../models/user.dart';
import '../services/password_service.dart';
import '../../core/constants/supabase_config.dart';
import '../services/supabase_service.dart';
import '../services/connectivity_service.dart';
import 'base_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;

class UserRepository extends BaseRepository<User> {
  static final UserRepository _instance = UserRepository._internal();
  factory UserRepository() => _instance;
  UserRepository._internal();

  final PasswordService _passwordService = PasswordService();
  final ConnectivityService _connectivityService = ConnectivityService();

  @override
  String get supabaseTableName => SupabaseConfig.usersTable;

  @override
  User fromMap(Map<String, dynamic> map) => User.fromMap(map);

  @override
  Map<String, dynamic> toMap(User item) => item.toMap();

  @override
  String getId(User item) => item.id;

  void _checkConnection() {
    if (!_connectivityService.isOnline || !SupabaseService.isInitialized) {
      throw Exception('No internet connection. Please check your network and try again.');
    }
  }

  Future<User?> getByEmail(String email) async {
    _checkConnection();
    
    final response = await SupabaseService.client
        .from(supabaseTableName)
        .select()
        .eq('email', email)
        .eq('is_active', true)
        .maybeSingle();
    
    if (response == null) return null;
    return User.fromMap(response);
  }

  Future<User?> getByPhone(String phone) async {
    _checkConnection();
    
    final response = await SupabaseService.client
        .from(supabaseTableName)
        .select()
        .eq('phone', phone)
        .eq('is_active', true)
        .maybeSingle();
    
    if (response == null) return null;
    return User.fromMap(response);
  }

  @override
  Future<User?> getById(String id) async {
    _checkConnection();
    
    final response = await SupabaseService.client
        .from(supabaseTableName)
        .select()
        .eq('id', id)
        .eq('is_active', true)
        .maybeSingle();
    
    if (response == null) return null;
    return User.fromMap(response);
  }

  /// Find user by email or phone
  Future<User?> getByEmailOrPhone(String identifier) async {
    // Try email first
    var user = await getByEmail(identifier);
    if (user != null) return user;
    
    // Try phone
    user = await getByPhone(identifier);
    return user;
  }

  /// Authenticate with PIN using secure hash verification
  Future<User?> authenticateWithPin(String pin) async {
    _checkConnection();
    
    // Get all active users
    final response = await SupabaseService.client
        .from(supabaseTableName)
        .select()
        .eq('is_active', true);
    
    for (final map in response as List) {
      final user = User.fromMap(map);
      
      // First check hashed PIN (new secure method)
      if (user.pinHash != null && _passwordService.verifyPin(pin, user.pinHash!)) {
        return user;
      }
      
      // Fallback: check legacy plaintext PIN (for migration)
      if (user.pin != null && user.pin == pin) {
        // Auto-migrate: hash the PIN for future logins
        await _migrateToHashedPin(user.id, pin);
        return user;
      }
    }
    
    return null;
  }

  /// Authenticate with email and password using secure hash verification
  Future<User?> authenticateWithEmail(String email, String password) async {
    final user = await getByEmail(email);
    if (user == null) return null;
    
    // Verify password hash
    if (user.passwordHash != null) {
      if (_passwordService.verifyPassword(password, user.passwordHash!)) {
        return user;
      }
    }
    
    // For development: if no password set, allow login (will prompt to set password)
    if (user.passwordHash == null) {
      return user;
    }
    
    return null;
  }

  Future<List<User>> getByRole(UserRole role) async {
    _checkConnection();
    
    final response = await SupabaseService.client
        .from(supabaseTableName)
        .select()
        .eq('role', role.name)
        .eq('is_active', true)
        .order('name');
    
    return (response as List).map((map) => User.fromMap(map)).toList();
  }

  Future<int> getUserCount() async {
    _checkConnection();
    
    final response = await SupabaseService.client
        .from(supabaseTableName)
        .select('id')
        .eq('is_active', true);
    
    return (response as List).length;
  }

  /// Update PIN with secure hashing
  Future<void> updatePin(String userId, String newPin) async {
    _checkConnection();
    
    final hashedPin = _passwordService.hashPin(newPin);
    await SupabaseService.client.from(supabaseTableName).update({
      'pin': null,
      'pin_hash': hashedPin,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  /// Set password with secure hashing
  Future<void> setPassword(String userId, String password) async {
    _checkConnection();
    
    final hashedPassword = _passwordService.hashPassword(password);
    await SupabaseService.client.from(supabaseTableName).update({
      'password_hash': hashedPassword,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  /// Migrate legacy plaintext PIN to hashed version
  Future<void> _migrateToHashedPin(String userId, String pin) async {
    _checkConnection();
    
    final hashedPin = _passwordService.hashPin(pin);
    await SupabaseService.client.from(supabaseTableName).update({
      'pin': null,
      'pin_hash': hashedPin,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  /// Create user with hashed credentials
  Future<User> createUser({
    required String email,
    required String name,
    String? phone,
    UserRole role = UserRole.cashier,
    String? pin,
    String? password,
    String? avatarUrl,
  }) async {
    String? hashedPin;
    String? hashedPassword;
    
    if (pin != null) {
      hashedPin = _passwordService.hashPin(pin);
    }
    if (password != null) {
      hashedPassword = _passwordService.hashPassword(password);
    }
    
    final user = User(
      email: email,
      name: name,
      phone: phone,
      role: role,
      pinHash: hashedPin,
      passwordHash: hashedPassword,
      avatarUrl: avatarUrl,
    );
    
    await insert(user);
    return user;
  }

  /// Upload user avatar to Supabase Storage
  Future<String?> uploadAvatar(List<int> imageBytes, String fileName) async {
    _checkConnection();
    
    // Try user-avatars bucket first
    try {
      final path = 'avatars/$fileName';
      await SupabaseService.client.storage
          .from('user-avatars')
          .uploadBinary(path, Uint8List.fromList(imageBytes), fileOptions: const FileOptions(upsert: true));
      
      return SupabaseService.client.storage.from('user-avatars').getPublicUrl(path);
    } catch (e) {
      print('uploadAvatar: user-avatars bucket failed: $e');
      
      // Fallback: try products bucket (if user-avatars doesn't exist)
      try {
        final path = 'avatars/$fileName';
        await SupabaseService.client.storage
            .from('products')
            .uploadBinary(path, Uint8List.fromList(imageBytes), fileOptions: const FileOptions(upsert: true));
        
        return SupabaseService.client.storage.from('products').getPublicUrl(path);
      } catch (e2) {
        print('uploadAvatar: products bucket also failed: $e2');
        // Both buckets failed - throw the error so user can see it
        throw Exception('Storage upload failed. Create a "user-avatars" bucket in Supabase Storage.');
      }
    }
  }

  /// Delete user avatar from storage
  Future<void> deleteAvatar(String avatarUrl) async {
    _checkConnection();
    
    try {
      final uri = Uri.parse(avatarUrl);
      final pathSegments = uri.pathSegments;
      if (pathSegments.length >= 2) {
        final bucket = pathSegments[pathSegments.length - 2];
        final fileName = pathSegments.last;
        await SupabaseService.client.storage.from(bucket).remove(['avatars/$fileName']);
      }
    } catch (e) {
      // Silently fail - avatar may already be deleted
    }
  }
}
