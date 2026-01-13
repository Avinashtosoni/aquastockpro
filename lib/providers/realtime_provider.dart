import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/supabase_config.dart';

/// Realtime event types
enum RealtimeEventType { insert, update, delete }

/// Realtime event data
class RealtimeEvent {
  final RealtimeEventType type;
  final String table;
  final Map<String, dynamic>? newRecord;
  final Map<String, dynamic>? oldRecord;

  RealtimeEvent({
    required this.type,
    required this.table,
    this.newRecord,
    this.oldRecord,
  });
}

/// Realtime service for Supabase subscriptions
class RealtimeService {
  final _client = Supabase.instance.client;
  final Map<String, RealtimeChannel> _channels = {};
  final _eventController = StreamController<RealtimeEvent>.broadcast();

  Stream<RealtimeEvent> get events => _eventController.stream;

  /// Subscribe to changes on a table
  void subscribeToTable(String tableName) {
    if (_channels.containsKey(tableName)) return;

    final channel = _client
        .channel('public:$tableName')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: tableName,
          callback: (payload) {
            final eventType = _parseEventType(payload.eventType);
            _eventController.add(RealtimeEvent(
              type: eventType,
              table: tableName,
              newRecord: payload.newRecord,
              oldRecord: payload.oldRecord,
            ));
          },
        )
        .subscribe();

    _channels[tableName] = channel;
  }

  /// Subscribe to orders changes (for dashboard)
  void subscribeToOrders() => subscribeToTable(SupabaseConfig.ordersTable);

  /// Subscribe to products changes (for POS)
  void subscribeToProducts() => subscribeToTable(SupabaseConfig.productsTable);

  /// Subscribe to customers changes
  void subscribeToCustomers() => subscribeToTable(SupabaseConfig.customersTable);

  /// Unsubscribe from a table
  void unsubscribeFromTable(String tableName) {
    final channel = _channels.remove(tableName);
    if (channel != null) {
      _client.removeChannel(channel);
    }
  }

  /// Unsubscribe from all tables
  void unsubscribeAll() {
    for (final tableName in _channels.keys.toList()) {
      unsubscribeFromTable(tableName);
    }
  }

  /// Dispose the service
  void dispose() {
    unsubscribeAll();
    _eventController.close();
  }

  RealtimeEventType _parseEventType(PostgresChangeEvent event) {
    switch (event) {
      case PostgresChangeEvent.insert:
        return RealtimeEventType.insert;
      case PostgresChangeEvent.update:
        return RealtimeEventType.update;
      case PostgresChangeEvent.delete:
        return RealtimeEventType.delete;
      default:
        return RealtimeEventType.update;
    }
  }
}

/// Provider for RealtimeService
final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  final service = RealtimeService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Stream provider for realtime events
final realtimeEventsProvider = StreamProvider<RealtimeEvent>((ref) {
  final service = ref.watch(realtimeServiceProvider);
  return service.events;
});

/// Provider to listen for order updates and invalidate dashboard
final ordersRealtimeProvider = Provider<void>((ref) {
  final service = ref.watch(realtimeServiceProvider);
  service.subscribeToOrders();
  
  ref.listen(realtimeEventsProvider, (previous, next) {
    next.whenData((event) {
      if (event.table == SupabaseConfig.ordersTable) {
        // Note: Dashboard/orders providers that use this should listen to realtimeEventsProvider
        // This provider just ensures subscription is active
      }
    });
  });
});

/// Provider to listen for product updates (for POS screen)
final productsRealtimeProvider = Provider<void>((ref) {
  final service = ref.watch(realtimeServiceProvider);
  service.subscribeToProducts();
  
  ref.listen(realtimeEventsProvider, (previous, next) {
    next.whenData((event) {
      if (event.table == SupabaseConfig.productsTable) {
        // Note: Product providers that use this should listen to realtimeEventsProvider
        // This provider just ensures subscription is active
      }
    });
  });
});
