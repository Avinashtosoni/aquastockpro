import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../app/theme/app_colors.dart';
import '../../../data/models/order.dart';
import '../../../data/models/order_item.dart';
import '../../../data/models/customer.dart';
import '../../../data/models/business_settings.dart';
import '../../../data/services/pdf_invoice_service.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/customers_provider.dart';
import '../../../data/services/sms_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/repositories/customer_repository.dart';

class PaymentDialog extends ConsumerStatefulWidget {
  final CartState cart;
  final Customer? selectedCustomer;
  final Function(Order order) onPaymentComplete;

  const PaymentDialog({
    super.key,
    required this.cart,
    this.selectedCustomer,
    required this.onPaymentComplete,
  });

  @override
  ConsumerState<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends ConsumerState<PaymentDialog> {
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _discountCodeController = TextEditingController();
  double _paidAmount = 0;
  double _discountAmount = 0;
  String? _appliedDiscountCode;
  bool _isProcessing = false;
  bool _isPartialPayment = false; // Enable partial payment mode
  Customer? _selectedCustomer;
  final _customerSearchController = TextEditingController();
  final _walkInPhoneController = TextEditingController(); // Walk-in customer phone
  BusinessSettings? _cachedSettings; // Cached settings for invoice generation
  final bool _showCustomerSearch = false;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.cart.total.toStringAsFixed(2);
    _paidAmount = widget.cart.total;
    _selectedCustomer = widget.selectedCustomer;
    // Preload settings
    _loadSettings();
  }
  
  void _loadSettings() {
    final settingsAsync = ref.read(settingsNotifierProvider);
    settingsAsync.whenData((s) {
      if (mounted) {
        setState(() => _cachedSettings = s);
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _customerSearchController.dispose();
    _walkInPhoneController.dispose();
    _notesController.dispose();
    _discountCodeController.dispose();
    super.dispose();
  }

  double get _change => (_paidAmount - _effectiveTotal).clamp(0, double.infinity);
  
  double get _effectiveTotal => (widget.cart.total - _discountAmount).clamp(0, double.infinity);
  
  // Amount that will go to credit (only when partial payment enabled)
  double get _remainingCredit => _isPartialPayment 
      ? (_effectiveTotal - _paidAmount).clamp(0, double.infinity) 
      : 0;
  
  // Total Due = Previous Outstanding + Current Bill
  double get _totalDue => (_selectedCustomer?.creditBalance ?? 0) + _effectiveTotal;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 450,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Iconsax.card, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Complete Payment',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${widget.cart.itemCount} items',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Customer Selection Section
              _buildCustomerSection(),
              const SizedBox(height: 12),

              // Scrollable content
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Total Amount
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Total Amount',
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              currencyFormat.format(widget.cart.total),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Bill Summary - Shows when customer has outstanding or credit payment
                      if (_selectedCustomer != null && 
                          _selectedCustomer!.id != 'walk-in' &&
                          (_selectedCustomer!.hasOutstandingCredit || _selectedMethod == PaymentMethod.credit)) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.grey50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.grey200),
                          ),
                          child: Column(
                            children: [
                              // Previous Outstanding
                              if (_selectedCustomer!.hasOutstandingCredit)
                                _BillSummaryRow(
                                  label: 'Previous Outstanding',
                                  value: '₹${_selectedCustomer!.creditBalance.toStringAsFixed(0)}',
                                  valueColor: AppColors.error,
                                  icon: Iconsax.wallet_minus,
                                ),
                              // Current Bill
                              _BillSummaryRow(
                                label: 'Current Bill',
                                value: '₹${_effectiveTotal.toStringAsFixed(0)}',
                                icon: Iconsax.receipt_1,
                              ),
                              // Divider
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 6),
                                child: Divider(height: 1),
                              ),
                              // Total Due (if credit payment)
                              if (_selectedMethod == PaymentMethod.credit)
                                _BillSummaryRow(
                                  label: 'New Total Outstanding',
                                  value: '₹${(_selectedCustomer!.creditBalance + _effectiveTotal).toStringAsFixed(0)}',
                                  valueColor: AppColors.error,
                                  isBold: true,
                                  icon: Iconsax.wallet_2,
                                )
                              else
                                _BillSummaryRow(
                                  label: 'Total Due',
                                  value: '₹${(_selectedCustomer!.creditBalance + _effectiveTotal).toStringAsFixed(0)}',
                                  valueColor: AppColors.error,
                                  isBold: true,
                                  icon: Iconsax.money,
                                ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),

                      // Payment Method Selection
                      const Text(
                        'Payment Method',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: PaymentMethod.values.where((m) {
                          // Hide mixed payment
                          if (m == PaymentMethod.mixed) return false;
                          // Hide credit for walk-in customers - no udhar for walk-in
                          if (m == PaymentMethod.credit && 
                              (_selectedCustomer == null || _selectedCustomer!.id == 'walk-in')) {
                            return false;
                          }
                          return true;
                        }).map((method) {
                          final isSelected = _selectedMethod == method;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: InkWell(
                                onTap: () => setState(() => _selectedMethod = method),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primary : AppColors.grey100,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected ? AppColors.primary : AppColors.grey200,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        _getMethodIcon(method),
                                        size: 22,
                                        color: isSelected ? Colors.white : AppColors.textSecondary,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _getMethodName(method),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: isSelected ? Colors.white : AppColors.textSecondary,
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

                      // Order Notes
                      const Text(
                        'Order Notes (Optional)',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Add special instructions or notes...',
                          hintStyle: TextStyle(fontSize: 13, color: AppColors.grey400),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Icon(Iconsax.note, size: 18, color: AppColors.grey400),
                          ),
                          filled: true,
                          fillColor: AppColors.grey100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),

                      // Partial Payment Option (for customers only, not walk-in)
                      if (_selectedCustomer != null && 
                          _selectedCustomer!.id != 'walk-in' &&
                          _selectedMethod != PaymentMethod.credit) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _isPartialPayment 
                                ? AppColors.warning.withValues(alpha: 0.05)
                                : AppColors.grey50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _isPartialPayment 
                                  ? AppColors.warning.withValues(alpha: 0.3)
                                  : AppColors.grey200,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Toggle Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Iconsax.wallet_money,
                                        size: 18,
                                        color: _isPartialPayment ? AppColors.warning : AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Partial Payment (Udhar)',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: _isPartialPayment ? AppColors.warning : AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Switch(
                                    value: _isPartialPayment,
                                    onChanged: (val) {
                                      setState(() {
                                        _isPartialPayment = val;
                                        if (!val) {
                                          _paidAmount = _effectiveTotal;
                                          _amountController.text = _effectiveTotal.toStringAsFixed(2);
                                        }
                                      });
                                    },
                                    activeColor: AppColors.warning,
                                  ),
                                ],
                              ),
                              // Partial Payment Amount Input
                              if (_isPartialPayment) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Paying Now',
                                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                          ),
                                          const SizedBox(height: 4),
                                          TextField(
                                            controller: _amountController,
                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                            inputFormatters: [
                                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                                            ],
                                            onChanged: (value) {
                                              setState(() {
                                                _paidAmount = double.tryParse(value) ?? 0;
                                              });
                                            },
                                            decoration: InputDecoration(
                                              prefixText: '₹ ',
                                              filled: true,
                                              fillColor: Colors.white,
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: BorderSide(color: AppColors.grey200),
                                              ),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                            ),
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Adding to Credit',
                                            style: TextStyle(fontSize: 11, color: AppColors.error),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                            decoration: BoxDecoration(
                                              color: AppColors.error.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                                            ),
                                            child: Text(
                                              '₹ ${_remainingCredit.toStringAsFixed(0)}',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.error,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Amount Received (for cash)
                      if (_selectedMethod == PaymentMethod.cash) ...[
                        const Text(
                          'Amount Received',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _paidAmount = double.tryParse(value) ?? 0;
                            });
                          },
                          decoration: InputDecoration(
                            prefixText: '₹ ',
                            filled: true,
                            fillColor: AppColors.grey100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          ),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ),

              // Action buttons (always visible at bottom)
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      // Allow payment if: processing completed, OR for credit payment, OR partial payment enabled, OR paid enough
                      onPressed: _isProcessing || 
                          (_paidAmount < _effectiveTotal && 
                           _selectedMethod != PaymentMethod.credit && 
                           !_isPartialPayment)
                          ? null
                          : _processPayment,
                      icon: _isProcessing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Iconsax.tick_circle, size: 18),
                      label: const Text('Complete Payment'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _setAmount(double amount) {
    setState(() {
      _paidAmount = amount;
      _amountController.text = amount.toStringAsFixed(2);
    });
  }

  Widget _buildCustomerSection() {
    final customersAsync = ref.watch(customersNotifierProvider);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Iconsax.user, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                'Customer',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              if (_selectedCustomer != null && _selectedCustomer!.id != 'walk-in')
                TextButton.icon(
                  onPressed: () => setState(() => _selectedCustomer = null),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Clear'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          
          if (_selectedCustomer != null && _selectedCustomer!.id != 'walk-in') ...[
            // Show selected customer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      _selectedCustomer!.name[0].toUpperCase(),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedCustomer!.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (_selectedCustomer!.phone != null)
                          Row(
                            children: [
                              Icon(Iconsax.call, size: 12, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                _selectedCustomer!.phone!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Iconsax.message, size: 12, color: Color(0xFF25D366)),
                            ],
                          ),
                      ],
                    ),
                  ),
                  // Credit Balance Badge
                  if (_selectedCustomer!.creditBalance > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '₹${_selectedCustomer!.creditBalance.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Credit Info Banner - Shows when customer has outstanding credit
            if (_selectedCustomer!.hasOutstandingCredit) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Iconsax.wallet_minus,
                          size: 14,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Outstanding (Udhar)',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '₹${_selectedCustomer!.creditBalance.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ] else if (_selectedCustomer != null && _selectedCustomer!.id == 'walk-in') ...[
            // Walk-in customer selected - show with phone field
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.grey300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.grey200,
                        child: Icon(Iconsax.profile_circle, size: 22, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Walk-in Customer',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() {
                          _selectedCustomer = null;
                          _walkInPhoneController.clear();
                        }),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(0, 0),
                        ),
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Phone number field for walk-in
                  TextField(
                    controller: _walkInPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'WhatsApp Number (optional)',
                      hintStyle: TextStyle(fontSize: 13, color: AppColors.grey400),
                      prefixIcon: Icon(Iconsax.call, size: 18, color: AppColors.grey400),
                      suffixIcon: Icon(Iconsax.message, size: 18, color: Color(0xFF25D366)),
                      filled: true,
                      fillColor: AppColors.grey50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.grey200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.grey200),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter phone to send bill via WhatsApp',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Customer search/select
            Column(
              children: [
                TextField(
                  controller: _customerSearchController,
                  decoration: InputDecoration(
                    hintText: 'Search customer by name or phone...',
                    hintStyle: TextStyle(fontSize: 13, color: AppColors.grey400),
                    prefixIcon: Icon(Iconsax.search_normal, size: 18, color: AppColors.grey400),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.grey200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.grey200),
                    ),
                  ),
                  onChanged: (value) => setState(() {}),
                ),
                const SizedBox(height: 8),
                
                // Customer suggestions
                if (_customerSearchController.text.isNotEmpty)
                  customersAsync.when(
                    data: (customers) {
                      final filtered = customers.where((c) =>
                        c.name.toLowerCase().contains(_customerSearchController.text.toLowerCase()) ||
                        (c.phone?.contains(_customerSearchController.text) ?? false)
                      ).take(4).toList();
                      
                      if (filtered.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Iconsax.info_circle, size: 16, color: AppColors.textSecondary),
                              const SizedBox(width: 8),
                              const Text('No customers found'),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () => _showAddCustomerDialog(_customerSearchController.text),
                                icon: const Icon(Iconsax.add, size: 16),
                                label: const Text('Add New'),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 0),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.grey200),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: filtered.map((customer) => ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.grey100,
                              child: Text(
                                customer.name[0].toUpperCase(),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            title: Text(customer.name, style: const TextStyle(fontSize: 13)),
                            subtitle: customer.phone != null 
                              ? Text(customer.phone!, style: const TextStyle(fontSize: 11))
                              : null,
                            trailing: customer.phone != null
                              ? Icon(Iconsax.message, size: 16, color: Color(0xFF25D366))
                              : null,
                            onTap: () {
                              setState(() {
                                _selectedCustomer = customer;
                                _customerSearchController.clear();
                              });
                            },
                          )).toList(),
                        ),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    error: (error, stackTrace) => const SizedBox(),
                  ),
                
                // Walk-in AND Add New Customer options
                if (_customerSearchController.text.isEmpty)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => setState(() => _selectedCustomer = Customer.walkInCustomer),
                          icon: const Icon(Iconsax.profile_circle, size: 16),
                          label: const Text('Walk-in'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _showAddCustomerDialog(''),
                          icon: const Icon(Iconsax.user_add, size: 16),
                          label: const Text('Add New'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showAddCustomerDialog(String initialName) {
    final nameController = TextEditingController(text: initialName);
    final phoneController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Iconsax.user),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'WhatsApp Number',
                prefixIcon: Icon(Iconsax.call),
                hintText: '+91 9876543210',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              
              final newCustomer = Customer(
                name: nameController.text.trim(),
                phone: phoneController.text.trim().isNotEmpty 
                  ? phoneController.text.trim() 
                  : null,
              );
              
              await ref.read(customersNotifierProvider.notifier).addCustomer(newCustomer);
              
              setState(() {
                _selectedCustomer = newCustomer;
                _customerSearchController.clear();
              });
              
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  IconData _getMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Iconsax.money_4;
      case PaymentMethod.card:
        return Iconsax.card;
      case PaymentMethod.upi:
        return Iconsax.mobile;
      case PaymentMethod.credit:
        return Iconsax.wallet;
      default:
        return Iconsax.card;
    }
  }

  String _getMethodName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.credit:
        return 'Credit';
      default:
        return method.name;
    }
  }

  /// Apply discount code - validates and applies discount
  void _applyDiscountCode() {
    final code = _discountCodeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a discount code')),
      );
      return;
    }

    // Simple discount code validation
    // In production, this should check against a database
    double discount = 0;
    String? validCode;

    // Sample discount codes (replace with database lookup)
    if (code == 'SAVE10') {
      discount = widget.cart.total * 0.10; // 10% off
      validCode = code;
    } else if (code == 'SAVE20') {
      discount = widget.cart.total * 0.20; // 20% off
      validCode = code;
    } else if (code == 'FLAT50') {
      discount = 50; // ₹50 off
      validCode = code;
    } else if (code == 'FLAT100') {
      discount = 100; // ₹100 off
      validCode = code;
    }

    if (validCode != null) {
      setState(() {
        _discountAmount = discount.clamp(0, widget.cart.total);
        _appliedDiscountCode = validCode;
        _amountController.text = _effectiveTotal.toStringAsFixed(2);
        _paidAmount = _effectiveTotal;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Discount applied! Saved ₹${discount.toStringAsFixed(0)}'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Invalid discount code'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    try {
      // Create order items
      final orderItems = widget.cart.items.map((ci) => OrderItem(
        orderId: '', // Will be set when saving
        productId: ci.product.id,
        productName: ci.product.name,
        quantity: ci.quantity,
        unitPrice: ci.product.price,
        discount: 0,
        taxRate: 5,
      )).toList();

      // Get current user for employee info
      final currentUser = ref.read(currentUserProvider);

      // Calculate credit amount for ledger
      double creditAmount = 0;
      if (_selectedMethod == PaymentMethod.credit) {
        creditAmount = _effectiveTotal;
      } else if (_isPartialPayment && _remainingCredit > 0) {
        creditAmount = _remainingCredit;
      }

      // Calculate actual paid amount
      double actualPaidAmount = _effectiveTotal;
      if (_selectedMethod == PaymentMethod.cash) {
        actualPaidAmount = _paidAmount;
      } else if (_isPartialPayment) {
        actualPaidAmount = _paidAmount;
      }

      // Create order with notes and discount
      final order = Order(
        orderNumber: 'ORD${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
        employeeId: currentUser?.id,
        employeeName: currentUser?.name ?? 'Staff',
        customerId: _selectedCustomer?.id != 'walk-in' ? _selectedCustomer?.id : null,
        customerName: _selectedCustomer?.id != 'walk-in' ? _selectedCustomer?.name : null,
        items: orderItems,
        subtotal: widget.cart.subtotal,
        taxAmount: widget.cart.taxAmount,
        discountAmount: widget.cart.totalDiscount + _discountAmount,
        totalAmount: _effectiveTotal,
        paidAmount: actualPaidAmount,
        changeAmount: _selectedMethod == PaymentMethod.cash && !_isPartialPayment ? _change : 0,
        status: OrderStatus.completed,
        paymentMethod: _isPartialPayment ? PaymentMethod.mixed : _selectedMethod,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      // Add credit to ledger if applicable
      if (creditAmount > 0 && _selectedCustomer != null && _selectedCustomer!.id != 'walk-in') {
        try {
          final customerRepo = CustomerRepository();
          await customerRepo.addCredit(
            customerId: _selectedCustomer!.id,
            amount: creditAmount,
            orderId: order.id,
            notes: 'Order #${order.orderNumber}${_isPartialPayment ? " (Partial Payment)" : ""}',
            collectedBy: currentUser?.name,
          );
          // Refresh customers provider to update UI
          ref.invalidate(customersNotifierProvider);
        } catch (e) {
          debugPrint('Error adding credit to ledger: $e');
        }
      }

      // Call completion callback
      widget.onPaymentComplete(order);

      // Send SMS notification in background if enabled
      _sendBillSmsIfEnabled(order);

      // Show success dialog with print option
      if (mounted) {
        Navigator.pop(context);
        _showSuccessDialog(context, order);
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: $e')),
        );
      }
    }
  }

  void _showSuccessDialog(BuildContext context, Order order) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    
    // Use cached settings if available, otherwise try to get from provider
    BusinessSettings settings;
    if (_cachedSettings != null) {
      settings = _cachedSettings!;
    } else {
      final settingsAsync = ref.read(settingsNotifierProvider);
      settings = settingsAsync.valueOrNull ?? BusinessSettings(businessName: 'AquaStock Pro');
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          // Get customer's previous outstanding (before this order was added)
          final previousBalance = _selectedCustomer?.creditBalance ?? 0;
          return _PaymentSuccessDialog(
            order: order,
            customer: _selectedCustomer,
            currencyFormat: currencyFormat,
            ref: ref,
            previousBalance: previousBalance,
            settings: settings, // Pass settings from parent
          );
        },
      ),
    );
  }

  /// Send SMS notification to customer if enabled
  Future<void> _sendBillSmsIfEnabled(Order order) async {
    try {
      // Check if customer has phone number
      final customerPhone = _selectedCustomer?.phone;
      if (customerPhone == null || customerPhone.isEmpty) {
        debugPrint('SMS: No customer phone number');
        return;
      }

      // Get settings
      final settingsAsync = ref.read(settingsNotifierProvider);
      final settings = settingsAsync.valueOrNull;
      if (settings == null || !settings.smsEnabled) {
        debugPrint('SMS: Not enabled in settings');
        return;
      }

      // Create SmsSettings from business settings
      final smsSettings = SmsSettings(
        enabled: settings.smsEnabled,
        method: settings.smsMethod == 'cloud' ? SmsMethod.cloud : SmsMethod.sim,
        provider: _getProvider(settings.smsProvider),
        apiKey: settings.smsApiKey,
        senderId: settings.smsSenderId,
        templateId: settings.smsTemplateId,
        template: settings.smsTemplate,
      );

      // Send SMS in background
      final result = await SmsService().sendBillSms(
        order: order,
        customerPhone: customerPhone,
        businessSettings: settings,
        smsSettings: smsSettings,
        customerName: _selectedCustomer?.name,
      );

      if (result.success) {
        debugPrint('SMS: Sent successfully (${result.messageId})');
      } else {
        debugPrint('SMS: Failed - ${result.error}');
      }
    } catch (e) {
      debugPrint('SMS: Error - $e');
    }
  }

  SmsProvider _getProvider(String provider) {
    switch (provider) {
      case 'fast2sms': return SmsProvider.fast2sms;
      case 'twilio': return SmsProvider.twilio;
      default: return SmsProvider.msg91;
    }
  }
}

class _PaymentSuccessDialog extends StatefulWidget {
  final Order order;
  final Customer? customer;
  final NumberFormat currencyFormat;
  final WidgetRef ref;
  final double previousBalance; // Customer's old outstanding before this order
  final BusinessSettings settings; // Business settings passed from parent

  const _PaymentSuccessDialog({
    required this.order,
    this.customer,
    required this.currencyFormat,
    required this.ref,
    this.previousBalance = 0,
    required this.settings,
  });

  @override
  State<_PaymentSuccessDialog> createState() => _PaymentSuccessDialogState();
}

class _PaymentSuccessDialogState extends State<_PaymentSuccessDialog> {
  bool _isPrinting = false;
  bool _isSharing = false;
  String? _message;

  BusinessSettings get _defaultSettings => BusinessSettings(businessName: 'AquaStock Pro');

  BusinessSettings _getSettings() {
    // Use settings passed from parent (properly loaded)
    return widget.settings;
  }

  String _getPaymentMethodText(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash: return 'Cash';
      case PaymentMethod.card: return 'Card';
      case PaymentMethod.upi: return 'UPI';
      case PaymentMethod.credit: return 'Credit (Udhar)';
      case PaymentMethod.mixed: return 'Partial Payment';
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = _getSettings();
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 460,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success Header
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Iconsax.tick_circle5,
                      color: AppColors.success,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Sale Completed!',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    iconSize: 22,
                  ),
                ],
              ),
            ),

            // Receipt Preview
            Flexible(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.grey200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Receipt Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.grey50,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Receipt Preview',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          Icon(Iconsax.receipt_1, size: 18, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                    
                    // Receipt Content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Business Logo
                            if (settings.showLogo && settings.logoUrl != null && settings.logoUrl!.isNotEmpty) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  settings.logoUrl!,
                                  height: 60,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                            // Store Name
                            Text(
                              settings.businessName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (settings.address != null && settings.address!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                settings.address!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                            if (settings.gstin != null && settings.gstin!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                'GSTIN: ${settings.gstin}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                            
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            
                            // Invoice Info
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Inv: ${widget.order.orderNumber}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                Text(
                                  DateFormat('dd/MM/yyyy, hh:mm a').format(widget.order.createdAt),
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Customer Info
                            if (widget.customer != null && widget.customer!.id != 'walk-in') ...[
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.grey50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.grey200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Iconsax.user, size: 14, color: AppColors.textSecondary),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            widget.customer!.name,
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (widget.customer!.phone != null && widget.customer!.phone!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Iconsax.call, size: 12, color: AppColors.textTertiary),
                                          const SizedBox(width: 6),
                                          Text(
                                            widget.customer!.phone!,
                                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (widget.customer!.address != null && widget.customer!.address!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(Iconsax.location, size: 12, color: AppColors.textTertiary),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              widget.customer!.address!,
                                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ] else ...[
                              Row(
                                children: [
                                  Icon(Iconsax.user, size: 14, color: AppColors.textSecondary),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Walk-in Customer',
                                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ],
                            
                            const SizedBox(height: 14),
                            
                            // Items Table Header
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: AppColors.grey200),
                                  bottom: BorderSide(color: AppColors.grey200),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      'Item',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      'Qty',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Net',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Items List
                            ...widget.order.items.map((item) => Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: AppColors.grey100),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      item.productName,
                                      style: const TextStyle(fontSize: 12),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '${item.quantity}',
                                      style: const TextStyle(fontSize: 12),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      widget.currencyFormat.format(item.total),
                                      style: const TextStyle(fontSize: 12),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                            
                            const SizedBox(height: 12),
                            
                            // Totals
                            _ReceiptSummaryRow(
                              label: 'Subtotal:',
                              value: widget.currencyFormat.format(widget.order.subtotal),
                            ),
                            if (widget.order.taxAmount > 0) 
                              _ReceiptSummaryRow(
                                label: 'Tax:',
                                value: widget.currencyFormat.format(widget.order.taxAmount),
                              ),
                            if (widget.order.discountAmount > 0)
                              _ReceiptSummaryRow(
                                label: 'Discount:',
                                value: '-${widget.currencyFormat.format(widget.order.discountAmount)}',
                                valueColor: AppColors.success,
                              ),
                            
                            // Previous Outstanding (Old Dues) - Show if customer has previous balance
                            if (widget.previousBalance > 0) ...[
                              const Divider(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Iconsax.clock, size: 14, color: AppColors.warning),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Previous Outstanding',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.warning,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      widget.currencyFormat.format(widget.previousBalance),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.warning,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                border: Border(top: BorderSide(color: AppColors.grey200, width: 1.5)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'TOTAL',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    widget.currencyFormat.format(widget.order.totalAmount),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // ========== PAYMENT BREAKDOWN SECTION ==========
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.grey50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.grey200),
                              ),
                              child: Column(
                                children: [
                                  // Payment Method
                                  _ReceiptSummaryRow(
                                    label: 'Payment Method:',
                                    value: _getPaymentMethodText(widget.order.paymentMethod),
                                    valueColor: AppColors.primary,
                                  ),
                                  
                                  const Divider(height: 16),
                                  
                                  // Amount Paid
                                  _ReceiptSummaryRow(
                                    label: 'Amount Paid:',
                                    value: widget.currencyFormat.format(widget.order.paidAmount),
                                    valueColor: AppColors.success,
                                    isBold: true,
                                  ),
                                  
                                  // Change (if any)
                                  if (widget.order.changeAmount > 0)
                                    _ReceiptSummaryRow(
                                      label: 'Change Returned:',
                                      value: widget.currencyFormat.format(widget.order.changeAmount),
                                    ),
                                  
                                  // Credit/Due Amount (highlighted prominently if > 0)
                                  if (widget.order.totalAmount > widget.order.paidAmount) ...[
                                    const Divider(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.error.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Iconsax.wallet_minus, size: 16, color: AppColors.error),
                                              const SizedBox(width: 8),
                                              Text(
                                                'BALANCE DUE (UDHAR)',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color: AppColors.error,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            widget.currencyFormat.format(widget.order.totalAmount - widget.order.paidAmount),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: AppColors.error,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Added to customer credit ledger',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontStyle: FontStyle.italic,
                                        color: AppColors.error.withValues(alpha: 0.7),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    // TOTAL OUTSTANDING (Previous + Current Due)
                                    if (widget.previousBalance > 0 || widget.order.totalAmount > widget.order.paidAmount) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppColors.error.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'TOTAL OUTSTANDING',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                            Text(
                                              widget.currencyFormat.format(
                                                widget.previousBalance + (widget.order.totalAmount - widget.order.paidAmount)
                                              ),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: AppColors.error,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                  
                                  // Full payment confirmation
                                  if (widget.order.totalAmount <= widget.order.paidAmount) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Iconsax.tick_circle, size: 14, color: AppColors.success),
                                        const SizedBox(width: 6),
                                        Text(
                                          'PAID IN FULL',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: AppColors.success,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            
                            // Thank you message
                            const SizedBox(height: 16),
                            Text(
                              'Thank you for shopping with us!',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: AppColors.textTertiary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Message (if any)
            if (_message != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Iconsax.tick_circle, size: 16, color: AppColors.info),
                      const SizedBox(width: 8),
                      Flexible(child: Text(_message!, style: TextStyle(fontSize: 12, color: AppColors.info))),
                    ],
                  ),
                ),
              ),

            // Action Buttons - Mobile Responsive
            Container(
              padding: const EdgeInsets.all(20),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 400;
                  
                  if (isMobile) {
                    // Stack buttons vertically on small screens
                    return Column(
                      children: [
                        // WhatsApp and Print Row
                        Row(
                          children: [
                            Expanded(
                              child: _MobileActionButton(
                                icon: Iconsax.message,
                                label: 'WhatsApp',
                                color: const Color(0xFF25D366),
                                isLoading: _isSharing,
                                onPressed: _shareOnWhatsApp,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _MobileActionButton(
                                icon: Iconsax.printer,
                                label: 'Print',
                                color: AppColors.info,
                                isLoading: _isPrinting,
                                onPressed: _printReceipt,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // New Sale Button - Full Width
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Iconsax.add_circle, size: 18),
                            label: const Text('New Sale'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: AppColors.grey300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  
                  // Desktop/Tablet horizontal layout
                  return Row(
                    children: [
                      // New Sale Button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: AppColors.grey300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'New Sale',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      
                      // WhatsApp Button
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isSharing ? null : _shareOnWhatsApp,
                          icon: _isSharing 
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Iconsax.share, size: 18),
                          label: const Text('WhatsApp'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366), // WhatsApp green
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      
                      // Print Bill Button
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isPrinting ? null : _printReceipt,
                          icon: _isPrinting 
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Iconsax.printer, size: 18),
                          label: const Text('Print Bill'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.info,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _printReceipt() async {
    setState(() => _isPrinting = true);
    try {
      final settings = _getSettings();
      await PdfInvoiceService().printReceipt(
        order: widget.order,
        settings: settings,
        items: widget.order.items,
        previousBalance: widget.previousBalance,
      );
      setState(() => _message = 'Receipt sent to printer');
    } catch (e) {
      setState(() => _message = 'Print failed: $e');
    } finally {
      setState(() => _isPrinting = false);
    }
  }

  Future<void> _shareOnWhatsApp() async {
    if (!mounted) return;
    setState(() => _isSharing = true);
    
    try {
      final settings = _getSettings();
      
      // Generate A4 Invoice PDF for WhatsApp sharing (professional format)
      final pdfData = await PdfInvoiceService().generateInvoicePdf(
        order: widget.order,
        settings: settings,
        items: widget.order.items,
        customer: widget.customer,
        previousBalance: widget.previousBalance,
      );
      
      if (!mounted) return;
      
      if (kIsWeb) {
        // ===== WEB PLATFORM =====
        String? targetPhone = widget.customer?.phone;
        
        if (targetPhone == null || targetPhone.isEmpty) {
          targetPhone = await _askForWhatsAppNumber();
          if (targetPhone == null || targetPhone.isEmpty) {
            if (mounted) setState(() => _isSharing = false);
            return;
          }
        }
        
        // Clean phone number
        String cleanPhone = targetPhone.replaceAll(RegExp(r'[^\d+]'), '');
        if (cleanPhone.startsWith('+')) {
          cleanPhone = cleanPhone.substring(1);
        } else if (cleanPhone.startsWith('0')) {
          cleanPhone = '91${cleanPhone.substring(1)}';
        } else if (!cleanPhone.startsWith('91') && cleanPhone.length == 10) {
          cleanPhone = '91$cleanPhone';
        }
        
        final receiptText = _generateReceiptText(settings);
        final encodedMessage = Uri.encodeComponent(receiptText);
        final whatsappUrl = Uri.parse('https://wa.me/$cleanPhone?text=$encodedMessage');
        
        await launchUrl(whatsappUrl, mode: LaunchMode.platformDefault);
        
        await Printing.sharePdf(
          bytes: pdfData,
          filename: 'invoice_${widget.order.orderNumber}.pdf',
        );
        
        if (mounted) {
          setState(() => _message = '✅ WhatsApp opened! Invoice downloaded');
        }
      } else {
        // ===== MOBILE PLATFORM =====
        try {
          final directory = await getTemporaryDirectory();
          final pdfPath = '${directory.path}/invoice_${widget.order.orderNumber}.pdf';
          final pdfFile = File(pdfPath);
          await pdfFile.writeAsBytes(pdfData, flush: true);
          
          if (!mounted) return;
          
          // Generate short caption for WhatsApp (not full receipt)
          final caption = _generateShortCaption(settings);
          
          // Share PDF with caption via share sheet
          // When user selects WhatsApp, the caption becomes the file message
          await Share.shareXFiles(
            [XFile(pdfPath, mimeType: 'application/pdf')],
            text: caption,
            subject: 'Invoice #${widget.order.orderNumber}',
          );
          
          if (mounted) setState(() => _message = '✅ Invoice shared');
        } catch (fileError) {
          debugPrint('File error: $fileError');
          await Printing.sharePdf(
            bytes: pdfData,
            filename: 'invoice_${widget.order.orderNumber}.pdf',
          );
          if (mounted) setState(() => _message = '✅ Invoice shared');
        }
      }
      
    } catch (e) {
      debugPrint('WhatsApp share error: $e');
      if (mounted) setState(() => _message = 'Share failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  /// Short caption for Invoice share (appears as file message in WhatsApp)
  String _generateShortCaption(BusinessSettings settings) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final dateFormat = DateFormat('dd/MM/yy');
    
    final buffer = StringBuffer();
    buffer.writeln('📄 *Invoice #${widget.order.orderNumber}*');
    buffer.writeln('━━━━━━━━━━━━━━━');
    buffer.writeln('🏪 ${settings.businessName}');
    buffer.writeln('📅 ${dateFormat.format(widget.order.createdAt)}');
    if (widget.customer != null && widget.customer!.id != 'walk-in') {
      buffer.writeln('👤 ${widget.customer!.name}');
    }
    buffer.writeln('━━━━━━━━━━━━━━━');
    buffer.writeln('💰 *Total: ${currencyFormat.format(widget.order.totalAmount)}*');
    buffer.writeln('━━━━━━━━━━━━━━━');
    buffer.writeln('');
    buffer.writeln(settings.thankYouMessage ?? '🙏 Thank you for your business!');
    
    return buffer.toString();
  }

  Future<String?> _askForWhatsAppNumber() async {
    final phoneController = TextEditingController();
    
    return await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF25D366).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.message, color: Color(0xFF25D366), size: 20),
            ),
            const SizedBox(width: 12),
            const Text('WhatsApp Number'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter customer\'s WhatsApp number to send receipt:',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '9876543210',
                prefixText: '+91 ',
                prefixIcon: const Icon(Iconsax.call),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              final phone = phoneController.text.trim();
              if (phone.isNotEmpty) {
                Navigator.pop(ctx, phone);
              }
            },
            icon: const Icon(Iconsax.send_1, size: 18),
            label: const Text('Send'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
            ),
          ),
        ],
      ),
    );
  }

  String _generateReceiptText(BusinessSettings settings) {
    final buffer = StringBuffer();
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    
    buffer.writeln('📄 *RECEIPT*');
    buffer.writeln('━━━━━━━━━━━━━━━━');
    buffer.writeln('*${settings.businessName}*');
    if (settings.address != null) buffer.writeln(settings.address);
    if (settings.phone != null) buffer.writeln('📞 ${settings.phone}');
    buffer.writeln();
    buffer.writeln('🧾 Order: #${widget.order.orderNumber}');
    buffer.writeln('📅 Date: ${DateFormat('dd/MM/yy HH:mm').format(widget.order.createdAt)}');
    if (widget.customer != null && widget.customer!.id != 'walk-in') {
      buffer.writeln('👤 Customer: ${widget.customer!.name}');
    }
    buffer.writeln('━━━━━━━━━━━━━━━━');
    buffer.writeln();
    
    for (final item in widget.order.items) {
      buffer.writeln('• ${item.productName}');
      buffer.writeln('  ${item.quantity} x ${currencyFormat.format(item.unitPrice)} = ${currencyFormat.format(item.total)}');
    }
    
    buffer.writeln();
    buffer.writeln('━━━━━━━━━━━━━━━━');
    if (widget.order.discountAmount > 0) {
      buffer.writeln('Discount: -${currencyFormat.format(widget.order.discountAmount)}');
    }
    if (widget.order.taxAmount > 0) {
      buffer.writeln('Tax: ${currencyFormat.format(widget.order.taxAmount)}');
    }
    buffer.writeln('*💰 TOTAL: ${currencyFormat.format(widget.order.totalAmount)}*');
    buffer.writeln('━━━━━━━━━━━━━━━━');
    buffer.writeln();
    buffer.writeln(settings.thankYouMessage ?? '🙏 Thank you for shopping with us!');
    buffer.writeln();
    buffer.writeln('_PDF receipt attached below_');
    
    return buffer.toString();
  }
}

class _ReceiptSummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  const _ReceiptSummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 13 : 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAmountButton extends StatelessWidget {
  final double amount;
  final String? label;
  final VoidCallback onTap;

  const _QuickAmountButton({
    required this.amount,
    this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Text(
          label ?? currencyFormat.format(amount),
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

/// Mobile-optimized action button with larger touch target
class _MobileActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isLoading;
  final VoidCallback onPressed;

  const _MobileActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.isLoading = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else
                Icon(icon, color: Colors.white, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bill summary row for displaying outstanding and payment breakdown
class _BillSummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;
  final IconData? icon;

  const _BillSummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: valueColor ?? AppColors.textSecondary),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 14 : 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
