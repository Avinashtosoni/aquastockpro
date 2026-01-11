import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../data/models/customer.dart';
import '../../../data/models/credit_transaction.dart';
import '../../../providers/customers_provider.dart';
import '../../../providers/orders_provider.dart';
import '../../../data/models/order.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersNotifierProvider);
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isTablet = MediaQuery.of(context).size.width < 1000;
    final isDark = context.isDarkMode;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
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
                  Text(
                    'Customer Management',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage profiles, credit limits, and history.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              AppButton(
                label: 'Add Customer',
                icon: Iconsax.add,
                onPressed: () => _showAddCustomerDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardBackground : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.darkCardBorder : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Iconsax.search_normal,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by Name or Mobile Number...',
                      hintStyle: TextStyle(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Customer Grid
          Expanded(
            child: customersAsync.when(
              loading: () => const LoadingIndicator(message: 'Loading customers...'),
              error: (e, s) => ErrorState(
                title: 'Failed to load customers',
                onRetry: () => ref.read(customersNotifierProvider.notifier).refresh(),
              ),
              data: (customers) {
                var filtered = _searchQuery.isEmpty
                    ? customers
                    : customers.where((c) =>
                        c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        (c.phone?.contains(_searchQuery) ?? false)
                      ).toList();

                if (filtered.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      await ref.read(customersNotifierProvider.notifier).refresh();
                    },
                    child: ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: EmptyState(
                            icon: Iconsax.people,
                            title: 'No customers found',
                            subtitle: 'Add customers to manage their profiles and credit',
                            actionLabel: 'Add Customer',
                            onAction: () => _showAddCustomerDialog(context),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 3);

                return RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(customersNotifierProvider.notifier).refresh();
                  },
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: isMobile ? 2.4 : 2.6,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final customer = filtered[index];
                      return _CustomerCard(
                        customer: customer,
                        currencyFormat: currencyFormat,
                        onHistory: () => _showCustomerHistory(context, customer),
                        onWhatsApp: () => _openWhatsApp(context, customer),
                        onEdit: () => _showAddCustomerDialog(context, customer: customer),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext context, {Customer? customer}) {
    showDialog(
      context: context,
      builder: (context) => _AddCustomerDialog(customer: customer),
    );
  }

  void _showCustomerHistory(BuildContext context, Customer customer) {
    showDialog(
      context: context,
      builder: (context) => _CustomerHistoryDialog(customer: customer),
    );
  }

  Future<void> _openWhatsApp(BuildContext context, Customer customer) async {
    if (customer.phone == null || customer.phone!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number available')),
      );
      return;
    }

    String phone = customer.phone!.replaceAll(RegExp(r'[^0-9]'), '');
    if (!phone.startsWith('91') && phone.length == 10) {
      phone = '91$phone';
    }

    final url = Uri.parse('https://wa.me/$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp')),
        );
      }
    }
  }
}

// Customer Card Widget - Compact Modern Design
class _CustomerCard extends StatelessWidget {
  final Customer customer;
  final NumberFormat currencyFormat;
  final VoidCallback onHistory;
  final VoidCallback onWhatsApp;
  final VoidCallback onEdit;

  const _CustomerCard({
    required this.customer,
    required this.currencyFormat,
    required this.onHistory,
    required this.onWhatsApp,
    required this.onEdit,
  });

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFEC4899), // Pink
      const Color(0xFFEF4444), // Red
      const Color(0xFFF97316), // Orange
      const Color(0xFF10B981), // Emerald
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFF3B82F6), // Blue
    ];
    return colors[name.codeUnitAt(0) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final hasBalance = customer.creditBalance > 0;
    final avatarColor = _getAvatarColor(customer.name);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.grey200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row - Avatar, Name, Balance
                Row(
                  children: [
                    // Gradient Avatar
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [avatarColor, avatarColor.withValues(alpha: 0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: avatarColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          customer.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Name and Phone
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Iconsax.call,
                                size: 11,
                                color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  customer.phone ?? 'No phone',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Balance Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: hasBalance
                            ? AppColors.error.withValues(alpha: 0.1)
                            : AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            currencyFormat.format(customer.creditBalance),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: hasBalance ? AppColors.error : AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Info Row - Address & Limit
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Iconsax.location,
                            size: 12,
                            color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              customer.address ?? 'N/A',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceVariant : AppColors.grey100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Iconsax.wallet_2,
                            size: 10,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Limit: ${currencyFormat.format(customer.creditLimit)}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Action Buttons Row
                Row(
                  children: [
                    // History Button
                    Expanded(
                      child: InkWell(
                        onTap: onHistory,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurfaceVariant : AppColors.grey50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Iconsax.clock,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'History',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // WhatsApp Button
                    Expanded(
                      child: InkWell(
                        onTap: onWhatsApp,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF25D366).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Iconsax.message,
                                size: 14,
                                color: const Color(0xFF25D366),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'WhatsApp',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF25D366),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Info Row Widget
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;

  const _InfoRow({
    required this.icon,
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// Add Customer Dialog
class _AddCustomerDialog extends ConsumerStatefulWidget {
  final Customer? customer;

  const _AddCustomerDialog({this.customer});

  @override
  ConsumerState<_AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends ConsumerState<_AddCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _creditLimitController;
  late final TextEditingController _gstController;
  bool _isLoading = false;

  bool get isEditing => widget.customer != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer?.name ?? '');
    _phoneController = TextEditingController(text: widget.customer?.phone ?? '');
    _addressController = TextEditingController(text: widget.customer?.address ?? '');
    _creditLimitController = TextEditingController(
      text: widget.customer?.creditLimit.toInt().toString() ?? '0',
    );
    _gstController = TextEditingController(text: widget.customer?.gstin ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _creditLimitController.dispose();
    _gstController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Customer' : 'Add New Customer',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Customer Name
              _buildLabel('Customer Name', isRequired: true),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration(),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Mobile Number
              _buildLabel('Mobile Number', isRequired: true),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                decoration: _inputDecoration(),
                keyboardType: TextInputType.phone,
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Address
              _buildLabel('Address'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _addressController,
                decoration: _inputDecoration(),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Credit Limit and GST Number
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Credit Limit'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _creditLimitController,
                          decoration: _inputDecoration(),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('GST Number'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _gstController,
                          decoration: _inputDecoration(),
                          textCapitalization: TextCapitalization.characters,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Iconsax.save_2, size: 18),
                    label: Text(isEditing ? 'Update Customer' : 'Save Customer'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label, {bool isRequired = false}) {
    return RichText(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: context.isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
        ),
        children: isRequired
            ? [
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppColors.error),
                ),
              ]
            : null,
      ),
    );
  }

  InputDecoration _inputDecoration() {
    final isDark = context.isDarkMode;
    return InputDecoration(
      filled: true,
      fillColor: isDark ? AppColors.darkCardBackground : Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: isDark ? AppColors.darkCardBorder : AppColors.border,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: isDark ? AppColors.darkCardBorder : AppColors.border,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final customer = Customer(
        id: widget.customer?.id,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        creditLimit: double.tryParse(_creditLimitController.text) ?? 0,
        gstin: _gstController.text.trim().isEmpty ? null : _gstController.text.trim(),
        creditBalance: widget.customer?.creditBalance ?? 0,
        totalPurchases: widget.customer?.totalPurchases ?? 0,
        visitCount: widget.customer?.visitCount ?? 0,
        isActive: widget.customer?.isActive ?? true,
      );

      if (isEditing) {
        await ref.read(customersNotifierProvider.notifier).updateCustomer(customer);
      } else {
        await ref.read(customersNotifierProvider.notifier).addCustomer(customer);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Customer updated' : 'Customer added'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// Enhanced Customer Ledger Dialog
class _CustomerHistoryDialog extends ConsumerStatefulWidget {
  final Customer customer;

  const _CustomerHistoryDialog({required this.customer});

  @override
  ConsumerState<_CustomerHistoryDialog> createState() => _CustomerHistoryDialogState();
}

class _CustomerHistoryDialogState extends ConsumerState<_CustomerHistoryDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final isDark = context.isDarkMode;
    final ordersAsync = ref.watch(customerOrdersProvider(widget.customer.id));
    final creditAsync = ref.watch(creditHistoryProvider(widget.customer.id));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 650,
        height: 680,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            // Profile Header
            _buildProfileHeader(ordersAsync, currencyFormat, isDark),
            
            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceVariant : AppColors.grey100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Orders'),
                  Tab(text: 'Payments'),
                  Tab(text: 'Credit'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAllTimelineTab(ordersAsync, creditAsync, currencyFormat, isDark),
                  _buildOrdersTab(ordersAsync, currencyFormat, isDark),
                  _buildPaymentsTab(creditAsync, currencyFormat, isDark),
                  _buildCreditTab(creditAsync, currencyFormat, isDark),
                ],
              ),
            ),

            // Summary Footer
            _buildSummaryFooter(ordersAsync, currencyFormat, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(AsyncValue<List<Order>> ordersAsync, NumberFormat currencyFormat, bool isDark) {
    // Calculate stats from actual orders
    int totalOrders = 0;
    double totalPurchases = 0;
    
    ordersAsync.whenData((orders) {
      totalOrders = orders.length;
      totalPurchases = orders.fold<double>(0, (sum, o) => sum + o.totalAmount);
    });
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Top Row - Avatar and Close
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    widget.customer.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.customer.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Iconsax.call, size: 14, color: Colors.white70),
                        const SizedBox(width: 6),
                        Text(
                          widget.customer.phone ?? 'No phone',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Stats Cards Row - Using actual orders data
          Row(
            children: [
              _buildStatCard(
                'Total Purchases',
                currencyFormat.format(totalPurchases),
                Iconsax.shopping_bag,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'Orders',
                '$totalOrders',
                Iconsax.receipt_1,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'Outstanding',
                currencyFormat.format(widget.customer.creditBalance),
                Iconsax.wallet_2,
                isNegative: widget.customer.creditBalance > 0,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, {bool isNegative = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: Colors.white70),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: isNegative ? const Color(0xFFFFB4AB) : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllTimelineTab(
    AsyncValue<List<Order>> ordersAsync,
    AsyncValue<List<CreditTransaction>> creditAsync,
    NumberFormat currencyFormat,
    bool isDark,
  ) {
    return ordersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (orders) => creditAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (credits) {
          // Combine orders and credits into timeline
          final timeline = <_TimelineItem>[];
          
          for (final order in orders) {
            timeline.add(_TimelineItem(
              type: _TimelineType.order,
              date: order.createdAt,
              order: order,
            ));
          }
          
          for (final credit in credits) {
            timeline.add(_TimelineItem(
              type: credit.type == CreditTransactionType.creditGiven
                  ? _TimelineType.creditGiven
                  : _TimelineType.payment,
              date: credit.createdAt,
              credit: credit,
            ));
          }
          
          // Sort by date descending
          timeline.sort((a, b) => b.date.compareTo(a.date));
          
          if (timeline.isEmpty) {
            return _buildEmptyState('No transactions yet', Iconsax.document);
          }
          
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: timeline.length,
            itemBuilder: (context, index) {
              final item = timeline[index];
              return _buildTimelineItem(item, currencyFormat, isDark, index == timeline.length - 1);
            },
          );
        },
      ),
    );
  }

  Widget _buildTimelineItem(_TimelineItem item, NumberFormat currencyFormat, bool isDark, bool isLast) {
    Color color;
    IconData icon;
    String title;
    String subtitle;
    String amount;
    
    switch (item.type) {
      case _TimelineType.order:
        color = AppColors.primary;
        icon = Iconsax.shopping_bag;
        title = 'Order ${item.order!.orderNumber}';
        subtitle = '${item.order!.items.length} items • ${item.order!.paymentMethod.name}';
        amount = currencyFormat.format(item.order!.totalAmount);
        break;
      case _TimelineType.payment:
        color = AppColors.success;
        icon = Iconsax.money_recive;
        title = 'Payment Received';
        subtitle = item.credit!.notes ?? 'Credit payment';
        amount = '-${currencyFormat.format(item.credit!.amount)}';
        break;
      case _TimelineType.creditGiven:
        color = AppColors.error;
        icon = Iconsax.money_send;
        title = 'Credit Given (Udhar)';
        subtitle = item.credit!.notes ?? 'Credit transaction';
        amount = '+${currencyFormat.format(item.credit!.amount)}';
        break;
    }
    
    return InkWell(
      onTap: item.type == _TimelineType.order ? () => _showOrderDetail(item.order!) : null,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline line and dot
            SizedBox(
              width: 40,
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 18, color: color),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 50,
                      color: isDark ? AppColors.darkCardBorder : AppColors.grey200,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            
            // Content
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardBackground : AppColors.grey50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.darkCardBorder : AppColors.grey200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          amount,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: item.type == _TimelineType.creditGiven 
                                ? AppColors.error 
                                : item.type == _TimelineType.payment 
                                    ? AppColors.success 
                                    : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd MMM yyyy, hh:mm a').format(item.date),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                      ),
                    ),
                    if (item.type == _TimelineType.order) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _getStatusColor(item.order!.status).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.order!.status.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _getStatusColor(item.order!.status),
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Tap to view details →',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersTab(AsyncValue<List<Order>> ordersAsync, NumberFormat currencyFormat, bool isDark) {
    return ordersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (orders) {
        if (orders.isEmpty) {
          return _buildEmptyState('No orders yet', Iconsax.receipt_item);
        }
        
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final order = orders[index];
            return _buildOrderCard(order, currencyFormat, isDark);
          },
        );
      },
    );
  }

  Widget _buildOrderCard(Order order, NumberFormat currencyFormat, bool isDark) {
    return InkWell(
      onTap: () => _showOrderDetail(order),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBackground : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.grey200),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Iconsax.receipt_1, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        order.orderNumber,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getStatusColor(order.status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          order.status.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(order.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${order.items.length} items • ${order.paymentMethod.name} • ${DateFormat('dd MMM').format(order.createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
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
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Icon(
                  Iconsax.arrow_right_3,
                  size: 16,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentsTab(AsyncValue<List<CreditTransaction>> creditAsync, NumberFormat currencyFormat, bool isDark) {
    return creditAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (transactions) {
        final payments = transactions.where((t) => t.type != CreditTransactionType.creditGiven).toList();
        
        if (payments.isEmpty) {
          return _buildEmptyState('No payments recorded', Iconsax.money_recive);
        }
        
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: payments.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final payment = payments[index];
            return _buildPaymentCard(payment, currencyFormat, isDark);
          },
        );
      },
    );
  }

  Widget _buildPaymentCard(CreditTransaction payment, NumberFormat currencyFormat, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.grey200),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Iconsax.money_recive, color: AppColors.success, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.typeDisplayName,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd MMM yyyy, hh:mm a').format(payment.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
                if (payment.notes != null && payment.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    payment.notes!,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '-${currencyFormat.format(payment.amount)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditTab(AsyncValue<List<CreditTransaction>> creditAsync, NumberFormat currencyFormat, bool isDark) {
    return Column(
      children: [
        // Outstanding Balance Card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.customer.creditBalance > 0
                  ? [AppColors.error, AppColors.error.withValues(alpha: 0.8)]
                  : [AppColors.success, AppColors.success.withValues(alpha: 0.8)],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Outstanding Balance (Udhar)',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormat.format(widget.customer.creditBalance),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.customer.creditBalance > 0 ? Iconsax.warning_2 : Iconsax.tick_circle,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Credit Transactions
        Expanded(
          child: creditAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error: $e')),
            data: (transactions) {
              final credits = transactions.where((t) => t.type == CreditTransactionType.creditGiven).toList();
              
              if (credits.isEmpty) {
                return _buildEmptyState('No credit given', Iconsax.money_send);
              }
              
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: credits.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final credit = credits[index];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCardBackground : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.grey200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Iconsax.money_send, color: AppColors.error, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Credit Given (Udhar)',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('dd MMM yyyy, hh:mm a').format(credit.createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '+${currencyFormat.format(credit.amount)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryFooter(AsyncValue<List<Order>> ordersAsync, NumberFormat currencyFormat, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.grey50,
        border: Border(
          top: BorderSide(color: isDark ? AppColors.darkCardBorder : AppColors.grey200),
        ),
      ),
      child: ordersAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
        data: (orders) {
          final totalOrders = orders.length;
          final totalPaid = orders.fold<double>(0, (sum, o) => sum + o.totalAmount);
          
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildFooterStat('Total Orders', '$totalOrders', Iconsax.receipt_1, isDark),
              Container(width: 1, height: 30, color: isDark ? AppColors.darkCardBorder : AppColors.grey300),
              _buildFooterStat('Total Billed', currencyFormat.format(totalPaid), Iconsax.wallet_1, isDark),
              Container(width: 1, height: 30, color: isDark ? AppColors.darkCardBorder : AppColors.grey300),
              _buildFooterStat(
                'Outstanding', 
                currencyFormat.format(widget.customer.creditBalance), 
                Iconsax.danger,
                isDark,
                isHighlight: widget.customer.creditBalance > 0,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFooterStat(String label, String value, IconData icon, bool isDark, {bool isHighlight = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isHighlight ? AppColors.error : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isHighlight ? AppColors.error : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    final isDark = context.isDarkMode;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: AppColors.grey400),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderDetail(Order order) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final isDark = context.isDarkMode;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 450,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order ${order.orderNumber}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt),
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(height: 24),
              
              // Order Items
              const Text('Items', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...order.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.productName,
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      'x${item.quantity}',
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      currencyFormat.format(item.total),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              )),
              
              const Divider(height: 24),
              
              // Totals
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal'),
                  Text(currencyFormat.format(order.subtotal)),
                ],
              ),
              if (order.discountAmount > 0) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Discount'),
                    Text('-${currencyFormat.format(order.discountAmount)}', 
                      style: const TextStyle(color: AppColors.success)),
                  ],
                ),
              ],
              if (order.taxAmount > 0) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tax'),
                    Text(currencyFormat.format(order.taxAmount)),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                    currencyFormat.format(order.totalAmount),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Payment Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceVariant : AppColors.grey100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Iconsax.card, size: 18, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text(
                          order.paymentMethod.name.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(order.status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        order.status.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(order.status),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.completed:
        return AppColors.success;
      case OrderStatus.pending:
        return AppColors.warning;
      case OrderStatus.cancelled:
        return AppColors.error;
      case OrderStatus.refunded:
        return AppColors.info;
      case OrderStatus.onHold:
        return AppColors.grey500;
    }
  }
}

// Timeline Item Model
enum _TimelineType { order, payment, creditGiven }

class _TimelineItem {
  final _TimelineType type;
  final DateTime date;
  final Order? order;
  final CreditTransaction? credit;

  _TimelineItem({
    required this.type,
    required this.date,
    this.order,
    this.credit,
  });
}
