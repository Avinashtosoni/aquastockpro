import 'package:uuid/uuid.dart';
import 'refund_item.dart';

enum RefundStatus { pending, approved, completed, rejected }

class Refund {
  final String id;
  final String orderId;
  final String? customerId;
  final String? employeeId;
  final String refundNumber;
  final double amount;
  final String? reason;
  final RefundStatus status;
  final String? notes;
  final List<RefundItem> items;
  final DateTime? processedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Refund({
    String? id,
    required this.orderId,
    this.customerId,
    this.employeeId,
    required this.refundNumber,
    required this.amount,
    this.reason,
    this.status = RefundStatus.pending,
    this.notes,
    this.items = const [],
    this.processedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Refund copyWith({
    String? id,
    String? orderId,
    String? customerId,
    String? employeeId,
    String? refundNumber,
    double? amount,
    String? reason,
    RefundStatus? status,
    String? notes,
    List<RefundItem>? items,
    DateTime? processedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Refund(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      customerId: customerId ?? this.customerId,
      employeeId: employeeId ?? this.employeeId,
      refundNumber: refundNumber ?? this.refundNumber,
      amount: amount ?? this.amount,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      items: items ?? this.items,
      processedAt: processedAt ?? this.processedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'customer_id': customerId,
      'employee_id': employeeId,
      'refund_number': refundNumber,
      'amount': amount,
      'reason': reason,
      'status': status.name,
      'notes': notes,
      'processed_at': processedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Refund.fromMap(Map<String, dynamic> map, {List<RefundItem>? items}) {
    return Refund(
      id: map['id'] as String,
      orderId: map['order_id'] as String,
      customerId: map['customer_id'] as String?,
      employeeId: map['employee_id'] as String?,
      refundNumber: map['refund_number'] as String,
      amount: (map['amount'] as num).toDouble(),
      reason: map['reason'] as String?,
      status: RefundStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => RefundStatus.pending,
      ),
      notes: map['notes'] as String?,
      items: items ?? [],
      processedAt: map['processed_at'] != null
          ? DateTime.parse(map['processed_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  String get statusDisplayName {
    switch (status) {
      case RefundStatus.pending:
        return 'Pending';
      case RefundStatus.approved:
        return 'Approved';
      case RefundStatus.completed:
        return 'Completed';
      case RefundStatus.rejected:
        return 'Rejected';
    }
  }

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  /// Generate a unique refund number
  static String generateRefundNumber() {
    final now = DateTime.now();
    final timestamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final random = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    return 'REF-$timestamp-$random';
  }
}
