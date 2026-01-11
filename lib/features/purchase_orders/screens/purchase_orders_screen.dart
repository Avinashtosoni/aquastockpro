import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../data/models/purchase_order.dart';
import '../../../providers/purchase_orders_provider.dart';

class PurchaseOrdersScreen extends ConsumerStatefulWidget {
  const PurchaseOrdersScreen({super.key});

  @override
  ConsumerState<PurchaseOrdersScreen> createState() => _PurchaseOrdersScreenState();
}

class _PurchaseOrdersScreenState extends ConsumerState<PurchaseOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(purchaseOrdersProvider);
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Purchase Orders', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text(
                      'Manage supplier orders and stock replenishment',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                AppButton(
                  label: 'New Order',
                  icon: Iconsax.add,
                  onPressed: () => _showCreateOrderDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Stats Row
            Row(
              children: [
                _StatChip(
                  label: 'Total',
                  value: ordersState.orders.length.toString(),
                  color: AppColors.info,
                ),
                const SizedBox(width: 12),
                _StatChip(
                  label: 'Pending',
                  value: ordersState.orders
                      .where((o) => o.status == PurchaseOrderStatus.pending || o.status == PurchaseOrderStatus.ordered)
                      .length
                      .toString(),
                  color: AppColors.warning,
                ),
                const SizedBox(width: 12),
                _StatChip(
                  label: 'Received',
                  value: ordersState.orders
                      .where((o) => o.status == PurchaseOrderStatus.received)
                      .length
                      .toString(),
                  color: AppColors.success,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Tab Bar
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.border),
              ),
              child: TabBar(
                controller: _tabController,
                padding: const EdgeInsets.all(4),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Draft'),
                  Tab(text: 'Ordered'),
                  Tab(text: 'Received'),
                  Tab(text: 'Cancelled'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Orders List
            Expanded(
              child: ordersState.isLoading
                  ? const LoadingIndicator(message: 'Loading orders...')
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOrdersList(ordersState.orders, currencyFormat, isDark),
                        _buildOrdersList(
                          ordersState.orders.where((o) => o.status == PurchaseOrderStatus.draft).toList(),
                          currencyFormat,
                          isDark,
                        ),
                        _buildOrdersList(
                          ordersState.orders.where((o) => o.status == PurchaseOrderStatus.ordered || o.status == PurchaseOrderStatus.pending).toList(),
                          currencyFormat,
                          isDark,
                        ),
                        _buildOrdersList(
                          ordersState.orders.where((o) => o.status == PurchaseOrderStatus.received).toList(),
                          currencyFormat,
                          isDark,
                        ),
                        _buildOrdersList(
                          ordersState.orders.where((o) => o.status == PurchaseOrderStatus.cancelled).toList(),
                          currencyFormat,
                          isDark,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList(List<PurchaseOrder> orders, NumberFormat currencyFormat, bool isDark) {
    if (orders.isEmpty) {
      return const EmptyState(
        icon: Iconsax.document,
        title: 'No orders found',
        subtitle: 'Create a new purchase order to get started',
      );
    }

    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _PurchaseOrderCard(
          order: order,
          currencyFormat: currencyFormat,
          isDark: isDark,
          onTap: () => _showOrderDetails(context, order),
          onStatusChange: (status) => ref.read(purchaseOrdersProvider.notifier).updateStatus(order.id, status),
        );
      },
    );
  }

  void _showCreateOrderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Purchase Order'),
        content: const Text('Purchase order creation form will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(BuildContext context, PurchaseOrder order) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final dateFormat = DateFormat('dd MMM yyyy');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.orderNumber,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.supplierName ?? 'Unknown Supplier',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  _StatusBadge(status: order.status),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dates
                    Row(
                      children: [
                        Expanded(
                          child: _InfoTile(
                            icon: Iconsax.calendar,
                            label: 'Order Date',
                            value: dateFormat.format(order.orderDate),
                          ),
                        ),
                        if (order.expectedDeliveryDate != null)
                          Expanded(
                            child: _InfoTile(
                              icon: Iconsax.truck,
                              label: 'Expected',
                              value: dateFormat.format(order.expectedDeliveryDate!),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Items
                    Text(
                      'Items (${order.items.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    ...order.items.map((item) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceVariant : AppColors.grey100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  '${item.quantity} × ${currencyFormat.format(item.unitPrice)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            currencyFormat.format(item.total),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )),
                    const SizedBox(height: 20),
                    // Summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _SummaryRow('Subtotal', currencyFormat.format(order.subtotal)),
                          _SummaryRow('Tax (18% GST)', currencyFormat.format(order.taxAmount)),
                          if (order.discount > 0)
                            _SummaryRow('Discount', '- ${currencyFormat.format(order.discount)}'),
                          const Divider(),
                          _SummaryRow(
                            'Total',
                            currencyFormat.format(order.totalAmount),
                            isBold: true,
                          ),
                          if (order.paidAmount != null && order.paidAmount! > 0)
                            _SummaryRow('Paid', currencyFormat.format(order.paidAmount!)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseOrderCard extends StatelessWidget {
  final PurchaseOrder order;
  final NumberFormat currencyFormat;
  final bool isDark;
  final VoidCallback onTap;
  final Function(PurchaseOrderStatus) onStatusChange;

  const _PurchaseOrderCard({
    required this.order,
    required this.currencyFormat,
    required this.isDark,
    required this.onTap,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Iconsax.document_text,
                    color: _getStatusColor(order.status),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            order.orderNumber,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          _StatusBadge(status: order.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.supplierName ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${order.items.length} items • ${dateFormat.format(order.orderDate)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFormat.format(order.totalAmount),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (!order.isFullyPaid)
                      Text(
                        'Due: ${currencyFormat.format(order.balance)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.error,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(
                  Iconsax.arrow_right_3,
                  size: 18,
                  color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(PurchaseOrderStatus status) {
    switch (status) {
      case PurchaseOrderStatus.draft:
        return AppColors.grey500;
      case PurchaseOrderStatus.pending:
        return AppColors.warning;
      case PurchaseOrderStatus.ordered:
        return AppColors.info;
      case PurchaseOrderStatus.partiallyReceived:
        return AppColors.warning;
      case PurchaseOrderStatus.received:
        return AppColors.success;
      case PurchaseOrderStatus.cancelled:
        return AppColors.error;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final PurchaseOrderStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Color _getColor() {
    switch (status) {
      case PurchaseOrderStatus.draft:
        return AppColors.grey500;
      case PurchaseOrderStatus.pending:
        return AppColors.warning;
      case PurchaseOrderStatus.ordered:
        return AppColors.info;
      case PurchaseOrderStatus.partiallyReceived:
        return AppColors.warning;
      case PurchaseOrderStatus.received:
        return AppColors.success;
      case PurchaseOrderStatus.cancelled:
        return AppColors.error;
    }
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
            ),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _SummaryRow(this.label, this.value, {this.isBold = false});

  @override
  Widget build(BuildContext context) {
    final style = isBold
        ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)
        : TextStyle(fontSize: 13, color: AppColors.textSecondary);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style.copyWith(
            color: isBold ? AppColors.primary : null,
          )),
        ],
      ),
    );
  }
}
