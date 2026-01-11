import 'package:uuid/uuid.dart';

enum CreditTransactionType {
  creditGiven,    // Credit given on purchase
  paymentReceived, // Payment received from customer
  adjustment,      // Manual adjustment
  refundCredit,    // Credit given for refund
}

class CreditTransaction {
  final String id;
  final String customerId;
  final String? orderId;
  final double amount;
  final CreditTransactionType type;
  final double previousBalance;
  final double newBalance;
  final String? notes;
  final String? collectedBy; // Employee who collected payment
  final DateTime createdAt;

  CreditTransaction({
    String? id,
    required this.customerId,
    this.orderId,
    required this.amount,
    required this.type,
    required this.previousBalance,
    required this.newBalance,
    this.notes,
    this.collectedBy,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  String get typeDisplayName {
    switch (type) {
      case CreditTransactionType.creditGiven:
        return 'Credit Given';
      case CreditTransactionType.paymentReceived:
        return 'Payment Received';
      case CreditTransactionType.adjustment:
        return 'Adjustment';
      case CreditTransactionType.refundCredit:
        return 'Refund Credit';
    }
  }

  bool get isCredit => type == CreditTransactionType.creditGiven;
  bool get isPayment => type == CreditTransactionType.paymentReceived;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'order_id': orderId,
      'type': type.name,
      'amount': amount,
      'balance_after': newBalance, // DB uses balance_after, not new_balance
      'notes': notes,
      // 'created_by': createdBy, // Not using this field currently
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CreditTransaction.fromMap(Map<String, dynamic> map) {
    return CreditTransaction(
      id: map['id'] as String,
      customerId: map['customer_id'] as String,
      orderId: map['order_id'] as String?,
      amount: (map['amount'] as num).toDouble(),
      type: CreditTransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => CreditTransactionType.creditGiven,
      ),
      previousBalance: 0, // DB doesn't have previous_balance
      newBalance: (map['balance_after'] as num?)?.toDouble() ?? 0,
      notes: map['notes'] as String?,
      collectedBy: map['created_by'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
