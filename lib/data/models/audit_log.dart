import 'package:uuid/uuid.dart';

/// Audit Log Entry for tracking all user actions
class AuditLog {
  final String id;
  final String userId;
  final String? userName;
  final String action;         // e.g., 'create', 'update', 'delete', 'login'
  final String entityType;     // e.g., 'product', 'order', 'customer'
  final String? entityId;
  final String? entityName;
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues;
  final String? ipAddress;
  final String? userAgent;
  final String? notes;
  final DateTime createdAt;

  AuditLog({
    required this.id,
    required this.userId,
    this.userName,
    required this.action,
    required this.entityType,
    this.entityId,
    this.entityName,
    this.oldValues,
    this.newValues,
    this.ipAddress,
    this.userAgent,
    this.notes,
    required this.createdAt,
  });

  factory AuditLog.create({
    required String userId,
    String? userName,
    required String action,
    required String entityType,
    String? entityId,
    String? entityName,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
    String? notes,
  }) {
    return AuditLog(
      id: const Uuid().v4(),
      userId: userId,
      userName: userName,
      action: action,
      entityType: entityType,
      entityId: entityId,
      entityName: entityName,
      oldValues: oldValues,
      newValues: newValues,
      notes: notes,
      createdAt: DateTime.now(),
    );
  }

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String?,
      action: json['action'] as String,
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as String?,
      entityName: json['entity_name'] as String?,
      oldValues: json['old_values'] as Map<String, dynamic>?,
      newValues: json['new_values'] as Map<String, dynamic>?,
      ipAddress: json['ip_address'] as String?,
      userAgent: json['user_agent'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'action': action,
      'entity_type': entityType,
      'entity_id': entityId,
      'entity_name': entityName,
      'old_values': oldValues,
      'new_values': newValues,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Icon for action type
  String get actionIcon {
    switch (action.toLowerCase()) {
      case 'create':
        return '➕';
      case 'update':
        return '✏️';
      case 'delete':
        return '🗑️';
      case 'login':
        return '🔐';
      case 'logout':
        return '🚪';
      case 'view':
        return '👁️';
      case 'export':
        return '📤';
      case 'import':
        return '📥';
      default:
        return '📋';
    }
  }

  /// Readable description of the action
  String get description {
    final entityDesc = entityName ?? entityId ?? entityType;
    switch (action.toLowerCase()) {
      case 'create':
        return 'Created $entityType: $entityDesc';
      case 'update':
        return 'Updated $entityType: $entityDesc';
      case 'delete':
        return 'Deleted $entityType: $entityDesc';
      case 'login':
        return 'Logged in';
      case 'logout':
        return 'Logged out';
      default:
        return '${action.substring(0, 1).toUpperCase()}${action.substring(1)} $entityType';
    }
  }
}

/// Common audit actions
class AuditAction {
  static const String create = 'create';
  static const String update = 'update';
  static const String delete = 'delete';
  static const String login = 'login';
  static const String logout = 'logout';
  static const String view = 'view';
  static const String export = 'export';
  static const String import = 'import';
  static const String payment = 'payment';
  static const String refund = 'refund';
  static const String stockAdjust = 'stock_adjust';
}

/// Entity types for audit
class AuditEntity {
  static const String product = 'product';
  static const String order = 'order';
  static const String customer = 'customer';
  static const String supplier = 'supplier';
  static const String employee = 'employee';
  static const String category = 'category';
  static const String settings = 'settings';
  static const String user = 'user';
  static const String inventory = 'inventory';
  static const String purchaseOrder = 'purchase_order';
  static const String stockTransfer = 'stock_transfer';
}
