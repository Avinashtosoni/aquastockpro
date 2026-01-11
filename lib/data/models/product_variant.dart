import 'package:uuid/uuid.dart';

/// Product Variant for size, color, weight variations
class ProductVariant {
  final String id;
  final String productId;
  final String name;          // e.g., "Large", "Red", "500g"
  final String type;          // e.g., "size", "color", "weight"
  final String? sku;
  final String? barcode;
  final double priceAdjustment; // Can be positive or negative
  final int stockQuantity;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductVariant({
    required this.id,
    required this.productId,
    required this.name,
    required this.type,
    this.sku,
    this.barcode,
    this.priceAdjustment = 0,
    this.stockQuantity = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductVariant.create({
    required String productId,
    required String name,
    required String type,
    String? sku,
    String? barcode,
    double priceAdjustment = 0,
    int stockQuantity = 0,
  }) {
    final now = DateTime.now();
    return ProductVariant(
      id: const Uuid().v4(),
      productId: productId,
      name: name,
      type: type,
      sku: sku,
      barcode: barcode,
      priceAdjustment: priceAdjustment,
      stockQuantity: stockQuantity,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String?,
      priceAdjustment: (json['price_adjustment'] as num?)?.toDouble() ?? 0,
      stockQuantity: json['stock_quantity'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'name': name,
      'type': type,
      'sku': sku,
      'barcode': barcode,
      'price_adjustment': priceAdjustment,
      'stock_quantity': stockQuantity,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ProductVariant copyWith({
    String? name,
    String? type,
    String? sku,
    String? barcode,
    double? priceAdjustment,
    int? stockQuantity,
    bool? isActive,
  }) {
    return ProductVariant(
      id: id,
      productId: productId,
      name: name ?? this.name,
      type: type ?? this.type,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      priceAdjustment: priceAdjustment ?? this.priceAdjustment,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

/// Variant options for dropdowns
class VariantOption {
  final String type;
  final List<String> values;

  const VariantOption({required this.type, required this.values});

  static const List<VariantOption> defaultOptions = [
    VariantOption(type: 'size', values: ['Small', 'Medium', 'Large', 'XL', 'XXL']),
    VariantOption(type: 'color', values: ['Red', 'Blue', 'Green', 'Black', 'White']),
    VariantOption(type: 'weight', values: ['250g', '500g', '1kg', '2kg', '5kg']),
    VariantOption(type: 'volume', values: ['100ml', '250ml', '500ml', '1L', '2L']),
  ];
}
