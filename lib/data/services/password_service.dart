import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// Service for secure password and PIN hashing
class PasswordService {
  static final PasswordService _instance = PasswordService._internal();
  factory PasswordService() => _instance;
  PasswordService._internal();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  /// Hash a password with a random salt using SHA-256
  /// Returns the format: salt$hash
  String hashPassword(String password) {
    final salt = const Uuid().v4().substring(0, 16);
    final bytes = utf8.encode(salt + password);
    final hash = sha256.convert(bytes).toString();
    return '$salt\$$hash';
  }

  /// Verify a password against a stored hash
  bool verifyPassword(String password, String storedHash) {
    try {
      final parts = storedHash.split('\$');
      if (parts.length != 2) return false;
      
      final salt = parts[0];
      final hash = parts[1];
      
      final bytes = utf8.encode(salt + password);
      final computedHash = sha256.convert(bytes).toString();
      
      return hash == computedHash;
    } catch (e) {
      return false;
    }
  }

  /// Hash a PIN code (4-6 digits) with salt
  String hashPin(String pin) {
    final salt = const Uuid().v4().substring(0, 8);
    final bytes = utf8.encode(salt + pin);
    final hash = sha256.convert(bytes).toString();
    return '$salt\$$hash';
  }

  /// Verify a PIN against a stored hash
  bool verifyPin(String pin, String storedHash) {
    try {
      final parts = storedHash.split('\$');
      if (parts.length != 2) return false;
      
      final salt = parts[0];
      final hash = parts[1];
      
      final bytes = utf8.encode(salt + pin);
      final computedHash = sha256.convert(bytes).toString();
      
      return hash == computedHash;
    } catch (e) {
      return false;
    }
  }

  /// Store a sensitive value securely
  Future<void> storeSecure(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// Read a sensitive value from secure storage
  Future<String?> readSecure(String key) async {
    return await _storage.read(key: key);
  }

  /// Delete a sensitive value from secure storage
  Future<void> deleteSecure(String key) async {
    await _storage.delete(key: key);
  }

  /// Clear all secure storage
  Future<void> clearSecure() async {
    await _storage.deleteAll();
  }

  /// Check if a PIN is valid (4-6 numeric digits)
  bool isValidPin(String pin) {
    if (pin.length < 4 || pin.length > 6) return false;
    return RegExp(r'^\d+$').hasMatch(pin);
  }

  /// Check if a password is strong enough
  /// Requires: 8+ chars, uppercase, lowercase, number
  PasswordStrength checkPasswordStrength(String password) {
    if (password.length < 6) return PasswordStrength.weak;
    
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasDigit = password.contains(RegExp(r'[0-9]'));
    bool hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    
    int score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (hasUppercase) score++;
    if (hasLowercase) score++;
    if (hasDigit) score++;
    if (hasSpecial) score++;
    
    if (score <= 2) return PasswordStrength.weak;
    if (score <= 4) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }
}

enum PasswordStrength { weak, medium, strong }
