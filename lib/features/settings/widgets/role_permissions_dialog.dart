import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/models/permission.dart';
import '../../../data/models/role_permissions.dart';
import '../../../data/models/user.dart';
import '../../../providers/permissions_provider.dart';

/// Full-screen dialog for managing role permissions
class RolePermissionsDialog extends ConsumerStatefulWidget {
  const RolePermissionsDialog({super.key});

  @override
  ConsumerState<RolePermissionsDialog> createState() => _RolePermissionsDialogState();
}

class _RolePermissionsDialogState extends ConsumerState<RolePermissionsDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, Set<Permission>> _rolePermissions = {};
  bool _hasChanges = false;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPermissions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPermissions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(permissionRepositoryProvider);
      
      // Load permissions for each role
      for (final role in UserRole.values) {
        final perms = await repo.getRolePermissions(role);
        _rolePermissions[role.name] = perms;
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _togglePermission(String roleName, Permission permission, bool value) {
    setState(() {
      if (value) {
        _rolePermissions[roleName]?.add(permission);
      } else {
        _rolePermissions[roleName]?.remove(permission);
      }
      _hasChanges = true;
    });
  }

  void _toggleAllInCategory(String roleName, String category, bool value) {
    setState(() {
      final categoryPerms = getPermissionsByCategory(category);
      for (final perm in categoryPerms) {
        if (value) {
          _rolePermissions[roleName]?.add(perm);
        } else {
          _rolePermissions[roleName]?.remove(perm);
        }
      }
      _hasChanges = true;
    });
  }

  Future<void> _savePermissions(String roleName) async {
    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(rolePermissionsNotifierProvider.notifier);
      await notifier.updateRolePermissions(
        roleName,
        _rolePermissions[roleName] ?? {},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_getRoleDisplayName(roleName)} permissions saved'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving permissions: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resetToDefaults(String roleName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults?'),
        content: Text(
          'This will reset all ${_getRoleDisplayName(roleName)} permissions to their default values. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(rolePermissionsNotifierProvider.notifier);
      await notifier.resetToDefaults(roleName);
      
      // Reload permissions
      final role = UserRole.values.firstWhere((r) => r.name == roleName);
      final perms = DefaultRolePermissions.getDefaultPermissions(role);
      setState(() {
        _rolePermissions[roleName] = perms;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_getRoleDisplayName(roleName)} permissions reset to defaults'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _getRoleDisplayName(String roleName) {
    switch (roleName) {
      case 'admin':
        return 'Admin';
      case 'manager':
        return 'Manager';
      case 'cashier':
        return 'Cashier';
      default:
        return roleName;
    }
  }

  Color _getRoleColor(String roleName) {
    switch (roleName) {
      case 'admin':
        return AppColors.error;
      case 'manager':
        return AppColors.warning;
      case 'cashier':
        return AppColors.info;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      insetPadding: EdgeInsets.all(isMobile ? 16 : 48),
      child: Container(
        width: isMobile ? double.infinity : 800,
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardBackground : AppColors.primary.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Iconsax.security_user,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Roles & Permissions',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Configure what each role can access and do',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              color: isDark ? AppColors.darkCardBackground : Colors.grey.shade100,
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                tabs: [
                  _buildTab('Admin', 'admin'),
                  _buildTab('Manager', 'manager'),
                  _buildTab('Cashier', 'cashier'),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Iconsax.warning_2, size: 48, color: AppColors.error),
                              const SizedBox(height: 16),
                              Text('Error: $_error'),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadPermissions,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildRolePermissions('admin'),
                            _buildRolePermissions('manager'),
                            _buildRolePermissions('cashier'),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, String roleName) {
    final permCount = _rolePermissions[roleName]?.length ?? 0;
    final totalPerms = Permission.values.length;
    
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 4,
            backgroundColor: _getRoleColor(roleName),
          ),
          const SizedBox(width: 8),
          Text(label),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getRoleColor(roleName).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$permCount/$totalPerms',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _getRoleColor(roleName),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRolePermissions(String roleName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final permissions = _rolePermissions[roleName] ?? {};
    
    return Column(
      children: [
        // Action buttons
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Select permissions for ${_getRoleDisplayName(roleName)} role',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ),
              TextButton.icon(
                icon: const Icon(Iconsax.refresh, size: 18),
                label: const Text('Reset'),
                onPressed: () => _resetToDefaults(roleName),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Iconsax.tick_circle, size: 18),
                label: const Text('Save'),
                onPressed: () => _savePermissions(roleName),
              ),
            ],
          ),
        ),
        
        // Permission categories
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: allPermissionCategories.length,
            itemBuilder: (context, index) {
              final category = allPermissionCategories[index];
              return _buildCategorySection(roleName, category, permissions, isDark);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection(
    String roleName,
    String category,
    Set<Permission> rolePerms,
    bool isDark,
  ) {
    final categoryPerms = getPermissionsByCategory(category);
    final enabledCount = categoryPerms.where((p) => rolePerms.contains(p)).length;
    final allEnabled = enabledCount == categoryPerms.length;
    final someEnabled = enabledCount > 0 && !allEnabled;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? AppColors.darkCardBackground : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getCategoryIcon(category),
              size: 20,
              color: AppColors.primary,
            ),
          ),
          title: Text(
            category,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '$enabledCount of ${categoryPerms.length} permissions enabled',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Toggle all in category
              Checkbox(
                value: allEnabled,
                tristate: true,
                onChanged: someEnabled ? null : (value) {
                  _toggleAllInCategory(roleName, category, value ?? false);
                },
              ),
              const Icon(Icons.expand_more),
            ],
          ),
          children: categoryPerms.map((perm) {
            final isEnabled = rolePerms.contains(perm);
            return CheckboxListTile(
              value: isEnabled,
              onChanged: (value) {
                _togglePermission(roleName, perm, value ?? false);
              },
              title: Text(
                perm.displayName,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              contentPadding: const EdgeInsets.only(left: 56, right: 16),
            );
          }).toList(),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Dashboard':
        return Iconsax.home;
      case 'POS':
        return Iconsax.calculator;
      case 'Products':
        return Iconsax.box;
      case 'Categories':
        return Iconsax.category;
      case 'Orders':
        return Iconsax.receipt;
      case 'Customers':
        return Iconsax.people;
      case 'Payments':
        return Iconsax.wallet_money;
      case 'Quotations':
        return Iconsax.document_text;
      case 'Employees':
        return Iconsax.user_octagon;
      case 'Suppliers':
        return Iconsax.truck_fast;
      case 'Reports':
        return Iconsax.chart;
      case 'Settings':
        return Iconsax.setting;
      default:
        return Iconsax.more;
    }
  }
}
