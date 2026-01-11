import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/models/quotation.dart';
import '../../../providers/quotations_provider.dart';
import '../widgets/quotation_details_sheet.dart';
import '../widgets/create_quotation_dialog.dart';

class QuotationsScreen extends ConsumerStatefulWidget {
  const QuotationsScreen({super.key});

  @override
  ConsumerState<QuotationsScreen> createState() => _QuotationsScreenState();
}

class _QuotationsScreenState extends ConsumerState<QuotationsScreen> {
  String _selectedStatus = 'all';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quotationsAsync = ref.watch(quotationsNotifierProvider);
    final statsAsync = ref.watch(quotationStatsProvider);
    final isDark = context.isDarkMode;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(quotationsNotifierProvider);
        ref.invalidate(quotationStatsProvider);
      },
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quotations',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage price quotes for customers',
                          style: TextStyle(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _createQuotation,
                    icon: const Icon(Iconsax.add, size: 18),
                    label: Text(isMobile ? 'New' : 'New Quotation'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Stats Cards
              statsAsync.when(
                data: (stats) => _buildStatsCards(stats, isMobile, isDark),
                loading: () => const SizedBox(height: 80),
                error: (_, __) => const SizedBox(),
              ),

              const SizedBox(height: 20),

              // Search and Filter
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Search quotations...',
                        prefixIcon: const Icon(Iconsax.search_normal, size: 20),
                        filled: true,
                        fillColor: isDark ? AppColors.darkCardBackground : AppColors.grey100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCardBackground : AppColors.grey100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedStatus,
                        icon: const Icon(Iconsax.arrow_down_1, size: 18),
                        items: [
                          const DropdownMenuItem(value: 'all', child: Text('All Status')),
                          ...QuotationStatus.values.map((s) => DropdownMenuItem(
                            value: s.name,
                            child: Text(s.name[0].toUpperCase() + s.name.substring(1)),
                          )),
                        ],
                        onChanged: (value) => setState(() => _selectedStatus = value ?? 'all'),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Quotations List
              Expanded(
                child: quotationsAsync.when(
                  data: (quotations) {
                    final filtered = _filterQuotations(quotations);
                    if (filtered.isEmpty) {
                      return EmptyState(
                        icon: Iconsax.document_text,
                        title: 'No Quotations',
                        subtitle: quotations.isEmpty
                            ? 'Create your first quotation to get started'
                            : 'No quotations match your filters',
                        actionLabel: quotations.isEmpty ? 'Create Quotation' : null,
                        onAction: quotations.isEmpty ? _createQuotation : null,
                      );
                    }
                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) => _QuotationCard(
                        quotation: filtered[index],
                        onTap: () => _showQuotationDetails(filtered[index]),
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Iconsax.warning_2, size: 48, color: AppColors.error),
                        const SizedBox(height: 16),
                        Text('Failed to load quotations'),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => ref.invalidate(quotationsNotifierProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards(Map<String, int> stats, bool isMobile, bool isDark) {
    final cardData = [
      {'label': 'Total', 'value': stats['total'] ?? 0, 'color': AppColors.primary, 'icon': Iconsax.document_text},
      {'label': 'Draft', 'value': stats['draft'] ?? 0, 'color': AppColors.grey500, 'icon': Iconsax.edit},
      {'label': 'Sent', 'value': stats['sent'] ?? 0, 'color': AppColors.info, 'icon': Iconsax.send_1},
      {'label': 'Accepted', 'value': stats['accepted'] ?? 0, 'color': AppColors.success, 'icon': Iconsax.tick_circle},
      {'label': 'Converted', 'value': stats['converted'] ?? 0, 'color': AppColors.primary, 'icon': Iconsax.convert},
    ];

    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cardData.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final data = cardData[index];
          return Container(
            width: isMobile ? 120 : 140,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardBackground : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.grey200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(data['icon'] as IconData, size: 16, color: data['color'] as Color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        data['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${data['value']}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : null,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Quotation> _filterQuotations(List<Quotation> quotations) {
    return quotations.where((q) {
      // Status filter
      if (_selectedStatus != 'all' && q.status.name != _selectedStatus) {
        return false;
      }
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return q.quotationNumber.toLowerCase().contains(query) ||
            (q.customerName?.toLowerCase().contains(query) ?? false);
      }
      return true;
    }).toList();
  }

  void _createQuotation() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateQuotationDialog(),
    ).then((_) {
      ref.invalidate(quotationsNotifierProvider);
      ref.invalidate(quotationStatsProvider);
    });
  }

  void _showQuotationDetails(Quotation quotation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuotationDetailsSheet(quotation: quotation),
    ).then((_) {
      ref.invalidate(quotationsNotifierProvider);
      ref.invalidate(quotationStatsProvider);
    });
  }
}

// Quotation Card Widget
class _QuotationCard extends StatelessWidget {
  final Quotation quotation;
  final VoidCallback onTap;

  const _QuotationCard({
    required this.quotation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final dateFormat = DateFormat('dd MMM yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? AppColors.darkCardBackground : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? AppColors.darkCardBorder : AppColors.grey200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getStatusColor(quotation.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Iconsax.document_text,
                  color: _getStatusColor(quotation.status),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            quotation.quotationNumber,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkTextPrimary : null,
                            ),
                          ),
                        ),
                        _StatusChip(status: quotation.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      quotation.customerName ?? 'Walk-in Customer',
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Iconsax.calendar,
                          size: 14,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateFormat.format(quotation.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                        if (quotation.validUntil != null) ...[
                          const SizedBox(width: 12),
                          Icon(
                            quotation.isExpired ? Iconsax.warning_2 : Iconsax.timer,
                            size: 14,
                            color: quotation.isExpired ? AppColors.error : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            quotation.isExpired 
                                ? 'Expired' 
                                : 'Valid until ${dateFormat.format(quotation.validUntil!)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: quotation.isExpired ? AppColors.error : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currencyFormat.format(quotation.totalAmount),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? AppColors.darkTextPrimary : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${quotation.itemCount} items',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Icon(
                Iconsax.arrow_right_3,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
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
}

class _StatusChip extends StatelessWidget {
  final QuotationStatus status;
  const _StatusChip({required this.status});

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
