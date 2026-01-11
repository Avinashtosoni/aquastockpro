import 'package:uuid/uuid.dart';

/// Product Batch for expiry date tracking and batch management
class ProductBatch {
  final String id;
  final String productId;
  final String? variantId;
  final String batchNumber;
  final DateTime? manufacturingDate;
  final DateTime? expiryDate;
  final int quantity;
  final double? costPrice;
  final String? supplierId;
  final String? purchaseOrderId;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductBatch({
    required this.id,
    required this.productId,
    this.variantId,
    required this.batchNumber,
    this.manufacturingDate,
    this.expiryDate,
    required this.quantity,
    this.costPrice,
    this.supplierId,
    this.purchaseOrderId,
    this.notes,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductBatch.create({
    required String productId,
    String? variantId,
    required String batchNumber,
    DateTime? manufacturingDate,
    DateTime? expiryDate,
    required int quantity,
    double? costPrice,
    String? supplierId,
    String? purchaseOrderId,
    String? notes,
  }) {
    final now = DateTime.now();
    return ProductBatch(
      id: const Uuid().v4(),
      productId: productId,
      variantId: variantId,
      batchNumber: batchNumber,
      manufacturingDate: manufacturingDate,
      expiryDate: expiryDate,
      quantity: quantity,
      costPrice: costPrice,
      supplierId: supplierId,
      purchaseOrderId: purchaseOrderId,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory ProductBatch.fromJson(Map<String, dynamic> json) {
    return ProductBatch(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      variantId: json['variant_id'] as String?,
      batchNumber: json['batch_number'] as String,
      manufacturingDate: json['manufacturing_date'] != null 
          ? DateTime.parse(json['manufacturing_date'] as String) 
          : null,
      expiryDate: json['expiry_date'] != null 
          ? DateTime.parse(json['expiry_date'] as String) 
          : null,
      quantity: json['quantity'] as int? ?? 0,
      costPrice: (json['cost_price'] as num?)?.toDouble(),
      supplierId: json['supplier_id'] as String?,
      purchaseOrderId: json['purchase_order_id'] as String?,
      notes: json['notes'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'variant_id': variantId,
      'batch_number': batchNumber,
      'manufacturing_date': manufacturingDate?.toIso8601String(),
      'expiry_date': expiryDate?.toIso8601String(),
      'quantity': quantity,
      'cost_price': costPrice,
      'supplier_id': supplierId,
      'purchase_order_id': purchaseOrderId,
      'notes': notes,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Check if batch is expired
  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  /// Check if batch is expiring soon (within 30 days)
  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final daysUntilExpiry = expiryDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiry >= 0 && daysUntilExpiry <= 30;
  }

  /// Days until expiry (negative if expired)
  int? get daysUntilExpiry {
    if (expiryDate == null) return null;
    return expiryDate!.difference(DateTime.now()).inDays;
  }

  ProductBatch copyWith({
    String? batchNumber,
    DateTime? manufacturingDate,
    DateTime? expiryDate,
    int? quantity,
    double? costPrice,
    String? notes,
    bool? isActive,
  }) {
    return ProductBatch(
      id: id,
      productId: productId,
      variantId: variantId,
      batchNumber: batchNumber ?? this.batchNumber,
      manufacturingDate: manufacturingDate ?? this.manufacturingDate,
      expiryDate: expiryDate ?? this.expiryDate,
      quantity: quantity ?? this.quantity,
      costPrice: costPrice ?? this.costPrice,
      supplierId: supplierId,
      purchaseOrderId: purchaseOrderId,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
