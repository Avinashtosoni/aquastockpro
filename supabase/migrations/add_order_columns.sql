-- =====================================================
-- MIGRATION: Add missing columns to orders and order_items
-- Run this in Supabase SQL Editor
-- =====================================================

-- ORDERS TABLE - Add missing columns
ALTER TABLE orders ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES users(id);
ALTER TABLE orders ADD COLUMN IF NOT EXISTS employee_name TEXT DEFAULT 'Staff';
ALTER TABLE orders ADD COLUMN IF NOT EXISTS item_count INTEGER DEFAULT 0;

-- ORDER_ITEMS TABLE - Add missing columns
ALTER TABLE order_items ADD COLUMN IF NOT EXISTS discount_amount DECIMAL(10,2) DEFAULT 0;
ALTER TABLE order_items ADD COLUMN IF NOT EXISTS tax_amount DECIMAL(10,2) DEFAULT 0;
ALTER TABLE order_items ADD COLUMN IF NOT EXISTS total_price DECIMAL(10,2) DEFAULT 0;

-- Verify columns exist
SELECT 'orders columns:' as info;
SELECT column_name FROM information_schema.columns WHERE table_name = 'orders';
SELECT 'order_items columns:' as info;
SELECT column_name FROM information_schema.columns WHERE table_name = 'order_items';
