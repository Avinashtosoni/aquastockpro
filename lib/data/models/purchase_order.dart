import 'package:uuid/uuid.dart';

/// Purchase Order Status
enum PurchaseOrderStatus {
  draft,
  pending,
  ordered,
  partiallyReceived,
  received,
  cancelled,
}

extension PurchaseOrderStatusExtension on PurchaseOrderStatus {
  String get displayName {
    switch (this) {
      case PurchaseOrderStatus.draft:
        return 'Draft';
      case PurchaseOrderStatus.pending:
        return 'Pending';
      case PurchaseOrderStatus.ordered:
        return 'Ordered';
      case PurchaseOrderStatus.partiallyReceived:
        return 'Partial';
      case PurchaseOrderStatus.received:
        return 'Received';
      case PurchaseOrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// Purchase Order model for supplier orders
class PurchaseOrder {
  final String id;
  final String orderNumber;
  final String supplierId;
  final String? supplierName;
  final PurchaseOrderStatus status;
  final DateTime orderDate;
  final DateTime? expectedDeliveryDate;
  final DateTime? receivedDate;
  final List<PurchaseOrderItem> items;
  final double subtotal;
  final double taxAmount;
  final double discount;
  final double totalAmount;
  final double? paidAmount;
  final String? notes;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  PurchaseOrder({
    required this.id,
    required this.orderNumber,
    required this.supplierId,
    this.supplierName,
    required this.status,
    required this.orderDate,
    this.expectedDeliveryDate,
    this.receivedDate,
    required this.items,
    required this.subtotal,
    required this.taxAmount,
    required this.discount,
    required this.totalAmount,
    this.paidAmount,
    this.notes,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PurchaseOrder.create({
    required String supplierId,
    String? supplierName,
    required List<PurchaseOrderItem> items,
    DateTime? expectedDeliveryDate,
    double taxRate = 0,
    double discount = 0,
    String? notes,
    String? createdBy,
  }) {
    final now = DateTime.now();
    final subtotal = items.fold(0.0, (sum, item) => sum + item.total);
    final taxAmount = subtotal * (taxRate / 100);
    final total = subtotal + taxAmount - discount;
    
    return PurchaseOrder(
      id: const Uuid().v4(),
      orderNumber: 'PO-${now.millisecondsSinceEpoch.toString().substring(5)}',
      supplierId: supplierId,
      supplierName: supplierName,
      status: PurchaseOrderStatus.draft,
      orderDate: now,
      expectedDeliveryDate: expectedDeliveryDate,
      items: items,
      subtotal: subtotal,
      taxAmount: taxAmount,
      discount: discount,
      totalAmount: total,
      notes: notes,
      createdBy: createdBy,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    return PurchaseOrder(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String,
      supplierId: json['supplier_id'] as String,
      supplierName: json['supplier_name'] as String?,
      status: PurchaseOrderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PurchaseOrderStatus.draft,
      ),
      orderDate: DateTime.parse(json['order_date'] as String),
      expectedDeliveryDate: json['expected_delivery_date'] != null 
          ? DateTime.parse(json['expected_delivery_date'] as String) 
          : null,
      receivedDate: json['received_date'] != null 
          ? DateTime.parse(json['received_date'] as String) 
          : null,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => PurchaseOrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      paidAmount: (json['paid_amount'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'supplier_id': supplierId,
      'supplier_name': supplierName,
      'status': status.name,
      'order_date': orderDate.toIso8601String(),
      'expected_delivery_date': expectedDeliveryDate?.toIso8601String(),
      'received_date': receivedDate?.toIso8601String(),
      'items': items.map((e) => e.toJson()).toList(),
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'discount': discount,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'notes': notes,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Outstanding balance
  double get balance => totalAmount - (paidAmount ?? 0);

  /// Is fully paid
  bool get isFullyPaid => balance <= 0;

  PurchaseOrder copyWith({
    PurchaseOrderStatus? status,
    DateTime? expectedDeliveryDate,
    DateTime? receivedDate,
    List<PurchaseOrderItem>? items,
    double? paidAmount,
    String? notes,
  }) {
    return PurchaseOrder(
      id: id,
      orderNumber: orderNumber,
      supplierId: supplierId,
      supplierName: supplierName,
      status: status ?? this.status,
      orderDate: orderDate,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      receivedDate: receivedDate ?? this.receivedDate,
      items: items ?? this.items,
      subtotal: subtotal,
      taxAmount: taxAmount,
      discount: discount,
      totalAmount: totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      notes: notes ?? this.notes,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

/// Purchase Order Item
class PurchaseOrderItem {
  final String id;
  final String productId;
  final String? variantId;
  final String productName;
  final String? sku;
  final int quantity;
  final int receivedQuantity;
  final double unitPrice;
  final double total;

  PurchaseOrderItem({
    required this.id,
    required this.productId,
    this.variantId,
    required this.productName,
    this.sku,
    required this.quantity,
    this.receivedQuantity = 0,
    required this.unitPrice,
    required this.total,
  });

  factory PurchaseOrderItem.create({
    required String productId,
    String? variantId,
    required String productName,
    String? sku,
    required int quantity,
    required double unitPrice,
  }) {
    return PurchaseOrderItem(
      id: const Uuid().v4(),
      productId: productId,
      variantId: variantId,
      productName: productName,
      sku: sku,
      quantity: quantity,
      unitPrice: unitPrice,
      total: quantity * unitPrice,
    );
  }

  factory PurchaseOrderItem.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderItem(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      variantId: json['variant_id'] as String?,
      productName: json['product_name'] as String,
      sku: json['sku'] as String?,
      quantity: json['quantity'] as int? ?? 0,
      receivedQuantity: json['received_quantity'] as int? ?? 0,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'variant_id': variantId,
      'product_name': productName,
      'sku': sku,
      'quantity': quantity,
      'received_quantity': receivedQuantity,
      'unit_price': unitPrice,
      'total': total,
    };
  }

  /// Pending quantity to receive
  int get pendingQuantity => quantity - receivedQuantity;

  /// Is fully received
  bool get isFullyReceived => receivedQuantity >= quantity;
}
