import 'permission.dart';
import '../models/user.dart';
import '../models/employee.dart';

/// Default permissions for each role
class DefaultRolePermissions {
  /// Get default permissions for admin role
  static Set<Permission> get adminPermissions => Permission.values.toSet();

  /// Get default permissions for manager role
  static Set<Permission> get managerPermissions => {
    // Dashboard - Full access
    Permission.viewDashboard,
    Permission.viewSalesStats,
    Permission.viewInventoryAlerts,
    
    // POS - Full access
    Permission.accessPOS,
    Permission.createSale,
    Permission.applyDiscount,
    Permission.applyCustomDiscount,
    Permission.holdRecallOrders,
    
    // Products - Full access
    Permission.viewProducts,
    Permission.createProduct,
    Permission.editProduct,
    Permission.deleteProduct,
    Permission.adjustStock,
    Permission.importExportProducts,
    
    // Categories - Full access
    Permission.viewCategories,
    Permission.manageCategories,
    
    // Orders - Full access
    Permission.viewOrders,
    Permission.viewAllOrders,
    Permission.editOrder,
    Permission.cancelOrder,
    Permission.processRefund,
    Permission.printReceipt,
    
    // Customers - Full access
    Permission.viewCustomers,
    Permission.createCustomer,
    Permission.editCustomer,
    Permission.deleteCustomer,
    Permission.viewCustomerHistory,
    
    // Payments - Full access
    Permission.viewPayments,
    Permission.recordPayment,
    Permission.viewPaymentReports,
    
    // Quotations - Full access
    Permission.viewQuotations,
    Permission.createQuotation,
    Permission.editQuotation,
    Permission.deleteQuotation,
    Permission.convertQuotation,
    
    // Employees - View only
    Permission.viewEmployees,
    
    // Suppliers - View only
    Permission.viewSuppliers,
    
    // Reports - Full access except financial
    Permission.viewBasicReports,
    Permission.viewDetailedReports,
    Permission.exportReports,
    
    // Settings - Limited access
    Permission.viewSettings,
    Permission.editReceiptSettings,
  };

  /// Get default permissions for cashier role
  static Set<Permission> get cashierPermissions => {
    // Dashboard - Limited
    Permission.viewDashboard,
    
    // POS - Basic sales
    Permission.accessPOS,
    Permission.createSale,
    Permission.applyDiscount,
    Permission.holdRecallOrders,
    Permission.printReceipt,
    
    // Products - View only
    Permission.viewProducts,
    
    // Categories - View only
    Permission.viewCategories,
    
    // Orders - Own orders only
    Permission.viewOrders,
    Permission.printReceipt,
    
    // Customers - Basic access
    Permission.viewCustomers,
    Permission.createCustomer,
    
    // Payments - Record only
    Permission.recordPayment,
    
    // Quotations - View only
    Permission.viewQuotations,
    
    // Settings - View only
    Permission.viewSettings,
  };

  /// Get default permissions for a role
  static Set<Permission> getDefaultPermissions(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return adminPermissions;
      case UserRole.manager:
        return managerPermissions;
      case UserRole.cashier:
        return cashierPermissions;
    }
  }

  /// Get default permissions for employee role
  static Set<Permission> getDefaultEmployeePermissions(EmployeeRole role) {
    switch (role) {
      case EmployeeRole.admin:
        return adminPermissions;
      case EmployeeRole.manager:
        return managerPermissions;
      case EmployeeRole.cashier:
        return cashierPermissions;
    }
  }
}

/// Model for storing customized role permissions in database
class RolePermissions {
  final String id;
  final String roleName;
  final List<String> permissions;
  final DateTime updatedAt;

  const RolePermissions({
    required this.id,
    required this.roleName,
    required this.permissions,
    required this.updatedAt,
  });

  /// Get permission set
  Set<Permission> get permissionSet => permissionsFromNames(permissions);

  /// Copy with new values
  RolePermissions copyWith({
    String? id,
    String? roleName,
    List<String>? permissions,
    DateTime? updatedAt,
  }) {
    return RolePermissions(
      id: id ?? this.id,
      roleName: roleName ?? this.roleName,
      permissions: permissions ?? this.permissions,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'role_name': roleName,
      'permissions': permissions,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create from database map
  factory RolePermissions.fromMap(Map<String, dynamic> map) {
    return RolePermissions(
      id: map['id'] as String,
      roleName: map['role_name'] as String,
      permissions: List<String>.from(map['permissions'] ?? []),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Create default role permissions
  factory RolePermissions.defaultFor(String roleName) {
    final role = UserRole.values.firstWhere(
      (r) => r.name == roleName,
      orElse: () => UserRole.cashier,
    );
    final permissions = DefaultRolePermissions.getDefaultPermissions(role);
    return RolePermissions(
      id: '',
      roleName: roleName,
      permissions: permissionsToNames(permissions),
      updatedAt: DateTime.now(),
    );
  }
}
