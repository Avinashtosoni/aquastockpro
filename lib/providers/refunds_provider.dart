import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../data/models/refund.dart';
import '../data/models/refund_item.dart';
import '../data/models/order.dart';
import '../data/models/order_item.dart';
import '../data/repositories/refund_repository.dart';
import '../data/repositories/product_repository.dart';
import '../data/repositories/customer_repository.dart';

// Refund state
class RefundState {
  final List<Refund> refunds;
  final bool isLoading;
  final String? error;

  const RefundState({
    this.refunds = const [],
    this.isLoading = false,
    this.error,
  });

  RefundState copyWith({
    List<Refund>? refunds,
    bool? isLoading,
    String? error,
  }) {
    return RefundState(
      refunds: refunds ?? this.refunds,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Refund notifier
class RefundNotifier extends StateNotifier<RefundState> {
  final RefundRepository _refundRepository;
  final ProductRepository _productRepository;

  RefundNotifier(this._refundRepository, this._productRepository)
      : super(const RefundState());

  /// Load all refunds
  Future<void> loadRefunds() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final refunds = await _refundRepository.getAll();
      state = state.copyWith(refunds: refunds, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load refunds for a specific order
  Future<List<Refund>> loadRefundsByOrderId(String orderId) async {
    try {
      return await _refundRepository.getByOrderId(orderId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  /// Load refund with items for an order (for PDF receipt)
  Future<Refund?> loadRefundByOrderIdWithItems(String orderId) async {
    try {
      return await _refundRepository.getByOrderIdWithItems(orderId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Load refunds by status
  Future<List<Refund>> loadRefundsByStatus(RefundStatus status) async {
    try {
      return await _refundRepository.getByStatus(status);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  /// Process a refund from an order
  Future<Refund?> processRefund({
    required Order order,
    required List<OrderItem> itemsToRefund,
    required String reason,
    String? notes,
    String? employeeId,
    bool restockItems = true,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Generate refund number (for display) and UUID (for database)
      final refundNumber = Refund.generateRefundNumber();
      final refundUuid = const Uuid().v4();
      
      // Calculate refund amount
      double refundAmount = 0;
      final refundItems = <RefundItem>[];
      
      for (final orderItem in itemsToRefund) {
        refundAmount += orderItem.total;
        
        refundItems.add(RefundItem(
          refundId: refundUuid, // Use the actual UUID, not the number
          productId: orderItem.productId,
          productName: orderItem.productName,
          quantity: orderItem.quantity,
          unitPrice: orderItem.unitPrice,
          totalAmount: orderItem.total,
          restockStatus: restockItems ? RestockStatus.pending : RestockStatus.discarded,
        ));
      }
      
      // Create refund with explicit UUID
      final refund = Refund(
        id: refundUuid, // Explicitly set UUID
        orderId: order.id,
        customerId: order.customerId,
        employeeId: employeeId,
        refundNumber: refundNumber, // Display number
        amount: refundAmount,
        reason: reason,
        status: RefundStatus.pending,
        notes: notes,
        items: refundItems,
      );
      
      // Save refund with items
      final createdRefund = await _refundRepository.createWithItems(refund, refundItems);
      
      // Update customer credit balance (reduce dues for refund)
      if (order.customerId != null) {
        try {
          await CustomerRepository().processRefundCredit(
            customerId: order.customerId!,
            amount: refundAmount,
            orderId: order.id,
            refundNumber: refundNumber,
            notes: 'Refund for order ${order.orderNumber}',
            processedBy: employeeId,
          );
        } catch (e) {
          // Log but don't fail the refund if credit update fails
          // ignore: avoid_print
          print('Warning: Failed to update customer credit: $e');
        }
      }
      
      // Update state
      state = state.copyWith(
        refunds: [...state.refunds, createdRefund],
        isLoading: false,
      );
      
      return createdRefund;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      // Rethrow so the UI can show the actual error
      rethrow;
    }
  }

  /// Approve a refund
  Future<bool> approveRefund(String refundId) async {
    try {
      await _refundRepository.updateStatus(refundId, RefundStatus.approved);
      await loadRefunds();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Complete a refund (including restock)
  Future<bool> completeRefund(String refundId, {bool restockItems = true}) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Get refund with items
      final refund = await _refundRepository.getByIdWithItems(refundId);
      if (refund == null) {
        throw Exception('Refund not found');
      }
      
      // Restock items if requested
      if (restockItems) {
        for (final item in refund.items) {
          if (item.restockStatus == RestockStatus.pending) {
            // Add stock back to product
            final product = await _productRepository.getById(item.productId);
            if (product != null) {
              await _productRepository.updateStock(
                item.productId,
                product.stockQuantity + item.quantity,
              );
            }
            
            // Update restock status
            await _refundRepository.updateItemRestockStatus(
              item.id,
              RestockStatus.restocked,
            );
          }
        }
      }
      
      // Complete refund
      await _refundRepository.updateStatus(
        refundId,
        RefundStatus.completed,
        processedAt: DateTime.now(),
      );
      
      await loadRefunds();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Reject a refund
  Future<bool> rejectRefund(String refundId, String? reason) async {
    try {
      final refund = await _refundRepository.getById(refundId);
      if (refund != null) {
        final updated = refund.copyWith(
          status: RefundStatus.rejected,
          notes: reason != null ? '${refund.notes ?? ''}\nRejection reason: $reason' : refund.notes,
        );
        await _refundRepository.update(updated);
      }
      await loadRefunds();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Get refund statistics
  Future<Map<String, dynamic>> getRefundStats(DateTime start, DateTime end) async {
    try {
      final totalAmount = await _refundRepository.getTotalRefundAmount(start, end);
      final countByStatus = await _refundRepository.getCountByStatus();
      final refunds = await _refundRepository.getByDateRange(start, end);
      
      return {
        'totalAmount': totalAmount,
        'totalCount': refunds.length,
        'countByStatus': countByStatus,
        'refunds': refunds,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}

// Providers
final refundRepositoryProvider = Provider((ref) => RefundRepository());
final productRepositoryProvider = Provider((ref) => ProductRepository());

final refundProvider = StateNotifierProvider<RefundNotifier, RefundState>((ref) {
  return RefundNotifier(
    ref.watch(refundRepositoryProvider),
    ref.watch(productRepositoryProvider),
  );
});

// Convenience providers
final pendingRefundsProvider = Provider<List<Refund>>((ref) {
  return ref.watch(refundProvider).refunds
      .where((r) => r.status == RefundStatus.pending)
      .toList();
});

final completedRefundsProvider = Provider<List<Refund>>((ref) {
  return ref.watch(refundProvider).refunds
      .where((r) => r.status == RefundStatus.completed)
      .toList();
});
