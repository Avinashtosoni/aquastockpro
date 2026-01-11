import 'package:uuid/uuid.dart';

class Supplier {
  final String id;
  final String name;
  final String? contactPerson;
  final String phone;
  final String? email;
  final String? address;
  final String? gstin;
  final double outstandingAmount; // Amount we owe to supplier
  final String? bankDetails;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Supplier({
    String? id,
    required this.name,
    this.contactPerson,
    required this.phone,
    this.email,
    this.address,
    this.gstin,
    this.outstandingAmount = 0,
    this.bankDetails,
    this.notes,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Supplier copyWith({
    String? id,
    String? name,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    String? gstin,
    double? outstandingAmount,
    String? bankDetails,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      gstin: gstin ?? this.gstin,
      outstandingAmount: outstandingAmount ?? this.outstandingAmount,
      bankDetails: bankDetails ?? this.bankDetails,
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
      'contact_person': contactPerson,
      'phone': phone,
      'email': email,
      'address': address,
      'gstin': gstin,
      // 'outstanding_amount': outstandingAmount, // TODO: Add column to DB
      // 'bank_details': bankDetails, // TODO: Add column to DB
      // 'notes': notes, // TODO: Add column to DB
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'] as String,
      name: map['name'] as String,
      contactPerson: map['contact_person'] as String?,
      phone: map['phone'] as String,
      email: map['email'] as String?,
      address: map['address'] as String?,
      gstin: map['gstin'] as String?,
      outstandingAmount: (map['outstanding_amount'] as num?)?.toDouble() ?? 0,
      bankDetails: map['bank_details'] as String?, // May be null if column doesn't exist
      notes: map['notes'] as String?,
      isActive: map['is_active'] == 1 || map['is_active'] == true,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
