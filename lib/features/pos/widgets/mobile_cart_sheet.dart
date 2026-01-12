import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/alert_service.dart';
import '../../../providers/cart_provider.dart';

/// Mobile-optimized cart bottom sheet with swipe-to-delete and smooth animations
class MobileCartSheet extends ConsumerWidget {
  final VoidCallback? onCheckout;
  final VoidCallback? onHold;
  final VoidCallback? onClear;

  const MobileCartSheet({
    super.key,
    this.onCheckout,
    this.onHold,
    this.onClear,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final isDark = context.isDarkMode;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardBackground : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Iconsax.shopping_cart5,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Cart',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${cart.itemCount} item${cart.itemCount != 1 ? 's' : ''}',
                            style: TextStyle(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (cart.isNotEmpty)
                      IconButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          _showClearConfirmation(context, ref);
                        },
                        icon: Icon(Iconsax.trash, color: AppColors.error, size: 20),
                        tooltip: 'Clear Cart',
                      ),
                  ],
                ),
              ),
              
              const Divider(height: 1),
              
              // Cart items
              Expanded(
                child: cart.isEmpty
                    ? _buildEmptyCart(context)
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: cart.items.length,
                        itemBuilder: (context, index) {
                          final item = cart.items[index];
                          return _CartItemTile(
                            item: item,
                            currencyFormat: currencyFormat,
                            onDismissed: () {
                              HapticFeedback.mediumImpact();
                              ref.read(cartProvider.notifier).removeProduct(item.product.id);
                            },
                            onQuantityChanged: (qty) {
                              HapticFeedback.lightImpact();
                              ref.read(cartProvider.notifier).updateQuantity(item.product.id, qty);
                            },
                          );
                        },
                      ),
              ),
              
              // Bottom summary and actions
              if (cart.isNotEmpty) ...[
                const Divider(height: 1),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardBackground : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Summary rows
                        _SummaryRow(
                          label: 'Subtotal',
                          value: currencyFormat.format(cart.subtotal),
                        ),
                        if (cart.totalDiscount > 0)
                          _SummaryRow(
                            label: 'Discount',
                            value: '-${currencyFormat.format(cart.totalDiscount)}',
                            valueColor: AppColors.success,
                          ),
                        // CGST and SGST breakdown
                        if (cart.taxAmount > 0) ...[
                          _SummaryRow(
                            label: 'CGST',
                            value: currencyFormat.format(cart.taxAmount / 2),
                          ),
                          _SummaryRow(
                            label: 'SGST',
                            value: currencyFormat.format(cart.taxAmount / 2),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              currencyFormat.format(cart.total),
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Action buttons
                        Row(
                          children: [
                            // Hold button
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: onHold,
                                icon: const Icon(Iconsax.pause_circle, size: 18),
                                label: const Text('Hold'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Checkout button
                            Expanded(
                              flex: 2,
                              child: FilledButton.icon(
                                onPressed: onCheckout,
                                icon: const Icon(Iconsax.card, size: 18),
                                label: const Text('Checkout'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
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
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    final isDark = context.isDarkMode;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceVariant : AppColors.grey100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Iconsax.shopping_cart,
              size: 48,
              color: isDark ? AppColors.darkTextTertiary : AppColors.grey400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Cart is empty',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap products to add them',
            style: TextStyle(
              color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  void _showClearConfirmation(BuildContext context, WidgetRef ref) {
    AlertService().showConfirm(
      context: context,
      title: 'Clear Cart?',
      text: 'This will remove all items from your cart.',
      confirmBtnText: 'Clear',
      confirmBtnColor: AppColors.error,
      onConfirmBtnTap: () {
        Navigator.pop(context); // Close the sheet
        ref.read(cartProvider.notifier).clearCart();
        onClear?.call();
      },
    );
  }
}

/// Individual cart item with swipe-to-delete
class _CartItemTile extends StatelessWidget {
  final CartItem item;
  final NumberFormat currencyFormat;
  final VoidCallback onDismissed;
  final ValueChanged<int> onQuantityChanged;

  const _CartItemTile({
    required this.item,
    required this.currencyFormat,
    required this.onDismissed,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    
    return Dismissible(
      key: Key(item.product.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismissed(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: AppColors.error,
        child: const Icon(Iconsax.trash, color: Colors.white),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Product image/icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceVariant : AppColors.grey100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: item.product.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        item.product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Iconsax.box,
                          color: isDark ? AppColors.darkTextTertiary : AppColors.grey400,
                        ),
                      ),
                    )
                  : Icon(Iconsax.box, color: isDark ? AppColors.darkTextTertiary : AppColors.grey400),
            ),
            const SizedBox(width: 12),
            
            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currencyFormat.format(item.product.price),
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            
            // Quantity controls
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceVariant : AppColors.grey100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _QuantityButton(
                    icon: item.quantity > 1 ? Iconsax.minus : Iconsax.trash,
                    onTap: () {
                      if (item.quantity > 1) {
                        onQuantityChanged(item.quantity - 1);
                      } else {
                        onDismissed();
                      }
                    },
                    isDestructive: item.quantity <= 1,
                  ),
                  Container(
                    constraints: const BoxConstraints(minWidth: 36),
                    alignment: Alignment.center,
                    child: Text(
                      '${item.quantity}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  _QuantityButton(
                    icon: Iconsax.add,
                    onTap: () => onQuantityChanged(item.quantity + 1),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Item total
            SizedBox(
              width: 70,
              child: Text(
                currencyFormat.format(item.total),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;

  const _QuantityButton({
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 18,
            color: isDestructive ? AppColors.error : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: valueColor ?? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
