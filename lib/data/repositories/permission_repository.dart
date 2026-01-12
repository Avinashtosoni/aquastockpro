import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/permission.dart';
import '../models/role_permissions.dart';
import '../models/user.dart' show User, UserRole;
import '../models/employee.dart' show Employee, EmployeeRole;
import '../../core/constants/supabase_config.dart';

/// Repository for managing role and user permissions
class PermissionRepository {
  final _supabase = Supabase.instance.client;

  /// Get Supabase client
  SupabaseClient get _client => _supabase;

  // ============ ROLE PERMISSIONS ============

  /// Get all role permissions from database
  Future<List<RolePermissions>> getAllRolePermissions() async {
    try {
      final response = await _client
          .from(SupabaseConfig.rolePermissionsTable)
          .select()
          .order('role_name');
      
      return (response as List)
          .map((item) => RolePermissions.fromMap(item))
          .toList();
    } catch (e) {
      // If table doesn't exist or error, return defaults
      return [
        RolePermissions.defaultFor('admin'),
        RolePermissions.defaultFor('manager'),
        RolePermissions.defaultFor('cashier'),
      ];
    }
  }

  /// Get permissions for a specific role
  Future<Set<Permission>> getRolePermissions(UserRole role) async {
    try {
      final response = await _client
          .from(SupabaseConfig.rolePermissionsTable)
          .select()
          .eq('role_name', role.name)
          .maybeSingle();
      
      if (response != null) {
        final rolePerms = RolePermissions.fromMap(response);
        return rolePerms.permissionSet;
      }
    } catch (e) {
      // Fall back to defaults on error
    }
    
    // Return default permissions for role
    return DefaultRolePermissions.getDefaultPermissions(role);
  }

  /// Get permissions for an employee role
  Future<Set<Permission>> getEmployeeRolePermissions(EmployeeRole role) async {
    // Map EmployeeRole to UserRole
    final userRole = UserRole.values.firstWhere(
      (r) => r.name == role.name,
      orElse: () => UserRole.cashier,
    );
    return getRolePermissions(userRole);
  }

  /// Update role permissions (admin only)
  Future<void> updateRolePermissions(String roleName, Set<Permission> permissions) async {
    final permissionNames = permissionsToNames(permissions);
    
    await _client
        .from(SupabaseConfig.rolePermissionsTable)
        .upsert({
          'role_name': roleName,
          'permissions': permissionNames,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'role_name');
  }

  /// Reset role permissions to defaults
  Future<void> resetRolePermissionsToDefault(String roleName) async {
    final role = UserRole.values.firstWhere(
      (r) => r.name == roleName,
      orElse: () => UserRole.cashier,
    );
    final defaultPerms = DefaultRolePermissions.getDefaultPermissions(role);
    await updateRolePermissions(roleName, defaultPerms);
  }

  // ============ USER PERMISSIONS ============

  /// Get effective permissions for a user (role permissions + overrides - denials)
  Future<Set<Permission>> getEffectiveUserPermissions(User user) async {
    // Start with role-based permissions
    final rolePerms = await getRolePermissions(user.role);
    
    // Apply overrides (add permissions)
    final overrides = user.permissionOverrides != null
        ? permissionsFromNames(user.permissionOverrides!)
        : <Permission>{};
    
    // Apply denials (remove permissions)
    final denials = user.permissionDenials != null
        ? permissionsFromNames(user.permissionDenials!)
        : <Permission>{};
    
    // Calculate effective permissions: (role + overrides) - denials
    return (rolePerms.union(overrides)).difference(denials);
  }

  /// Get effective permissions for an employee
  Future<Set<Permission>> getEffectiveEmployeePermissions(Employee employee) async {
    // Start with role-based permissions
    final rolePerms = await getEmployeeRolePermissions(employee.role);
    
    // Apply overrides (add permissions)
    final overrides = employee.permissionOverrides != null
        ? permissionsFromNames(employee.permissionOverrides!)
        : <Permission>{};
    
    // Apply denials (remove permissions)
    final denials = employee.permissionDenials != null
        ? permissionsFromNames(employee.permissionDenials!)
        : <Permission>{};
    
    // Calculate effective permissions: (role + overrides) - denials
    return (rolePerms.union(overrides)).difference(denials);
  }

  /// Check if a user has a specific permission
  Future<bool> userHasPermission(User user, Permission permission) async {
    final effectivePerms = await getEffectiveUserPermissions(user);
    return effectivePerms.contains(permission);
  }

  /// Check if an employee has a specific permission
  Future<bool> employeeHasPermission(Employee employee, Permission permission) async {
    final effectivePerms = await getEffectiveEmployeePermissions(employee);
    return effectivePerms.contains(permission);
  }

  // ============ PERMISSION HELPERS ============

  /// Get all permissions grouped by category
  Map<String, List<Permission>> getAllPermissionsGrouped() {
    final result = <String, List<Permission>>{};
    for (final category in allPermissionCategories) {
      result[category] = getPermissionsByCategory(category);
    }
    return result;
  }

  /// Get permissions that a role doesn't have by default
  Set<Permission> getMissingDefaultPermissions(UserRole role) {
    final defaultPerms = DefaultRolePermissions.getDefaultPermissions(role);
    return Permission.values.toSet().difference(defaultPerms);
  }
}
