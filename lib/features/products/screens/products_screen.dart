import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../data/models/product.dart';
import '../../../providers/products_provider.dart';
import '../../../providers/categories_provider.dart';
import '../widgets/adjust_stock_dialog.dart';
import 'product_form_screen.dart';

// Search query state provider
final _productSearchQueryProvider = StateProvider<String>((ref) => '');
final _selectedCategoryProvider = StateProvider<String?>((ref) => null);

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  Future<void> _onRefresh(WidgetRef ref) async {
    await ref.read(productsNotifierProvider.notifier).loadProducts();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsNotifierProvider);
    final categoriesAsync = ref.watch(categoriesNotifierProvider);
    final searchQuery = ref.watch(_productSearchQueryProvider);
    final selectedCategory = ref.watch(_selectedCategoryProvider);
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced Header
          _buildHeader(context, ref, isDark, isMobile),
          SizedBox(height: isMobile ? 16 : 20),
          
          // Search & Filter Row
          _buildSearchFilterRow(context, ref, categoriesAsync, isDark, isMobile),
          SizedBox(height: isMobile ? 12 : 16),
          
          // Products Table/List
          Expanded(
            child: productsAsync.when(
              loading: () => const LoadingIndicator(message: 'Loading products...'),
              error: (e, s) => ErrorState(
                title: 'Failed to load products',
                subtitle: e.toString(),
                onRetry: () => ref.read(productsNotifierProvider.notifier).loadProducts(),
              ),
              data: (products) {
                // Filter products
                var filteredProducts = products.where((p) {
                  // Search filter
                  if (searchQuery.isNotEmpty) {
                    final query = searchQuery.toLowerCase();
                    if (!p.name.toLowerCase().contains(query) &&
                        !(p.sku?.toLowerCase().contains(query) ?? false) &&
                        !(p.barcode?.toLowerCase().contains(query) ?? false) &&
                        !(p.batchNumber?.toLowerCase().contains(query) ?? false)) {
                      return false;
                    }
                  }
                  // Category filter
                  if (selectedCategory != null && p.categoryId != selectedCategory) {
                    return false;
                  }
                  return true;
                }).toList();

                if (filteredProducts.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () => _onRefresh(ref),
                    child: ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.4,
                          child: EmptyState(
                            icon: Iconsax.box,
                            title: searchQuery.isNotEmpty ? 'No products found' : 'No products yet',
                            subtitle: searchQuery.isNotEmpty 
                                ? 'Try a different search term' 
                                : 'Add products to start selling',
                            actionLabel: searchQuery.isEmpty ? 'Add Product' : null,
                            onAction: searchQuery.isEmpty ? () => _showProductForm(context) : null,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return RefreshIndicator(
                  onRefresh: () => _onRefresh(ref),
                  child: isMobile
                      ? _buildMobileList(context, ref, filteredProducts, currencyFormat, isDark)
                      : _buildDesktopTable(context, ref, filteredProducts, currencyFormat, isDark),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, bool isDark, bool isMobile) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Inventory Management',
                style: TextStyle(
                  fontSize: isMobile ? 20 : 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Track stock, expiry dates, and batches.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white54 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (!isMobile) ...[
          OutlinedButton.icon(
            onPressed: () {
              // TODO: Share re-order list
            },
            icon: const Icon(Iconsax.share, size: 18),
            label: const Text('Share Re-order List'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(width: 12),
        ],
        AppButton(
          label: isMobile ? '' : 'Add Product',
          icon: Iconsax.add,
          onPressed: () => _showProductForm(context),
        ),
      ],
    );
  }

  Widget _buildSearchFilterRow(BuildContext context, WidgetRef ref, 
      AsyncValue categoriesAsync, bool isDark, bool isMobile) {
    final categories = categoriesAsync.valueOrNull ?? [];
    final selectedCategory = ref.watch(_selectedCategoryProvider);

    return Row(
      children: [
        // Search
        Expanded(
          child: SizedBox(
            height: 44,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or batch number...',
                prefixIcon: const Icon(Iconsax.search_normal, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.grey200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.grey200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
              ),
              onChanged: (value) => ref.read(_productSearchQueryProvider.notifier).state = value,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Filter icon
        IconButton(
          onPressed: () {},
          icon: const Icon(Iconsax.filter),
          style: IconButton.styleFrom(
            backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.grey100,
          ),
        ),
        const SizedBox(width: 8),
        // Category dropdown
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? Colors.white12 : AppColors.grey200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: selectedCategory,
              hint: const Text('All Categories'),
              icon: const Icon(Icons.keyboard_arrow_down),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('All Categories')),
                ...categories.map((c) => DropdownMenuItem<String?>(value: c.id, child: Text(c.name))),
              ],
              onChanged: (value) => ref.read(_selectedCategoryProvider.notifier).state = value,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopTable(BuildContext context, WidgetRef ref, 
      List<Product> products, NumberFormat currencyFormat, bool isDark) {
    final categoriesAsync = ref.watch(categoriesNotifierProvider);
    final categories = categoriesAsync.valueOrNull ?? [];
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.grey200),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.03) : AppColors.grey50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                SizedBox(width: 50, child: _tableHeaderText('IMAGE')),
                const SizedBox(width: 12),
                Expanded(flex: 3, child: _tableHeaderText('PRODUCT NAME')),
                Expanded(flex: 2, child: _tableHeaderText('CATEGORY')),
                Expanded(flex: 2, child: _tableHeaderText('BATCH / EXPIRY')),
                Expanded(flex: 2, child: _tableHeaderText('PRICE')),
                Expanded(flex: 2, child: _tableHeaderText('STOCK')),
                Expanded(flex: 2, child: _tableHeaderText('STATUS')),
                SizedBox(width: 130, child: _tableHeaderText('ACTIONS')),
              ],
            ),
          ),
          Divider(height: 1, color: isDark ? Colors.white12 : AppColors.grey200),
          // Table Body
          Expanded(
            child: ListView.separated(
              itemCount: products.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.grey100),
              itemBuilder: (context, index) {
                final product = products[index];
                final category = categories.where((c) => c.id == product.categoryId).firstOrNull;
                
                return _buildTableRow(context, ref, product, category?.name ?? 'Unknown', currencyFormat, isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableHeaderText(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }



  Widget _buildTableRow(BuildContext context, WidgetRef ref, Product product, 
      String categoryName, NumberFormat currencyFormat, bool isDark) {
    final dateFormat = DateFormat('dd MMM yy');
    
    return InkWell(
      onTap: () => _showProductForm(context, product: product),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Image
            SizedBox(
              width: 50,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.grey100,
                  borderRadius: BorderRadius.circular(8),
                  image: product.imageUrl != null
                      ? DecorationImage(image: NetworkImage(product.imageUrl!), fit: BoxFit.cover)
                      : null,
                ),
                child: product.imageUrl == null
                    ? Icon(Iconsax.image, color: isDark ? Colors.white30 : AppColors.grey400, size: 18)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            // Product Name
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (product.brand != null)
                    Text(product.brand!, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : AppColors.textSecondary), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            // Category Badge
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                child: Text(categoryName, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.primary), overflow: TextOverflow.ellipsis),
              ),
            ),
            // Batch / Expiry
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.batchNumber ?? '-',
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (product.expiryDate != null)
                    Text(
                      dateFormat.format(product.expiryDate!),
                      style: TextStyle(
                        fontSize: 11,
                        color: product.isExpired ? AppColors.error : (product.isExpiringSoon ? AppColors.warning : (isDark ? Colors.white38 : AppColors.grey500)),
                      ),
                    ),
                ],
              ),
            ),
            // Price
            Expanded(
              flex: 2,
              child: Text(
                '${currencyFormat.format(product.price)}/${product.unit}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Stock
            Expanded(
              flex: 2,
              child: Text(
                '${product.stockQuantity} ${product.unit}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? Colors.white : AppColors.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Status
            Expanded(
              flex: 2,
              child: _buildStatusBadge(product, isDark),
            ),
            // Actions
            SizedBox(
              width: 130,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _showProductForm(context, product: product),
                    icon: const Icon(Iconsax.edit_2, size: 16),
                    style: IconButton.styleFrom(backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.grey100, padding: const EdgeInsets.all(8)),
                    tooltip: 'Edit',
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: TextButton(
                      onPressed: () => _showAdjustStockDialog(context, ref, product),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6), side: BorderSide(color: isDark ? Colors.white12 : AppColors.grey200)),
                      ),
                      child: Text('Adjust', style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : AppColors.textPrimary)),
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

  Widget _buildStatusBadge(Product product, bool isDark) {
    Color color;
    String label;
    
    if (product.isOutOfStock) {
      color = AppColors.error;
      label = 'Out of Stock';
    } else if (product.isLowStock) {
      color = AppColors.warning;
      label = 'Low Stock';
    } else {
      color = AppColors.success;
      label = 'In Stock';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildMobileList(BuildContext context, WidgetRef ref, 
      List<Product> products, NumberFormat currencyFormat, bool isDark) {
    final categoriesAsync = ref.watch(categoriesNotifierProvider);
    final categories = categoriesAsync.valueOrNull ?? [];

    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final category = categories.where((c) => c.id == product.categoryId).firstOrNull;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardBackground : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.grey200),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.grey100,
                borderRadius: BorderRadius.circular(10),
                image: product.imageUrl != null
                    ? DecorationImage(image: NetworkImage(product.imageUrl!), fit: BoxFit.cover)
                    : null,
              ),
              child: product.imageUrl == null 
                  ? Icon(Iconsax.box, color: isDark ? Colors.white30 : AppColors.grey400)
                  : null,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    product.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
                _buildStatusBadge(product, isDark),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        category?.name ?? 'Unknown',
                        style: TextStyle(fontSize: 10, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      currencyFormat.format(product.price),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Stock: ${product.stockQuantity} ${product.unit}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            onTap: () => _showProductForm(context, product: product),
            trailing: IconButton(
              onPressed: () => _showAdjustStockDialog(context, ref, product),
              icon: const Icon(Iconsax.setting_4),
              tooltip: 'Adjust Stock',
            ),
          ),
        );
      },
    );
  }

  void _showProductForm(BuildContext context, {Product? product}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ProductFormScreen(product: product),
    );
  }

  void _showAdjustStockDialog(BuildContext context, WidgetRef ref, Product product) {
    showDialog(
      context: context,
      builder: (context) => AdjustStockDialog(
        product: product,
        onUpdate: (quantity, type, reason) async {
          Navigator.pop(context);
          
          int newStock = product.stockQuantity;
          if (type == 'in') {
            newStock += quantity;
          } else if (type == 'out' || type == 'transfer') {
            newStock -= quantity;
          }
          
          await ref.read(productsNotifierProvider.notifier).updateProduct(
            product.copyWith(stockQuantity: newStock),
          );
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Stock updated: ${product.name} now has $newStock ${product.unit}'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
      ),
    );
  }
}
