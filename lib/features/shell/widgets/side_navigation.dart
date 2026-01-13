import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../screens/main_shell.dart';

class SideNavigation extends StatefulWidget {
  final List<NavItem> items;
  final String selectedId;
  final ValueChanged<String> onItemSelected;
  final bool inDrawer;

  const SideNavigation({
    super.key,
    required this.items,
    required this.selectedId,
    required this.onItemSelected,
    this.inDrawer = false,
  });

  @override
  State<SideNavigation> createState() => _SideNavigationState();
}

class _SideNavigationState extends State<SideNavigation> {
  bool _isCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final sidebarColor = isDark ? AppColors.darkBackground : AppColors.primary;
    
    return AnimatedContainer(
      duration: AppConstants.animationDuration,
      width: widget.inDrawer 
          ? null // Let drawer control width
          : (_isCollapsed
              ? AppConstants.sidebarCollapsedWidth
              : AppConstants.sidebarWidth),
      constraints: widget.inDrawer 
          ? null 
          : BoxConstraints(
              maxWidth: _isCollapsed 
                  ? AppConstants.sidebarCollapsedWidth 
                  : AppConstants.sidebarWidth,
            ),
      decoration: BoxDecoration(
        color: sidebarColor,
        border: isDark ? Border(right: BorderSide(color: AppColors.darkCardBorder)) : null,
        boxShadow: isDark ? null : const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: SafeArea(
        right: false,
        child: Column(
          children: [
            // Logo/Brand
            _buildHeader(),
            Divider(color: isDark ? AppColors.darkCardBorder : Colors.white12, height: 1),
            // Navigation Items
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: widget.items.length,
                itemBuilder: (context, index) {
                  final item = widget.items[index];
                  final isSelected = item.id == widget.selectedId;
                  return _buildNavItem(item, isSelected, index);
                },
              ),
            ),
            // Collapse Button - only show when not in drawer
            if (!widget.inDrawer) _buildCollapseButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final showExpanded = !_isCollapsed || widget.inDrawer;
    final isDark = context.isDarkMode;
    
    return Container(
      height: AppConstants.headerHeight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: isDark ? AppColors.darkPrimaryGradient : AppColors.accentGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.water_drop,
              color: isDark ? Colors.white : AppColors.primary,
              size: 24,
            ),
          ),
          if (showExpanded) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppConstants.appName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isDark ? AppColors.darkTextPrimary : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'POS System',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark ? AppColors.darkTextTertiary : Colors.white60,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavItem(NavItem item, bool isSelected, int index) {
    final showExpanded = !_isCollapsed || widget.inDrawer;
    final isDark = context.isDarkMode;
    
    // In dark mode, use different colors for better contrast
    final selectedBgColor = isDark 
        ? AppColors.primary.withValues(alpha: 0.3) 
        : Colors.white.withValues(alpha: 0.15);
    final iconColor = isSelected 
        ? (isDark ? AppColors.accent : AppColors.accent)
        : (isDark ? AppColors.darkTextSecondary : Colors.white70);
    final textColor = isSelected 
        ? (isDark ? AppColors.darkTextPrimary : Colors.white) 
        : (isDark ? AppColors.darkTextSecondary : Colors.white70);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onItemSelected(item.id),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: showExpanded ? 16 : 12,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: isSelected ? selectedBgColor : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected && isDark 
                  ? Border.all(color: AppColors.primary.withValues(alpha: 0.5))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? item.activeIcon : item.icon,
                  color: iconColor,
                  size: 22,
                ),
                if (showExpanded) ...[
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        color: textColor,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSelected)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
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

  Widget _buildCollapseButton() {
    final isDark = context.isDarkMode;
    
    return Container(
      padding: const EdgeInsets.all(12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _isCollapsed = !_isCollapsed),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark 
                  ? AppColors.darkSurfaceVariant 
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isCollapsed
                      ? Icons.keyboard_double_arrow_right
                      : Icons.keyboard_double_arrow_left,
                  color: isDark ? AppColors.darkTextSecondary : Colors.white70,
                  size: 20,
                ),
                if (!_isCollapsed) ...[
                  const SizedBox(width: 8),
                  Text(
                    'Collapse',
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextSecondary : Colors.white70,
                      fontSize: 13,
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
