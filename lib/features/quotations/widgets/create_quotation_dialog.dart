import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/alert_service.dart';
import '../../../data/models/quotation.dart';
import '../../../data/models/quotation_item.dart';
import '../../../data/models/product.dart';
import '../../../data/models/customer.dart';
import '../../../data/services/pdf_invoice_service.dart';
import '../../../providers/quotations_provider.dart';
import '../../../providers/products_provider.dart';
import '../../../providers/customers_provider.dart';
import '../../../providers/settings_provider.dart';

/// Dialog for creating a new quotation
class CreateQuotationDialog extends ConsumerStatefulWidget {
  const CreateQuotationDialog({super.key});

  @override
  ConsumerState<CreateQuotationDialog> createState() => _CreateQuotationDialogState();
}

class _CreateQuotationDialogState extends ConsumerState<CreateQuotationDialog> {
  final _currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
  
  Customer? _selectedCustomer;
  DateTime? _validUntil;
  final _notesController = TextEditingController();
  final List<_CartItem> _items = [];
  bool _isLoading = false;

  double get _subtotal => _items.fold(0.0, (sum, item) => sum + item.lineTotal);
  double get _totalDiscount => _items.fold(0.0, (sum, item) => sum + item.discountAmount);
  double get _taxAmount => _subtotal * 0.18; // 18% GST default
  double get _totalAmount => _subtotal + _taxAmount;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final customersAsync = ref.watch(customersNotifierProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
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
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Iconsax.document_text,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'New Quotation',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkTextPrimary : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Create a price quote for customer',
                            style: TextStyle(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Iconsax.close_circle,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
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
                    // Customer Selection with Add Button
                    _SectionCard(
                      title: 'Customer',
                      icon: Iconsax.user,
                      trailing: TextButton.icon(
                        onPressed: () => _showAddCustomerDialog(context),
                        icon: const Icon(Iconsax.add, size: 18),
                        label: const Text('New'),
                      ),
                      child: customersAsync.when(
                        data: (customers) => DropdownButtonFormField<Customer>(
                          value: _selectedCustomer,
                          hint: const Text('Select Customer (Optional)'),
                          isExpanded: true,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: isDark ? AppColors.darkCardBackground : AppColors.grey100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          items: [
                            const DropdownMenuItem<Customer>(
                              value: null,
                              child: Text('Walk-in Customer'),
                            ),
                            ...customers.map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c.name),
                            )),
                          ],
                          onChanged: (value) => setState(() => _selectedCustomer = value),
                        ),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (_, __) => const Text('Failed to load customers'),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Validity Date
                    _SectionCard(
                      title: 'Validity',
                      icon: Iconsax.calendar,
                      child: InkWell(
                        onTap: _selectValidityDate,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCardBackground : AppColors.grey100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Iconsax.calendar_1,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _validUntil != null
                                    ? DateFormat('dd MMM yyyy').format(_validUntil!)
                                    : 'Select validity date (optional)',
                                style: TextStyle(
                                  color: _validUntil != null
                                      ? (isDark ? AppColors.darkTextPrimary : null)
                                      : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                                ),
                              ),
                              const Spacer(),
                              if (_validUntil != null)
                                IconButton(
                                  icon: const Icon(Iconsax.close_circle, size: 20),
                                  onPressed: () => setState(() => _validUntil = null),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Products with Discount
                    _SectionCard(
                      title: 'Products',
                      icon: Iconsax.box,
                      trailing: TextButton.icon(
                        onPressed: () => _showProductPicker(context),
                        icon: const Icon(Iconsax.add, size: 18),
                        label: const Text('Add'),
                      ),
                      child: _items.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  Icon(
                                    Iconsax.box,
                                    size: 48,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.grey400,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No products added',
                                    style: TextStyle(
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () => _showProductPicker(context),
                                    child: const Text('Add Products'),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              children: _items.asMap().entries.map((entry) {
                                final index = entry.key;
                                final item = entry.value;
                                return _ProductItemCard(
                                  item: item,
                                  onQuantityChanged: (qty) {
                                    setState(() => _items[index].quantity = qty);
                                  },
                                  onDiscountChanged: (discount) {
                                    setState(() => _items[index].discount = discount);
                                  },
                                  onRemove: () {
                                    setState(() => _items.removeAt(index));
                                  },
                                );
                              }).toList(),
                            ),
                    ),

                    if (_items.isNotEmpty) ...[
                      const SizedBox(height: 16),

                      // Summary
                      _SectionCard(
                        title: 'Summary',
                        icon: Iconsax.money,
                        child: Column(
                          children: [
                            _SummaryRow('Subtotal', _currencyFormat.format(_subtotal + _totalDiscount)),
                            if (_totalDiscount > 0)
                              _SummaryRow('Discount', '-${_currencyFormat.format(_totalDiscount)}', 
                                valueColor: AppColors.success),
                            _SummaryRow('After Discount', _currencyFormat.format(_subtotal)),
                            _SummaryRow('Tax (18%)', _currencyFormat.format(_taxAmount)),
                            const Divider(height: 16),
                            _SummaryRow('Total', _currencyFormat.format(_totalAmount), isBold: true),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Notes
                    _SectionCard(
                      title: 'Notes',
                      icon: Iconsax.note,
                      child: TextField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Add notes (optional)',
                          filled: true,
                          fillColor: isDark ? AppColors.darkCardBackground : AppColors.grey100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 100),
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
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: _items.isEmpty ? null : _createQuotation,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Create Quotation'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectValidityDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _validUntil ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _validUntil = date);
    }
  }

  void _showAddCustomerDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final isDark = context.isDarkMode;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Iconsax.user_add, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Add Customer'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name *',
                  prefixIcon: const Icon(Iconsax.user),
                  filled: true,
                  fillColor: isDark ? AppColors.darkCardBackground : AppColors.grey100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone *',
                  prefixIcon: const Icon(Iconsax.call),
                  filled: true,
                  fillColor: isDark ? AppColors.darkCardBackground : AppColors.grey100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email (Optional)',
                  prefixIcon: const Icon(Iconsax.sms),
                  filled: true,
                  fillColor: isDark ? AppColors.darkCardBackground : AppColors.grey100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.isEmpty || phoneController.text.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Name and Phone are required')),
                );
                return;
              }

              try {
                final newCustomer = Customer(
                  name: nameController.text,
                  phone: phoneController.text,
                  email: emailController.text.isEmpty ? null : emailController.text,
                );

                await ref.read(customersNotifierProvider.notifier).addCustomer(newCustomer);
                
                if (mounted) {
                  Navigator.pop(dialogContext);
                  // Refresh the customers list - don't auto-select to avoid dropdown assertion
                  ref.invalidate(customersNotifierProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Customer "${newCustomer.name}" added. Select them from the dropdown.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showProductPicker(BuildContext context) {
    final productsAsync = ref.read(productsProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) {
          final isDark = sheetContext.isDarkMode;
          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardBorder : AppColors.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Select Products',
                    style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: productsAsync.when(
                    data: (products) => ListView.builder(
                      controller: scrollController,
                      itemCount: products.length,
                      itemBuilder: (_, index) {
                        final product = products[index];
                        final isAdded = _items.any((i) => i.product.id == product.id);
                        return ListTile(
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.grey100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Iconsax.box, color: AppColors.grey400),
                          ),
                          title: Text(product.name),
                          subtitle: Text(_currencyFormat.format(product.price)),
                          trailing: isAdded
                              ? const Icon(Iconsax.tick_circle, color: AppColors.success)
                              : IconButton(
                                  icon: const Icon(Iconsax.add_circle),
                                  onPressed: () {
                                    setState(() {
                                      _items.add(_CartItem(product: product, quantity: 1, discount: 0));
                                    });
                                    Navigator.pop(sheetContext);
                                  },
                                ),
                          onTap: isAdded
                              ? null
                              : () {
                                  setState(() {
                                    _items.add(_CartItem(product: product, quantity: 1, discount: 0));
                                  });
                                  Navigator.pop(sheetContext);
                                },
                        );
                      },
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const Center(child: Text('Failed to load products')),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _createQuotation() async {
    if (_items.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final quotationNumber = await ref.read(quotationsNotifierProvider.notifier)
          .generateQuotationNumber();

      final quotationItems = _items.map((item) => QuotationItem(
        quotationId: '',
        productId: item.product.id,
        productName: item.product.name,
        unitPrice: item.product.price,
        quantity: item.quantity,
        discount: item.discountAmount,
      )).toList();

      final quotation = Quotation(
        quotationNumber: quotationNumber,
        customerId: _selectedCustomer?.id,
        customerName: _selectedCustomer?.name,
        items: quotationItems,
        subtotal: _subtotal,
        discountAmount: _totalDiscount,
        taxAmount: _taxAmount,
        totalAmount: _totalAmount,
        validUntil: _validUntil,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      // Update items with correct quotation ID
      final finalItems = quotationItems.map((item) => item.copyWith(quotationId: quotation.id)).toList();
      final finalQuotation = quotation.copyWith(items: finalItems);

      await ref.read(quotationsNotifierProvider.notifier).createQuotation(finalQuotation);

      if (mounted) {
        Navigator.pop(context);
        // Show success dialog with PDF download option
        _showQuotationCreatedDialog(finalQuotation);
      }
    } catch (e) {
      if (mounted) {
        AlertService().showError(
          context: context,
          title: 'Failed',
          text: e.toString(),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Show success dialog with PDF download option
  void _showQuotationCreatedDialog(Quotation quotation) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Consumer(
        builder: (context, ref, _) {
          final settingsAsync = ref.watch(settingsNotifierProvider);
          final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
          
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
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
                  child: Icon(Iconsax.tick_circle, color: AppColors.success, size: 48),
                ),
                const SizedBox(height: 20),
                
                Text(
                  'Quotation Created!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  quotation.quotationNumber,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardBackground : AppColors.grey50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _dialogRow('Customer', quotation.customerName ?? 'Walk-in', isDark),
                      const SizedBox(height: 8),
                      _dialogRow('Items', '${quotation.items.length} products', isDark),
                      const SizedBox(height: 8),
                      _dialogRow('Total', _currencyFormat.format(quotation.totalAmount), isDark, isBold: true),
                      if (quotation.validUntil != null) ...[
                        const SizedBox(height: 8),
                        _dialogRow('Valid Until', DateFormat('dd MMM yyyy').format(quotation.validUntil!), isDark),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Close'),
              ),
              settingsAsync.when(
                data: (settings) => ElevatedButton.icon(
                  onPressed: () async {
                    await PdfInvoiceService().printQuotationPdf(
                      quotation: quotation,
                      settings: settings,
                      customer: _selectedCustomer,
                    );
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  },
                  icon: const Icon(Iconsax.document_download, size: 18),
                  label: const Text('Download PDF'),
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

  Widget _dialogRow(String label, String value, bool isDark, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(
          color: isDark ? Colors.white54 : AppColors.textSecondary,
          fontSize: 13,
        )),
        Text(value, style: TextStyle(
          fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          fontSize: 13,
          color: isBold ? AppColors.success : (isDark ? Colors.white : AppColors.textPrimary),
        )),
      ],
    );
  }
}

// Helper Classes
class _CartItem {
  final Product product;
  int quantity;
  double discount; // Percentage discount

  _CartItem({required this.product, required this.quantity, required this.discount});

  double get lineTotal => (product.price * quantity) - discountAmount;
  double get discountAmount => (product.price * quantity) * (discount / 100);
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ProductItemCard extends StatelessWidget {
  final _CartItem item;
  final ValueChanged<int> onQuantityChanged;
  final ValueChanged<double> onDiscountChanged;
  final VoidCallback onRemove;

  const _ProductItemCard({
    required this.item,
    required this.onQuantityChanged,
    required this.onDiscountChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final isDark = context.isDarkMode;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.grey200),
      ),
      child: Column(
        children: [
          // Product info row
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.grey200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Iconsax.box, size: 20, color: AppColors.grey500),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      currencyFormat.format(item.product.price),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Iconsax.trash, size: 18, color: AppColors.error),
                onPressed: onRemove,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Quantity and Discount row
          Row(
            children: [
              // Quantity
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardBackground : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.grey300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Iconsax.minus, size: 16),
                        onPressed: item.quantity > 1 ? () => onQuantityChanged(item.quantity - 1) : null,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                      Text(
                        '${item.quantity}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Iconsax.add, size: 16),
                        onPressed: () => onQuantityChanged(item.quantity + 1),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Discount
              SizedBox(
                width: 100,
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Disc %',
                    isDense: true,
                    filled: true,
                    fillColor: isDark ? AppColors.darkCardBackground : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: isDark ? AppColors.darkCardBorder : AppColors.grey300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  controller: TextEditingController(text: item.discount > 0 ? item.discount.toString() : ''),
                  onChanged: (value) {
                    final discount = double.tryParse(value) ?? 0;
                    onDiscountChanged(discount.clamp(0, 100));
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Line total
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currencyFormat.format(item.lineTotal),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  if (item.discount > 0)
                    Text(
                      '-${currencyFormat.format(item.discountAmount)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.success,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  const _SummaryRow(this.label, this.value, {this.isBold = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              fontWeight: isBold ? FontWeight.bold : null,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: valueColor ?? (isBold ? AppColors.primary : (isDark ? AppColors.darkTextPrimary : null)),
            ),
          ),
        ],
      ),
    );
  }
}
