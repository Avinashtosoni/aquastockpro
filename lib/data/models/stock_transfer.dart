import 'package:uuid/uuid.dart';

/// Stock Transfer Status
enum StockTransferStatus {
  draft,
  pending,
  inTransit,
  completed,
  cancelled,
}

extension StockTransferStatusExtension on StockTransferStatus {
  String get displayName {
    switch (this) {
      case StockTransferStatus.draft:
        return 'Draft';
      case StockTransferStatus.pending:
        return 'Pending';
      case StockTransferStatus.inTransit:
        return 'In Transit';
      case StockTransferStatus.completed:
        return 'Completed';
      case StockTransferStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// Stock Transfer between stores/locations
class StockTransfer {
  final String id;
  final String transferNumber;
  final String fromStoreId;
  final String toStoreId;
  final String? fromStoreName;
  final String? toStoreName;
  final StockTransferStatus status;
  final List<StockTransferItem> items;
  final String? notes;
  final String? createdBy;
  final String? approvedBy;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final DateTime? completedAt;

  StockTransfer({
    required this.id,
    required this.transferNumber,
    required this.fromStoreId,
    required this.toStoreId,
    this.fromStoreName,
    this.toStoreName,
    required this.status,
    required this.items,
    this.notes,
    this.createdBy,
    this.approvedBy,
    required this.createdAt,
    this.approvedAt,
    this.completedAt,
  });

  factory StockTransfer.create({
    required String fromStoreId,
    required String toStoreId,
    String? fromStoreName,
    String? toStoreName,
    required List<StockTransferItem> items,
    String? notes,
    String? createdBy,
  }) {
    final now = DateTime.now();
    return StockTransfer(
      id: const Uuid().v4(),
      transferNumber: 'TRF-${now.millisecondsSinceEpoch.toString().substring(5)}',
      fromStoreId: fromStoreId,
      toStoreId: toStoreId,
      fromStoreName: fromStoreName,
      toStoreName: toStoreName,
      status: StockTransferStatus.draft,
      items: items,
      notes: notes,
      createdBy: createdBy,
      createdAt: now,
    );
  }

  factory StockTransfer.fromJson(Map<String, dynamic> json) {
    return StockTransfer(
      id: json['id'] as String,
      transferNumber: json['transfer_number'] as String,
      fromStoreId: json['from_store_id'] as String,
      toStoreId: json['to_store_id'] as String,
      fromStoreName: json['from_store_name'] as String?,
      toStoreName: json['to_store_name'] as String?,
      status: StockTransferStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => StockTransferStatus.draft,
      ),
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => StockTransferItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String?,
      approvedBy: json['approved_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      approvedAt: json['approved_at'] != null 
          ? DateTime.parse(json['approved_at'] as String) 
          : null,
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transfer_number': transferNumber,
      'from_store_id': fromStoreId,
      'to_store_id': toStoreId,
      'from_store_name': fromStoreName,
      'to_store_name': toStoreName,
      'status': status.name,
      'items': items.map((e) => e.toJson()).toList(),
      'notes': notes,
      'created_by': createdBy,
      'approved_by': approvedBy,
      'created_at': createdAt.toIso8601String(),
      'approved_at': approvedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  /// Total items in transfer
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  StockTransfer copyWith({
    StockTransferStatus? status,
    String? notes,
    String? approvedBy,
    DateTime? approvedAt,
    DateTime? completedAt,
  }) {
    return StockTransfer(
      id: id,
      transferNumber: transferNumber,
      fromStoreId: fromStoreId,
      toStoreId: toStoreId,
      fromStoreName: fromStoreName,
      toStoreName: toStoreName,
      status: status ?? this.status,
      items: items,
      notes: notes ?? this.notes,
      createdBy: createdBy,
      approvedBy: approvedBy ?? this.approvedBy,
      createdAt: createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

/// Stock Transfer Item
class StockTransferItem {
  final String id;
  final String productId;
  final String? variantId;
  final String productName;
  final String? sku;
  final int quantity;
  final int? receivedQuantity;

  StockTransferItem({
    required this.id,
    required this.productId,
    this.variantId,
    required this.productName,
    this.sku,
    required this.quantity,
    this.receivedQuantity,
  });

  factory StockTransferItem.create({
    required String productId,
    String? variantId,
    required String productName,
    String? sku,
    required int quantity,
  }) {
    return StockTransferItem(
      id: const Uuid().v4(),
      productId: productId,
      variantId: variantId,
      productName: productName,
      sku: sku,
      quantity: quantity,
    );
  }

  factory StockTransferItem.fromJson(Map<String, dynamic> json) {
    return StockTransferItem(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      variantId: json['variant_id'] as String?,
      productName: json['product_name'] as String,
      sku: json['sku'] as String?,
      quantity: json['quantity'] as int? ?? 0,
      receivedQuantity: json['received_quantity'] as int?,
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
    };
  }
}
