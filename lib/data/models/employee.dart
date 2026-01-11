import 'package:uuid/uuid.dart';

enum EmployeeRole { admin, manager, cashier }

class Employee {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String pin; // 4-6 digit PIN for quick login
  final EmployeeRole role;
  final bool isActive;
  final DateTime joinDate;
  final double? salary;
  final String? address;
  final String? emergencyContact;
  final DateTime createdAt;
  final DateTime updatedAt;

  Employee({
    String? id,
    required this.name,
    required this.phone,
    this.email,
    required this.pin,
    this.role = EmployeeRole.cashier,
    this.isActive = true,
    DateTime? joinDate,
    this.salary,
    this.address,
    this.emergencyContact,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        joinDate = joinDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  String get roleDisplayName {
    switch (role) {
      case EmployeeRole.admin:
        return 'Admin';
      case EmployeeRole.manager:
        return 'Manager';
      case EmployeeRole.cashier:
        return 'Cashier';
    }
  }

  bool get isAdmin => role == EmployeeRole.admin;
  bool get isManager => role == EmployeeRole.manager || role == EmployeeRole.admin;

  // Permission checks
  bool get canManageProducts => isManager;
  bool get canManageEmployees => isAdmin;
  bool get canViewReports => isManager;
  bool get canGiveDiscount => isManager;
  bool get canProcessRefund => isManager;
  bool get canAdjustStock => isManager;

  Employee copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? pin,
    EmployeeRole? role,
    bool? isActive,
    DateTime? joinDate,
    double? salary,
    String? address,
    String? emergencyContact,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      pin: pin ?? this.pin,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      joinDate: joinDate ?? this.joinDate,
      salary: salary ?? this.salary,
      address: address ?? this.address,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'pin': pin,
      'role': role.name,
      'is_active': isActive,
      'join_date': joinDate.toIso8601String(),
      'salary': salary,
      'address': address,
      'emergency_contact': emergencyContact,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String,
      email: map['email'] as String?,
      pin: map['pin'] as String,
      role: EmployeeRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => EmployeeRole.cashier,
      ),
      isActive: map['is_active'] == 1 || map['is_active'] == true,
      joinDate: DateTime.parse(map['join_date'] as String),
      salary: (map['salary'] as num?)?.toDouble(),
      address: map['address'] as String?,
      emergencyContact: map['emergency_contact'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  // Default admin employee for initial setup
  static Employee defaultAdmin = Employee(
    id: 'default-admin',
    name: 'Admin',
    phone: '0000000000',
    pin: '1234',
    role: EmployeeRole.admin,
  );
}
