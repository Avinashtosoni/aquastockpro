import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/alert_service.dart';
import '../../../data/models/order.dart';
import '../../../data/models/business_settings.dart';
import '../../../data/models/customer.dart';
import '../../../data/models/refund.dart';
import '../../../data/services/pdf_invoice_service.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/customers_provider.dart';
import '../../../providers/refunds_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/orders_provider.dart';
import 'refund_dialog.dart';

/// Full-screen order details bottom sheet with items, actions, and print options
class OrderDetailsSheet extends ConsumerStatefulWidget {
  final Order order;
  final VoidCallback? onRefund;
  final VoidCallback? onCancel;

  const OrderDetailsSheet({
    super.key,
    required this.order,
    this.onRefund,
    this.onCancel,
  });

  @override
  ConsumerState<OrderDetailsSheet> createState() => _OrderDetailsSheetState();
}

class _OrderDetailsSheetState extends ConsumerState<OrderDetailsSheet> {
  final _currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
  final _dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
  bool _isPrinting = false;
  bool _isDownloading = false;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final isDark = context.isDarkMode;
    
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardBorder : AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getStatusColor(order.status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Iconsax.receipt_item,
                        color: _getStatusColor(order.status),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.orderNumber,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkTextPrimary : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _dateFormat.format(order.createdAt),
                            style: TextStyle(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusBadge(status: order.status),
                  ],
                ),
              ),
              
              Divider(height: 1, color: isDark ? AppColors.darkCardBorder : null),
              
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Payment Info Card
                    _InfoCard(
                      title: 'Payment Information',
                      icon: Iconsax.wallet_2,
                      children: [
                        _InfoRow('Payment Method', order.paymentMethodDisplayName, 
                          icon: _getPaymentIcon(order.paymentMethod)),
                        _InfoRow('Subtotal', _currencyFormat.format(order.subtotal)),
                        if (order.discountAmount > 0)
                          _InfoRow('Discount', '-${_currencyFormat.format(order.discountAmount)}',
                            valueColor: AppColors.success),
                        _InfoRow('Tax', _currencyFormat.format(order.taxAmount)),
                        const Divider(height: 16),
                        _InfoRow('Total', _currencyFormat.format(order.totalAmount),
                          isBold: true, valueColor: AppColors.primary),
                        _InfoRow('Paid', _currencyFormat.format(order.paidAmount)),
                        if (order.changeAmount > 0)
                          _InfoRow('Change', _currencyFormat.format(order.changeAmount),
                            valueColor: AppColors.success),
                      ],
                    ),
                    
                    // Customer Info Card (if customer is associated)
                    if (order.customerName != null && order.customerName!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _InfoCard(
                        title: 'Customer Information',
                        icon: Iconsax.user,
                        children: [
                          _InfoRow('Customer Name', order.customerName!, icon: Iconsax.user),
                        ],
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    // Items Card
                    _InfoCard(
                      title: 'Order Items (${order.itemCount})',
                      icon: Iconsax.box,
                      children: order.items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.grey100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Iconsax.box, size: 20, color: AppColors.grey400),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    '${_currencyFormat.format(item.unitPrice)} × ${item.quantity}',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _currencyFormat.format(item.total),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )).toList(),
                    ),
                    
                    if (order.notes != null && order.notes!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _InfoCard(
                        title: 'Notes',
                        icon: Iconsax.note,
                        children: [
                          Text(order.notes!, style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                    
                    // Refund Info Card (for refunded orders)
                    if (order.status == OrderStatus.refunded)
                      FutureBuilder<List<Refund>>(
                        future: ref.read(refundProvider.notifier).loadRefundsByOrderId(order.id),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const SizedBox(height: 16);
                          }
                          final refunds = snapshot.data ?? [];
                          if (refunds.isEmpty) return const SizedBox.shrink();
                          
                          final refund = refunds.first;
                          return Column(
                            children: [
                              const SizedBox(height: 16),
                              _InfoCard(
                                title: 'Refund Information',
                                icon: Iconsax.money_recive,
                                children: [
                                  _InfoRow('Refund Number', refund.refundNumber, icon: Iconsax.receipt_item),
                                  _InfoRow('Refund Amount', _currencyFormat.format(refund.amount),
                                    valueColor: AppColors.warning, isBold: true),
                                  _InfoRow('Reason', refund.reason ?? 'Not specified'),
                                  _InfoRow('Status', refund.statusDisplayName,
                                    valueColor: refund.status == RefundStatus.completed 
                                      ? AppColors.success : AppColors.warning),
                                  if (refund.processedAt != null)
                                    _InfoRow('Processed On', _dateFormat.format(refund.processedAt!)),
                                  if (refund.notes != null && refund.notes!.isNotEmpty)
                                    _InfoRow('Notes', refund.notes!),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    
                    const SizedBox(height: 100), // Space for bottom actions
                  ],
                ),
              ),
              
              // Bottom Actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  border: isDark ? Border(top: BorderSide(color: AppColors.darkCardBorder)) : null,
                  boxShadow: isDark ? null : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      // Print Receipt
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isPrinting ? null : _printReceipt,
                          icon: _isPrinting 
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Iconsax.printer, size: 18),
                          label: const Text('Print'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Download Invoice
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isDownloading ? null : _downloadInvoice,
                          icon: _isDownloading 
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Iconsax.document_download, size: 18),
                          label: const Text('Invoice'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Refund (if completed) or Download Refund Receipt (if refunded)
                      if (order.status == OrderStatus.completed)
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _handleRefund,
                            icon: const Icon(Iconsax.money_recive, size: 18),
                            label: const Text('Refund'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.warning,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      if (order.status == OrderStatus.refunded)
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _downloadRefundReceipt,
                            icon: const Icon(Iconsax.document_download, size: 18),
                            label: const Text('Refund Receipt'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.warning,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.completed: return AppColors.success;
      case OrderStatus.pending: return AppColors.warning;
      case OrderStatus.cancelled: return AppColors.error;
      case OrderStatus.refunded: return AppColors.info;
      case OrderStatus.onHold: return AppColors.warning;
    }
  }

  IconData _getPaymentIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash: return Iconsax.money;
      case PaymentMethod.card: return Iconsax.card;
      case PaymentMethod.upi: return Iconsax.mobile;
      case PaymentMethod.credit: return Iconsax.wallet;
      case PaymentMethod.mixed: return Iconsax.money_add;
    }
  }

  Future<void> _printReceipt() async {
    setState(() => _isPrinting = true);
    try {
      final pdfService = PdfInvoiceService();
      // Get proper settings from provider
      final settingsAsync = ref.read(settingsNotifierProvider);
      final settings = settingsAsync.valueOrNull ?? BusinessSettings();
      
      // Get customer's previous balance if customer exists
      double previousBalance = 0;
      if (widget.order.customerId != null) {
        final customersAsync = ref.read(customersNotifierProvider);
        final customers = customersAsync.valueOrNull ?? [];
        final customer = customers.where((c) => c.id == widget.order.customerId).firstOrNull;
        if (customer != null) {
          // Previous balance before this order (current balance - this order's due)
          final orderDue = widget.order.totalAmount - widget.order.paidAmount;
          previousBalance = (customer.creditBalance - orderDue).clamp(0, double.infinity);
        }
      }
      
      await pdfService.printReceipt(
        order: widget.order,
        settings: settings,
        items: widget.order.items,
        previousBalance: previousBalance,
      );
      if (mounted) {
        AlertService().showSuccess(
          context: context,
          title: 'Printing',
          text: 'Receipt sent to printer',
          autoCloseDuration: true,
        );
      }
    } catch (e) {
      if (mounted) {
        AlertService().showError(
          context: context,
          title: 'Print Failed',
          text: e.toString(),
        );
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  Future<void> _downloadInvoice() async {
    setState(() => _isDownloading = true);
    try {
      final pdfService = PdfInvoiceService();
      // Get proper settings from provider
      final settingsAsync = ref.read(settingsNotifierProvider);
      final settings = settingsAsync.valueOrNull ?? BusinessSettings();
      
      // Get customer's previous balance if customer exists
      double previousBalance = 0;
      Customer? customer;
      if (widget.order.customerId != null) {
        final customersAsync = ref.read(customersNotifierProvider);
        final customers = customersAsync.valueOrNull ?? [];
        customer = customers.where((c) => c.id == widget.order.customerId).firstOrNull;
        if (customer != null) {
          // Previous balance before this order (current balance - this order's due)
          final orderDue = widget.order.totalAmount - widget.order.paidAmount;
          previousBalance = (customer.creditBalance - orderDue).clamp(0, double.infinity);
        }
      }
      
      await pdfService.saveInvoicePdf(
        order: widget.order,
        settings: settings,
        items: widget.order.items,
        customer: customer,
        previousBalance: previousBalance,
      );
      if (mounted) {
        AlertService().showSuccess(
          context: context,
          title: 'Invoice Saved',
          text: 'Invoice has been saved to your downloads folder',
          autoCloseDuration: true,
        );
      }
    } catch (e) {
      if (mounted) {
        AlertService().showError(
          context: context,
          title: 'Download Failed',
          text: e.toString(),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _downloadRefundReceipt() async {
    setState(() => _isDownloading = true);
    try {
      // Fetch refund with items for this order
      final refundWithItems = await ref.read(refundProvider.notifier).loadRefundByOrderIdWithItems(widget.order.id);
      
      if (refundWithItems == null) {
        throw Exception('No refund found for this order');
      }
      
      final settings = ref.read(settingsNotifierProvider).valueOrNull ?? BusinessSettings();
      
      // Get customer details and balance
      Customer? customer;
      double previousBalance = 0;
      if (widget.order.customerId != null) {
        final customersAsync = ref.read(customersNotifierProvider);
        final customers = customersAsync.valueOrNull ?? [];
        customer = customers.where((c) => c.id == widget.order.customerId).firstOrNull;
        if (customer != null) {
          previousBalance = customer.creditBalance;
        }
      }
      
      await PdfInvoiceService().saveRefundReceiptPdf(
        order: widget.order,
        settings: settings,
        refundItems: refundWithItems.items, // Actual refund items with correct quantities
        refundNumber: refundWithItems.refundNumber,
        refundAmount: refundWithItems.amount,
        reason: refundWithItems.reason ?? 'Customer Request',
        notes: refundWithItems.notes,
        customer: customer,
        previousBalance: previousBalance,
      );
      
      if (mounted) {
        AlertService().showSuccess(
          context: context,
          title: 'Downloaded',
          text: 'Refund receipt has been saved',
          autoCloseDuration: true,
        );
      }
    } catch (e) {
      if (mounted) {
        AlertService().showError(
          context: context,
          title: 'Download Failed',
          text: e.toString(),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  void _handleRefund() {
    showDialog(
      context: context,
      builder: (dialogContext) => RefundDialog(
        order: widget.order,
        onProcess: (reason, notes, restockItems, selectedItems) async {
          try {
            // Get current user for tracking who processed the refund
            final authState = ref.read(authProvider);
            final employeeId = authState.user?.id;
            
            // Create refund record with selected items only
            final refund = await ref.read(refundProvider.notifier).processRefund(
              order: widget.order,
              itemsToRefund: selectedItems, // Use selected items, not all items
              reason: reason,
              notes: notes,
              employeeId: employeeId,
              restockItems: restockItems,
            );
            
            if (refund != null) {
              // Complete the refund immediately
              await ref.read(refundProvider.notifier).completeRefund(
                refund.id,
                restockItems: restockItems,
              );
              
              // Update order status to refunded
              await ref.read(ordersNotifierProvider.notifier).updateOrderStatus(
                widget.order.id,
                OrderStatus.refunded,
              );
              
              // Close the order details sheet
              if (mounted) Navigator.pop(context);
              
              if (mounted) {
                // Get customer for PDF
                Customer? pdfCustomer;
                double prevBalance = 0;
                if (widget.order.customerId != null) {
                  final customersAsync = ref.read(customersNotifierProvider);
                  final customers = customersAsync.valueOrNull ?? [];
                  pdfCustomer = customers.where((c) => c.id == widget.order.customerId).firstOrNull;
                  if (pdfCustomer != null) {
                    prevBalance = pdfCustomer.creditBalance;
                  }
                }
                
                // Show refund success dialog with download option
                showDialog(
                  context: context,
                  builder: (ctx) => _RefundSuccessDialog(
                    refundNumber: refund.refundNumber,
                    amount: refund.amount,
                    itemCount: selectedItems.length,
                    order: widget.order,
                    onDownloadReceipt: () async {
                      final settings = ref.read(settingsProvider).value;
                      if (settings != null) {
                        await PdfInvoiceService().saveRefundReceiptPdf(
                          order: widget.order,
                          settings: settings,
                          refundItems: refund.items, // Use refund.items (RefundItem list)
                          refundNumber: refund.refundNumber,
                          refundAmount: refund.amount,
                          reason: reason,
                          notes: notes,
                          customer: pdfCustomer,
                          previousBalance: prevBalance,
                        );
                      }
                    },
                  ),
                );
              }
            } else {
              throw Exception('Failed to create refund record');
            }
          } catch (e) {
            if (mounted) {
              AlertService().showError(
                context: context,
                title: 'Refund Failed',
                text: e.toString(),
              );
            }
          }
        },
      ),
    );
  }
}

// Helper Widgets
class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case OrderStatus.completed: color = AppColors.success;
      case OrderStatus.pending: color = AppColors.warning;
      case OrderStatus.cancelled: color = AppColors.error;
      case OrderStatus.refunded: color = AppColors.info;
      case OrderStatus.onHold: color = AppColors.warning;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.name[0].toUpperCase() + status.name.substring(1),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.grey50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: isDark ? AppColors.primaryLight : AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? AppColors.darkTextPrimary : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;
  final IconData? icon;

  const _InfoRow(
    this.label, 
    this.value, {
    this.isBold = false,
    this.valueColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                const SizedBox(width: 8),
              ],
              Text(label, style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: valueColor ?? (isDark ? AppColors.darkTextPrimary : null),
            ),
          ),
        ],
      ),
    );
  }
}

/// Refund success dialog with download receipt option
class _RefundSuccessDialog extends StatelessWidget {
  final String refundNumber;
  final double amount;
  final int itemCount;
  final Order order;
  final VoidCallback onDownloadReceipt;

  const _RefundSuccessDialog({
    required this.refundNumber,
    required this.amount,
    required this.itemCount,
    required this.order,
    required this.onDownloadReceipt,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 350,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success Icon
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            
            // Title
            Text(
              'Refund Processed',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // Refund details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardBackground : AppColors.grey50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.darkCardBorder : AppColors.grey200,
                ),
              ),
              child: Column(
                children: [
                  // Refund Number - Clickable
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Refund #',
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: SelectableText(
                          refundNumber,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  
                  // Amount
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Amount Refunded',
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        currencyFormat.format(amount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Items count
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Items Refunded',
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '$itemCount item(s)',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Action Buttons
            Row(
              children: [
                // Close Button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Download Receipt Button
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: () {
                      onDownloadReceipt();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Iconsax.document_download, size: 18),
                    label: const Text('Download Receipt'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
