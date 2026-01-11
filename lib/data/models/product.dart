import 'package:uuid/uuid.dart';

class Product {
  final String id;
  final String name;
  final String? description;
  final String? sku;
  final String? barcode;
  final double price;
  final double? costPrice;
  final double? mrp; // Maximum Retail Price
  final double gstRate; // GST percentage (0, 5, 12, 18, 28)
  final String? batchNumber;
  final DateTime? expiryDate;
  final String? brand;
  final int stockQuantity;
  final int lowStockThreshold;
  final String categoryId;
  final String? imageUrl;
  final String unit;
  final bool trackInventory;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    String? id,
    required this.name,
    this.description,
    this.sku,
    this.barcode,
    required this.price,
    this.costPrice,
    this.mrp,
    this.gstRate = 0,
    this.batchNumber,
    this.expiryDate,
    this.brand,
    this.stockQuantity = 0,
    this.lowStockThreshold = 10,
    required this.categoryId,
    this.imageUrl,
    this.unit = 'Piece',
    this.trackInventory = true,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Product copyWith({
    String? id,
    String? name,
    String? description,
    String? sku,
    String? barcode,
    double? price,
    double? costPrice,
    double? mrp,
    double? gstRate,
    String? batchNumber,
    DateTime? expiryDate,
    String? brand,
    int? stockQuantity,
    int? lowStockThreshold,
    String? categoryId,
    String? imageUrl,
    String? unit,
    bool? trackInventory,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      mrp: mrp ?? this.mrp,
      gstRate: gstRate ?? this.gstRate,
      batchNumber: batchNumber ?? this.batchNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      brand: brand ?? this.brand,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      categoryId: categoryId ?? this.categoryId,
      imageUrl: imageUrl ?? this.imageUrl,
      unit: unit ?? this.unit,
      trackInventory: trackInventory ?? this.trackInventory,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'sku': sku,
      'barcode': barcode,
      'price': price,
      'cost_price': costPrice,
      'mrp': mrp,
      'gst_rate': gstRate,
      'batch_number': batchNumber,
      'expiry_date': expiryDate?.toIso8601String(),
      'brand': brand,
      'stock_quantity': stockQuantity,
      'low_stock_threshold': lowStockThreshold,
      'category_id': categoryId,
      'image_url': imageUrl,
      'unit': unit,
      'track_inventory': trackInventory,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      sku: map['sku'] as String?,
      barcode: map['barcode'] as String?,
      price: (map['price'] as num).toDouble(),
      costPrice: (map['cost_price'] as num?)?.toDouble(),
      mrp: (map['mrp'] as num?)?.toDouble(),
      gstRate: (map['gst_rate'] as num?)?.toDouble() ?? 0,
      batchNumber: map['batch_number'] as String?,
      expiryDate: map['expiry_date'] != null ? DateTime.tryParse(map['expiry_date'] as String) : null,
      brand: map['brand'] as String?,
      stockQuantity: map['stock_quantity'] as int? ?? 0,
      lowStockThreshold: map['low_stock_threshold'] as int? ?? 10,
      categoryId: map['category_id'] as String,
      imageUrl: map['image_url'] as String?,
      unit: map['unit'] as String? ?? 'Piece',
      trackInventory: map['track_inventory'] == 1 || map['track_inventory'] == true,
      isActive: map['is_active'] == 1 || map['is_active'] == true,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  bool get isLowStock => trackInventory && stockQuantity <= lowStockThreshold && stockQuantity > 0;
  bool get isOutOfStock => trackInventory && stockQuantity <= 0;
  bool get isInStock => !isLowStock && !isOutOfStock;
  
  bool get isExpired => expiryDate != null && expiryDate!.isBefore(DateTime.now());
  bool get isExpiringSoon => expiryDate != null && 
      expiryDate!.isAfter(DateTime.now()) && 
      expiryDate!.isBefore(DateTime.now().add(const Duration(days: 30)));
  
  double get profitMargin {
    if (costPrice == null || costPrice == 0) return 0;
    return ((price - costPrice!) / costPrice!) * 100;
  }

  /// Available unit options
  static const List<String> unitOptions = [
    'Piece',
    'pcs', // Legacy support
    'Bag',
    'Kg',
    'Gram',
    'Bottle',
    'Litre',
    'Box',
    'Roll',
    'Pallet',
    'Pack',
  ];

  /// Available GST rate options
  static const List<double> gstRateOptions = [0, 5, 12, 18, 28];
}
