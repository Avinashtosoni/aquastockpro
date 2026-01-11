import 'package:uuid/uuid.dart';

enum RestockStatus { pending, restocked, discarded }

class RefundItem {
  final String id;
  final String refundId;
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalAmount;
  final RestockStatus restockStatus;
  final DateTime createdAt;

  RefundItem({
    String? id,
    required this.refundId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    double? totalAmount,
    this.restockStatus = RestockStatus.pending,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        totalAmount = totalAmount ?? (quantity * unitPrice),
        createdAt = createdAt ?? DateTime.now();

  RefundItem copyWith({
    String? id,
    String? refundId,
    String? productId,
    String? productName,
    int? quantity,
    double? unitPrice,
    double? totalAmount,
    RestockStatus? restockStatus,
    DateTime? createdAt,
  }) {
    return RefundItem(
      id: id ?? this.id,
      refundId: refundId ?? this.refundId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalAmount: totalAmount ?? this.totalAmount,
      restockStatus: restockStatus ?? this.restockStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'refund_id': refundId,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_amount': totalAmount,
      'restock_status': restockStatus.name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory RefundItem.fromMap(Map<String, dynamic> map) {
    return RefundItem(
      id: map['id'] as String,
      refundId: map['refund_id'] as String,
      productId: map['product_id'] as String,
      productName: map['product_name'] as String,
      quantity: map['quantity'] as int,
      unitPrice: (map['unit_price'] as num).toDouble(),
      totalAmount: (map['total_amount'] as num).toDouble(),
      restockStatus: RestockStatus.values.firstWhere(
        (e) => e.name == map['restock_status'],
        orElse: () => RestockStatus.pending,
      ),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  String get restockStatusDisplayName {
    switch (restockStatus) {
      case RestockStatus.pending:
        return 'Pending';
      case RestockStatus.restocked:
        return 'Restocked';
      case RestockStatus.discarded:
        return 'Discarded';
    }
  }
}
