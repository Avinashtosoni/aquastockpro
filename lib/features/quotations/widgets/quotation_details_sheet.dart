import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/alert_service.dart';
import '../../../data/models/quotation.dart';
import '../../../data/services/pdf_invoice_service.dart';
import '../../../providers/quotations_provider.dart';
import '../../../providers/orders_provider.dart';
import '../../../providers/settings_provider.dart';

/// Full-screen quotation details bottom sheet with items, actions, and conversion
class QuotationDetailsSheet extends ConsumerStatefulWidget {
  final Quotation quotation;

  const QuotationDetailsSheet({
    super.key,
    required this.quotation,
  });

  @override
  ConsumerState<QuotationDetailsSheet> createState() => _QuotationDetailsSheetState();
}

class _QuotationDetailsSheetState extends ConsumerState<QuotationDetailsSheet> {
  final _currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
  final _dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
  bool _isConverting = false;
  bool _isUpdating = false;
  bool _isDownloadingPdf = false;

  @override
  Widget build(BuildContext context) {
    final quotation = widget.quotation;
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
                        color: _getStatusColor(quotation.status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Iconsax.document_text,
                        color: _getStatusColor(quotation.status),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            quotation.quotationNumber,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkTextPrimary : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _dateFormat.format(quotation.createdAt),
                            style: TextStyle(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusBadge(status: quotation.status),
                    const SizedBox(width: 8),
                    // PDF Download Button
                    IconButton(
                      onPressed: _isDownloadingPdf ? null : _downloadPdf,
                      icon: _isDownloadingPdf 
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Iconsax.document_download),
                      tooltip: 'Download PDF',
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        foregroundColor: AppColors.primary,
                      ),
                    ),
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
                    // Customer Info
                    _InfoCard(
                      title: 'Customer Information',
                      icon: Iconsax.user,
                      children: [
                        _InfoRow('Customer', quotation.customerName ?? 'Walk-in Customer'),
                        if (quotation.validUntil != null)
                          _InfoRow(
                            'Valid Until',
                            DateFormat('dd MMM yyyy').format(quotation.validUntil!),
                            valueColor: quotation.isExpired ? AppColors.error : null,
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Pricing Info
                    _InfoCard(
                      title: 'Pricing Summary',
                      icon: Iconsax.money,
                      children: [
                        _InfoRow('Subtotal', _currencyFormat.format(quotation.subtotal)),
                        if (quotation.discountAmount > 0)
                          _InfoRow('Discount', '-${_currencyFormat.format(quotation.discountAmount)}',
                              valueColor: AppColors.success),
                        _InfoRow('Tax', _currencyFormat.format(quotation.taxAmount)),
                        const Divider(height: 16),
                        _InfoRow('Total', _currencyFormat.format(quotation.totalAmount),
                            isBold: true, valueColor: AppColors.primary),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Items Card
                    _InfoCard(
                      title: 'Items (${quotation.itemCount})',
                      icon: Iconsax.box,
                      children: quotation.items.map((item) => Padding(
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

                    if (quotation.notes != null && quotation.notes!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _InfoCard(
                        title: 'Notes',
                        icon: Iconsax.note,
                        children: [
                          Text(quotation.notes!, style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    ],

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
                  child: _buildActionButtons(quotation),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(Quotation quotation) {
    final List<Widget> buttons = [];

    // Draft: Send, Edit, Delete
    if (quotation.status == QuotationStatus.draft) {
      buttons.addAll([
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _updateStatus(QuotationStatus.sent),
            icon: _isUpdating 
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Iconsax.send_1, size: 18),
            label: const Text('Send'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: _deleteQuotation,
            icon: const Icon(Iconsax.trash, size: 18),
            label: const Text('Delete'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ]);
    }

    // Sent: Accept, Reject
    if (quotation.status == QuotationStatus.sent) {
      buttons.addAll([
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _updateStatus(QuotationStatus.rejected),
            icon: const Icon(Iconsax.close_circle, size: 18),
            label: const Text('Reject'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: () => _updateStatus(QuotationStatus.accepted),
            icon: _isUpdating 
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Iconsax.tick_circle, size: 18),
            label: const Text('Accept'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.success,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ]);
    }

    // Accepted: Convert to Order
    if (quotation.status == QuotationStatus.accepted) {
      buttons.add(
        Expanded(
          child: FilledButton.icon(
            onPressed: _convertToOrder,
            icon: _isConverting 
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Iconsax.convert, size: 18),
            label: const Text('Convert to Order'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      );
    }

    // Expired or Rejected: Close only
    if (quotation.status == QuotationStatus.expired ||
        quotation.status == QuotationStatus.rejected ||
        quotation.status == QuotationStatus.converted) {
      buttons.add(
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      );
    }

    return Row(children: buttons);
  }

  Color _getStatusColor(QuotationStatus status) {
    switch (status) {
      case QuotationStatus.draft: return AppColors.grey500;
      case QuotationStatus.sent: return AppColors.info;
      case QuotationStatus.accepted: return AppColors.success;
      case QuotationStatus.rejected: return AppColors.error;
      case QuotationStatus.expired: return AppColors.warning;
      case QuotationStatus.converted: return AppColors.primary;
    }
  }

  Future<void> _updateStatus(QuotationStatus newStatus) async {
    setState(() => _isUpdating = true);
    try {
      await ref.read(quotationsNotifierProvider.notifier)
          .updateQuotationStatus(widget.quotation.id, newStatus);
      if (mounted) {
        AlertService().showSuccess(
          context: context,
          title: 'Status Updated',
          text: 'Quotation marked as ${newStatus.name}',
          autoCloseDuration: true,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AlertService().showError(
          context: context,
          title: 'Update Failed',
          text: e.toString(),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _convertToOrder() async {
    setState(() => _isConverting = true);
    try {
      final order = await ref.read(quotationsNotifierProvider.notifier)
          .convertToOrder(widget.quotation);
      // Refresh orders list
      ref.invalidate(ordersNotifierProvider);
      if (mounted) {
        AlertService().showSuccess(
          context: context,
          title: 'Order Created',
          text: 'Order ${order.orderNumber} created successfully',
          autoCloseDuration: true,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AlertService().showError(
          context: context,
          title: 'Conversion Failed',
          text: e.toString(),
        );
      }
    } finally {
      if (mounted) setState(() => _isConverting = false);
    }
  }

  void _deleteQuotation() {
    AlertService().showConfirm(
      context: context,
      title: 'Delete Quotation?',
      text: 'Are you sure you want to delete this quotation? This action cannot be undone.',
      confirmBtnText: 'Delete',
      confirmBtnColor: AppColors.error,
      onConfirmBtnTap: () async {
        try {
          await ref.read(quotationsNotifierProvider.notifier)
              .deleteQuotation(widget.quotation.id);
          if (mounted) {
            Navigator.pop(context);
            AlertService().showSuccess(
              context: context,
              title: 'Deleted',
              text: 'Quotation has been deleted',
              autoCloseDuration: true,
            );
          }
        } catch (e) {
          if (mounted) {
            AlertService().showError(
              context: context,
              title: 'Delete Failed',
              text: e.toString(),
            );
          }
        }
      },
    );
  }

  Future<void> _downloadPdf() async {
    setState(() => _isDownloadingPdf = true);
    try {
      final settingsAsync = ref.read(settingsNotifierProvider);
      final settings = settingsAsync.valueOrNull;
      if (settings == null) {
        throw Exception('Business settings not loaded');
      }
      await PdfInvoiceService().printQuotationPdf(
        quotation: widget.quotation,
        settings: settings,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF downloaded: quotation_${widget.quotation.quotationNumber}.pdf'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
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
      if (mounted) setState(() => _isDownloadingPdf = false);
    }
  }
}

// Helper Widgets
class _StatusBadge extends StatelessWidget {
  final QuotationStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case QuotationStatus.draft: color = AppColors.grey500;
      case QuotationStatus.sent: color = AppColors.info;
      case QuotationStatus.accepted: color = AppColors.success;
      case QuotationStatus.rejected: color = AppColors.error;
      case QuotationStatus.expired: color = AppColors.warning;
      case QuotationStatus.converted: color = AppColors.primary;
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

  const _InfoRow(
    this.label,
    this.value, {
    this.isBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
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
