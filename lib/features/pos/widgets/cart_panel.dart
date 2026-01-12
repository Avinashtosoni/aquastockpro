import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/models/customer.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/customers_provider.dart';

class CartPanel extends ConsumerStatefulWidget {
  final CartState cart;
  final VoidCallback? onCheckout;
  final VoidCallback? onHold;
  final VoidCallback? onClear;

  const CartPanel({
    super.key,
    required this.cart,
    this.onCheckout,
    this.onHold,
    this.onClear,
  });

  @override
  ConsumerState<CartPanel> createState() => _CartPanelState();
}

class _CartPanelState extends ConsumerState<CartPanel> {
  final _discountController = TextEditingController();
  bool _isPercentageDiscount = true;

  @override
  void initState() {
    super.initState();
    _updateDiscountController();
  }

  @override
  void didUpdateWidget(CartPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cart.discountAmount != widget.cart.discountAmount) {
      _updateDiscountController();
    }
  }

  void _updateDiscountController() {
    if (_isPercentageDiscount) {
      // Convert amount to percentage
      if (widget.cart.subtotal > 0) {
        final percentage = (widget.cart.discountAmount / widget.cart.subtotal) * 100;
        _discountController.text = percentage > 0 ? percentage.toStringAsFixed(1) : '';
      }
    } else {
      _discountController.text = widget.cart.discountAmount > 0 
          ? widget.cart.discountAmount.toStringAsFixed(0) 
          : '';
    }
  }

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final selectedCustomer = ref.watch(selectedCustomerProvider);

    return Column(
      children: [
        // Customer Selection Header
        _CustomerSelectionHeader(
          selectedCustomer: selectedCustomer,
          onCustomerSelected: (customer) {
            ref.read(selectedCustomerProvider.notifier).state = customer;
            if (customer != null) {
              ref.read(cartProvider.notifier).setCustomer(customer.id, customer.name);
            } else {
              ref.read(cartProvider.notifier).setCustomer(null, null);
            }
          },
          onSync: () {
            ref.invalidate(customersProvider);
            HapticFeedback.lightImpact();
          },
        ),

        // Header with order info
        Builder(
          builder: (context) {
            final isDark = context.isDarkMode;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedCustomer?.name ?? 'Walk-in Customer',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextPrimary : null,
                        ),
                      ),
                      Text(
                        '${widget.cart.itemCount} items',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Held Orders Button
                      _HeldOrdersButton(),
                      const SizedBox(width: 8),
                      // Clear Button
                      if (widget.cart.isNotEmpty)
                        IconButton(
                          icon: const Icon(Iconsax.trash, size: 20),
                          onPressed: widget.onClear,
                          tooltip: 'Clear Cart',
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.error.withValues(alpha: 0.1),
                            foregroundColor: AppColors.error,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        // Cart Items
        Expanded(
          child: widget.cart.isEmpty
              ? _EmptyCart()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: widget.cart.items.length,
                  itemBuilder: (context, index) {
                    final item = widget.cart.items[index];
                    return EnhancedCartItemTile(
                      item: item,
                      onIncrement: () {
                        HapticFeedback.selectionClick();
                        ref.read(cartProvider.notifier).incrementQuantity(item.product.id);
                      },
                      onDecrement: () {
                        HapticFeedback.selectionClick();
                        ref.read(cartProvider.notifier).decrementQuantity(item.product.id);
                      },
                      onRemove: () {
                        HapticFeedback.mediumImpact();
                        ref.read(cartProvider.notifier).removeProduct(item.product.id);
                      },
                      onReset: () {
                        HapticFeedback.selectionClick();
                        ref.read(cartProvider.notifier).updateQuantity(item.product.id, 1);
                      },
                    );
                  },
                ),
        ),

        // Order Summary
        Builder(
          builder: (context) {
            final isDark = context.isDarkMode;
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceVariant : AppColors.grey50,
                border: Border(top: BorderSide(color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Subtotal
                  _SummaryRow(
                    label: 'Subtotal',
                    value: currencyFormat.format(widget.cart.subtotal),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 6),
                  // CGST (half of total tax)
                  if (widget.cart.taxAmount > 0) ...[
                    _SummaryRow(
                      label: 'CGST',
                      value: currencyFormat.format(widget.cart.taxAmount / 2),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 4),
                    // SGST (half of total tax)
                    _SummaryRow(
                      label: 'SGST',
                      value: currencyFormat.format(widget.cart.taxAmount / 2),
                      isDark: isDark,
                    ),
                  ],
                  const SizedBox(height: 10),
                  // Bill Discount Input
                  _BillDiscountRow(
                    controller: _discountController,
                    isPercentage: _isPercentageDiscount,
                    onToggleType: () {
                      setState(() {
                        _isPercentageDiscount = !_isPercentageDiscount;
                        _updateDiscountController();
                      });
                    },
                    onDiscountChanged: (value) {
                      final numValue = double.tryParse(value) ?? 0;
                      if (_isPercentageDiscount) {
                        // Convert percentage to amount
                        final discountAmount = (widget.cart.subtotal * numValue) / 100;
                        ref.read(cartProvider.notifier).setDiscount(discountAmount);
                      } else {
                        ref.read(cartProvider.notifier).setDiscount(numValue);
                      }
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: isDark ? AppColors.darkCardBorder : null),
                  ),
                  // Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Pay',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextSecondary : null,
                        ),
                      ),
                      Text(
                        currencyFormat.format(widget.cart.total),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: isDark ? AppColors.primaryLight : AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                      ),
                    ],
                  ),
              const SizedBox(height: 16),
              // Action Buttons
              Row(
                children: [
                  // Hold Button
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: widget.onHold,
                        icon: const Icon(Iconsax.pause, size: 20),
                        label: const Text('Hold'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: const BorderSide(color: AppColors.grey300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Pay & Print Button
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: widget.onCheckout,
                        icon: const Icon(Iconsax.printer, size: 20),
                        label: const Text(
                          'Pay & Print',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.info,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
            );
          },
        ),
      ],
    );
  }
}

// Customer Selection Header Widget
class _CustomerSelectionHeader extends ConsumerStatefulWidget {
  final Customer? selectedCustomer;
  final ValueChanged<Customer?> onCustomerSelected;
  final VoidCallback onSync;

  const _CustomerSelectionHeader({
    required this.selectedCustomer,
    required this.onCustomerSelected,
    required this.onSync,
  });

  @override
  ConsumerState<_CustomerSelectionHeader> createState() => _CustomerSelectionHeaderState();
}

class _CustomerSelectionHeaderState extends ConsumerState<_CustomerSelectionHeader> {
  final _searchController = TextEditingController();
  bool _isDropdownOpen = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _buttonKey = GlobalKey();

  @override
  void dispose() {
    _searchController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _toggleDropdown() {
    if (_isDropdownOpen) {
      _removeOverlay();
      setState(() => _isDropdownOpen = false);
    } else {
      _showDropdown();
      setState(() => _isDropdownOpen = true);
    }
  }

  void _showDropdown() {
    final RenderBox? renderBox = _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: context.surfaceColor,
            child: _CustomerDropdown(
              searchController: _searchController,
              onCustomerSelected: (customer) {
                widget.onCustomerSelected(customer);
                _toggleDropdown();
              },
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        border: Border(bottom: BorderSide(color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: CompositedTransformTarget(
              link: _layerLink,
              child: InkWell(
                key: _buttonKey,
                onTap: _toggleDropdown,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceVariant : AppColors.grey100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.grey200),
                  ),
                  child: Row(
                    children: [
                      Icon(Iconsax.user, size: 20, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.selectedCustomer?.name ?? 'Select Customer (Optional)',
                          style: TextStyle(
                            color: widget.selectedCustomer != null 
                                ? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)
                                : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        _isDropdownOpen ? Iconsax.arrow_up_2 : Iconsax.arrow_down_1,
                        size: 18,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Sync Button
          Material(
            color: isDark ? AppColors.darkSurfaceVariant : AppColors.grey100,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: widget.onSync,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(10),
                child: Icon(Iconsax.refresh, size: 20, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerDropdown extends ConsumerWidget {
  final TextEditingController searchController;
  final ValueChanged<Customer?> onCustomerSelected;

  const _CustomerDropdown({
    required this.searchController,
    required this.onCustomerSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customersProvider);

    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search customers...',
                prefixIcon: const Icon(Iconsax.search_normal, size: 18),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.grey200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.grey200),
                ),
              ),
              onChanged: (value) {
                // Trigger rebuild
                (context as Element).markNeedsBuild();
              },
            ),
          ),
          const Divider(height: 1),
          // Walk-in option
          ListTile(
            dense: true,
            leading: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Iconsax.user, size: 18, color: AppColors.textSecondary),
            ),
            title: const Text('Walk-in Customer'),
            onTap: () => onCustomerSelected(null),
          ),
          const Divider(height: 1),
          // Customer list
          Flexible(
            child: customersAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, st) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error: $e'),
              ),
              data: (customers) {
                final query = searchController.text.toLowerCase();
                final filtered = query.isEmpty
                    ? customers
                    : customers.where((c) => 
                        c.name.toLowerCase().contains(query) ||
                        (c.phone?.contains(query) ?? false)
                      ).toList();

                if (filtered.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No customers found'),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final customer = filtered[index];
                    return ListTile(
                      dense: true,
                      leading: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Iconsax.user, size: 18, color: AppColors.primary),
                      ),
                      title: Text(customer.name),
                      subtitle: customer.phone != null ? Text(customer.phone!) : null,
                      onTap: () => onCustomerSelected(customer),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Enhanced Cart Item Tile
class EnhancedCartItemTile extends StatelessWidget {
  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;
  final VoidCallback onReset;

  const EnhancedCartItemTile({
    super.key,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final unit = item.product.unit ?? 'Pc';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Name and Actions
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.info,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${currencyFormat.format(item.product.price)} / $unit',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Action icons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _IconActionButton(
                    icon: Iconsax.refresh,
                    onTap: onReset,
                    tooltip: 'Reset to 1',
                  ),
                  const SizedBox(width: 4),
                  _IconActionButton(
                    icon: Iconsax.trash,
                    onTap: onRemove,
                    tooltip: 'Remove',
                    color: AppColors.error,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Quantity Controls and Total
          Row(
            children: [
              // Quantity Controls
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.grey200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _QuantityButton(
                      icon: Icons.remove,
                      onTap: onDecrement,
                    ),
                    Container(
                      constraints: const BoxConstraints(minWidth: 40),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        item.quantity.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    _QuantityButton(
                      icon: Icons.add,
                      onTap: onIncrement,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Total
              Text(
                currencyFormat.format(item.total),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final Color? color;

  const _IconActionButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              icon,
              size: 18,
              color: color ?? AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QuantityButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 16, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isDark;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: valueColor ?? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}

class _BillDiscountRow extends StatelessWidget {
  final TextEditingController controller;
  final bool isPercentage;
  final VoidCallback onToggleType;
  final ValueChanged<String> onDiscountChanged;

  const _BillDiscountRow({
    required this.controller,
    required this.isPercentage,
    required this.onToggleType,
    required this.onDiscountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Iconsax.discount_shape,
          size: 16,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 8),
        Text(
          'Bill Discount (%)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const Spacer(),
        SizedBox(
          width: 80,
          height: 36,
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.success,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(color: AppColors.grey400),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.grey200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.grey200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
            onChanged: onDiscountChanged,
          ),
        ),
      ],
    );
  }
}

class _EmptyCart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.shopping_cart,
                size: 48,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your cart is empty',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add products to start a sale',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeldOrdersButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heldOrders = ref.watch(heldOrdersProvider);

    if (heldOrders.isEmpty) return const SizedBox.shrink();

    return Badge(
      label: Text(heldOrders.length.toString()),
      child: IconButton(
        icon: const Icon(Iconsax.pause_circle, size: 20),
        onPressed: () => _showHeldOrders(context, ref),
        tooltip: 'Held Orders',
        style: IconButton.styleFrom(
          backgroundColor: AppColors.warning.withValues(alpha: 0.1),
          foregroundColor: AppColors.warning,
        ),
      ),
    );
  }

  void _showHeldOrders(BuildContext context, WidgetRef ref) {
    final heldOrders = ref.read(heldOrdersProvider);
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Iconsax.pause_circle, color: AppColors.warning),
            ),
            const SizedBox(width: 12),
            const Text('Held Orders'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: ListView.separated(
            shrinkWrap: true,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemCount: heldOrders.length,
            itemBuilder: (context, index) {
              final order = heldOrders[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                title: Text('Order #${index + 1}'),
                subtitle: Text('${order.itemCount} items'),
                trailing: Text(
                  currencyFormat.format(order.total),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    fontSize: 15,
                  ),
                ),
                onTap: () {
                  // Restore this order
                  ref.read(cartProvider.notifier).restoreState(order);
                  // Remove from held orders
                  final newHeld = [...heldOrders];
                  newHeld.removeAt(index);
                  ref.read(heldOrdersProvider.notifier).state = newHeld;
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
