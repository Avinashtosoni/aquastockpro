import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/models/category.dart';
import '../../../providers/products_provider.dart';

class CategorySidebar extends ConsumerWidget {
  final List<Category> categories;
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;

  const CategorySidebar({
    super.key,
    required this.categories,
    this.isCollapsed = false,
    this.onToggleCollapse,
  });

  IconData _getCategoryIcon(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName == 'all items' || lowerName == 'all') return Iconsax.element_4;
    if (lowerName.contains('feed')) return Iconsax.box;
    if (lowerName.contains('medicine')) return Iconsax.health;
    if (lowerName.contains('chemical')) return Iconsax.note_2;
    if (lowerName.contains('seed')) return Iconsax.stickynote;
    if (lowerName.contains('equipment')) return Iconsax.setting_2;
    return Iconsax.category;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final isDark = context.isDarkMode;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isCollapsed ? 60 : 140,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        border: Border(right: BorderSide(color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder)),
      ),
      child: Column(
        children: [
          // Header with collapse button
          if (onToggleCollapse != null)
            Container(
              padding: const EdgeInsets.all(8),
              child: IconButton(
                icon: Icon(
                  isCollapsed ? Iconsax.arrow_right_1 : Iconsax.arrow_left_2,
                  size: 20,
                  color: isDark ? AppColors.darkTextSecondary : null,
                ),
                onPressed: onToggleCollapse,
                tooltip: isCollapsed ? 'Expand' : 'Collapse',
              ),
            ),
          
          // Category List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = category.id == selectedCategory;
                final icon = _getCategoryIcon(category.name);

                return _CategoryItem(
                  name: category.name,
                  icon: icon,
                  isSelected: isSelected,
                  isCollapsed: isCollapsed,
                  isDark: isDark,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(selectedCategoryProvider.notifier).state = category.id;
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

class _CategoryItem extends StatelessWidget {
  final String name;
  final IconData icon;
  final bool isSelected;
  final bool isCollapsed;
  final bool isDark;
  final VoidCallback onTap;

  const _CategoryItem({
    required this.name,
    required this.icon,
    required this.isSelected,
    required this.isCollapsed,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isCollapsed ? 8 : 10,
        vertical: 2,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 8 : 12,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isSelected 
                  ? AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected 
                      ? (isDark ? AppColors.primaryLight : AppColors.primary)
                      : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        color: isSelected 
                            ? (isDark ? AppColors.primaryLight : AppColors.primary)
                            : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Compact category tabs for narrower screens
class CompactCategoryTabs extends ConsumerWidget {
  final List<Category> categories;

  const CompactCategoryTabs({super.key, required this.categories});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category.id == selectedCategory;

          return Padding(
            padding: EdgeInsets.only(
              right: 8,
              left: index == 0 ? 0 : 0,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref.read(selectedCategoryProvider.notifier).state = category.id;
                },
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.grey100,
                    borderRadius: BorderRadius.circular(20),
                    border: isSelected
                        ? null
                        : Border.all(color: AppColors.grey200),
                  ),
                  child: Text(
                    category.name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
