import 'package:uuid/uuid.dart';

enum DiscountType { percentage, fixed, bogo }

class Discount {
  final String id;
  final String name;
  final String? code;
  final DiscountType type;
  final double value;
  final double minPurchase;
  final double? maxDiscount;
  final List<String>? applicableProducts;
  final List<String>? applicableCategories;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final int? usageLimit;
  final int usageCount;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Discount({
    String? id,
    required this.name,
    this.code,
    required this.type,
    required this.value,
    this.minPurchase = 0,
    this.maxDiscount,
    this.applicableProducts,
    this.applicableCategories,
    this.validFrom,
    this.validUntil,
    this.usageLimit,
    this.usageCount = 0,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Discount copyWith({
    String? id,
    String? name,
    String? code,
    DiscountType? type,
    double? value,
    double? minPurchase,
    double? maxDiscount,
    List<String>? applicableProducts,
    List<String>? applicableCategories,
    DateTime? validFrom,
    DateTime? validUntil,
    int? usageLimit,
    int? usageCount,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Discount(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      type: type ?? this.type,
      value: value ?? this.value,
      minPurchase: minPurchase ?? this.minPurchase,
      maxDiscount: maxDiscount ?? this.maxDiscount,
      applicableProducts: applicableProducts ?? this.applicableProducts,
      applicableCategories: applicableCategories ?? this.applicableCategories,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      usageLimit: usageLimit ?? this.usageLimit,
      usageCount: usageCount ?? this.usageCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'type': type.name,
      'value': value,
      'min_purchase': minPurchase,
      'max_discount': maxDiscount,
      'applicable_products': applicableProducts?.join(','),
      'applicable_categories': applicableCategories?.join(','),
      'valid_from': validFrom?.toIso8601String(),
      'valid_until': validUntil?.toIso8601String(),
      'usage_limit': usageLimit,
      'usage_count': usageCount,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Discount.fromMap(Map<String, dynamic> map) {
    return Discount(
      id: map['id'] as String,
      name: map['name'] as String,
      code: map['code'] as String?,
      type: DiscountType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => DiscountType.percentage,
      ),
      value: (map['value'] as num).toDouble(),
      minPurchase: (map['min_purchase'] as num?)?.toDouble() ?? 0,
      maxDiscount: (map['max_discount'] as num?)?.toDouble(),
      applicableProducts: map['applicable_products'] != null
          ? (map['applicable_products'] as String).split(',')
          : null,
      applicableCategories: map['applicable_categories'] != null
          ? (map['applicable_categories'] as String).split(',')
          : null,
      validFrom: map['valid_from'] != null
          ? DateTime.parse(map['valid_from'] as String)
          : null,
      validUntil: map['valid_until'] != null
          ? DateTime.parse(map['valid_until'] as String)
          : null,
      usageLimit: map['usage_limit'] as int?,
      usageCount: map['usage_count'] as int? ?? 0,
      isActive: map['is_active'] == 1 || map['is_active'] == true,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  String get typeDisplayName {
    switch (type) {
      case DiscountType.percentage:
        return 'Percentage';
      case DiscountType.fixed:
        return 'Fixed Amount';
      case DiscountType.bogo:
        return 'Buy One Get One';
    }
  }

  String get valueDisplay {
    switch (type) {
      case DiscountType.percentage:
        return '${value.toStringAsFixed(0)}%';
      case DiscountType.fixed:
        return '₹${value.toStringAsFixed(2)}';
      case DiscountType.bogo:
        return 'Buy ${value.toInt()} Get 1';
    }
  }

  /// Check if discount is currently valid
  bool get isValid {
    if (!isActive) return false;
    
    final now = DateTime.now();
    if (validFrom != null && now.isBefore(validFrom!)) return false;
    if (validUntil != null && now.isAfter(validUntil!)) return false;
    if (usageLimit != null && usageCount >= usageLimit!) return false;
    
    return true;
  }

  /// Check if this discount applies to a product
  bool appliesToProduct(String productId, String categoryId) {
    // If no restrictions, applies to all
    if ((applicableProducts == null || applicableProducts!.isEmpty) &&
        (applicableCategories == null || applicableCategories!.isEmpty)) {
      return true;
    }
    
    // Check product-specific
    if (applicableProducts != null && applicableProducts!.contains(productId)) {
      return true;
    }
    
    // Check category-specific
    if (applicableCategories != null && applicableCategories!.contains(categoryId)) {
      return true;
    }
    
    return false;
  }

  /// Calculate discount amount for a given subtotal
  double calculateDiscount(double subtotal) {
    if (subtotal < minPurchase) return 0;
    
    double discountAmount;
    
    switch (type) {
      case DiscountType.percentage:
        discountAmount = subtotal * (value / 100);
        break;
      case DiscountType.fixed:
        discountAmount = value;
        break;
      case DiscountType.bogo:
        // BOGO logic should be handled at cart level
        discountAmount = 0;
        break;
    }
    
    // Apply max discount cap
    if (maxDiscount != null && discountAmount > maxDiscount!) {
      discountAmount = maxDiscount!;
    }
    
    // Can't discount more than subtotal
    if (discountAmount > subtotal) {
      discountAmount = subtotal;
    }
    
    return discountAmount;
  }
}
