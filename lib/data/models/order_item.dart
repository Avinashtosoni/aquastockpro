import 'package:uuid/uuid.dart';
import 'product.dart';

class OrderItem {
  final String id;
  final String orderId;
  final String productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final double discount;
  final double taxRate;
  final double total;

  OrderItem({
    String? id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    this.quantity = 1,
    this.discount = 0,
    this.taxRate = 0,
    double? total,
  })  : id = id ?? const Uuid().v4(),
        total = total ?? ((unitPrice * quantity) - discount);

  OrderItem copyWith({
    String? id,
    String? orderId,
    String? productId,
    String? productName,
    double? unitPrice,
    int? quantity,
    double? discount,
    double? taxRate,
    double? total,
  }) {
    final newQuantity = quantity ?? this.quantity;
    final newUnitPrice = unitPrice ?? this.unitPrice;
    final newDiscount = discount ?? this.discount;
    return OrderItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      unitPrice: newUnitPrice,
      quantity: newQuantity,
      discount: newDiscount,
      taxRate: taxRate ?? this.taxRate,
      total: total ?? ((newUnitPrice * newQuantity) - newDiscount),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'product_name': productName,
      'unit_price': unitPrice,
      'quantity': quantity,
      'discount_amount': discount,
      'tax_amount': taxRate,
      'total_price': total,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] as String,
      orderId: map['order_id'] as String,
      productId: map['product_id'] as String,
      productName: map['product_name'] as String,
      unitPrice: (map['unit_price'] as num).toDouble(),
      quantity: map['quantity'] as int,
      discount: (map['discount_amount'] as num?)?.toDouble() ?? 0,
      taxRate: (map['tax_amount'] as num?)?.toDouble() ?? 0,
      total: (map['total_price'] as num).toDouble(),
    );
  }

  factory OrderItem.fromProduct(Product product, String orderId, {int quantity = 1}) {
    return OrderItem(
      orderId: orderId,
      productId: product.id,
      productName: product.name,
      unitPrice: product.price,
      quantity: quantity,
    );
  }

  double get subtotal => unitPrice * quantity;
  double get taxAmount => subtotal * (taxRate / 100);
}
