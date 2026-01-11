import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';

/// Stats card with value and trend indicator
class ReportStatsCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final double? trend;
  final int animationDelay;

  const ReportStatsCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    this.trend,
    this.animationDelay = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: isDark ? AppColors.darkShadowColor : AppColors.shadowColorLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (trend! >= 0 ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trend! >= 0 ? Iconsax.arrow_up_3 : Iconsax.arrow_down,
                        size: 12,
                        color: trend! >= 0 ? AppColors.success : AppColors.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${trend!.abs().toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: trend! >= 0 ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    ).animate(delay: Duration(milliseconds: animationDelay))
      .fadeIn(duration: 400.ms)
      .slideY(begin: 0.1, end: 0);
  }
}

/// Sales Line Chart
class SalesLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> salesData;
  final bool showLabels;

  const SalesLineChart({
    super.key,
    required this.salesData,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    
    if (salesData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.chart_21,
              size: 48,
              color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              'No sales data for this period',
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }
    
    final spots = <FlSpot>[];
    final labels = <String>[];
    double maxY = 0;
    
    for (int i = 0; i < salesData.length; i++) {
      final value = (salesData[i]['total'] as num?)?.toDouble() ?? 0;
      spots.add(FlSpot(i.toDouble(), value));
      if (value > maxY) maxY = value;
      
      if (salesData[i]['date'] != null) {
        labels.add(DateFormat('dd/MM').format(DateTime.parse(salesData[i]['date'])));
      } else {
        labels.add('Day ${i + 1}');
      }
    }
    
    if (maxY == 0) maxY = 1000;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.chart_21, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Sales Trend',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextPrimary : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark ? AppColors.darkCardBorder : AppColors.grey200,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text(
                          '₹${(value / 1000).toStringAsFixed(0)}K',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: showLabels && labels.length <= 7,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < labels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              labels[index],
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: spots.length - 1 > 0 ? spots.length - 1 : 1,
                minY: 0,
                maxY: maxY * 1.2,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: spots.length <= 14,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
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
                          AppColors.primary.withValues(alpha: 0.3),
                          AppColors.primary.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((LineBarSpot spot) {
                        return LineTooltipItem(
                          '₹${NumberFormat('#,##,###').format(spot.y.toInt())}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }
}

/// Top Products Progress Bars
class TopProductsChart extends StatelessWidget {
  final List<Map<String, dynamic>> products;

  const TopProductsChart({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.crown,
              size: 48,
              color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              'No product data available',
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }
    
    final maxRevenue = products.isNotEmpty
        ? (products.first['revenue'] as num?)?.toDouble() ?? 1
        : 1.0;
    
    final colors = [
      AppColors.success,
      AppColors.info,
      AppColors.warning,
      AppColors.primary,
      AppColors.secondary,
    ];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.crown, color: AppColors.warning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Top Products',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextPrimary : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: products.length > 5 ? 5 : products.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final product = products[index];
                final name = product['name'] ?? 'Unknown';
                final revenue = (product['revenue'] as num?)?.toDouble() ?? 0;
                final qty = product['quantity'] ?? 0;
                final progress = maxRevenue > 0 ? revenue / maxRevenue : 0.0;
                final color = colors[index % colors.length];
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark ? AppColors.darkTextPrimary : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          currencyFormat.format(revenue),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: isDark ? AppColors.darkSurfaceVariant : AppColors.grey100,
                              valueColor: AlwaysStoppedAnimation(color),
                              minHeight: 8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$qty sold',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ).animate(delay: Duration(milliseconds: 100 * index))
                  .fadeIn(duration: 300.ms)
                  .slideX(begin: -0.1, end: 0);
              },
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms);
  }
}

/// Revenue Donut Chart
class RevenueDonutChart extends StatelessWidget {
  final Map<String, double> data;
  final String title;

  const RevenueDonutChart({
    super.key,
    required this.data,
    this.title = 'Revenue Distribution',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    
    if (data.isEmpty || data.values.every((v) => v == 0)) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.diagram,
              size: 48,
              color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              'No data available',
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }
    
    final colors = [
      AppColors.primary,
      AppColors.success,
      AppColors.info,
      AppColors.warning,
      AppColors.secondary,
    ];
    
    final total = data.values.fold(0.0, (a, b) => a + b);
    final entries = data.entries.toList();
    
    final sections = <PieChartSectionData>[];
    for (int i = 0; i < entries.length; i++) {
      final value = entries[i].value;
      if (value > 0) {
        sections.add(
          PieChartSectionData(
            color: colors[i % colors.length],
            value: value,
            title: '',
            radius: 40,
            badgeWidget: null,
          ),
        );
      }
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.diagram, color: AppColors.info, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextPrimary : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 35,
                      sections: sections,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < entries.length && i < 5; i++)
                        if (entries[i].value > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: colors[i % colors.length],
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    entries[i].key,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${(entries[i].value / total * 100).toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppColors.darkTextPrimary : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 400.ms);
  }
}
