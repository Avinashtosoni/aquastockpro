import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/audit_log.dart';
import '../../core/constants/supabase_config.dart';

/// Service for logging audit events to the database
class AuditService {
  static final AuditService _instance = AuditService._internal();
  factory AuditService() => _instance;
  AuditService._internal();

  final _client = Supabase.instance.client;

  /// Log an audit event
  Future<void> log({
    required String action,
    required String entityType,
    String? entityId,
    String? userId,
    String? userName,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
  }) async {
    try {
      await _client.from(SupabaseConfig.auditLogsTable).insert({
        'action': action,
        'entity_type': entityType,
        'entity_id': entityId,
        'user_id': userId,
        'user_name': userName,
        'old_values': oldValues,
        'new_values': newValues,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Silently fail - audit logging should not break main operations
      print('Audit log failed: $e');
    }
  }

  /// Log a create event
  Future<void> logCreate({
    required String entityType,
    required String entityId,
    required Map<String, dynamic> newValues,
    String? userId,
    String? userName,
  }) async {
    await log(
      action: 'create',
      entityType: entityType,
      entityId: entityId,
      userId: userId,
      userName: userName,
      newValues: newValues,
    );
  }

  /// Log an update event
  Future<void> logUpdate({
    required String entityType,
    required String entityId,
    Map<String, dynamic>? oldValues,
    required Map<String, dynamic> newValues,
    String? userId,
    String? userName,
  }) async {
    await log(
      action: 'update',
      entityType: entityType,
      entityId: entityId,
      userId: userId,
      userName: userName,
      oldValues: oldValues,
      newValues: newValues,
    );
  }

  /// Log a delete event
  Future<void> logDelete({
    required String entityType,
    required String entityId,
    Map<String, dynamic>? oldValues,
    String? userId,
    String? userName,
  }) async {
    await log(
      action: 'delete',
      entityType: entityType,
      entityId: entityId,
      userId: userId,
      userName: userName,
      oldValues: oldValues,
    );
  }

  /// Log a login event
  Future<void> logLogin({
    required String userId,
    required String userName,
    String? method,
  }) async {
    await log(
      action: 'login',
      entityType: 'user',
      entityId: userId,
      userId: userId,
      userName: userName,
      newValues: {'method': method ?? 'password'},
    );
  }

  /// Log a logout event
  Future<void> logLogout({
    required String userId,
    required String userName,
  }) async {
    await log(
      action: 'logout',
      entityType: 'user',
      entityId: userId,
      userId: userId,
      userName: userName,
    );
  }

  /// Get audit logs with pagination
  Future<List<AuditLog>> getAuditLogs({
    String? entityType,
    String? entityId,
    String? userId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _client
          .from(SupabaseConfig.auditLogsTable)
          .select();

      if (entityType != null) {
        query = query.eq('entity_type', entityType);
      }
      if (entityId != null) {
        query = query.eq('entity_id', entityId);
      }
      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).map((e) => AuditLog.fromJson(e)).toList();
    } catch (e) {
      print('Failed to get audit logs: $e');
      return [];
    }
  }
}
