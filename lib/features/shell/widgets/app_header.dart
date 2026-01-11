import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/services/connectivity_service.dart';
import '../screens/main_shell.dart';
import '../../auth/screens/login_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../profile/screens/profile_screen.dart';

class AppHeader extends ConsumerWidget {
  final bool showMenuButton;
  final VoidCallback? onMenuPressed;

  const AppHeader({
    super.key,
    this.showMenuButton = false,
    this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isMobile = ScreenBreakpoints.isMobile(context);
    final isTablet = ScreenBreakpoints.isTablet(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      height: AppConstants.headerHeight,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(
          bottom: BorderSide(color: context.cardBorderColor),
        ),
      ),
      child: Row(
        children: [
          // Hamburger menu - always visible like reference
          IconButton(
            icon: const Icon(Icons.menu, size: 24),
            onPressed: onMenuPressed ?? () {},
            color: context.textSecondaryColor,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
            tooltip: 'Menu',
          ),
          const SizedBox(width: 12),

          // Search Bar - smaller and dark mode aware
          Expanded(
            child: isMobile
                ? const SizedBox() // No search bar on mobile header
                : Builder(
                    builder: (context) {
                      final isDark = context.isDarkMode;
                      return Container(
                        constraints: const BoxConstraints(maxWidth: 350),
                        height: 38,
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search...',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                            ),
                            prefixIcon: Icon(
                              Iconsax.search_normal,
                              size: 16,
                              color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                            ),
                            filled: true,
                            fillColor: isDark ? AppColors.darkSurfaceVariant : AppColors.grey100,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            isDense: true,
                          ),
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextPrimary : null,
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Right side actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Connection Status - hide on small screens
              if (screenWidth > 700) ...[
                _ConnectionIndicator(),
                const SizedBox(width: 12),
              ],

              // Notifications
              _HeaderIconButton(
                icon: Iconsax.notification,
                badge: 3,
                onPressed: () {
                  _showNotificationsPopup(context);
                },
              ),

              // Additional actions - hide on mobile
              if (!isMobile) ...[
                const SizedBox(width: 8),
                _HeaderIconButton(
                  icon: Iconsax.add_square,
                  onPressed: () {
                    _showQuickActionsMenu(context);
                  },
                ),
              ],

              if (!isMobile && !isTablet) ...[
                const SizedBox(width: 12),
                Container(
                  height: 28,
                  width: 1,
                  color: context.cardBorderColor,
                ),
                const SizedBox(width: 12),
              ] else
                const SizedBox(width: 8),

              // User Profile
              _UserProfileButton(user: user, compact: isMobile || isTablet, ref: ref),
            ],
          ),
        ],
      ),
    );
  }

  void _showNotificationsPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Iconsax.notification, color: AppColors.primary),
            SizedBox(width: 12),
            Text('Notifications'),
          ],
        ),
        content: SizedBox(
          width: 350,
          height: 300,
          child: Column(
            children: [
              _NotificationItem(
                icon: Iconsax.warning_2,
                title: 'Low Stock Alert',
                message: '5 products are running low on stock',
                time: '2 hours ago',
                color: AppColors.warning,
              ),
              const Divider(),
              _NotificationItem(
                icon: Iconsax.money_recive,
                title: 'Payment Received',
                message: 'Customer payment of ₹2,500 received',
                time: '3 hours ago',
                color: AppColors.success,
              ),
              const Divider(),
              _NotificationItem(
                icon: Iconsax.box,
                title: 'New Order',
                message: 'Order #1234 has been placed',
                time: '5 hours ago',
                color: AppColors.info,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mark All Read'),
          ),
        ],
      ),
    );
  }

  void _showQuickActionsMenu(BuildContext context) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width - 220,
        AppConstants.headerHeight,
        0,
        0,
      ),
      items: [
        PopupMenuItem(
          child: const Row(
            children: [
              Icon(Iconsax.box_add, size: 20, color: AppColors.primary),
              SizedBox(width: 12),
              Text('Add Product'),
            ],
          ),
          onTap: () {
            // Navigate to add product
          },
        ),
        PopupMenuItem(
          child: const Row(
            children: [
              Icon(Iconsax.profile_add, size: 20, color: AppColors.success),
              SizedBox(width: 12),
              Text('Add Customer'),
            ],
          ),
          onTap: () {
            // Navigate to add customer
          },
        ),
        PopupMenuItem(
          child: const Row(
            children: [
              Icon(Iconsax.receipt_add, size: 20, color: AppColors.info),
              SizedBox(width: 12),
              Text('New Sale'),
            ],
          ),
          onTap: () {
            // Navigate to POS
          },
        ),
        PopupMenuItem(
          child: const Row(
            children: [
              Icon(Iconsax.document_download, size: 20, color: AppColors.warning),
              SizedBox(width: 12),
              Text('Export Report'),
            ],
          ),
          onTap: () {
            // Export report
          },
        ),
      ],
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String time;
  final Color color;

  const _NotificationItem({
    required this.icon,
    required this.title,
    required this.message,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(message, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                Text(time, style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserProfileButton extends StatelessWidget {
  final dynamic user;
  final bool compact;
  final WidgetRef ref;

  const _UserProfileButton({
    required this.user,
    required this.compact,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showUserMenu(context),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: context.isDarkMode ? AppColors.darkSurfaceVariant : AppColors.grey50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: compact ? 14 : 16,
              backgroundColor: AppColors.primary,
              child: Text(
                user?.name.substring(0, 1).toUpperCase() ?? 'A',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: compact ? 11 : 13,
                ),
              ),
            ),
            if (!compact) ...[
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 100),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? 'Guest',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      user?.roleDisplayName ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showUserMenu(BuildContext context) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width - 200,
        AppConstants.headerHeight,
        0,
        0,
      ),
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'profile',
          child: Row(
            children: [
              const Icon(Iconsax.user, size: 20),
              const SizedBox(width: 12),
              const Text('Profile'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'settings',
          child: Row(
            children: [
              const Icon(Iconsax.setting_2, size: 20),
              const SizedBox(width: 12),
              const Text('Settings'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              const Icon(Iconsax.logout, size: 20, color: AppColors.error),
              const SizedBox(width: 12),
              const Text('Logout', style: TextStyle(color: AppColors.error)),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'profile') {
        _showProfileDialog(context);
      } else if (value == 'settings') {
        _navigateToSettings(context);
      } else if (value == 'logout') {
        _handleLogout(context);
      }
    });
  }

  void _showProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ProfileScreen(),
    );
  }

  void _navigateToSettings(BuildContext context) {
    // Find the MainShell and switch to Settings tab (index 6 for settings)
    // Alternative: directly navigate to settings screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsPageWrapper(),
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen(mode: LoginMode.full)),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

/// Wrapper to show Settings screen standalone
class SettingsPageWrapper extends ConsumerWidget {
  const SettingsPageWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const SettingsScreen(),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final int? badge;

  const _HeaderIconButton({
    required this.icon,
    required this.onPressed,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.grey50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, size: 20, color: AppColors.textSecondary),
              if (badge != null && badge! > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      badge! > 9 ? '9+' : badge.toString(),
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
    );
  }
}

class _ConnectionIndicator extends StatefulWidget {
  @override
  State<_ConnectionIndicator> createState() => _ConnectionIndicatorState();
}

class _ConnectionIndicatorState extends State<_ConnectionIndicator> {
  final _connectivityService = ConnectivityService();
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _isOnline = _connectivityService.isOnline;
    _connectivityService.connectionStream.listen((isOnline) {
      if (mounted) {
        setState(() => _isOnline = isOnline);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _isOnline
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: _isOnline ? AppColors.success : AppColors.warning,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            _isOnline ? 'Online' : 'Offline',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _isOnline ? AppColors.success : AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}
