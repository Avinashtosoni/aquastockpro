import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../data/models/category.dart';
import '../../../providers/categories_provider.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  Future<void> _onRefresh(WidgetRef ref) async {
    await ref.read(categoriesNotifierProvider.notifier).loadCategories();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesNotifierProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - Responsive layout
          if (isMobile) ...[
            // Mobile: Title and icon button
            Row(
              children: [
                Expanded(
                  child: Text('Categories', style: Theme.of(context).textTheme.headlineSmall),
                ),
                IconButton(
                  onPressed: () => _showCategoryDialog(context, ref),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Iconsax.add, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Organize your products into categories',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ] else ...[
            // Desktop: Title and button on same line
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Categories', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 4),
                      Text(
                        'Organize your products into categories',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                AppButton(
                  label: 'Add Category',
                  icon: Iconsax.add,
                  onPressed: () => _showCategoryDialog(context, ref),
                ),
              ],
            ),
          ],
          SizedBox(height: isMobile ? 16 : 24),
          
          // Categories Grid/List
          Expanded(
            child: categoriesAsync.when(
              loading: () => const LoadingIndicator(message: 'Loading categories...'),
              error: (e, s) => ErrorState(
                title: 'Failed to load categories',
                subtitle: e.toString(),
                onRetry: () => ref.read(categoriesNotifierProvider.notifier).loadCategories(),
              ),
              data: (categories) {
                if (categories.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () => _onRefresh(ref),
                    child: ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.4,
                          child: EmptyState(
                            icon: Iconsax.category,
                            title: 'No categories yet',
                            subtitle: 'Add categories to organize your products',
                            actionLabel: 'Add Category',
                            onAction: () => _showCategoryDialog(context, ref),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => _onRefresh(ref),
                  child: isMobile 
                      ? _buildMobileList(context, ref, categories)
                      : _buildDesktopGrid(context, ref, categories),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileList(BuildContext context, WidgetRef ref, List<Category> categories) {
    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Iconsax.category, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name, 
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (category.description != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          category.description!, 
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                          maxLines: 1, 
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton(
                  icon: const Icon(Iconsax.more, size: 18),
                  padding: EdgeInsets.zero,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      onTap: () => _showCategoryDialog(context, ref, category: category),
                      child: const Row(children: [Icon(Iconsax.edit, size: 18), SizedBox(width: 8), Text('Edit')]),
                    ),
                    PopupMenuItem(
                      onTap: () => _deleteCategory(context, ref, category),
                      child: const Row(children: [Icon(Iconsax.trash, size: 18, color: AppColors.error), SizedBox(width: 8), Text('Delete', style: TextStyle(color: AppColors.error))]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopGrid(BuildContext context, WidgetRef ref, List<Category> categories) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        childAspectRatio: 1.3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _CategoryCard(
          category: category,
          onEdit: () => _showCategoryDialog(context, ref, category: category),
          onDelete: () => _deleteCategory(context, ref, category),
        );
      },
    );
  }

  void _showCategoryDialog(BuildContext context, WidgetRef ref, {Category? category}) {
    final nameController = TextEditingController(text: category?.name ?? '');
    final descController = TextEditingController(text: category?.description ?? '');
    final isEditing = category != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Category' : 'Add Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(label: 'Name', hint: 'Category name', controller: nameController),
            const SizedBox(height: 16),
            AppTextField(label: 'Description', hint: 'Optional description', controller: descController, maxLines: 2),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;
              final newCategory = Category(
                id: category?.id,
                name: nameController.text,
                description: descController.text.isEmpty ? null : descController.text,
                sortOrder: category?.sortOrder ?? 0,
              );
              final notifier = ref.read(categoriesNotifierProvider.notifier);
              try {
                if (isEditing) {
                  await notifier.updateCategory(newCategory);
                } else {
                  await notifier.addCategory(newCategory);
                }
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: Text(isEditing ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _deleteCategory(BuildContext context, WidgetRef ref, Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(categoriesNotifierProvider.notifier).deleteCategory(category.id);
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryCard({required this.category, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Iconsax.category, color: AppColors.primary, size: 20),
              ),
              const Spacer(),
              PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(onTap: onEdit, child: const Row(children: [Icon(Iconsax.edit, size: 18), SizedBox(width: 8), Text('Edit')])),
                  PopupMenuItem(onTap: onDelete, child: const Row(children: [Icon(Iconsax.trash, size: 18, color: AppColors.error), SizedBox(width: 8), Text('Delete', style: TextStyle(color: AppColors.error))])),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(category.name, style: Theme.of(context).textTheme.titleMedium),
          if (category.description != null) ...[
            const SizedBox(height: 4),
            Text(category.description!, style: Theme.of(context).textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }
}
