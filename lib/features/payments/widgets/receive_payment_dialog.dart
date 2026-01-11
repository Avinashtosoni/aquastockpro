import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../data/models/customer.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/customer_repository.dart';

/// Dialog for receiving payment from a customer
class ReceivePaymentDialog extends ConsumerStatefulWidget {
  final Customer customer;
  final VoidCallback? onPaymentReceived;

  const ReceivePaymentDialog({
    super.key,
    required this.customer,
    this.onPaymentReceived,
  });

  @override
  ConsumerState<ReceivePaymentDialog> createState() => _ReceivePaymentDialogState();
}

class _ReceivePaymentDialogState extends ConsumerState<ReceivePaymentDialog> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  bool _isProcessing = false;
  String? _errorMessage;

  final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

  double get _enteredAmount => double.tryParse(_amountController.text) ?? 0;
  double get _remainingAfter => (widget.customer.creditBalance - _enteredAmount).clamp(0, double.infinity);

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Iconsax.money_recive, color: AppColors.success, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Receive Payment',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Collect outstanding dues',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white60 : AppColors.textSecondary,
                            ),
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

                // Customer Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary.withValues(alpha: 0.8), AppColors.primary],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            widget.customer.name.isNotEmpty ? widget.customer.name[0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.customer.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            if (widget.customer.phone != null)
                              Text(
                                widget.customer.phone!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white54 : AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Outstanding Balance
                Container(
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
                          Text(
                            'Outstanding Balance',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        currencyFormat.format(widget.customer.creditBalance),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Amount Input
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          labelText: 'Amount Receiving',
                          prefixText: '₹ ',
                          filled: true,
                          fillColor: isDark ? AppColors.darkSurface : AppColors.surface,
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
                        setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Pay Full'),
                    ),
                  ],
                ),
                if (_enteredAmount > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Remaining after: ${currencyFormat.format(_remainingAfter)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: _remainingAfter == 0 ? AppColors.success : AppColors.warning,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // Payment Method
                Text(
                  'Payment Method',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: PaymentMethod.values.where((m) => m != PaymentMethod.credit).map((method) {
                    final isSelected = _selectedMethod == method;
                    return ChoiceChip(
                      label: Text(_getMethodName(method)),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedMethod = method);
                      },
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppColors.textSecondary),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Notes
                TextField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Notes (Optional)',
                    hintText: 'UPI ref, cheque no, etc.',
                    filled: true,
                    fillColor: isDark ? AppColors.darkSurface : AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Error message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: AppColors.error, fontSize: 13),
                    ),
                  ),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isProcessing ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing || _enteredAmount <= 0 ? null : _receivePayment,
                        icon: _isProcessing
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Iconsax.money_recive),
                        label: Text(_isProcessing ? 'Processing...' : 'Receive Payment'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  String _getMethodName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash: return 'Cash';
      case PaymentMethod.upi: return 'UPI';
      case PaymentMethod.card: return 'Card';
      case PaymentMethod.mixed: return 'Mixed';
      default: return method.name;
    }
  }

  Future<void> _receivePayment() async {
    if (_enteredAmount <= 0) {
      setState(() => _errorMessage = 'Please enter a valid amount');
      return;
    }

    if (_enteredAmount > widget.customer.creditBalance) {
      setState(() => _errorMessage = 'Amount cannot exceed outstanding balance');
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final repo = CustomerRepository();
      await repo.receivePayment(
        customerId: widget.customer.id,
        amount: _enteredAmount,
        notes: '${_getMethodName(_selectedMethod)}${_notesController.text.isNotEmpty ? ': ${_notesController.text}' : ''}',
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onPaymentReceived?.call();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment of ${currencyFormat.format(_enteredAmount)} received successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = e.toString();
      });
    }
  }
}
