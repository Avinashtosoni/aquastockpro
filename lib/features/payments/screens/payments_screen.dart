import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../data/models/customer.dart';
import '../../../data/models/order.dart';
import '../../../data/models/credit_transaction.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/services/pdf_invoice_service.dart';
import '../../../providers/customers_provider.dart';
import '../../../providers/settings_provider.dart';

/// Payments screen with split-panel layout for collecting outstanding payments
class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  final String _sortBy = 'amount';
  Customer? _selectedCustomer;

  final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: Column(
        children: [
          // Header with stats
          _buildHeader(customersAsync, isDark),
          
          // Main content - split panel
          Expanded(
            child: customersAsync.when(
              data: (customers) {
                final customersWithDues = customers.where((c) => c.creditBalance > 0).toList();
                
                if (isWide) {
                  // Desktop: Split panel layout
                  return Row(
                    children: [
                      // Left Panel - Customers List
                      Expanded(
                        flex: 3,
                        child: _buildCustomersList(customersWithDues, isDark),
                      ),
                      // Right Panel - Customer Details
                      Expanded(
                        flex: 2,
                        child: _buildDetailsPanel(isDark),
                      ),
                    ],
                  );
                } else {
                  // Mobile: Show list or details
                  if (_selectedCustomer != null) {
                    return _buildDetailsPanel(isDark, showBack: true);
                  }
                  return _buildCustomersList(customersWithDues, isDark);
                }
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AsyncValue<List<Customer>> customersAsync, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Iconsax.wallet_money, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payments',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Collect outstanding payments from customers',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white60 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Stats cards row
          customersAsync.when(
            data: (customers) {
              final customersWithDues = customers.where((c) => c.creditBalance > 0).toList();
              final totalOutstanding = customersWithDues.fold<double>(0, (sum, c) => sum + c.creditBalance);
              return Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  _MiniStatCard(
                    icon: Iconsax.money_recive,
                    label: 'Total Outstanding',
                    value: currencyFormat.format(totalOutstanding),
                    color: AppColors.error,
                    isDark: isDark,
                  ),
                  _MiniStatCard(
                    icon: Iconsax.people,
                    label: 'Customers',
                    value: '${customersWithDues.length}',
                    color: AppColors.warning,
                    isDark: isDark,
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomersList(List<Customer> customers, bool isDark) {
    // Filter
    var filteredCustomers = customers;
    if (_searchQuery.isNotEmpty) {
      filteredCustomers = customers.where((c) =>
        c.name.toLowerCase().contains(_searchQuery) ||
        (c.phone?.toLowerCase().contains(_searchQuery) ?? false)
      ).toList();
    }
    
    // Sort
    switch (_sortBy) {
      case 'amount':
        filteredCustomers.sort((a, b) => b.creditBalance.compareTo(a.creditBalance));
        break;
      case 'name':
        filteredCustomers.sort((a, b) => a.name.compareTo(b.name));
        break;
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Outstanding Customers',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                // Search
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      prefixIcon: const Icon(Iconsax.search_normal, size: 18),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      filled: true,
                      fillColor: isDark ? AppColors.darkSurface : AppColors.grey50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: isDark ? Colors.white.withValues(alpha: 0.1) : AppColors.grey200),
          // List
          Expanded(
            child: filteredCustomers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Iconsax.tick_circle, size: 48, color: AppColors.success.withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        Text(
                          'No outstanding payments',
                          style: TextStyle(color: isDark ? Colors.white60 : AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: filteredCustomers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final customer = filteredCustomers[index];
                      final isSelected = _selectedCustomer?.id == customer.id;
                      return _CustomerListTile(
                        customer: customer,
                        currencyFormat: currencyFormat,
                        isSelected: isSelected,
                        isDark: isDark,
                        onTap: () => setState(() => _selectedCustomer = customer),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsPanel(bool isDark, {bool showBack = false}) {
    if (_selectedCustomer == null) {
      return Container(
        margin: const EdgeInsets.fromLTRB(0, 16, 16, 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBackground : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.grey200),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.grey100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Iconsax.user, size: 48, color: isDark ? Colors.white30 : AppColors.grey400),
              ),
              const SizedBox(height: 16),
              Text(
                'Select a Customer',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Click on a customer to view details',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white38 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _CustomerDetailPanel(
      customer: _selectedCustomer!,
      currencyFormat: currencyFormat,
      isDark: isDark,
      showBack: showBack,
      onBack: () => setState(() => _selectedCustomer = null),
      onPaymentReceived: () {
        ref.invalidate(customersNotifierProvider);
        setState(() => _selectedCustomer = null);
      },
    );
  }
}

// Mini Stat Card for header
class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _MiniStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : AppColors.textSecondary),
              ),
              Text(
                value,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Customer List Tile
class _CustomerListTile extends StatelessWidget {
  final Customer customer;
  final NumberFormat currencyFormat;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _CustomerListTile({
    required this.customer,
    required this.currencyFormat,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected 
          ? AppColors.primary.withValues(alpha: 0.1) 
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isSelected 
                ? Border.all(color: AppColors.primary, width: 2)
                : null,
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isSelected 
                        ? [AppColors.primary.withValues(alpha: 0.9), AppColors.primary]
                        : [AppColors.grey400, AppColors.grey500],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    if (customer.phone != null)
                      Text(
                        customer.phone!,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              // Amount
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  currencyFormat.format(customer.creditBalance),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Customer Detail Panel
class _CustomerDetailPanel extends StatefulWidget {
  final Customer customer;
  final NumberFormat currencyFormat;
  final bool isDark;
  final bool showBack;
  final VoidCallback onBack;
  final VoidCallback onPaymentReceived;

  const _CustomerDetailPanel({
    required this.customer,
    required this.currencyFormat,
    required this.isDark,
    required this.showBack,
    required this.onBack,
    required this.onPaymentReceived,
  });

  @override
  State<_CustomerDetailPanel> createState() => _CustomerDetailPanelState();
}

class _CustomerDetailPanelState extends State<_CustomerDetailPanel> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(widget.showBack ? 16 : 0, 16, 16, 16),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.grey200),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary.withValues(alpha: 0.1), Colors.transparent],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                if (widget.showBack)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: widget.onBack,
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Back'),
                    ),
                  ),
                // Customer Avatar & Name
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary.withValues(alpha: 0.9), AppColors.primary],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      widget.customer.name.isNotEmpty ? widget.customer.name[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.customer.name,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: widget.isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                if (widget.customer.phone != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Iconsax.call, size: 14, color: widget.isDark ? Colors.white54 : AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          widget.customer.phone!,
                          style: TextStyle(color: widget.isDark ? Colors.white54 : AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          // Outstanding Badge
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Iconsax.warning_2, color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    Text('Outstanding', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                  ],
                ),
                Text(
                  widget.currencyFormat.format(widget.customer.creditBalance),
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.error),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Receive Payment Section
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Receive Payment',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: widget.isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Amount Input with Pay Full
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            labelText: 'Amount',
                            prefixText: '₹ ',
                            filled: true,
                            fillColor: widget.isDark ? AppColors.darkSurface : AppColors.grey50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          _amountController.text = widget.customer.creditBalance.toStringAsFixed(2);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Pay Full'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Notes
                  TextField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Notes (Optional)',
                      hintText: 'UPI ref, cheque no, etc.',
                      filled: true,
                      fillColor: widget.isDark ? AppColors.darkSurface : AppColors.grey50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(_errorMessage!, style: TextStyle(color: AppColors.error)),
                    ),
                    
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Payment History Section
                  Row(
                    children: [
                      Icon(Iconsax.clock, size: 18, color: widget.isDark ? Colors.white70 : AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        'Payment History',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: widget.isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Payment History List
                  FutureBuilder<List<CreditTransaction>>(
                    future: CustomerRepository().getCreditHistory(widget.customer.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ));
                      }
                      
                      if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: widget.isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.grey50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'No payment history',
                              style: TextStyle(color: widget.isDark ? Colors.white38 : AppColors.textSecondary),
                            ),
                          ),
                        );
                      }
                      
                      final transactions = snapshot.data!;
                      // Filter payment received AND refund credit transactions
                      final payments = transactions
                          .where((t) => t.type == CreditTransactionType.paymentReceived ||
                                       t.type == CreditTransactionType.refundCredit)
                          .toList();
                      
                      if (payments.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: widget.isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.grey50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'No payments or refunds yet',
                              style: TextStyle(color: widget.isDark ? Colors.white38 : AppColors.textSecondary),
                            ),
                          ),
                        );
                      }
                      
                      return Column(
                        children: payments.take(10).map((payment) {
                          final isRefund = payment.type == CreditTransactionType.refundCredit;
                          final color = isRefund ? AppColors.warning : AppColors.success;
                          final icon = isRefund ? Iconsax.refresh_left_square : Iconsax.money_recive;
                          final label = isRefund ? 'Refund Credit' : 'Payment Received';
                          
                          return InkWell(
                            onTap: () => _showPaymentDetailsDialog(payment),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: widget.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: color.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(icon, color: color, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              widget.currencyFormat.format(payment.amount),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: color,
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: color.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                label,
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w600,
                                                  color: color,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          DateFormat('dd MMM yyyy, hh:mm a').format(payment.createdAt),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: widget.isDark ? Colors.white54 : AppColors.textSecondary,
                                          ),
                                        ),
                                        if (payment.notes != null && payment.notes!.isNotEmpty)
                                          Text(
                                            payment.notes!,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: widget.isDark ? Colors.white38 : AppColors.grey500,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  // Download Button
                                  IconButton(
                                    onPressed: () => _showPaymentDetailsDialog(payment),
                                    icon: Icon(Iconsax.document_download, size: 20, color: AppColors.primary),
                                    tooltip: 'Download Receipt',
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          // Receive Button
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _receivePayment,
                icon: _isProcessing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Iconsax.money_recive),
                label: Text(_isProcessing ? 'Processing...' : 'Receive Payment', style: const TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _receivePayment() async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    
    if (amount <= 0) {
      setState(() => _errorMessage = 'Please enter a valid amount');
      return;
    }

    if (amount > widget.customer.creditBalance) {
      setState(() => _errorMessage = 'Amount cannot exceed outstanding balance');
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final previousBalance = widget.customer.creditBalance;
      final newBalance = previousBalance - amount;
      
      final repo = CustomerRepository();
      await repo.receivePayment(
        customerId: widget.customer.id,
        amount: amount,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      if (mounted) {
        // Show success dialog with print options
        _showReceiptDialog(
          previousBalance: previousBalance,
          amountReceived: amount,
          newBalance: newBalance,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _showReceiptDialog({
    required double previousBalance,
    required double amountReceived,
    required double newBalance,
    String? notes,
  }) {
    final isFullyPaid = newBalance <= 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final settingsAsync = ref.watch(settingsNotifierProvider);
          
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success Icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Iconsax.tick_circle, size: 48, color: AppColors.success),
                ),
                const SizedBox(height: 20),
                
                Text(
                  'Payment Received!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rs.${amountReceived.toStringAsFixed(2)} from ${widget.customer.name}',
                  style: TextStyle(color: isDark ? Colors.white60 : AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                
                // Balance Summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.grey50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _summaryRow('Previous Balance', 'Rs.${previousBalance.toStringAsFixed(2)}', isDark),
                      const SizedBox(height: 8),
                      _summaryRow('Amount Received', '- Rs.${amountReceived.toStringAsFixed(2)}', isDark, isGreen: true),
                      const Divider(height: 20),
                      _summaryRow('New Balance', 'Rs.${newBalance.toStringAsFixed(2)}', isDark, isBold: true),
                    ],
                  ),
                ),
                
                if (isFullyPaid) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.success.withValues(alpha: 0.9), AppColors.success]),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Iconsax.tick_circle, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text('NO DUES', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              // Close Button
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onPaymentReceived();
                },
                child: const Text('Close'),
              ),
              // Print Button
              settingsAsync.when(
                data: (settings) => ElevatedButton.icon(
                  onPressed: () async {
                    // Fetch pending orders for this customer
                    List<Order> pendingOrders = [];
                    try {
                      final allOrders = await OrderRepository().getByCustomer(widget.customer.id);
                      pendingOrders = allOrders.where((o) => (o.totalAmount - o.paidAmount) > 0).toList();
                    } catch (_) {}
                    
                    await PdfInvoiceService().printPaymentReceipt(
                      customer: widget.customer,
                      amountReceived: amountReceived,
                      previousBalance: previousBalance,
                      newBalance: newBalance,
                      settings: settings,
                      notes: notes,
                      pendingOrders: pendingOrders,
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      widget.onPaymentReceived();
                    }
                  },
                  icon: const Icon(Iconsax.printer, size: 18),
                  label: const Text('Print Receipt'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryRow(String label, String value, bool isDark, {bool isBold = false, bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(
          color: isDark ? Colors.white70 : AppColors.textSecondary,
          fontWeight: isBold ? FontWeight.bold : null,
        )),
        Text(value, style: TextStyle(
          fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          color: isGreen ? AppColors.success : (isDark ? Colors.white : AppColors.textPrimary),
        )),
      ],
    );
  }

  /// Show payment details dialog with print option
  void _showPaymentDetailsDialog(CreditTransaction payment) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final settingsAsync = ref.watch(settingsNotifierProvider);
          
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Iconsax.money_recive, color: AppColors.success),
                ),
                const SizedBox(width: 12),
                const Text('Payment Details'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Amount
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        widget.currencyFormat.format(payment.amount),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Amount Received',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Details
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.grey50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _detailRow('Date', DateFormat('dd MMM yyyy').format(payment.createdAt), isDark),
                      const SizedBox(height: 8),
                      _detailRow('Time', DateFormat('hh:mm a').format(payment.createdAt), isDark),
                      const SizedBox(height: 8),
                      _detailRow('Customer', widget.customer.name, isDark),
                      if (payment.notes != null && payment.notes!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _detailRow('Notes', payment.notes!, isDark),
                      ],
                      const SizedBox(height: 8),
                      _detailRow('Balance After', widget.currencyFormat.format(payment.newBalance), isDark),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              settingsAsync.when(
                data: (settings) => ElevatedButton.icon(
                  onPressed: () async {
                    // Calculate previous balance from newBalance and amount
                    final previousBalance = payment.newBalance + payment.amount;
                    
                    // Fetch pending orders at time of payment
                    List<Order> pendingOrders = [];
                    try {
                      final allOrders = await OrderRepository().getByCustomer(widget.customer.id);
                      pendingOrders = allOrders.where((o) => (o.totalAmount - o.paidAmount) > 0).toList();
                    } catch (_) {}
                    
                    await PdfInvoiceService().printPaymentReceipt(
                      customer: widget.customer,
                      amountReceived: payment.amount,
                      previousBalance: previousBalance,
                      newBalance: payment.newBalance,
                      settings: settings,
                      notes: payment.notes,
                      pendingOrders: pendingOrders,
                      paymentDate: payment.createdAt, // Use original payment date
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  icon: const Icon(Iconsax.printer, size: 18),
                  label: const Text('Print Receipt'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _detailRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(
          color: isDark ? Colors.white54 : AppColors.textSecondary,
          fontSize: 13,
        )),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
