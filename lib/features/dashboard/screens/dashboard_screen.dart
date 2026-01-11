import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/stats_card.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/orders_provider.dart';
import '../../shell/screens/main_shell.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardStats = ref.watch(dashboardStatsProvider);
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final isMobile = ScreenBreakpoints.isMobile(context);
    final isTablet = ScreenBreakpoints.isTablet(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return dashboardStats.when(
      loading: () => const DashboardSkeleton(),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (stats) => RefreshIndicator(
        onRefresh: () async {
          // Invalidate all dashboard providers to refresh data
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(todayStatsProvider);
          ref.invalidate(recentOrdersProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Title - responsive
              _buildHeader(context, ref, isMobile),
              SizedBox(height: isMobile ? 16 : 24),

              // Stats Cards - responsive grid
              _buildStatsGrid(context, stats, currencyFormat, isMobile, isTablet, screenWidth),
              SizedBox(height: isMobile ? 16 : 24),

              // Charts Row - stack on mobile
              if (isMobile) ...[
                _SalesChart(salesData: stats.recentSales, isMobile: true),
                const SizedBox(height: 16),
                _TopProducts(products: stats.topProducts, isMobile: true),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _SalesChart(salesData: stats.recentSales, isMobile: false),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _TopProducts(products: stats.topProducts, isMobile: false),
                    ),
                  ],
                ),
              SizedBox(height: isMobile ? 16 : 24),

              // Bottom Row - stack on mobile
              if (isMobile) ...[
                _RecentOrders(isMobile: true),
                const SizedBox(height: 16),
                _QuickStats(stats: stats, isMobile: true),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _RecentOrders(isMobile: false)),
                    const SizedBox(width: 16),
                    Expanded(child: _QuickStats(stats: stats, isMobile: false)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, bool isMobile) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dashboard', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'Welcome back!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 12),
          _DateRangeSelector(),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dashboard', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Welcome back! Here\'s what\'s happening today.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
        _DateRangeSelector(),
      ],
    );
  }

  Widget _buildStatsGrid(
    BuildContext context,
    DashboardStats stats,
    NumberFormat currencyFormat,
    bool isMobile,
    bool isTablet,
    double screenWidth,
  ) {
    // Determine grid columns based on screen size
    int crossAxisCount = 4;
    double childAspectRatio = 2.2; // Wider, shorter cards like reference
    
    if (isMobile) {
      crossAxisCount = 2;
      childAspectRatio = 1.6; // Shorter cards for mobile
    } else if (isTablet) {
      crossAxisCount = 2;
      childAspectRatio = 2.0; // Shorter for tablet
    } else if (screenWidth < 1100) {
      crossAxisCount = 2;
      childAspectRatio = 2.2; // Shorter for small desktop
    }

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: isMobile ? 12 : 16,
      crossAxisSpacing: isMobile ? 12 : 16,
      childAspectRatio: childAspectRatio,
      children: [
        PastelStatsCard(
          title: "${stats.periodLabel} Sales",
          value: currencyFormat.format(stats.periodSales),
          icon: Iconsax.money_recive,
          backgroundColor: context.isDarkMode ? AppColors.darkPastelCyan : AppColors.pastelCyan,
          iconColor: AppColors.pastelCyanDark,
          compact: isMobile,
          animationDelay: 0,
        ),
        PastelStatsCard(
          title: "${stats.periodLabel} Orders",
          value: stats.periodOrders.toString(),
          icon: Iconsax.receipt_item,
          backgroundColor: context.isDarkMode ? AppColors.darkPastelGreen : AppColors.pastelGreen,
          iconColor: AppColors.pastelGreenDark,
          compact: isMobile,
          animationDelay: 100,
        ),
        
        PastelStatsCard(
          title: 'Low Stock',
          value: stats.lowStockCount.toString(),
          icon: Iconsax.warning_2,
          backgroundColor: context.isDarkMode ? AppColors.darkPastelOrange : AppColors.pastelOrange,
          iconColor: AppColors.pastelOrangeDark,
          subtitle: stats.lowStockCount > 0 ? 'Needs attention' : 'All stocked',
          compact: isMobile,
          animationDelay: 300,
        ),
        PastelStatsCard(
          title: 'Pending Credit',
          value: currencyFormat.format(stats.totalPendingCredit),
          icon: Iconsax.wallet_minus,
          backgroundColor: context.isDarkMode ? AppColors.darkPastelPurple : AppColors.pastelPurple,
          iconColor: stats.totalPendingCredit > 0 ? AppColors.error : AppColors.pastelPurpleDark,
          subtitle: stats.customersWithCreditCount > 0 
              ? '${stats.customersWithCreditCount} customers' 
              : 'No pending',
          compact: isMobile,
          animationDelay: 400,
        ),
      ],
    );
  }
}

class _DateRangeSelector extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(dashboardDateRangeProvider);
    final isMobile = ScreenBreakpoints.isMobile(context);

    if (isMobile) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButton<DashboardDateRange>(
          value: range,
          underline: const SizedBox(),
          isDense: true,
          items: DashboardDateRange.values.map((r) {
            return DropdownMenuItem(
              value: r,
              child: Text(r.name[0].toUpperCase() + r.name.substring(1)),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              ref.read(dashboardDateRangeProvider.notifier).state = value;
            }
          },
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: DashboardDateRange.values.map((r) {
          final isSelected = r == range;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  ref.read(dashboardDateRangeProvider.notifier).state = r;
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: isSelected
                        ? [BoxShadow(color: AppColors.shadowColorLight, blurRadius: 4)]
                        : null,
                  ),
                  child: Text(
                    r.name[0].toUpperCase() + r.name.substring(1),
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SalesChart extends StatelessWidget {
  final List<Map<String, dynamic>> salesData;
  final bool isMobile;

  const _SalesChart({required this.salesData, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    
    return AppCard(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sales Overview',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isDark ? AppColors.darkTextPrimary : null,
                ),
              ),
              if (!isMobile)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.trending_up, size: 14, color: AppColors.success),
                      SizedBox(width: 4),
                      Text(
                        '+15.3%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 24),
          SizedBox(
            height: isMobile ? 180 : 250,
            child: salesData.isEmpty
                ? Center(child: Text('No sales data available', style: TextStyle(color: isDark ? AppColors.darkTextSecondary : null)))
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 1,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: isDark ? AppColors.darkCardBorder : AppColors.grey200,
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: isMobile ? 2 : 1,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= salesData.length) {
                                return const Text('');
                              }
                              final date = salesData[value.toInt()]['date'] as String;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  DateFormat('E').format(DateTime.parse(date)),
                                  style: TextStyle(
                                    color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                                    fontSize: isMobile ? 10 : 11,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: !isMobile,
                            interval: 1000,
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '₹${(value / 1000).toStringAsFixed(0)}k',
                                style: TextStyle(
                                  color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                                  fontSize: 11,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: salesData.asMap().entries.map((entry) {
                            return FlSpot(
                              entry.key.toDouble(),
                              (entry.value['total_sales'] as num?)?.toDouble() ?? 0,
                            );
                          }).toList(),
                          isCurved: true,
                          gradient: const LinearGradient(
                            colors: [AppColors.primaryLight, AppColors.primary],
                          ),
                          barWidth: isMobile ? 2 : 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: !isMobile,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: isDark ? AppColors.darkCardBackground : AppColors.white,
                                strokeWidth: 2,
                                strokeColor: AppColors.primary,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.primary.withValues(alpha: isDark ? 0.3 : 0.2),
                                AppColors.primary.withValues(alpha: 0.0),
                              ],
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
  }
}

class _TopProducts extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  final bool isMobile;

  const _TopProducts({required this.products, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return AppCard(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top Products', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          if (products.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 16 : 32),
                child: const Text('No sales data yet'),
              ),
            )
          else
            ...products.take(isMobile ? 3 : 5).toList().asMap().entries.map((entry) {
              final index = entry.key;
              final product = entry.value;
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: index < (isMobile ? 2 : 4)
                      ? const Border(bottom: BorderSide(color: AppColors.grey200))
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: isMobile ? 28 : 32,
                      height: isMobile ? 28 : 32,
                      decoration: BoxDecoration(
                        color: index == 0
                            ? AppColors.warning.withValues(alpha: 0.2)
                            : AppColors.grey100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '#${index + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 10 : 12,
                            color: index == 0 ? AppColors.warning : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['product_name'] as String? ?? 'Unknown',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: isMobile ? 13 : 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${product['total_quantity']} sold',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      currencyFormat.format((product['total_revenue'] as num?)?.toDouble() ?? 0),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        fontSize: isMobile ? 12 : 14,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _RecentOrders extends ConsumerWidget {
  final bool isMobile;
  const _RecentOrders({required this.isMobile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentOrders = ref.watch(recentOrdersProvider);
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final timeFormat = DateFormat('hh:mm a');

    return AppCard(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Orders', style: Theme.of(context).textTheme.titleMedium),
              TextButton(
                onPressed: () {},
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          recentOrders.when(
            loading: () => Column(
              children: List.generate(3, (_) => const ListItemSkeleton()),
            ),
            error: (error, stack) => Text('Error: $error'),
            data: (orders) {
              if (orders.isEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 16 : 32),
                    child: const Text('No orders yet'),
                  ),
                );
              }
              return Column(
                children: orders.take(isMobile ? 3 : 5).map((order) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.grey200)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(isMobile ? 8 : 10),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Iconsax.receipt_item,
                            size: isMobile ? 16 : 20,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.orderNumber,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: isMobile ? 13 : 14,
                                ),
                              ),
                              Text(
                                '${order.itemCount} items • ${timeFormat.format(order.createdAt)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              currencyFormat.format(order.totalAmount),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                                fontSize: isMobile ? 12 : 14,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getStatusColor(order.status).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                order.statusDisplayName,
                                style: TextStyle(
                                  fontSize: isMobile ? 10 : 11,
                                  color: _getStatusColor(order.status),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(dynamic status) {
    switch (status.toString()) {
      case 'OrderStatus.completed':
        return AppColors.success;
      case 'OrderStatus.pending':
        return AppColors.warning;
      case 'OrderStatus.cancelled':
        return AppColors.error;
      default:
        return AppColors.info;
    }
  }
}

class _QuickStats extends StatelessWidget {
  final DashboardStats stats;
  final bool isMobile;

  const _QuickStats({required this.stats, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return AppCard(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Stats', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          _QuickStatItem(
            icon: Iconsax.box,
            label: 'Total Products',
            value: stats.totalProducts.toString(),
            color: AppColors.info,
            isMobile: isMobile,
          ),
          _QuickStatItem(
            icon: Iconsax.people,
            label: 'Total Customers',
            value: stats.totalCustomers.toString(),
            color: AppColors.success,
            isMobile: isMobile,
          ),
          _QuickStatItem(
            icon: Iconsax.dollar_square,
            label: 'Inventory Value',
            value: currencyFormat.format(stats.inventoryValue),
            color: AppColors.primary,
            isMobile: isMobile,
          ),
          _QuickStatItem(
            icon: Iconsax.wallet_minus,
            label: 'Pending Credit',
            value: currencyFormat.format(stats.totalPendingCredit),
            color: stats.totalPendingCredit > 0 ? AppColors.error : AppColors.success,
            isMobile: isMobile,
          ),
          _QuickStatItem(
            icon: Iconsax.warning_2,
            label: 'Low Stock Items',
            value: stats.lowStockCount.toString(),
            color: AppColors.warning,
            isLast: true,
            isMobile: isMobile,
          ),
        ],
      ),
    );
  }
}

class _QuickStatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isLast;
  final bool isMobile;

  const _QuickStatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isLast = false,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 12),
      decoration: BoxDecoration(
        border: !isLast
            ? const Border(bottom: BorderSide(color: AppColors.grey200))
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 8 : 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: isMobile ? 16 : 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: isMobile ? 13 : 14),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: isMobile ? 14 : 16,
            ),
          ),
        ],
      ),
    );
  }
}
