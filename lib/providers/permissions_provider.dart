import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/permission.dart';
import '../data/models/role_permissions.dart';
import '../data/models/user.dart';
import '../data/models/employee.dart';
import '../data/repositories/permission_repository.dart';
import 'auth_provider.dart';

// ============ REPOSITORY PROVIDER ============

final permissionRepositoryProvider = Provider((ref) => PermissionRepository());

// ============ ROLE PERMISSIONS PROVIDERS ============

/// Provider for all role permissions
final allRolePermissionsProvider = FutureProvider<List<RolePermissions>>((ref) async {
  final repo = ref.watch(permissionRepositoryProvider);
  return repo.getAllRolePermissions();
});

/// Provider for specific role permissions
final rolePermissionsProvider = FutureProvider.family<Set<Permission>, UserRole>((ref, role) async {
  final repo = ref.watch(permissionRepositoryProvider);
  return repo.getRolePermissions(role);
});

/// Provider for employee role permissions
final employeeRolePermissionsProvider = FutureProvider.family<Set<Permission>, EmployeeRole>((ref, role) async {
  final repo = ref.watch(permissionRepositoryProvider);
  return repo.getEmployeeRolePermissions(role);
});

// ============ CURRENT USER PERMISSIONS ============

/// Provider for current user's effective permissions
final currentUserPermissionsProvider = FutureProvider<Set<Permission>>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState.user == null) {
    return <Permission>{};
  }
  
  final repo = ref.watch(permissionRepositoryProvider);
  return repo.getEffectiveUserPermissions(authState.user!);
});

/// Provider to check if current user has a specific permission
final hasPermissionProvider = Provider.family<bool, Permission>((ref, permission) {
  final permissionsAsync = ref.watch(currentUserPermissionsProvider);
  return permissionsAsync.maybeWhen(
    data: (permissions) => permissions.contains(permission),
    orElse: () => false,
  );
});

/// Provider to check if current user has any of the given permissions
final hasAnyPermissionProvider = Provider.family<bool, List<Permission>>((ref, permissions) {
  final permissionsAsync = ref.watch(currentUserPermissionsProvider);
  return permissionsAsync.maybeWhen(
    data: (userPerms) => permissions.any((p) => userPerms.contains(p)),
    orElse: () => false,
  );
});

/// Provider to check if current user has all of the given permissions
final hasAllPermissionsProvider = Provider.family<bool, List<Permission>>((ref, permissions) {
  final permissionsAsync = ref.watch(currentUserPermissionsProvider);
  return permissionsAsync.maybeWhen(
    data: (userPerms) => permissions.every((p) => userPerms.contains(p)),
    orElse: () => false,
  );
});

// ============ EMPLOYEE PERMISSIONS ============

/// Provider for specific employee's effective permissions
final employeePermissionsProvider = FutureProvider.family<Set<Permission>, Employee>((ref, employee) async {
  final repo = ref.watch(permissionRepositoryProvider);
  return repo.getEffectiveEmployeePermissions(employee);
});

// ============ PERMISSION MANAGEMENT ============

/// Notifier for managing role permissions (admin only)
class RolePermissionsNotifier extends StateNotifier<AsyncValue<void>> {
  final PermissionRepository _repository;
  final Ref _ref;

  RolePermissionsNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  /// Update permissions for a role
  Future<void> updateRolePermissions(String roleName, Set<Permission> permissions) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateRolePermissions(roleName, permissions);
      // Invalidate related providers to refresh data
      _ref.invalidate(allRolePermissionsProvider);
      _ref.invalidate(currentUserPermissionsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Reset role permissions to defaults
  Future<void> resetToDefaults(String roleName) async {
    state = const AsyncValue.loading();
    try {
      await _repository.resetRolePermissionsToDefault(roleName);
      _ref.invalidate(allRolePermissionsProvider);
      _ref.invalidate(currentUserPermissionsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final rolePermissionsNotifierProvider = StateNotifierProvider<RolePermissionsNotifier, AsyncValue<void>>((ref) {
  return RolePermissionsNotifier(
    ref.watch(permissionRepositoryProvider),
    ref,
  );
});

/// Permission categories with their permissions
final permissionCategoriesProvider = Provider<Map<String, List<Permission>>>((ref) {
  final result = <String, List<Permission>>{};
  for (final category in allPermissionCategories) {
    result[category] = getPermissionsByCategory(category);
  }
  return result;
});

