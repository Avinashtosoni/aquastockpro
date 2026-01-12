import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../data/models/order.dart';
import '../../../providers/orders_provider.dart';
import '../../../providers/refunds_provider.dart';
import '../../../providers/auth_provider.dart';
import '../widgets/order_details_sheet.dart';
import '../widgets/refund_dialog.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  String _searchQuery = '';
  OrderStatus? _statusFilter;
  PaymentMethod? _paymentFilter;
  DateTimeRange? _dateRange;
  String _quickFilter = 'all'; // 'all', 'today', 'week', 'month'
  
  // Pagination
  static const int _pageSize = 20;
  int _displayCount = 20; // Initially show 20 orders

  final _currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
  final _dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
  final _shortDateFormat = DateFormat('dd MMM');

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersNotifierProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: ordersAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading transactions...'),
        error: (e, s) => ErrorState(
          title: 'Failed to load transactions',
          onRetry: () => ref.refresh(ordersNotifierProvider),
        ),
        data: (allOrders) {
          final filtered = _filterOrders(allOrders);
          final stats = _calculateStats(allOrders);
          
          // Paginated list - show only _displayCount items
          final paginatedOrders = filtered.take(_displayCount).toList();
          final hasMore = filtered.length > _displayCount;

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(ordersNotifierProvider),
            child: CustomScrollView(
              slivers: [
                // Stats Cards
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 16 : 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Transactions',
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${filtered.length} transactions found',
                                    style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            // Date Range Button
                            OutlinedButton.icon(
                              onPressed: _selectDateRange,
                              icon: const Icon(Iconsax.calendar, size: 18),
                              label: Text(
                                _dateRange != null
                                    ? '${_shortDateFormat.format(_dateRange!.start)} - ${_shortDateFormat.format(_dateRange!.end)}'
                                    : 'Date Range',
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Stats Cards Row
                        _buildStatsCards(stats, isMobile),
                        
                        const SizedBox(height: 20),
                        
                        // Quick Filters
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _QuickFilterChip(
                                label: 'All',
                                isSelected: _quickFilter == 'all',
                                onTap: () => _setQuickFilter('all'),
                              ),
                              const SizedBox(width: 8),
                              _QuickFilterChip(
                                label: 'Today',
                                isSelected: _quickFilter == 'today',
                                onTap: () => _setQuickFilter('today'),
                              ),
                              const SizedBox(width: 8),
                              _QuickFilterChip(
                                label: 'This Week',
                                isSelected: _quickFilter == 'week',
                                onTap: () => _setQuickFilter('week'),
                              ),
                              const SizedBox(width: 8),
                              _QuickFilterChip(
                                label: 'This Month',
                                isSelected: _quickFilter == 'month',
                                onTap: () => _setQuickFilter('month'),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Search and Filters Row
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.grey200),
                                ),
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: 'Search by order number...',
                                    hintStyle: TextStyle(color: AppColors.grey400),
                                    prefixIcon: const Icon(Iconsax.search_normal, size: 20),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  ),
                                  onChanged: (v) => setState(() => _searchQuery = v),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Status Filter
                            _FilterDropdown<OrderStatus?>(
                              icon: Iconsax.tag,
                              value: _statusFilter,
                              items: [
                                const DropdownMenuItem(value: null, child: Text('All Status')),
                                ...OrderStatus.values.map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s.name[0].toUpperCase() + s.name.substring(1)),
                                )),
                              ],
                              onChanged: (v) => setState(() => _statusFilter = v),
                            ),
                            const SizedBox(width: 8),
                            // Payment Filter
                            _FilterDropdown<PaymentMethod?>(
                              icon: Iconsax.wallet,
                              value: _paymentFilter,
                              items: [
                                const DropdownMenuItem(value: null, child: Text('All Payment')),
                                ...PaymentMethod.values.map((p) => DropdownMenuItem(
                                  value: p,
                                  child: Text(p.name[0].toUpperCase() + p.name.substring(1)),
                                )),
                              ],
                              onChanged: (v) => setState(() => _paymentFilter = v),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Orders List
                if (filtered.isEmpty)
                  const SliverFillRemaining(
                    child: EmptyState(
                      icon: Iconsax.receipt,
                      title: 'No transactions found',
                      subtitle: 'Try adjusting your filters',
                    ),
                  )
                else ...[
                  if (!isMobile) const SliverToBoxAdapter(child: _TableHeader()),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final order = paginatedOrders[index];
                          return _OrderCard(
                            order: order,
                            currencyFormat: _currencyFormat,
                            dateFormat: _dateFormat,
                            onTap: () => _showOrderDetails(order),
                          );
                        },
                        childCount: paginatedOrders.length,
                      ),
                    ),
                  ),
                  
                  // Load More Button
                  if (hasMore)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                        child: Center(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _displayCount += _pageSize;
                              });
                            },
                            icon: const Icon(Iconsax.arrow_down_1),
                            label: Text('Load More (${filtered.length - paginatedOrders.length} remaining)'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
                
                // Bottom padding
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsCards(_OrderStats stats, bool isMobile) {
    final cards = [
      _StatCard(
        title: 'Today\'s Sales',
        value: _currencyFormat.format(stats.todaySales),
        subtitle: '${stats.todayCount} orders',
        icon: Iconsax.chart,
        color: AppColors.success,
      ),
      _StatCard(
        title: 'This Week',
        value: _currencyFormat.format(stats.weekSales),
        subtitle: '${stats.weekCount} orders',
        icon: Iconsax.calendar,
        color: AppColors.primary,
      ),
      _StatCard(
        title: 'Pending',
        value: stats.pendingCount.toString(),
        subtitle: 'orders',
        icon: Iconsax.clock,
        color: AppColors.warning,
      ),
      _StatCard(
        title: 'Total Revenue',
        value: _currencyFormat.format(stats.totalRevenue),
        subtitle: '${stats.totalCount} orders',
        icon: Iconsax.money,
        color: AppColors.info,
      ),
    ];

    if (isMobile) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
        children: cards,
      );
    }

    return Row(
      children: cards.map((card) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: card,
        ),
      )).toList(),
    );
  }

  List<Order> _filterOrders(List<Order> orders) {
    var filtered = orders;

    // Quick filter
    final now = DateTime.now();
    switch (_quickFilter) {
      case 'today':
        filtered = filtered.where((o) => 
          o.createdAt.year == now.year && 
          o.createdAt.month == now.month && 
          o.createdAt.day == now.day
        ).toList();
        break;
      case 'week':
        final weekAgo = now.subtract(const Duration(days: 7));
        filtered = filtered.where((o) => o.createdAt.isAfter(weekAgo)).toList();
        break;
      case 'month':
        filtered = filtered.where((o) => 
          o.createdAt.year == now.year && 
          o.createdAt.month == now.month
        ).toList();
        break;
    }

    // Date range filter
    if (_dateRange != null) {
      filtered = filtered.where((o) =>
        o.createdAt.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
        o.createdAt.isBefore(_dateRange!.end.add(const Duration(days: 1)))
      ).toList();
    }

    // Status filter
    if (_statusFilter != null) {
      filtered = filtered.where((o) => o.status == _statusFilter).toList();
    }

    // Payment filter
    if (_paymentFilter != null) {
      filtered = filtered.where((o) => o.paymentMethod == _paymentFilter).toList();
    }

    // Search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((o) =>
        o.orderNumber.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    // Sort by date (newest first)
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return filtered;
  }

  _OrderStats _calculateStats(List<Order> orders) {
    final now = DateTime.now();
    final completedOrders = orders.where((o) => o.status == OrderStatus.completed);
    
    final todayOrders = completedOrders.where((o) =>
      o.createdAt.year == now.year &&
      o.createdAt.month == now.month &&
      o.createdAt.day == now.day
    ).toList();

    final weekAgo = now.subtract(const Duration(days: 7));
    final weekOrders = completedOrders.where((o) => o.createdAt.isAfter(weekAgo)).toList();

    final pendingOrders = orders.where((o) => o.status == OrderStatus.pending).toList();

    return _OrderStats(
      todaySales: todayOrders.fold(0.0, (sum, o) => sum + o.totalAmount),
      todayCount: todayOrders.length,
      weekSales: weekOrders.fold(0.0, (sum, o) => sum + o.totalAmount),
      weekCount: weekOrders.length,
      pendingCount: pendingOrders.length,
      totalRevenue: completedOrders.fold(0.0, (sum, o) => sum + o.totalAmount),
      totalCount: completedOrders.length,
    );
  }

  void _setQuickFilter(String filter) {
    setState(() {
      _quickFilter = filter;
      _dateRange = null; // Clear custom date range when using quick filter
      _displayCount = _pageSize; // Reset pagination
    });
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() {
        _dateRange = picked;
        _quickFilter = 'all'; // Clear quick filter when using custom date
        _displayCount = _pageSize; // Reset pagination
      });
    }
  }

  void _showOrderDetails(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OrderDetailsSheet(
        order: order,
        onRefund: () => _processRefund(order),
      ),
    );
  }

  void _processRefund(Order order) {
    showDialog(
      context: context,
      builder: (context) => RefundDialog(
        order: order,
        onProcess: (reason, notes, restockItems, selectedItems) async {
          try {
            // Get current user for tracking who processed the refund
            final authState = ref.read(authProvider);
            final employeeId = authState.user?.id;
            
            // Create refund record with selected items
            final refund = await ref.read(refundProvider.notifier).processRefund(
              order: order,
              itemsToRefund: selectedItems,
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
                order.id,
                OrderStatus.refunded,
              );
              
              // Close the order details sheet
              if (mounted) Navigator.pop(context);
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Refunded ${selectedItems.length} item(s) - ${refund.refundNumber}'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            } else {
              throw Exception('Failed to create refund record');
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Refund failed: $e'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          }
        },
      ),
    );
  }
}

// Helper Classes and Widgets
class _OrderStats {
  final double todaySales;
  final int todayCount;
  final double weekSales;
  final int weekCount;
  final int pendingCount;
  final double totalRevenue;
  final int totalCount;

  _OrderStats({
    required this.todaySales,
    required this.todayCount,
    required this.weekSales,
    required this.weekCount,
    required this.pendingCount,
    required this.totalRevenue,
    required this.totalCount,
  });
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : color.withValues(alpha: 0.2),
        ),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 11,
              color: isDark ? AppColors.darkTextPrimary : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _QuickFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.grey300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  final IconData icon;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _FilterDropdown({
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          icon: const Icon(Iconsax.arrow_down_1, size: 16),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: const [
          Expanded(flex: 2, child: Text('Order No', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
          Expanded(flex: 3, child: Text('Customer', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
          Expanded(flex: 2, child: Text('Mobile', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
          Expanded(flex: 2, child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
          Expanded(flex: 2, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
          Expanded(flex: 1, child: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final NumberFormat currencyFormat;
  final DateFormat dateFormat;
  final VoidCallback onTap;

  const _OrderCard({
    required this.order,
    required this.currencyFormat,
    required this.dateFormat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.grey200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                // 1. Order Number
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.orderNumber,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(order.createdAt),
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                
                // 2. Customer Name
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: Text(
                          (order.customerName?.isNotEmpty ?? false) ? order.customerName![0].toUpperCase() : 'W',
                          style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.customerName ?? 'Walk-in Customer',
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 3. Mobile Number
                Expanded(
                  flex: 2,
                  child: Text(
                    order.customerPhone ?? '-',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
                
                // 4. Bill Amount
                Expanded(
                  flex: 2,
                  child: Text(
                    currencyFormat.format(order.totalAmount),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
                
                // 5. Bill Status
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      _StatusChip(status: order.status),
                    ],
                  ),
                ),
                
                // 6. Action Options
                Expanded(
                  flex: 1,
                  child: PopupMenuButton<String>(
                    icon: const Icon(Iconsax.more, size: 20, color: AppColors.textSecondary),
                    onSelected: (value) {
                      if (value == 'view') onTap();
                      // Add other actions handling here
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                             Icon(Iconsax.eye, size: 18),
                             SizedBox(width: 8),
                             Text('View Details'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'print',
                        child: Row(
                          children: [
                             Icon(Iconsax.printer, size: 18),
                             SizedBox(width: 8),
                             Text('Print Bill'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                         value: 'download',
                         child: Row(
                           children: [
                              Icon(Iconsax.document_download, size: 18),
                              SizedBox(width: 8),
                              Text('Invoice'),
                           ],
                         ),
                       ),
                       if (order.status == OrderStatus.completed)
                       const PopupMenuItem(
                         value: 'refund',
                         child: Row(
                           children: [
                              Icon(Iconsax.undo, size: 18, color: AppColors.error),
                              SizedBox(width: 8),
                              Text('Refund', style: TextStyle(color: AppColors.error)),
                           ],
                         ),
                       ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
}

class _PaymentIcon extends StatelessWidget {
  final PaymentMethod method;
  const _PaymentIcon({required this.method});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    switch (method) {
      case PaymentMethod.cash:
        icon = Iconsax.money;
        color = AppColors.success;
        break;
      case PaymentMethod.card:
        icon = Iconsax.card;
        color = AppColors.primary;
        break;
      case PaymentMethod.upi:
        icon = Iconsax.mobile;
        color = AppColors.info;
        break;
      case PaymentMethod.credit:
        icon = Iconsax.wallet;
        color = AppColors.warning;
        break;
      case PaymentMethod.mixed:
        icon = Iconsax.money_add;
        color = AppColors.info;
        break;
    }
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, size: 12, color: color),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final OrderStatus status;
  const _StatusChip({required this.status});

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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.name[0].toUpperCase() + status.name.substring(1),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
