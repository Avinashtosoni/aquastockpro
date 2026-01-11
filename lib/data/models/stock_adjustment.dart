import 'package:uuid/uuid.dart';

enum StockAdjustmentReason {
  damage,
  theft,
  expired,
  correction,
  received,
  returned,
  other,
}

class StockAdjustment {
  final String id;
  final String productId;
  final String productName;
  final int previousQuantity;
  final int adjustedQuantity; // Positive for increase, negative for decrease
  final int newQuantity;
  final StockAdjustmentReason reason;
  final String? notes;
  final String employeeId;
  final String employeeName;
  final DateTime createdAt;

  StockAdjustment({
    String? id,
    required this.productId,
    required this.productName,
    required this.previousQuantity,
    required this.adjustedQuantity,
    required this.newQuantity,
    required this.reason,
    this.notes,
    required this.employeeId,
    required this.employeeName,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  String get reasonDisplayName {
    switch (reason) {
      case StockAdjustmentReason.damage:
        return 'Damaged';
      case StockAdjustmentReason.theft:
        return 'Theft/Loss';
      case StockAdjustmentReason.expired:
        return 'Expired';
      case StockAdjustmentReason.correction:
        return 'Stock Correction';
      case StockAdjustmentReason.received:
        return 'Stock Received';
      case StockAdjustmentReason.returned:
        return 'Returned to Supplier';
      case StockAdjustmentReason.other:
        return 'Other';
    }
  }

  bool get isIncrease => adjustedQuantity > 0;
  bool get isDecrease => adjustedQuantity < 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'previous_quantity': previousQuantity,
      'adjusted_quantity': adjustedQuantity,
      'new_quantity': newQuantity,
      'reason': reason.name,
      'notes': notes,
      'employee_id': employeeId,
      'employee_name': employeeName,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory StockAdjustment.fromMap(Map<String, dynamic> map) {
    return StockAdjustment(
      id: map['id'] as String,
      productId: map['product_id'] as String,
      productName: map['product_name'] as String,
      previousQuantity: map['previous_quantity'] as int,
      adjustedQuantity: map['adjusted_quantity'] as int,
      newQuantity: map['new_quantity'] as int,
      reason: StockAdjustmentReason.values.firstWhere(
        (e) => e.name == map['reason'],
        orElse: () => StockAdjustmentReason.other,
      ),
      notes: map['notes'] as String?,
      employeeId: map['employee_id'] as String,
      employeeName: map['employee_name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
