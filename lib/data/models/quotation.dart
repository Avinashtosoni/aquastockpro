import 'package:uuid/uuid.dart';
import 'quotation_item.dart';

enum QuotationStatus { draft, sent, accepted, rejected, expired, converted }

class Quotation {
  final String id;
  final String quotationNumber;
  final String? customerId;
  final String? customerName;
  final String? employeeId;
  final String? employeeName;
  final List<QuotationItem> items;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  final DateTime? validUntil;
  final QuotationStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Quotation({
    String? id,
    required this.quotationNumber,
    this.customerId,
    this.customerName,
    this.employeeId,
    this.employeeName,
    required this.items,
    required this.subtotal,
    this.taxAmount = 0,
    this.discountAmount = 0,
    required this.totalAmount,
    this.validUntil,
    this.status = QuotationStatus.draft,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Quotation copyWith({
    String? id,
    String? quotationNumber,
    String? customerId,
    String? customerName,
    String? employeeId,
    String? employeeName,
    List<QuotationItem>? items,
    double? subtotal,
    double? taxAmount,
    double? discountAmount,
    double? totalAmount,
    DateTime? validUntil,
    QuotationStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Quotation(
      id: id ?? this.id,
      quotationNumber: quotationNumber ?? this.quotationNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      validUntil: validUntil ?? this.validUntil,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quotation_number': quotationNumber,
      'customer_id': customerId,
      'customer_name': customerName,
      'user_id': employeeId,
      'employee_name': employeeName ?? 'Staff',
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'discount_amount': discountAmount,
      'total_amount': totalAmount,
      'valid_until': validUntil?.toIso8601String(),
      'item_count': itemCount,
      'status': status.name,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Quotation.fromMap(Map<String, dynamic> map, {List<QuotationItem>? items}) {
    return Quotation(
      id: map['id'] as String,
      quotationNumber: map['quotation_number'] as String,
      customerId: map['customer_id'] as String?,
      customerName: map['customer_name'] as String?,
      employeeId: map['user_id'] as String?,
      employeeName: map['employee_name'] as String?,
      items: items ?? [],
      subtotal: (map['subtotal'] as num).toDouble(),
      taxAmount: (map['tax_amount'] as num?)?.toDouble() ?? 0,
      discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0,
      totalAmount: (map['total_amount'] as num).toDouble(),
      validUntil: map['valid_until'] != null 
          ? DateTime.parse(map['valid_until'] as String) 
          : null,
      status: QuotationStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => QuotationStatus.draft,
      ),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  
  bool get isExpired => validUntil != null && DateTime.now().isAfter(validUntil!);
  
  String get statusDisplayName {
    switch (status) {
      case QuotationStatus.draft:
        return 'Draft';
      case QuotationStatus.sent:
        return 'Sent';
      case QuotationStatus.accepted:
        return 'Accepted';
      case QuotationStatus.rejected:
        return 'Rejected';
      case QuotationStatus.expired:
        return 'Expired';
      case QuotationStatus.converted:
        return 'Converted';
    }
  }
}
