import 'package:uuid/uuid.dart';

enum InventoryLogType { purchase, sale, adjustment, return_, damage, transfer }

class InventoryLog {
  final String id;
  final String productId;
  final String productName;
  final InventoryLogType type;
  final int quantityChange;
  final int previousQuantity;
  final int newQuantity;
  final String? referenceId;
  final String? notes;
  final String userId;
  final DateTime createdAt;

  InventoryLog({
    String? id,
    required this.productId,
    required this.productName,
    required this.type,
    required this.quantityChange,
    required this.previousQuantity,
    required this.newQuantity,
    this.referenceId,
    this.notes,
    required this.userId,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'type': type.name,
      'quantity_change': quantityChange,
      'previous_quantity': previousQuantity,
      'new_quantity': newQuantity,
      'reference_id': referenceId,
      'notes': notes,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory InventoryLog.fromMap(Map<String, dynamic> map) {
    return InventoryLog(
      id: map['id'] as String,
      productId: map['product_id'] as String,
      productName: map['product_name'] as String,
      type: InventoryLogType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => InventoryLogType.adjustment,
      ),
      quantityChange: map['quantity_change'] as int,
      previousQuantity: map['previous_quantity'] as int,
      newQuantity: map['new_quantity'] as int,
      referenceId: map['reference_id'] as String?,
      notes: map['notes'] as String?,
      userId: map['user_id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  String get typeDisplayName {
    switch (type) {
      case InventoryLogType.purchase:
        return 'Purchase';
      case InventoryLogType.sale:
        return 'Sale';
      case InventoryLogType.adjustment:
        return 'Adjustment';
      case InventoryLogType.return_:
        return 'Return';
      case InventoryLogType.damage:
        return 'Damage';
      case InventoryLogType.transfer:
        return 'Transfer';
    }
  }
}
