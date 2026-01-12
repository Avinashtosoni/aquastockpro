/// All app permissions for Role-Based Access Control
enum Permission {
  // ============ DASHBOARD ============
  /// View dashboard screen
  viewDashboard,
  /// View sales statistics and revenue data
  viewSalesStats,
  /// View inventory alerts and low stock warnings
  viewInventoryAlerts,

  // ============ POS (Point of Sale) ============
  /// Access POS screen
  accessPOS,
  /// Create new sales/orders
  createSale,
  /// Apply predefined discounts
  applyDiscount,
  /// Apply custom discount amounts
  applyCustomDiscount,
  /// Hold and recall orders
  holdRecallOrders,

  // ============ PRODUCTS ============
  /// View products list
  viewProducts,
  /// Create new products
  createProduct,
  /// Edit existing products
  editProduct,
  /// Delete products
  deleteProduct,
  /// Adjust stock quantities
  adjustStock,
  /// Import/export products
  importExportProducts,

  // ============ CATEGORIES ============
  /// View categories
  viewCategories,
  /// Create, edit, delete categories
  manageCategories,

  // ============ ORDERS ============
  /// View orders list
  viewOrders,
  /// View all orders (not just own)
  viewAllOrders,
  /// Edit order details
  editOrder,
  /// Cancel/void orders
  cancelOrder,
  /// Process refunds
  processRefund,
  /// Print receipts
  printReceipt,

  // ============ CUSTOMERS ============
  /// View customers list
  viewCustomers,
  /// Create new customers
  createCustomer,
  /// Edit customer details
  editCustomer,
  /// Delete customers
  deleteCustomer,
  /// View customer purchase history
  viewCustomerHistory,

  // ============ PAYMENTS ============
  /// View payments
  viewPayments,
  /// Record payments
  recordPayment,
  /// View payment reports
  viewPaymentReports,

  // ============ QUOTATIONS ============
  /// View quotations
  viewQuotations,
  /// Create quotations
  createQuotation,
  /// Edit quotations
  editQuotation,
  /// Delete quotations
  deleteQuotation,
  /// Convert quotation to order
  convertQuotation,

  // ============ EMPLOYEES ============
  /// View employees list
  viewEmployees,
  /// Create new employees
  createEmployee,
  /// Edit employee details
  editEmployee,
  /// Delete employees
  deleteEmployee,
  /// Manage employee permissions
  manageEmployeePermissions,

  // ============ SUPPLIERS ============
  /// View suppliers
  viewSuppliers,
  /// Manage suppliers (create, edit, delete)
  manageSuppliers,
  /// Create purchase orders
  createPurchaseOrder,

  // ============ REPORTS ============
  /// View basic reports
  viewBasicReports,
  /// View detailed/advanced reports
  viewDetailedReports,
  /// Export reports to PDF/Excel
  exportReports,
  /// View financial reports
  viewFinancialReports,

  // ============ SETTINGS ============
  /// View settings screen
  viewSettings,
  /// Edit business information
  editBusinessInfo,
  /// Edit tax settings
  editTaxSettings,
  /// Edit currency settings
  editCurrencySettings,
  /// Edit receipt settings
  editReceiptSettings,
  /// Edit loyalty settings
  editLoyaltySettings,
  /// Edit SMS settings
  editSmsSettings,
  /// Manage role permissions (admin only)
  manageRolePermissions,
  /// Backup and restore data
  backupRestore,
}

/// Extension to get permission display name and category
extension PermissionExtension on Permission {
  String get displayName {
    // Convert enum name to readable format
    final name = toString().split('.').last;
    // Insert space before capital letters and capitalize first letter
    final words = name.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (m) => ' ${m.group(1)}',
    );
    return words.trim().split(' ').map((w) => 
      w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}'
    ).join(' ');
  }

  String get category {
    switch (this) {
      case Permission.viewDashboard:
      case Permission.viewSalesStats:
      case Permission.viewInventoryAlerts:
        return 'Dashboard';
      case Permission.accessPOS:
      case Permission.createSale:
      case Permission.applyDiscount:
      case Permission.applyCustomDiscount:
      case Permission.holdRecallOrders:
        return 'POS';
      case Permission.viewProducts:
      case Permission.createProduct:
      case Permission.editProduct:
      case Permission.deleteProduct:
      case Permission.adjustStock:
      case Permission.importExportProducts:
        return 'Products';
      case Permission.viewCategories:
      case Permission.manageCategories:
        return 'Categories';
      case Permission.viewOrders:
      case Permission.viewAllOrders:
      case Permission.editOrder:
      case Permission.cancelOrder:
      case Permission.processRefund:
      case Permission.printReceipt:
        return 'Orders';
      case Permission.viewCustomers:
      case Permission.createCustomer:
      case Permission.editCustomer:
      case Permission.deleteCustomer:
      case Permission.viewCustomerHistory:
        return 'Customers';
      case Permission.viewPayments:
      case Permission.recordPayment:
      case Permission.viewPaymentReports:
        return 'Payments';
      case Permission.viewQuotations:
      case Permission.createQuotation:
      case Permission.editQuotation:
      case Permission.deleteQuotation:
      case Permission.convertQuotation:
        return 'Quotations';
      case Permission.viewEmployees:
      case Permission.createEmployee:
      case Permission.editEmployee:
      case Permission.deleteEmployee:
      case Permission.manageEmployeePermissions:
        return 'Employees';
      case Permission.viewSuppliers:
      case Permission.manageSuppliers:
      case Permission.createPurchaseOrder:
        return 'Suppliers';
      case Permission.viewBasicReports:
      case Permission.viewDetailedReports:
      case Permission.exportReports:
      case Permission.viewFinancialReports:
        return 'Reports';
      case Permission.viewSettings:
      case Permission.editBusinessInfo:
      case Permission.editTaxSettings:
      case Permission.editCurrencySettings:
      case Permission.editReceiptSettings:
      case Permission.editLoyaltySettings:
      case Permission.editSmsSettings:
      case Permission.manageRolePermissions:
      case Permission.backupRestore:
        return 'Settings';
    }
  }

  /// Get icon for this permission category
  String get categoryIcon {
    switch (category) {
      case 'Dashboard':
        return 'home';
      case 'POS':
        return 'calculator';
      case 'Products':
        return 'box';
      case 'Categories':
        return 'category';
      case 'Orders':
        return 'receipt';
      case 'Customers':
        return 'people';
      case 'Payments':
        return 'wallet';
      case 'Quotations':
        return 'document';
      case 'Employees':
        return 'user';
      case 'Suppliers':
        return 'truck';
      case 'Reports':
        return 'chart';
      case 'Settings':
        return 'setting';
      default:
        return 'more';
    }
  }
}

/// Get all permission categories
List<String> get allPermissionCategories => [
  'Dashboard',
  'POS',
  'Products',
  'Categories',
  'Orders',
  'Customers',
  'Payments',
  'Quotations',
  'Employees',
  'Suppliers',
  'Reports',
  'Settings',
];

/// Get permissions by category
List<Permission> getPermissionsByCategory(String category) {
  return Permission.values.where((p) => p.category == category).toList();
}

/// Convert permission name to Permission enum
Permission? permissionFromName(String name) {
  try {
    return Permission.values.firstWhere((p) => p.name == name);
  } catch (_) {
    return null;
  }
}

/// Convert list of permission names to Permission set
Set<Permission> permissionsFromNames(List<String> names) {
  return names
      .map((n) => permissionFromName(n))
      .whereType<Permission>()
      .toSet();
}

/// Convert Permission set to list of names
List<String> permissionsToNames(Set<Permission> permissions) {
  return permissions.map((p) => p.name).toList();
}
