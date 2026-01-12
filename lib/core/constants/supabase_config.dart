import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Supabase Configuration - reads from .env file
class SupabaseConfig {
  SupabaseConfig._();

  /// Get Supabase URL from environment
  static String get supabaseUrl => 
      dotenv.env['SUPABASE_URL'] ?? 'https://jxfgdfdezrqugxdzrbro.supabase.co';
  
  /// Get Supabase Anon Key from environment
  static String get supabaseAnonKey => 
      dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // Table Names
  static const String usersTable = 'users';
  static const String productsTable = 'products';
  static const String categoriesTable = 'categories';
  static const String customersTable = 'customers';
  static const String ordersTable = 'orders';
  static const String orderItemsTable = 'order_items';
  static const String paymentsTable = 'payments';
  static const String inventoryLogsTable = 'inventory_logs';
  static const String businessSettingsTable = 'business_settings';
  static const String employeesTable = 'employees';
  static const String suppliersTable = 'suppliers';
  static const String purchaseOrdersTable = 'purchase_orders';
  static const String purchaseOrderItemsTable = 'purchase_order_items';
  static const String stockAdjustmentsTable = 'stock_adjustments';
  static const String refundsTable = 'refunds';
  static const String refundItemsTable = 'refund_items';
  static const String discountsTable = 'discounts';
  static const String auditLogsTable = 'audit_logs';
  static const String creditTransactionsTable = 'credit_transactions';
  static const String quotationsTable = 'quotations';
  static const String quotationItemsTable = 'quotation_items';
  static const String rolePermissionsTable = 'role_permissions';

  // Storage Buckets
  static const String productImagesBucket = 'product-images';
  static const String logosBucket = 'logos';
  static const String receiptsBucket = 'receipts';
}
