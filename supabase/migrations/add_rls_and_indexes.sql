-- Migration: Add RLS policies and performance indexes
-- Date: 2026-01-14

-- ===========================================
-- PERFORMANCE INDEXES
-- ===========================================

-- Discount validity lookup
CREATE INDEX IF NOT EXISTS idx_discounts_valid 
ON discounts(valid_from, valid_until) 
WHERE is_active = true;

-- Customer phone search
CREATE INDEX IF NOT EXISTS idx_customers_phone ON customers(phone);

-- Product name full-text search
CREATE INDEX IF NOT EXISTS idx_products_name_gin 
ON products USING gin(to_tsvector('english', name));

-- Orders by date (common dashboard query)
CREATE INDEX IF NOT EXISTS idx_orders_created_date 
ON orders(DATE(created_at));

-- ===========================================
-- ENABLE ROW LEVEL SECURITY
-- ===========================================

ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE refunds ENABLE ROW LEVEL SECURITY;
ALTER TABLE employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE discounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_adjustments ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE refund_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- ===========================================
-- RLS POLICIES - Allow authenticated users to read all data
-- ===========================================

-- Payments policies
CREATE POLICY "Allow authenticated read payments" ON payments
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow authenticated insert payments" ON payments
  FOR INSERT TO authenticated WITH CHECK (true);

-- Refunds policies
CREATE POLICY "Allow authenticated read refunds" ON refunds
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow authenticated manage refunds" ON refunds
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Employees policies
CREATE POLICY "Allow authenticated read employees" ON employees
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow admin manage employees" ON employees
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id::TEXT = auth.uid()::TEXT
      AND users.role IN ('admin', 'manager')
    )
  );

-- Discounts policies
CREATE POLICY "Allow authenticated read discounts" ON discounts
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow admin manage discounts" ON discounts
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id::TEXT = auth.uid()::TEXT
      AND users.role IN ('admin', 'manager')
    )
  );

-- Suppliers policies
CREATE POLICY "Allow authenticated read suppliers" ON suppliers
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow authenticated manage suppliers" ON suppliers
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Purchase Orders policies
CREATE POLICY "Allow authenticated read purchase_orders" ON purchase_orders
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow authenticated manage purchase_orders" ON purchase_orders
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Allow authenticated read purchase_order_items" ON purchase_order_items
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow authenticated manage purchase_order_items" ON purchase_order_items
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Stock Adjustments policies
CREATE POLICY "Allow authenticated read stock_adjustments" ON stock_adjustments
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow authenticated insert stock_adjustments" ON stock_adjustments
  FOR INSERT TO authenticated WITH CHECK (true);

-- Inventory Logs policies
CREATE POLICY "Allow authenticated read inventory_logs" ON inventory_logs
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow authenticated insert inventory_logs" ON inventory_logs
  FOR INSERT TO authenticated WITH CHECK (true);

-- Categories policies
CREATE POLICY "Allow authenticated read categories" ON categories
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow admin manage categories" ON categories
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id::TEXT = auth.uid()::TEXT
      AND users.role IN ('admin', 'manager')
    )
  );

-- Refund Items policies
CREATE POLICY "Allow authenticated read refund_items" ON refund_items
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow authenticated manage refund_items" ON refund_items
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Audit Logs policies (read-only for non-admins)
CREATE POLICY "Allow authenticated read audit_logs" ON audit_logs
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow system insert audit_logs" ON audit_logs
  FOR INSERT TO authenticated WITH CHECK (true);

-- ===========================================
-- SECURITY: Remove plain PIN storage
-- ===========================================
-- Commented out as this needs careful migration
-- ALTER TABLE users DROP COLUMN IF EXISTS pin;
