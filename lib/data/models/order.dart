import 'package:uuid/uuid.dart';
import 'order_item.dart';

enum OrderStatus { pending, completed, cancelled, refunded, onHold }

enum PaymentMethod { cash, card, upi, credit, mixed }

class Order {
  final String id;
  final String orderNumber;
  final String? customerId;
  final String? customerName;
  final String? employeeId;
  final String? employeeName;
  final List<OrderItem> items;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  final double paidAmount;
  final double changeAmount;
  final OrderStatus status;
  final PaymentMethod paymentMethod;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Order({
    String? id,
    required this.orderNumber,
    this.customerId,
    this.customerName,
    this.employeeId,
    this.employeeName,
    required this.items,
    required this.subtotal,
    this.taxAmount = 0,
    this.discountAmount = 0,
    required this.totalAmount,
    this.paidAmount = 0,
    this.changeAmount = 0,
    this.status = OrderStatus.pending,
    this.paymentMethod = PaymentMethod.cash,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Order copyWith({
    String? id,
    String? orderNumber,
    String? customerId,
    String? customerName,
    String? employeeId,
    String? employeeName,
    List<OrderItem>? items,
    double? subtotal,
    double? taxAmount,
    double? discountAmount,
    double? totalAmount,
    double? paidAmount,
    double? changeAmount,
    OrderStatus? status,
    PaymentMethod? paymentMethod,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Order(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      changeAmount: changeAmount ?? this.changeAmount,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_number': orderNumber,
      'customer_id': customerId,
      'customer_name': customerName,
      'user_id': employeeId,
      'employee_name': employeeName ?? 'Staff',
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'discount_amount': discountAmount,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'change_amount': changeAmount,
      'item_count': itemCount,
      'status': status.name,
      'payment_method': paymentMethod.name,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Order.fromMap(Map<String, dynamic> map, {List<OrderItem>? items}) {
    return Order(
      id: map['id'] as String,
      orderNumber: map['order_number'] as String,
      customerId: map['customer_id'] as String?,
      customerName: map['customer_name'] as String?,
      employeeId: map['user_id'] as String?,
      employeeName: map['employee_name'] as String?,
      items: items ?? [],
      subtotal: (map['subtotal'] as num).toDouble(),
      taxAmount: (map['tax_amount'] as num?)?.toDouble() ?? 0,
      discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0,
      totalAmount: (map['total_amount'] as num).toDouble(),
      paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? 0,
      changeAmount: (map['change_amount'] as num?)?.toDouble() ?? 0,
      status: OrderStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => OrderStatus.pending,
      ),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == map['payment_method'],
        orElse: () => PaymentMethod.cash,
      ),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  
  String get statusDisplayName {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.refunded:
        return 'Refunded';
      case OrderStatus.onHold:
        return 'On Hold';
    }
  }

  String get paymentMethodDisplayName {
    switch (paymentMethod) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.credit:
        return 'Credit';
      case PaymentMethod.mixed:
        return 'Mixed';
    }
  }
}
