-- Migration: Add permission columns for RBAC
-- Date: 2026-01-13

-- Add permission columns to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS permission_overrides TEXT[];
ALTER TABLE users ADD COLUMN IF NOT EXISTS permission_denials TEXT[];

-- Add permission columns to employees table  
ALTER TABLE employees ADD COLUMN IF NOT EXISTS permission_overrides TEXT[];
ALTER TABLE employees ADD COLUMN IF NOT EXISTS permission_denials TEXT[];

-- Create role_permissions table for customized role defaults
CREATE TABLE IF NOT EXISTS role_permissions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  role_name TEXT UNIQUE NOT NULL,
  permissions TEXT[] NOT NULL DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS for role_permissions
ALTER TABLE role_permissions ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Allow all authenticated users to read role permissions
CREATE POLICY "Allow read role_permissions" ON role_permissions
  FOR SELECT TO authenticated USING (true);

-- RLS Policy: Only admins can modify role permissions
-- Note: Using text cast since users.id may be TEXT type
CREATE POLICY "Allow admin modify role_permissions" ON role_permissions
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id::TEXT = auth.uid()::TEXT
      AND users.role = 'admin'
    )
  );

-- Insert default role permissions
INSERT INTO role_permissions (role_name, permissions) VALUES
  ('admin', ARRAY[
    'viewDashboard', 'viewSalesStats', 'viewInventoryAlerts',
    'accessPOS', 'createSale', 'applyDiscount', 'applyCustomDiscount', 'holdRecallOrders',
    'viewProducts', 'createProduct', 'editProduct', 'deleteProduct', 'adjustStock', 'importExportProducts',
    'viewCategories', 'manageCategories',
    'viewOrders', 'viewAllOrders', 'editOrder', 'cancelOrder', 'processRefund', 'printReceipt',
    'viewCustomers', 'createCustomer', 'editCustomer', 'deleteCustomer', 'viewCustomerHistory',
    'viewPayments', 'recordPayment', 'viewPaymentReports',
    'viewQuotations', 'createQuotation', 'editQuotation', 'deleteQuotation', 'convertQuotation',
    'viewEmployees', 'createEmployee', 'editEmployee', 'deleteEmployee', 'manageEmployeePermissions',
    'viewSuppliers', 'manageSuppliers', 'createPurchaseOrder',
    'viewBasicReports', 'viewDetailedReports', 'exportReports', 'viewFinancialReports',
    'viewSettings', 'editBusinessInfo', 'editTaxSettings', 'editCurrencySettings', 
    'editReceiptSettings', 'editLoyaltySettings', 'editSmsSettings', 'manageRolePermissions', 'backupRestore'
  ]),
  ('manager', ARRAY[
    'viewDashboard', 'viewSalesStats', 'viewInventoryAlerts',
    'accessPOS', 'createSale', 'applyDiscount', 'applyCustomDiscount', 'holdRecallOrders',
    'viewProducts', 'createProduct', 'editProduct', 'deleteProduct', 'adjustStock', 'importExportProducts',
    'viewCategories', 'manageCategories',
    'viewOrders', 'viewAllOrders', 'editOrder', 'cancelOrder', 'processRefund', 'printReceipt',
    'viewCustomers', 'createCustomer', 'editCustomer', 'deleteCustomer', 'viewCustomerHistory',
    'viewPayments', 'recordPayment', 'viewPaymentReports',
    'viewQuotations', 'createQuotation', 'editQuotation', 'deleteQuotation', 'convertQuotation',
    'viewEmployees',
    'viewSuppliers',
    'viewBasicReports', 'viewDetailedReports', 'exportReports',
    'viewSettings', 'editReceiptSettings'
  ]),
  ('cashier', ARRAY[
    'viewDashboard',
    'accessPOS', 'createSale', 'applyDiscount', 'holdRecallOrders', 'printReceipt',
    'viewProducts',
    'viewCategories',
    'viewOrders',
    'viewCustomers', 'createCustomer',
    'recordPayment',
    'viewQuotations',
    'viewSettings'
  ])
ON CONFLICT (role_name) DO NOTHING;

-- Create trigger to update 'updated_at' on role_permissions
CREATE OR REPLACE FUNCTION update_role_permissions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_role_permissions_updated_at ON role_permissions;
CREATE TRIGGER trigger_update_role_permissions_updated_at
  BEFORE UPDATE ON role_permissions
  FOR EACH ROW
  EXECUTE FUNCTION update_role_permissions_updated_at();