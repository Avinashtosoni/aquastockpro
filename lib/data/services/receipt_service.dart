import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/business_settings.dart';

/// Service for generating and printing receipts
class ReceiptService {
  static final ReceiptService _instance = ReceiptService._internal();
  factory ReceiptService() => _instance;
  ReceiptService._internal();

  /// Generate receipt text
  String generateReceiptText({
    required Order order,
    required BusinessSettings settings,
    required List<OrderItem> items,
  }) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final currencyFormat = NumberFormat.currency(
      symbol: settings.currencySymbol,
      decimalDigits: 2,
    );
    
    final buffer = StringBuffer();
    final lineWidth = 48;
    
    // Header
    buffer.writeln(_center(settings.businessName.toUpperCase(), lineWidth));
    if (settings.tagline != null) {
      buffer.writeln(_center(settings.tagline!, lineWidth));
    }
    buffer.writeln(_center('─' * 32, lineWidth));
    
    // Store info
    if (settings.fullAddress.isNotEmpty) {
      buffer.writeln(_center(settings.fullAddress, lineWidth));
    }
    if (settings.phone != null) {
      buffer.writeln(_center('Tel: ${settings.phone}', lineWidth));
    }
    if (settings.gstin != null) {
      buffer.writeln(_center('GSTIN: ${settings.gstin}', lineWidth));
    }
    
    buffer.writeln('═' * lineWidth);
    
    // Receipt header
    if (settings.receiptHeader != null && settings.receiptHeader!.isNotEmpty) {
      buffer.writeln(_center(settings.receiptHeader!, lineWidth));
      buffer.writeln('');
    }
    
    // Order details
    buffer.writeln('Receipt #: ${order.orderNumber}');
    buffer.writeln('Date: ${dateFormat.format(order.createdAt)}');
    if (order.employeeName != null && order.employeeName!.isNotEmpty) {
      buffer.writeln('Cashier: ${order.employeeName}');
    }
    if (order.customerName != null) {
      buffer.writeln('Customer: ${order.customerName}');
    }
    
    buffer.writeln('─' * lineWidth);
    buffer.writeln(_formatColumns('Item', 'Qty', 'Price', 'Total', lineWidth));
    buffer.writeln('─' * lineWidth);
    
    // Items
    for (final item in items) {
      final itemName = item.productName.length > 18 
          ? '${item.productName.substring(0, 17)}...' 
          : item.productName;
      buffer.writeln(_formatColumns(
        itemName,
        item.quantity.toString(),
        currencyFormat.format(item.unitPrice),
        currencyFormat.format(item.total),
        lineWidth,
      ));
    }
    
    buffer.writeln('─' * lineWidth);
    
    // Totals
    buffer.writeln(_formatTotalRow('Subtotal:', currencyFormat.format(order.subtotal), lineWidth));
    
    if (order.discountAmount > 0) {
      buffer.writeln(_formatTotalRow('Discount:', '-${currencyFormat.format(order.discountAmount)}', lineWidth));
    }
    
    if (settings.showTaxBreakdown && order.taxAmount > 0) {
      buffer.writeln(_formatTotalRow(
        '${settings.taxLabel ?? "Tax"} (${settings.taxRate}%):',
        currencyFormat.format(order.taxAmount),
        lineWidth,
      ));
    }
    
    buffer.writeln('═' * lineWidth);
    buffer.writeln(_formatTotalRow('TOTAL:', currencyFormat.format(order.totalAmount), lineWidth, bold: true));
    buffer.writeln('═' * lineWidth);
    
    // Payment info
    buffer.writeln(_formatTotalRow('Paid (${order.paymentMethodDisplayName}):', currencyFormat.format(order.paidAmount), lineWidth));
    if (order.changeAmount > 0) {
      buffer.writeln(_formatTotalRow('Change:', currencyFormat.format(order.changeAmount), lineWidth));
    }
    
    buffer.writeln('');
    
    // Footer
    if (settings.receiptFooter != null && settings.receiptFooter!.isNotEmpty) {
      buffer.writeln(_center(settings.receiptFooter!, lineWidth));
    }
    
    buffer.writeln(_center(settings.thankYouMessage ?? 'Thank you for your purchase!', lineWidth));
    buffer.writeln('');
    buffer.writeln(_center('─' * 24, lineWidth));
    buffer.writeln(_center('Powered by AquaStock Pro', lineWidth));
    
    return buffer.toString();
  }

  /// Copy receipt to clipboard
  Future<void> copyToClipboard(String receiptText) async {
    await Clipboard.setData(ClipboardData(text: receiptText));
  }

  /// Show print preview dialog
  void showPrintPreview({
    required BuildContext context,
    required Order order,
    required BusinessSettings settings,
    required List<OrderItem> items,
    VoidCallback? onPrint,
    VoidCallback? onShare,
  }) {
    final receiptText = generateReceiptText(
      order: order,
      settings: settings,
      items: items,
    );

    showDialog(
      context: context,
      builder: (context) => _ReceiptPreviewDialog(
        receiptText: receiptText,
        order: order,
        onCopy: () async {
          await copyToClipboard(receiptText);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Receipt copied to clipboard!')),
            );
            Navigator.pop(context);
          }
        },
        onPrint: onPrint ?? () {
          // Default print action - copy and show message
          copyToClipboard(receiptText);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Receipt copied! Use system print for physical printing.')),
          );
          Navigator.pop(context);
        },
        onShare: onShare,
      ),
    );
  }

  // Helper methods
  String _center(String text, int width) {
    if (text.length >= width) return text;
    final padding = (width - text.length) ~/ 2;
    return ' ' * padding + text;
  }

  String _formatColumns(String col1, String col2, String col3, String col4, int width) {
    final col1Width = (width * 0.4).floor();
    final col2Width = (width * 0.1).floor();
    final col3Width = (width * 0.25).floor();
    final col4Width = width - col1Width - col2Width - col3Width;
    
    return '${col1.padRight(col1Width)}${col2.padLeft(col2Width)}${col3.padLeft(col3Width)}${col4.padLeft(col4Width)}';
  }

  String _formatTotalRow(String label, String value, int width, {bool bold = false}) {
    final valueWidth = 15;
    final labelWidth = width - valueWidth;
    return '${label.padRight(labelWidth)}${value.padLeft(valueWidth)}';
  }
}

class _ReceiptPreviewDialog extends StatelessWidget {
  final String receiptText;
  final Order order;
  final VoidCallback onCopy;
  final VoidCallback onPrint;
  final VoidCallback? onShare;

  const _ReceiptPreviewDialog({
    required this.receiptText,
    required this.order,
    required this.onCopy,
    required this.onPrint,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 450,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Receipt Preview',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Order #${order.orderNumber}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Receipt preview
            Flexible(
              child: Container(
                color: Colors.grey[200],
                padding: const EdgeInsets.all(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      receiptText,
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Action buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onCopy,
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (onShare != null) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onShare,
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text('Share'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: onPrint,
                      icon: const Icon(Icons.print, size: 18),
                      label: const Text('Print Receipt'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
