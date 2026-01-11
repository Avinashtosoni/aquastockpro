import 'package:uuid/uuid.dart';

enum UserRole { admin, manager, cashier }

class User {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final UserRole role;
  final String? pin; // Legacy field - kept for migration
  final String? pinHash; // Secure hashed PIN
  final String? passwordHash; // Secure hashed password
  final String? avatarUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    String? id,
    required this.email,
    required this.name,
    this.phone,
    this.role = UserRole.cashier,
    this.pin,
    this.pinHash,
    this.passwordHash,
    this.avatarUrl,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    UserRole? role,
    String? pin,
    String? pinHash,
    String? passwordHash,
    String? avatarUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      pin: pin ?? this.pin,
      pinHash: pinHash ?? this.pinHash,
      passwordHash: passwordHash ?? this.passwordHash,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'role': role.name,
      'pin': pin,
      'pin_hash': pinHash,
      'password_hash': passwordHash,
      'avatar_url': avatarUrl,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      email: map['email'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.cashier,
      ),
      pin: map['pin'] as String?,
      pinHash: map['pin_hash'] as String?,
      passwordHash: map['password_hash'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      isActive: map['is_active'] == 1 || map['is_active'] == true,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  String get roleDisplayName {
    switch (role) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.manager:
        return 'Manager';
      case UserRole.cashier:
        return 'Cashier';
    }
  }

  bool get isAdmin => role == UserRole.admin;
  bool get isManager => role == UserRole.manager || role == UserRole.admin;
}
