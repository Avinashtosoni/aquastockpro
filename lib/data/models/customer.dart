import 'package:uuid/uuid.dart';

enum CustomerType { retail, wholesale }

class Customer {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final String? gstin;
  final double totalPurchases;
  final int visitCount;
  final double loyaltyPoints;
  final double creditBalance; // Current credit/udhar amount
  final double creditLimit; // Maximum allowed credit
  final CustomerType customerType;
  final double discountPercentage; // Customer-specific discount
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    String? id,
    required this.name,
    this.email,
    this.phone,
    this.address,
    this.gstin,
    this.totalPurchases = 0,
    this.visitCount = 0,
    this.loyaltyPoints = 0,
    this.creditBalance = 0,
    this.creditLimit = 5000,
    this.customerType = CustomerType.retail,
    this.discountPercentage = 0,
    this.notes,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Check if customer can take more credit
  bool get canTakeCredit => creditBalance < creditLimit;
  double get availableCredit => creditLimit - creditBalance;
  bool get hasOutstandingCredit => creditBalance > 0;

  // Customer type display name
  String get customerTypeDisplayName {
    switch (customerType) {
      case CustomerType.retail:
        return 'Retail';
      case CustomerType.wholesale:
        return 'Wholesale';
    }
  }

  Customer copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? gstin,
    double? totalPurchases,
    int? visitCount,
    double? loyaltyPoints,
    double? creditBalance,
    double? creditLimit,
    CustomerType? customerType,
    double? discountPercentage,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      gstin: gstin ?? this.gstin,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      visitCount: visitCount ?? this.visitCount,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      creditBalance: creditBalance ?? this.creditBalance,
      creditLimit: creditLimit ?? this.creditLimit,
      customerType: customerType ?? this.customerType,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'gstin': gstin,
      'total_purchases': totalPurchases,
      'visit_count': visitCount,
      'loyalty_points': loyaltyPoints,
      'credit_balance': creditBalance,
      'credit_limit': creditLimit,
      'customer_type': customerType.name,
      'discount_percentage': discountPercentage,
      'notes': notes,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Minimal map for inserting new customers (only core database columns)
  Map<String, dynamic> toInsertMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'gstin': gstin,
      'notes': notes,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      gstin: map['gstin'] as String?,
      totalPurchases: (map['total_purchases'] as num?)?.toDouble() ?? 0,
      visitCount: map['visit_count'] as int? ?? 0,
      loyaltyPoints: (map['loyalty_points'] as num?)?.toDouble() ?? 0,
      creditBalance: (map['credit_balance'] as num?)?.toDouble() ?? 0,
      creditLimit: (map['credit_limit'] as num?)?.toDouble() ?? 5000,
      customerType: CustomerType.values.firstWhere(
        (e) => e.name == map['customer_type'],
        orElse: () => CustomerType.retail,
      ),
      discountPercentage: (map['discount_percentage'] as num?)?.toDouble() ?? 0,
      notes: map['notes'] as String?,
      isActive: map['is_active'] == 1 || map['is_active'] == true,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  static Customer walkInCustomer = Customer(
    id: 'walk-in',
    name: 'Walk-in Customer',
  );
}
