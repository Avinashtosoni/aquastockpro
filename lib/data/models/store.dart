import 'package:uuid/uuid.dart';

/// Store/Branch model for multi-store support
class Store {
  final String id;
  final String name;
  final String? code;
  final String? address;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? phone;
  final String? email;
  final String? managerId;
  final String? managerName;
  final bool isDefault;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Store({
    required this.id,
    required this.name,
    this.code,
    this.address,
    this.city,
    this.state,
    this.postalCode,
    this.phone,
    this.email,
    this.managerId,
    this.managerName,
    this.isDefault = false,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Store.create({
    required String name,
    String? code,
    String? address,
    String? city,
    String? state,
    String? postalCode,
    String? phone,
    String? email,
    String? managerId,
    bool isDefault = false,
  }) {
    final now = DateTime.now();
    return Store(
      id: const Uuid().v4(),
      name: name,
      code: code,
      address: address,
      city: city,
      state: state,
      postalCode: postalCode,
      phone: phone,
      email: email,
      managerId: managerId,
      isDefault: isDefault,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      postalCode: json['postal_code'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      managerId: json['manager_id'] as String?,
      managerName: json['manager_name'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'address': address,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'phone': phone,
      'email': email,
      'manager_id': managerId,
      'manager_name': managerName,
      'is_default': isDefault,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Full address
  String get fullAddress {
    final parts = <String>[];
    if (address != null && address!.isNotEmpty) parts.add(address!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (state != null && state!.isNotEmpty) parts.add(state!);
    if (postalCode != null && postalCode!.isNotEmpty) parts.add(postalCode!);
    return parts.join(', ');
  }

  Store copyWith({
    String? name,
    String? code,
    String? address,
    String? city,
    String? state,
    String? postalCode,
    String? phone,
    String? email,
    String? managerId,
    String? managerName,
    bool? isDefault,
    bool? isActive,
  }) {
    return Store(
      id: id,
      name: name ?? this.name,
      code: code ?? this.code,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      managerId: managerId ?? this.managerId,
      managerName: managerName ?? this.managerName,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
