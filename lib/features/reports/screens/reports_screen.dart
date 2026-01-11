import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/services/report_export_service.dart';
import '../../../providers/orders_provider.dart';
import '../../../providers/products_provider.dart';
import '../../../providers/customers_provider.dart';
import '../widgets/report_widgets.dart';
import '../../shell/screens/main_shell.dart';

// Date range state provider for reports
final reportDateRangeProvider = StateProvider<DateTimeRange>((ref) {
  final now = DateTime.now();
  return DateTimeRange(
    start: now.subtract(const Duration(days: 30)),
    end: now,
  );
});

// Calculate days from date range
final reportDaysProvider = Provider<int>((ref) {
  final range = ref.watch(reportDateRangeProvider);
  return range.end.difference(range.start).inDays + 1;
});

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = ScreenBreakpoints.isMobile(context);
    final isTablet = ScreenBreakpoints.isTablet(context);
    final isDark = context.isDarkMode;
    final dateRange = ref.watch(reportDateRangeProvider);
    final days = ref.watch(reportDaysProvider);
    
    // Real data from providers
    final statsAsync = ref.watch(periodStatsProvider(days));
    final salesDataAsync = ref.watch(salesByDateProvider(days));
    final topProductsAsync = ref.watch(topProductsProvider(5));

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(context, isMobile),
          SizedBox(height: isMobile ? 16 : 24),

          // Date range selector
          _DateRangeSelector(isMobile: isMobile),
          SizedBox(height: isMobile ? 16 : 24),

          // Main content area
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Stats Overview Cards
                  statsAsync.when(
                    loading: () => _buildStatsLoading(isMobile),
                    error: (e, s) => _buildStatsError(),
                    data: (stats) => _buildStatsRow(context, stats, isMobile, isDark),
                  ),
                  SizedBox(height: isMobile ? 16 : 24),

                  // Charts Row
                  if (isMobile)
                    Column(
                      children: [
                        // Sales Chart
                        SizedBox(
                          height: 280,
                          child: salesDataAsync.when(
                            loading: () => _buildChartLoading(),
                            error: (e, s) => _buildChartError('Sales Chart'),
                            data: (data) => SalesLineChart(
                              salesData: data.map((d) => {
                                'date': d['date'],
                                'total': d['total_sales'],
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Top Products
                        SizedBox(
                          height: 300,
                          child: topProductsAsync.when(
                            loading: () => _buildChartLoading(),
                            error: (e, s) => _buildChartError('Top Products'),
                            data: (data) => TopProductsChart(
                              products: data.map((p) => {
                                'name': p['product_name'],
                                'revenue': p['total_revenue'],
                                'quantity': p['total_quantity'],
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    SizedBox(
                      height: 320,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Sales Chart (larger)
                          Expanded(
                            flex: 2,
                            child: salesDataAsync.when(
                              loading: () => _buildChartLoading(),
                              error: (e, s) => _buildChartError('Sales Chart'),
                              data: (data) => SalesLineChart(
                                salesData: data.map((d) => {
                                  'date': d['date'],
                                  'total': d['total_sales'],
                                }).toList(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Top Products
                          Expanded(
                            flex: 1,
                            child: topProductsAsync.when(
                              loading: () => _buildChartLoading(),
                              error: (e, s) => _buildChartError('Top Products'),
                              data: (data) => TopProductsChart(
                                products: data.map((p) => {
                                  'name': p['product_name'],
                                  'revenue': p['total_revenue'],
                                  'quantity': p['total_quantity'],
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: isMobile ? 16 : 24),

                  // Report Export Cards
                  _buildReportCardsGrid(context, ref, isMobile, isTablet, dateRange, stats: statsAsync.valueOrNull),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Iconsax.chart_square, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reports',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'View business analytics and export data',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (!isMobile)
          FilledButton.icon(
            onPressed: () => _showQuickExportDialog(context),
            icon: const Icon(Iconsax.export_1, size: 18),
            label: const Text('Quick Export'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.05, end: 0);
  }

  Widget _buildStatsLoading(bool isMobile) {
    return GridView.count(
      crossAxisCount: isMobile ? 2 : 4,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: isMobile ? 1.4 : 1.8,
      children: List.generate(4, (i) => Container(
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      )),
    );
  }

  Widget _buildStatsError() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: const Center(
        child: Text('Failed to load stats', style: TextStyle(color: AppColors.error)),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, Map<String, dynamic> stats, bool isMobile, bool isDark) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final totalSales = (stats['totalSales'] as num?)?.toDouble() ?? 0;
    final orderCount = stats['orderCount'] ?? 0;
    final avgOrder = (stats['averageOrder'] as num?)?.toDouble() ?? 0;

    return GridView.count(
      crossAxisCount: isMobile ? 2 : 4,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: isMobile ? 1.3 : 1.6,
      children: [
        ReportStatsCard(
          title: 'Total Revenue',
          value: currencyFormat.format(totalSales),
          icon: Iconsax.money_recive,
          color: AppColors.success,
          subtitle: 'For selected period',
          animationDelay: 0,
        ),
        ReportStatsCard(
          title: 'Orders',
          value: orderCount.toString(),
          icon: Iconsax.shopping_cart,
          color: AppColors.info,
          subtitle: 'Completed orders',
          animationDelay: 100,
        ),
        ReportStatsCard(
          title: 'Avg. Order',
          value: currencyFormat.format(avgOrder),
          icon: Iconsax.chart_21,
          color: AppColors.warning,
          subtitle: 'Per transaction',
          animationDelay: 200,
        ),
        ReportStatsCard(
          title: 'Daily Avg',
          value: currencyFormat.format(totalSales / 30),
          icon: Iconsax.calendar_tick,
          color: AppColors.primary,
          subtitle: 'Revenue per day',
          animationDelay: 300,
        ),
      ],
    );
  }

  Widget _buildChartLoading() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }

  Widget _buildChartError(String title) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.warning_2, color: AppColors.error),
            const SizedBox(height: 8),
            Text('Failed to load $title', style: const TextStyle(color: AppColors.error)),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCardsGrid(
    BuildContext context, 
    WidgetRef ref, 
    bool isMobile, 
    bool isTablet,
    DateTimeRange dateRange, {
    Map<String, dynamic>? stats,
  }) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final totalSales = (stats?['totalSales'] as num?)?.toDouble() ?? 0;
    final orderCount = stats?['orderCount'] ?? 0;

    int crossAxisCount = 3;
    double childAspectRatio = 2.8;  // Very compact cards
    if (isMobile) {
      crossAxisCount = 2;
      childAspectRatio = 2.0;  // Compact on mobile
    } else if (isTablet) {
      crossAxisCount = 2;
      childAspectRatio = 2.5;
    }

    return GridView.count(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: isMobile ? 12 : 16,
      mainAxisSpacing: isMobile ? 12 : 16,
      childAspectRatio: childAspectRatio,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _EnhancedReportCard(
          title: 'Sales Report',
          subtitle: 'Revenue & order analytics',
          icon: Iconsax.chart_21,
          gradient: [AppColors.success, AppColors.success.withValues(alpha: 0.7)],
          stats: '${currencyFormat.format(totalSales)} this period',
          onTap: () => _showReportDialog(context, ref, ReportType.sales, dateRange),
          animationDelay: 0,
        ),
        _EnhancedReportCard(
          title: 'Inventory Report',
          subtitle: 'Stock levels & valuation',
          icon: Iconsax.box_1,
          gradient: [AppColors.info, AppColors.info.withValues(alpha: 0.7)],
          stats: 'View stock details',
          onTap: () => _showReportDialog(context, ref, ReportType.inventory, dateRange),
          animationDelay: 100,
        ),
        _EnhancedReportCard(
          title: 'Top Products',
          subtitle: 'Best-selling items',
          icon: Iconsax.crown,
          gradient: [AppColors.warning, AppColors.warning.withValues(alpha: 0.7)],
          stats: '$orderCount orders analyzed',
          onTap: () => _showReportDialog(context, ref, ReportType.topProducts, dateRange),
          animationDelay: 200,
        ),
        _EnhancedReportCard(
          title: 'Profit Report',
          subtitle: 'Revenue, cost & margins',
          icon: Iconsax.trend_up,
          gradient: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
          stats: 'Margin analysis',
          onTap: () => _showReportDialog(context, ref, ReportType.profit, dateRange),
          animationDelay: 300,
        ),
        _EnhancedReportCard(
          title: 'Customer Report',
          subtitle: 'Customer analytics & loyalty',
          icon: Iconsax.people,
          gradient: [AppColors.secondary, AppColors.secondary.withValues(alpha: 0.7)],
          stats: 'Customer insights',
          onTap: () => _showReportDialog(context, ref, ReportType.customers, dateRange),
          animationDelay: 400,
        ),
        _EnhancedReportCard(
          title: 'Tax Report',
          subtitle: 'GST/Tax summary',
          icon: Iconsax.receipt_21,
          gradient: [AppColors.error, AppColors.error.withValues(alpha: 0.7)],
          stats: 'Tax collected',
          onTap: () => _showReportDialog(context, ref, ReportType.tax, dateRange),
          animationDelay: 500,
        ),
      ],
    );
  }

  void _showReportDialog(BuildContext context, WidgetRef ref, ReportType type, DateTimeRange dateRange) {
    showDialog(
      context: context,
      builder: (context) => _ReportExportDialog(
        reportType: type,
        startDate: dateRange.start,
        endDate: dateRange.end,
      ),
    );
  }

  void _showQuickExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final dateRange = ref.watch(reportDateRangeProvider);
          return _QuickExportDialog(
            startDate: dateRange.start,
            endDate: dateRange.end,
          );
        },
      ),
    );
  }
}

class _DateRangeSelector extends ConsumerWidget {
  final bool isMobile;
  
  const _DateRangeSelector({required this.isMobile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateRange = ref.watch(reportDateRangeProvider);
    final dateFormat = DateFormat('dd MMM yyyy');
    final isDark = context.isDarkMode;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Calculate selected preset
    final days = dateRange.end.difference(dateRange.start).inDays;
    final isToday = days == 0 && dateRange.start.day == today.day;

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: isDark ? AppColors.darkShadowColor : AppColors.shadowColorLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Iconsax.calendar_1, size: 20, color: isDark ? AppColors.primaryLight : AppColors.primary),
                    const SizedBox(width: 8),
                    Text('Date Range', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextPrimary : null)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildDateButton(context, ref, true, dateFormat, dateRange)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text('to', style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
                    ),
                    Expanded(child: _buildDateButton(context, ref, false, dateFormat, dateRange)),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPresetButton(context, ref, 'Today', 0, isToday),
                      const SizedBox(width: 8),
                      _buildPresetButton(context, ref, '7 Days', 7, days == 7 && !isToday),
                      const SizedBox(width: 8),
                      _buildPresetButton(context, ref, '30 Days', 30, days == 30),
                      const SizedBox(width: 8),
                      _buildPresetButton(context, ref, '90 Days', 90, days == 90),
                      const SizedBox(width: 8),
                      _buildPresetButton(context, ref, 'This Year', 365, days >= 360),
                    ],
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Icon(Iconsax.calendar_1, size: 20, color: isDark ? AppColors.primaryLight : AppColors.primary),
                const SizedBox(width: 12),
                Text('Report Period:', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextPrimary : null)),
                const SizedBox(width: 16),
                _buildDateButton(context, ref, true, dateFormat, dateRange),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('to', style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
                ),
                _buildDateButton(context, ref, false, dateFormat, dateRange),
                const Spacer(),
                _buildPresetButton(context, ref, 'Today', 0, isToday),
                const SizedBox(width: 8),
                _buildPresetButton(context, ref, '7 Days', 7, days == 7 && !isToday),
                const SizedBox(width: 8),
                _buildPresetButton(context, ref, '30 Days', 30, days == 30),
                const SizedBox(width: 8),
                _buildPresetButton(context, ref, '90 Days', 90, days == 90),
                const SizedBox(width: 8),
                _buildPresetButton(context, ref, 'This Year', 365, days >= 360),
              ],
            ),
    ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildDateButton(BuildContext context, WidgetRef ref, bool isStart, DateFormat format, DateTimeRange range) {
    final date = isStart ? range.start : range.end;
    final isDark = context.isDarkMode;

    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          final current = ref.read(reportDateRangeProvider);
          ref.read(reportDateRangeProvider.notifier).state = DateTimeRange(
            start: isStart ? picked : current.start,
            end: isStart ? current.end : picked,
          );
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceVariant : AppColors.grey100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.grey200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              format.format(date),
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.keyboard_arrow_down, size: 18, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetButton(BuildContext context, WidgetRef ref, String label, int daysBack, bool isSelected) {
    final isDark = context.isDarkMode;

    return InkWell(
      onTap: () {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        ref.read(reportDateRangeProvider.notifier).state = DateTimeRange(
          start: daysBack == 0 ? today : today.subtract(Duration(days: daysBack)),
          end: today,
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : (isDark ? AppColors.darkSurfaceVariant : AppColors.grey100),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

class _EnhancedReportCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final String stats;
  final VoidCallback onTap;
  final int animationDelay;

  const _EnhancedReportCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.stats,
    required this.onTap,
    this.animationDelay = 0,
  });

  @override
  State<_EnhancedReportCard> createState() => _EnhancedReportCardState();
}

class _EnhancedReportCardState extends State<_EnhancedReportCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()
          ..setTranslationRaw(0.0, _isHovered ? -6.0 : 0.0, 0.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isHovered
                      ? widget.gradient.first.withValues(alpha: 0.4)
                      : (isDark ? AppColors.darkCardBorder : AppColors.cardBorder),
                  width: _isHovered ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isHovered
                        ? widget.gradient.first.withValues(alpha: 0.2)
                        : (isDark ? AppColors.darkShadowColor : AppColors.shadowColorLight),
                    blurRadius: _isHovered ? 16 : 8,
                    offset: Offset(0, _isHovered ? 8 : 2),
                    spreadRadius: _isHovered ? 1 : 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: widget.gradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(widget.icon, color: Colors.white, size: 18),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceVariant : AppColors.grey100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Iconsax.export_1,
                          size: 12,
                          color: _isHovered
                              ? widget.gradient.first
                              : (isDark ? AppColors.darkTextTertiary : AppColors.textTertiary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isDark ? AppColors.darkTextPrimary : null,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          fontSize: 10,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: widget.gradient.first.withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.stats,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: widget.gradient.first,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate(delay: Duration(milliseconds: widget.animationDelay))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic);
  }
}

class _ReportExportDialog extends ConsumerStatefulWidget {
  final ReportType reportType;
  final DateTime startDate;
  final DateTime endDate;

  const _ReportExportDialog({
    required this.reportType,
    required this.startDate,
    required this.endDate,
  });

  @override
  ConsumerState<_ReportExportDialog> createState() => _ReportExportDialogState();
}

class _ReportExportDialogState extends ConsumerState<_ReportExportDialog> {
  ExportFormat _selectedFormat = ExportFormat.preview;
  bool _isExporting = false;
  bool _isLoading = true;
  String? _previewContent;
  ReportData? _reportData;

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);
    
    final service = ReportExportService();
    final orderRepo = ref.read(orderRepositoryProvider);
    
    try {
      switch (widget.reportType) {
        case ReportType.sales:
          final orders = await orderRepo.getByDateRange(widget.startDate, widget.endDate);
          _reportData = await service.generateSalesReport(
            startDate: widget.startDate,
            endDate: widget.endDate,
            orders: orders,
          );
          break;
        case ReportType.inventory:
          final products = await ref.read(productsProvider.future);
          _reportData = await service.generateInventoryReport(products: products);
          break;
        case ReportType.customers:
          final customers = await ref.read(customersProvider.future);
          _reportData = await service.generateCustomerReport(customers: customers);
          break;
        case ReportType.tax:
          final orders = await orderRepo.getByDateRange(widget.startDate, widget.endDate);
          _reportData = await service.generateTaxReport(
            startDate: widget.startDate,
            endDate: widget.endDate,
            orders: orders,
          );
          break;
        case ReportType.profit:
          final orders = await orderRepo.getByDateRange(widget.startDate, widget.endDate);
          final products = await ref.read(productsProvider.future);
          _reportData = await service.generateProfitLossReport(
            startDate: widget.startDate,
            endDate: widget.endDate,
            orders: orders,
            products: products,
          );
          break;
        case ReportType.topProducts:
          final topProducts = await orderRepo.getTopProducts(10);
          _reportData = ReportData(
            title: 'Top Products Report',
            subtitle: 'Best selling items',
            generatedAt: DateTime.now(),
            summary: {'Total Products': topProducts.length.toString()},
            columns: ['Product', 'Qty Sold', 'Revenue'],
            rows: topProducts.map<List<String>>((p) => [
              (p['product_name'] ?? 'Unknown').toString(),
              (p['total_quantity'] ?? 0).toString(),
              '₹${(p['total_revenue'] as num?)?.toStringAsFixed(0) ?? '0'}',
            ]).toList(),
          );
          break;
        case ReportType.credit:
          final customers = await ref.read(customersProvider.future);
          _reportData = await service.generateCreditReport(customers: customers);
          break;
        case ReportType.gst:
          final orders = await orderRepo.getByDateRange(widget.startDate, widget.endDate);
          _reportData = await service.generateGSTReport(
            startDate: widget.startDate,
            endDate: widget.endDate,
            orders: orders,
          );
          break;
      }
      
      if (_reportData != null) {
        _previewContent = service.formatAsPreview(_reportData!);
      }
    } catch (e) {
      _previewContent = 'Error loading report data: $e';
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Iconsax.document_text, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.reportType.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        widget.reportType.description,
                        style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),

            // Export format selection
            Text('Export Format', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextPrimary : null)),
            const SizedBox(height: 12),
            Row(
              children: ExportFormat.values.map((format) {
                final isSelected = _selectedFormat == format;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () => setState(() => _selectedFormat = format),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : (isDark ? AppColors.darkSurfaceVariant : AppColors.grey100),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : (isDark ? AppColors.darkCardBorder : AppColors.grey200),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              format == ExportFormat.pdf
                                  ? Iconsax.document
                                  : format == ExportFormat.excel
                                      ? Iconsax.document_text
                                      : Iconsax.eye,
                              color: isSelected ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              format.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Preview or export info
            if (_isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_selectedFormat == ExportFormat.preview) ...[
              Text('Preview', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextPrimary : null)),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceVariant : AppColors.grey50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.grey200),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _previewContent ?? 'No data available',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextPrimary : null,
                      ),
                    ),
                  ),
                ),
              ),
            ] else
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _selectedFormat == ExportFormat.pdf ? Iconsax.document : Iconsax.document_text,
                        size: 64,
                        color: AppColors.primary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Export as ${_selectedFormat.title}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isDark ? AppColors.darkTextPrimary : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Click the button below to generate and download',
                        style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: (_isExporting || _isLoading) ? null : _handleExport,
                  icon: _isExporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Iconsax.export_1, size: 18),
                  label: Text(_selectedFormat == ExportFormat.preview ? 'Copy to Clipboard' : 'Export'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleExport() async {
    if (_reportData == null) return;
    
    setState(() => _isExporting = true);
    
    try {
      final service = ReportExportService();
      final filename = widget.reportType.title.toLowerCase().replaceAll(' ', '_');
      
      if (_selectedFormat == ExportFormat.preview && _previewContent != null) {
        await Clipboard.setData(ClipboardData(text: _previewContent!));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Report copied to clipboard!'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context); // Close dialog after copy
        }
      } else if (_selectedFormat == ExportFormat.excel) {
        final bytes = await service.exportToExcel(_reportData!);
        await _exportFile(bytes, '$filename.csv', 'text/csv');
      } else if (_selectedFormat == ExportFormat.pdf) {
        final bytes = await service.exportToPdf(_reportData!);
        // Use Printing package for proper PDF sharing/printing
        await Printing.sharePdf(
          bytes: bytes,
          filename: '$filename.pdf',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$filename.pdf exported'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context); // Close dialog after export
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: AppColors.error),
        );
      }
    }
    
    if (mounted) {
      setState(() => _isExporting = false);
    }
  }
  
  Future<void> _exportFile(Uint8List bytes, String filename, String mimeType) async {
    try {
      if (kIsWeb) {
        // Web: Use share_plus which downloads the file
        await Share.shareXFiles(
          [XFile.fromData(bytes, name: filename, mimeType: mimeType)],
          text: 'Exported Report',
        );
      } else {
        // Native: Save to documents and share
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$filename');
        await file.writeAsBytes(bytes);
        
        await Share.shareXFiles([XFile(file.path)], text: 'Exported Report');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$filename exported'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context); // Close dialog after export
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }
}

class _QuickExportDialog extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;

  const _QuickExportDialog({
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Iconsax.export_1, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 20),
            Text(
              'Quick Export',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Export all reports for the selected period',
              style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildExportOption(context, 'All Reports (PDF)', Iconsax.document, isDark),
            const SizedBox(height: 12),
            _buildExportOption(context, 'All Reports (Excel)', Iconsax.document_text, isDark),
            const SizedBox(height: 12),
            _buildExportOption(context, 'Sales Summary Only', Iconsax.chart_21, isDark),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOption(BuildContext context, String title, IconData icon, bool isDark) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exporting $title...')),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceVariant : AppColors.grey50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.grey200),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: isDark ? AppColors.darkTextPrimary : null)),
            const Spacer(),
            Icon(Iconsax.arrow_right_3, size: 18, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
