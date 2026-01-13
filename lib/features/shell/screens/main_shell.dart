import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/models/permission.dart';
import '../../../providers/permissions_provider.dart';
import '../../../providers/products_provider.dart';
import '../../../providers/categories_provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../widgets/side_navigation.dart';
import '../widgets/app_header.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../pos/screens/pos_screen.dart';
import '../../products/screens/products_screen.dart';
import '../../categories/screens/categories_screen.dart';
import '../../orders/screens/orders_screen.dart';
import '../../customers/screens/customers_screen.dart';

import '../../employees/screens/employees_screen.dart';
import '../../suppliers/screens/suppliers_screen.dart';
import '../../reports/screens/reports_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../quotations/screens/quotations_screen.dart';
import '../../payments/screens/payments_screen.dart';

// Screen size breakpoints
class ScreenBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
  
  static bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < mobile;
  static bool isTablet(BuildContext context) => MediaQuery.of(context).size.width >= mobile && MediaQuery.of(context).size.width < tablet;
  static bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= tablet;
}

// Navigation items for the sidebar
class NavItem {
  final String id;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Permission? requiredPermission; // Permission required to see this item

  const NavItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.requiredPermission,
  });
}

final navItems = [
  const NavItem(
    id: 'dashboard',
    label: 'Dashboard',
    icon: Iconsax.home,
    activeIcon: Iconsax.home_15,
    requiredPermission: Permission.viewDashboard,
  ),
  const NavItem(
    id: 'pos',
    label: 'POS',
    icon: Iconsax.calculator,
    activeIcon: Iconsax.calculator5,
    requiredPermission: Permission.accessPOS,
  ),
  const NavItem(
    id: 'products',
    label: 'Products',
    icon: Iconsax.box,
    activeIcon: Iconsax.box5,
    requiredPermission: Permission.viewProducts,
  ),
  const NavItem(
    id: 'categories',
    label: 'Categories',
    icon: Iconsax.category,
    activeIcon: Iconsax.category5,
    requiredPermission: Permission.viewCategories,
  ),
  const NavItem(
    id: 'orders',
    label: 'Orders',
    icon: Iconsax.receipt,
    activeIcon: Iconsax.receipt_25,
    requiredPermission: Permission.viewOrders,
  ),
  const NavItem(
    id: 'customers',
    label: 'Customers',
    icon: Iconsax.people,
    activeIcon: Iconsax.people5,
    requiredPermission: Permission.viewCustomers,
  ),
  const NavItem(
    id: 'payments',
    label: 'Payments',
    icon: Iconsax.wallet_money,
    activeIcon: Iconsax.wallet_money,
    requiredPermission: Permission.viewPayments,
  ),
  const NavItem(
    id: 'quotations',
    label: 'Quotations',
    icon: Iconsax.document_text,
    activeIcon: Iconsax.document_text_1,
    requiredPermission: Permission.viewQuotations,
  ),
  const NavItem(
    id: 'employees',
    label: 'Employees',
    icon: Iconsax.user_octagon,
    activeIcon: Iconsax.user_octagon5,
    requiredPermission: Permission.viewEmployees,
  ),
  const NavItem(
    id: 'suppliers',
    label: 'Suppliers',
    icon: Iconsax.truck_fast,
    activeIcon: Iconsax.truck_fast,
    requiredPermission: Permission.viewSuppliers,
  ),
  const NavItem(
    id: 'reports',
    label: 'Reports',
    icon: Iconsax.chart,
    activeIcon: Iconsax.chart_15,
    requiredPermission: Permission.viewBasicReports,
  ),
  const NavItem(
    id: 'settings',
    label: 'Settings',
    icon: Iconsax.setting,
    activeIcon: Iconsax.setting5,
    requiredPermission: Permission.viewSettings,
  ),
];

// Bottom navigation order: Dashboard, Orders, POS, Payments, Settings
const bottomNavOrder = ['dashboard', 'orders', 'pos', 'payments', 'settings'];

final selectedNavItemProvider = StateProvider<String>((ref) => 'dashboard');

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Prefetch data for faster screen loads
    _prefetchData();
  }

  void _prefetchData() {
    // Trigger all critical data providers in parallel
    // This preloads data while user is on dashboard
    ref.read(productsProvider);
    ref.read(categoriesProvider);
    ref.read(categoriesWithAllProvider);
    ref.read(dashboardStatsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final selectedItem = ref.watch(selectedNavItemProvider);
    final userPermissions = ref.watch(currentUserPermissionsProvider);
    
    // Filter items based on user permissions
    final filteredItems = userPermissions.maybeWhen(
      data: (permissions) => navItems.where((item) =>
        item.requiredPermission == null || permissions.contains(item.requiredPermission)
      ).toList(),
      orElse: () => navItems.where((item) => item.requiredPermission == null).toList(),
    );
    
    final isMobile = ScreenBreakpoints.isMobile(context);
    final isDesktop = ScreenBreakpoints.isDesktop(context);

    return PopScope(
      canPop: false, // Prevent app from closing
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // On back gesture/button, go to previous screen or dashboard
        _handleBackNavigation(filteredItems);
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: context.backgroundColor,
        // Drawer for mobile/tablet
        drawer: isMobile || !isDesktop
            ? Drawer(
                child: SideNavigation(
                  items: filteredItems,
                  selectedId: selectedItem,
                  onItemSelected: (id) {
                    ref.read(selectedNavItemProvider.notifier).state = id;
                    Navigator.pop(context); // Close drawer
                  },
                  inDrawer: true,
                ),
              )
            : null,
        // Bottom navigation for mobile
        bottomNavigationBar: isMobile && filteredItems.isNotEmpty
            ? _MobileBottomNav(
                items: bottomNavOrder
                    .map((id) => filteredItems.firstWhere(
                          (item) => item.id == id,
                          orElse: () => filteredItems.first,
                        ))
                    .where((item) => filteredItems.contains(item))
                    .toList(),
                selectedId: selectedItem,
                onItemSelected: (id) {
                  ref.read(selectedNavItemProvider.notifier).state = id;
                },
                onMorePressed: () => _scaffoldKey.currentState?.openDrawer(),
              )
            : null,
        body: Row(
          children: [
            // Side Navigation - only show on desktop
            if (isDesktop)
              SideNavigation(
                items: filteredItems,
                selectedId: selectedItem,
                onItemSelected: (id) {
                  ref.read(selectedNavItemProvider.notifier).state = id;
                },
              ),
            // Main Content
            Expanded(
              child: SafeArea(
                bottom: false, // Bottom is handled by bottom nav bar
                child: Column(
                  children: [
                    // Header
                    AppHeader(
                      showMenuButton: !isDesktop,
                      onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    ),
                    // Content with swipe navigation
                    Expanded(
                      child: GestureDetector(
                        onHorizontalDragEnd: (details) {
                          // Swipe sensitivity threshold
                          const sensitivity = 300.0;
                          
                          if (details.primaryVelocity == null) return;
                          
                          // Right swipe (go to previous screen)
                          if (details.primaryVelocity! > sensitivity) {
                            _navigateToPrevious(filteredItems);
                          }
                          // Left swipe (go to next screen)
                          else if (details.primaryVelocity! < -sensitivity) {
                            _navigateToNext(filteredItems);
                          }
                        },
                        child: _buildContent(selectedItem),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleBackNavigation(List<NavItem> items) {
    final currentId = ref.read(selectedNavItemProvider);
    final currentIndex = items.indexWhere((item) => item.id == currentId);
    
    // If already on first screen (dashboard), do nothing (don't close app)
    if (currentIndex <= 0) {
      return;
    }
    
    // Otherwise, go to previous screen
    ref.read(selectedNavItemProvider.notifier).state = items[currentIndex - 1].id;
  }

  void _navigateToPrevious(List<NavItem> items) {
    final currentId = ref.read(selectedNavItemProvider);
    final currentIndex = items.indexWhere((item) => item.id == currentId);
    
    if (currentIndex > 0) {
      ref.read(selectedNavItemProvider.notifier).state = items[currentIndex - 1].id;
    }
  }

  void _navigateToNext(List<NavItem> items) {
    final currentId = ref.read(selectedNavItemProvider);
    final currentIndex = items.indexWhere((item) => item.id == currentId);
    
    if (currentIndex < items.length - 1) {
      ref.read(selectedNavItemProvider.notifier).state = items[currentIndex + 1].id;
    }
  }

  Widget _buildContent(String selectedItem) {
    switch (selectedItem) {
      case 'dashboard':
        return const DashboardScreen();
      case 'pos':
        return const POSScreen();
      case 'products':
        return const ProductsScreen();
      case 'categories':
        return const CategoriesScreen();
      case 'orders':
        return const OrdersScreen();
      case 'customers':
        return const CustomersScreen();
      case 'payments':
        return const PaymentsScreen();
      case 'quotations':
        return const QuotationsScreen();

      case 'employees':
        return const EmployeesScreen();
      case 'suppliers':
        return const SuppliersScreen();
      case 'reports':
        return const ReportsScreen();
      case 'settings':
        return const SettingsScreen();
      default:
        return const DashboardScreen();
    }
  }
}

// Mobile bottom navigation bar
class _MobileBottomNav extends StatelessWidget {
  final List<NavItem> items;
  final String selectedId;
  final Function(String) onItemSelected;
  final VoidCallback onMorePressed;

  const _MobileBottomNav({
    required this.items,
    required this.selectedId,
    required this.onItemSelected,
    required this.onMorePressed,
  });

  @override
  Widget build(BuildContext context) {
    // Limit to 4 items + More button to prevent overflow
    final visibleItems = items.take(4).toList();
    
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColorLight,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ...visibleItems.map((item) {
                final isSelected = item.id == selectedId;
                return Expanded(
                  child: _NavBarItem(
                    icon: isSelected ? item.activeIcon : item.icon,
                    label: item.label,
                    isSelected: isSelected,
                    onTap: () => onItemSelected(item.id),
                  ),
                );
              }),
              // Settings button (instead of More)
              Expanded(
                child: _NavBarItem(
                  icon: selectedId == 'settings' ? Iconsax.setting5 : Iconsax.setting,
                  label: 'Settings',
                  isSelected: selectedId == 'settings',
                  onTap: () => onItemSelected('settings'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.primary : context.textSecondaryColor,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.primary : context.textSecondaryColor,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
