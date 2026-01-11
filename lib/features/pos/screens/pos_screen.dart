import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/alert_service.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../data/models/order.dart';
import '../../../data/models/product.dart';
import '../../../data/models/category.dart';
import '../../../data/models/customer.dart';
import '../../../providers/products_provider.dart';
import '../../../providers/categories_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/orders_provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/customers_provider.dart';
import '../widgets/product_grid.dart';
import '../widgets/cart_panel.dart';
import '../widgets/category_sidebar.dart';
import '../widgets/payment_dialog.dart';
import '../widgets/mobile_cart_sheet.dart';

class POSScreen extends ConsumerStatefulWidget {
  const POSScreen({super.key});

  @override
  ConsumerState<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends ConsumerState<POSScreen> with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late AnimationController _fabAnimController;
  late Animation<double> _fabScaleAnimation;
  int _previousItemCount = 0;
  bool _isSidebarCollapsed = false;

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _fabAnimController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fabAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final products = ref.watch(filteredProductsProvider);
    final categories = ref.watch(categoriesWithAllProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    // Animate FAB when items are added
    if (cart.itemCount > _previousItemCount && isMobile) {
      _fabAnimController.forward().then((_) => _fabAnimController.reverse());
      HapticFeedback.lightImpact();
    }
    _previousItemCount = cart.itemCount;

    if (isMobile) {
      return _buildMobileLayout(context, cart, products, categories);
    } else {
      return _buildDesktopLayout(context, cart, products, categories);
    }
  }

  // ==================== MOBILE LAYOUT ====================
  Widget _buildMobileLayout(
    BuildContext context,
    CartState cart,
    AsyncValue<List<Product>> products,
    AsyncValue<List<Category>> categories,
  ) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: Column(
        children: [
          // Branding header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            color: context.surfaceColor,
            child: Row(
              children: [
                // App Logo/Name
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Iconsax.shop, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                const Text(
                  'AquaStock Pro',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                // Scan button
                _MobileActionButton(
                  icon: Iconsax.scan_barcode,
                  onTap: () => _showBarcodeScannerPlaceholder(context),
                ),
              ],
            ),
          ),

          // Compact search bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            color: context.surfaceColor,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Scan barcode, enter SKU, or search...',
                  hintStyle: TextStyle(color: AppColors.grey400, fontSize: 14),
                  prefixIcon: Icon(Iconsax.search_normal, size: 20, color: AppColors.grey400),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Iconsax.close_circle5, size: 18, color: AppColors.grey400),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(productSearchQueryProvider.notifier).state = '';
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) {
                  ref.read(productSearchQueryProvider.notifier).state = value;
                  setState(() {}); // Update clear button
                },
              ),
            ),
          ),

          // Category chips - horizontal scroll
          Container(
            color: context.surfaceColor,
            child: categories.when(
              loading: () => SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: 6,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(right: 8, top: 4, bottom: 8),
                    child: SkeletonLoader(width: 80, height: 36, borderRadius: 20),
                  ),
                ),
              ),
              error: (e, s) => const SizedBox(height: 48),
              data: (cats) => SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: cats.length,
                  itemBuilder: (context, index) {
                    final cat = cats[index];
                    final isSelected = ref.watch(selectedCategoryProvider) == cat.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8, top: 4, bottom: 8),
                      child: _MobileCategoryChip(
                        label: cat.name,
                        isSelected: isSelected,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          ref.read(selectedCategoryProvider.notifier).state = cat.id;
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Product grid - main content
          Expanded(
            child: products.when(
              loading: () => const ProductGridSkeleton(itemCount: 6),
              error: (error, stack) => ErrorState(
                title: 'Failed to load products',
                subtitle: error.toString(),
                onRetry: () => ref.refresh(filteredProductsProvider),
              ),
              data: (productList) {
                if (productList.isEmpty) {
                  return EmptyState(
                    icon: Iconsax.box,
                    title: 'No products found',
                    subtitle: _searchController.text.isNotEmpty
                        ? 'Try a different search'
                        : 'Add products to start',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    // Trigger cloud sync and reload data
                    ref.invalidate(productsProvider);
                    ref.invalidate(filteredProductsProvider);
                    ref.invalidate(categoriesProvider);
                    ref.invalidate(categoriesWithAllProvider);
                    // Wait for providers to refresh
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: GridView.builder(
                    padding: EdgeInsets.fromLTRB(12, 12, 12, cart.isEmpty ? 12 : 90),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.82,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: productList.length,
                    itemBuilder: (context, index) {
                      final product = productList[index];
                      return _MobileProductCard(
                        product: product,
                        onTap: () => _addToCart(product),
                      );
                    },
                  ),
                );
              },
            ),
          ),

          // Horizontal Cart Bar at bottom
          if (cart.isNotEmpty)
            ScaleTransition(
              scale: _fabScaleAnimation,
              child: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showMobileCart(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          // Cart icon with badge
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Iconsax.shopping_cart5, color: Colors.white, size: 22),
                              ),
                              Positioned(
                                right: -4,
                                top: -4,
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: Text(
                                    '${cart.itemCount}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          // Items info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${cart.itemCount} ${cart.itemCount == 1 ? 'Item' : 'Items'}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '₹${cart.total.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // View Cart button
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'View Cart',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Iconsax.arrow_right_3, size: 16, color: AppColors.primary),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==================== DESKTOP LAYOUT ====================
  Widget _buildDesktopLayout(
    BuildContext context,
    CartState cart,
    AsyncValue<List<Product>> products,
    AsyncValue<List<Category>> categories,
  ) {
    final productCount = products.whenData((list) => list.length).valueOrNull ?? 0;

    return Row(
      children: [
        // Category Sidebar (Left)
        categories.when(
          loading: () => Container(
            width: 140,
            color: context.surfaceColor,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: List.generate(6, (i) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SkeletonLoader(height: 40, borderRadius: 8),
              )),
            ),
          ),
          error: (e, s) => const SizedBox(width: 140),
          data: (cats) => CategorySidebar(
            categories: cats,
            isCollapsed: _isSidebarCollapsed,
            onToggleCollapse: () {
              setState(() => _isSidebarCollapsed = !_isSidebarCollapsed);
            },
          ),
        ),

        // Product Section (Center)
        Expanded(
          flex: 3,
          child: Container(
            color: context.backgroundColor,
            child: Column(
              children: [
                // Search Bar with count
                Container(
                  padding: const EdgeInsets.all(16),
                  color: context.surfaceColor,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: context.isDarkMode ? AppColors.darkSurfaceVariant : AppColors.grey100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: context.cardBorderColor),
                              ),
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Scan barcode, enter SKU, or search product...',
                                  hintStyle: TextStyle(color: AppColors.grey400, fontSize: 14),
                                  prefixIcon: Icon(Iconsax.search_normal, size: 20, color: AppColors.grey400),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: Icon(Iconsax.close_circle5, size: 18, color: AppColors.grey400),
                                          onPressed: () {
                                            _searchController.clear();
                                            ref.read(productSearchQueryProvider.notifier).state = '';
                                            setState(() {});
                                          },
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                                onChanged: (value) {
                                  ref.read(productSearchQueryProvider.notifier).state = value;
                                  setState(() {});
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Barcode Scanner Button
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.grey100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.grey200),
                            ),
                            child: IconButton(
                              icon: const Icon(Iconsax.scan_barcode),
                              onPressed: () => _showBarcodeScannerPlaceholder(context),
                              tooltip: 'Scan Barcode',
                              padding: const EdgeInsets.all(12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Filter info row
                      Row(
                        children: [
                          Text(
                            'Press ',
                            style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.grey100,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.grey200),
                            ),
                            child: Text(
                              'Enter',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            ' to add exact match',
                            style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                          ),
                          const Spacer(),
                          Text(
                            '$productCount items found',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Product Grid
                Expanded(
                  child: products.when(
                    loading: () => const ProductGridSkeleton(itemCount: 12),
                    error: (error, stack) => ErrorState(
                      title: 'Failed to load products',
                      subtitle: error.toString(),
                      onRetry: () => ref.refresh(filteredProductsProvider),
                    ),
                    data: (productList) {
                      if (productList.isEmpty) {
                        return EmptyState(
                          icon: Iconsax.box,
                          title: 'No products found',
                          subtitle: _searchController.text.isNotEmpty
                              ? 'Try a different search term'
                              : 'Add products to get started',
                        );
                      }
                      return ProductGrid(
                        products: productList,
                        onProductTap: (product) => _addToCart(product),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // Cart Section (Right)
        Container(
          width: 380,
          decoration: BoxDecoration(
            color: context.isDarkMode ? AppColors.darkSurface : AppColors.white,
            border: Border(left: BorderSide(color: context.isDarkMode ? AppColors.darkCardBorder : AppColors.cardBorder)),
          ),
          child: CartPanel(
            cart: cart,
            onCheckout: cart.isEmpty ? null : () => _showPaymentDialog(context, ref),
            onHold: cart.isEmpty ? null : () => _holdOrder(ref),
            onClear: cart.isEmpty ? null : () => _clearCart(ref),
          ),
        ),
      ],
    );
  }

  // ==================== SHARED METHODS ====================
  void _addToCart(dynamic product) {
    if (product.trackInventory && product.stockQuantity <= 0) {
      HapticFeedback.heavyImpact();
      AlertService().showError(
        context: context,
        title: 'Out of Stock',
        text: '${product.name} is currently out of stock.',
      );
      return;
    }
    HapticFeedback.lightImpact();
    ref.read(cartProvider.notifier).addProduct(product);
  }

  void _showMobileCart(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MobileCartSheet(
        onCheckout: () {
          Navigator.pop(context);
          _showPaymentDialog(context, ref);
        },
        onHold: () {
          Navigator.pop(context);
          _holdOrder(ref);
        },
        onClear: () {
          // Already handled in sheet
        },
      ),
    );
  }

  void _showBarcodeScannerPlaceholder(BuildContext context) {
    // Show barcode scanner dialog
    showDialog(
      context: context,
      builder: (ctx) => _BarcodeScannerDialog(
        onBarcodeScanned: (barcode) {
          Navigator.pop(ctx);
          _findAndAddProductByBarcode(barcode);
        },
      ),
    );
  }

  void _findAndAddProductByBarcode(String barcode) {
    final products = ref.read(productsNotifierProvider).valueOrNull ?? [];
    
    // Find product by barcode or SKU - case insensitive
    Product? foundProduct;
    for (final p in products) {
      if ((p.sku?.toLowerCase() == barcode.toLowerCase()) || 
          (p.barcode?.toLowerCase() == barcode.toLowerCase())) {
        foundProduct = p;
        break;
      }
    }

    if (foundProduct != null) {
      _addToCart(foundProduct);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${foundProduct.name} to cart'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Product not found for barcode: $barcode'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showPaymentDialog(BuildContext context, WidgetRef ref) {
    final cart = ref.read(cartProvider);
    
    // Read customer directly from selectedCustomerProvider (used by CartPanel)
    final selectedCustomer = ref.read(selectedCustomerProvider);
    debugPrint('PaymentDialog: Selected customer = ${selectedCustomer?.name ?? "null"}');
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentDialog(
        cart: cart,
        selectedCustomer: selectedCustomer,
        onPaymentComplete: (order) async {
          await _saveOrder(ref, order);
        },
      ),
    );
  }

  Future<void> _saveOrder(WidgetRef ref, Order order) async {
    final cart = ref.read(cartProvider);
    final ordersNotifier = ref.read(ordersNotifierProvider.notifier);
    final productsNotifier = ref.read(productsNotifierProvider.notifier);

    try {
      await ordersNotifier.createOrder(order);

      for (final item in cart.items) {
        if (item.product.trackInventory) {
          await productsNotifier.updateStock(item.product.id, -item.quantity);
        }
      }

      // Update customer stats if customer is linked
      if (order.customerId != null && order.customerId!.isNotEmpty) {
        try {
          final customerRepo = ref.read(customerRepositoryProvider);
          await customerRepo.updatePurchaseStats(
            order.customerId!,
            order.totalAmount,
          );
          // Refresh customer providers
          ref.invalidate(customersNotifierProvider);
          ref.invalidate(customersProvider);
        } catch (e) {
          // Log error but don't fail the order save
          debugPrint('Failed to update customer stats: $e');
        }
      }

      ref.read(cartProvider.notifier).clearCart();
      
      // Reset selected customer for next order
      ref.read(selectedCustomerProvider.notifier).state = null;
      
      // Refresh dashboard stats and orders list
      ref.invalidate(dashboardStatsProvider);
      ref.invalidate(todayStatsProvider);
      ref.invalidate(todaysOrdersProvider);
      ref.invalidate(recentOrdersProvider);
      ref.invalidate(ordersProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving order: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _holdOrder(WidgetRef ref) {
    final cart = ref.read(cartProvider);
    final heldOrders = ref.read(heldOrdersProvider);
    ref.read(heldOrdersProvider.notifier).state = [...heldOrders, cart];
    ref.read(cartProvider.notifier).clearCart();
    
    HapticFeedback.mediumImpact();
    AlertService().showSuccess(
      context: context,
      title: 'Order on Hold',
      text: 'Your order has been saved. You can retrieve it anytime.',
      autoCloseDuration: true,
    );
  }

  void _clearCart(WidgetRef ref) {
    AlertService().showConfirm(
      context: context,
      title: 'Clear Cart?',
      text: 'Are you sure you want to remove all items from the cart?',
      confirmBtnText: 'Clear',
      confirmBtnColor: AppColors.error,
      onConfirmBtnTap: () {
        ref.read(cartProvider.notifier).clearCart();
      },
    );
  }
}

// ==================== MOBILE WIDGETS ====================

class _MobileActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MobileActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.grey100,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Icon(icon, size: 22, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _MobileCategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _MobileCategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    
    return Material(
      color: isSelected ? AppColors.primary : (isDark ? AppColors.darkSurfaceVariant : AppColors.grey100),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileProductCard extends StatelessWidget {
  final dynamic product;
  final VoidCallback onTap;

  const _MobileProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isOutOfStock = product.trackInventory && product.stockQuantity <= 0;
    final isLowStock = product.isLowStock;
    final unit = product.unit ?? 'Pc';
    final isDark = context.isDarkMode;
    
    return Material(
      color: isDark ? AppColors.darkCardBackground : Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      shadowColor: isDark ? Colors.black38 : Colors.black12,
      child: InkWell(
        onTap: isOutOfStock ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Opacity(
          opacity: isOutOfStock ? 0.5 : 1.0,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceVariant : AppColors.grey100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: product.imageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    product.imageUrl!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    errorBuilder: (context, error, stackTrace) => Icon(
                                      Iconsax.box,
                                      size: 40,
                                      color: isDark ? AppColors.darkTextTertiary : AppColors.grey400,
                                    ),
                                  ),
                                )
                              : Icon(Iconsax.box, size: 40, color: isDark ? AppColors.darkTextTertiary : AppColors.grey400),
                        ),
                        if (isOutOfStock)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Out of Stock',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                        else if (product.trackInventory)
                          Positioned(
                            bottom: 6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isLowStock ? AppColors.warning : AppColors.success,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${product.stockQuantity} $unit',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Product name
                Text(
                  product.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Price with unit
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '₹${product.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      TextSpan(
                        text: ' / $unit',
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== BARCODE SCANNER DIALOG ====================
class _BarcodeScannerDialog extends StatefulWidget {
  final Function(String) onBarcodeScanned;

  const _BarcodeScannerDialog({required this.onBarcodeScanned});

  @override
  State<_BarcodeScannerDialog> createState() => _BarcodeScannerDialogState();
}

class _BarcodeScannerDialogState extends State<_BarcodeScannerDialog> {
  final _manualController = TextEditingController();
  MobileScannerController? _cameraController;
  bool _isScanning = true;
  String? _lastScanned;

  @override
  void initState() {
    super.initState();
    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _manualController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 350,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Iconsax.scan_barcode, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Scan Barcode',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Camera preview
            if (_isScanning)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.grey200),
                ),
                clipBehavior: Clip.antiAlias,
                child: MobileScanner(
                  controller: _cameraController,
                  onDetect: (capture) {
                    final barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty && _lastScanned != barcodes.first.rawValue) {
                      final barcode = barcodes.first.rawValue;
                      if (barcode != null) {
                        setState(() {
                          _lastScanned = barcode;
                          _isScanning = false;
                        });
                        HapticFeedback.mediumImpact();
                        widget.onBarcodeScanned(barcode);
                      }
                    }
                  },
                ),
              ),

            const SizedBox(height: 16),
            
            // Divider with OR
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('OR', style: TextStyle(color: AppColors.textSecondary)),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 16),

            // Manual entry
            TextField(
              controller: _manualController,
              decoration: InputDecoration(
                hintText: 'Enter barcode manually...',
                prefixIcon: const Icon(Iconsax.keyboard, size: 20),
                filled: true,
                fillColor: AppColors.grey100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) widget.onBarcodeScanned(value);
              },
            ),
            const SizedBox(height: 16),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  if (_manualController.text.isNotEmpty) {
                    widget.onBarcodeScanned(_manualController.text);
                  }
                },
                icon: const Icon(Iconsax.search_normal, size: 18),
                label: const Text('Find Product'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
