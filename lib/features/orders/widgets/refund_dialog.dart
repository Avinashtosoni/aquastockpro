import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/models/order.dart';
import '../../../data/models/order_item.dart';

/// Item selection state for refund
class RefundItemState {
  final OrderItem item;
  bool selected;
  int quantity;

  RefundItemState({
    required this.item,
    this.selected = true,
    int? quantity,
  }) : quantity = quantity ?? item.quantity;

  double get refundAmount => item.unitPrice * quantity;
}

/// Advanced dialog for processing refunds with item selection
class RefundDialog extends ConsumerStatefulWidget {
  final Order order;
  final Function(String reason, String? notes, bool restockItems, List<OrderItem> selectedItems) onProcess;

  const RefundDialog({
    super.key,
    required this.order,
    required this.onProcess,
  });

  @override
  ConsumerState<RefundDialog> createState() => _RefundDialogState();
}

class _RefundDialogState extends ConsumerState<RefundDialog> {
  final _currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
  final _notesController = TextEditingController();
  
  String _selectedReason = 'Customer Request';
  bool _restockItems = true;
  bool _isProcessing = false;
  late List<RefundItemState> _itemStates;

  final List<String> _reasons = [
    'Customer Request',
    'Damaged Product',
    'Wrong Item',
    'Quality Issue',
    'Pricing Error',
    'Partial Return',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize item states - all selected by default
    _itemStates = widget.order.items.map((item) => RefundItemState(item: item)).toList();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  double get _totalRefundAmount {
    return _itemStates
        .where((s) => s.selected)
        .fold(0.0, (sum, s) => sum + s.refundAmount);
  }

  int get _selectedItemCount {
    return _itemStates.where((s) => s.selected).length;
  }

  List<OrderItem> get _selectedItems {
    return _itemStates
        .where((s) => s.selected)
        .map((s) => s.item.copyWith(quantity: s.quantity))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final order = widget.order;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 500,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Iconsax.money_recive, color: AppColors.warning, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Process Refund',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Order ${order.orderNumber}',
                          style: TextStyle(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
            ),
            
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Items Selection Section
                    Text(
                      'Select Items to Refund',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Items List
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.grey300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          // Select All Header
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCardBackground : AppColors.grey50,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: _itemStates.every((s) => s.selected),
                                  tristate: true,
                                  onChanged: (value) {
                                    setState(() {
                                      final selectAll = value ?? false;
                                      for (var item in _itemStates) {
                                        item.selected = selectAll;
                                      }
                                    });
                                  },
                                  activeColor: AppColors.primary,
                                ),
                                const Text('Select All', style: TextStyle(fontWeight: FontWeight.w500)),
                                const Spacer(),
                                Text(
                                  '$_selectedItemCount of ${_itemStates.length} items',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const Divider(height: 1),
                          
                          // Individual Items
                          ...List.generate(_itemStates.length, (index) {
                            final state = _itemStates[index];
                            return _buildItemRow(state, index, isDark);
                          }),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Refund Amount Summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Refund Amount',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                '$_selectedItemCount item(s) selected',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            _currencyFormat.format(_totalRefundAmount),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Reason Dropdown
                    Text(
                      'Refund Reason',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.grey300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedReason,
                          isExpanded: true,
                          icon: const Icon(Iconsax.arrow_down_1, size: 18),
                          items: _reasons.map((reason) => DropdownMenuItem(
                            value: reason,
                            child: Text(reason),
                          )).toList(),
                          onChanged: (value) {
                            if (value != null) setState(() => _selectedReason = value);
                          },
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Notes
                    Text(
                      'Additional Notes (Optional)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Enter any additional notes...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDark ? AppColors.darkCardBorder : AppColors.grey300),
                        ),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Restock Option
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCardBackground : AppColors.grey50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _restockItems,
                            onChanged: (value) => setState(() => _restockItems = value ?? true),
                            activeColor: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Restock Items',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  'Add refunded items back to inventory',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
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
            ),
            
            // Footer Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: isDark ? AppColors.darkCardBorder : AppColors.grey200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isProcessing ? null : () => Navigator.pop(context),
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
                      onPressed: _isProcessing || _selectedItemCount == 0 ? null : _processRefund,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.warning,
                        disabledBackgroundColor: AppColors.grey300,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text('Refund ${_currencyFormat.format(_totalRefundAmount)}'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(RefundItemState state, int index, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: index < _itemStates.length - 1
            ? Border(bottom: BorderSide(color: isDark ? AppColors.darkCardBorder : AppColors.grey200))
            : null,
      ),
      child: Row(
        children: [
          // Checkbox
          Checkbox(
            value: state.selected,
            onChanged: (value) {
              setState(() => state.selected = value ?? false);
            },
            activeColor: AppColors.primary,
          ),
          
          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.item.productName,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: state.selected 
                        ? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)
                        : AppColors.textSecondary,
                  ),
                ),
                Text(
                  '${_currencyFormat.format(state.item.unitPrice)} × ${state.item.quantity}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          // Quantity Selector
          if (state.selected && state.item.quantity > 1) ...[
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.grey300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: state.quantity > 1 
                        ? () => setState(() => state.quantity--)
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Iconsax.minus, 
                        size: 16,
                        color: state.quantity > 1 ? AppColors.primary : AppColors.grey400,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '${state.quantity}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  InkWell(
                    onTap: state.quantity < state.item.quantity 
                        ? () => setState(() => state.quantity++)
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Iconsax.add, 
                        size: 16,
                        color: state.quantity < state.item.quantity ? AppColors.primary : AppColors.grey400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
          ],
          
          // Item Refund Amount
          Text(
            _currencyFormat.format(state.selected ? state.refundAmount : 0),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: state.selected ? AppColors.warning : AppColors.grey400,
            ),
          ),
        ],
      ),
    );
  }

  void _processRefund() async {
    if (_selectedItemCount == 0) return;
    
    setState(() => _isProcessing = true);
    
    final notes = _notesController.text.trim().isEmpty 
        ? null 
        : _notesController.text.trim();
    
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      widget.onProcess(_selectedReason, notes, _restockItems, _selectedItems);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isProcessing = false);
    }
  }
}
