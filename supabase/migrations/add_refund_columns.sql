-- Migration: add_refund_columns.sql
-- Purpose: Add missing columns to refunds table and create refund_items table
-- Run this on existing databases to update the refunds schema

-- Add missing columns to refunds table
ALTER TABLE refunds ADD COLUMN IF NOT EXISTS customer_id UUID REFERENCES customers(id);
ALTER TABLE refunds ADD COLUMN IF NOT EXISTS refund_number TEXT;
ALTER TABLE refunds ADD COLUMN IF NOT EXISTS notes TEXT;
ALTER TABLE refunds ADD COLUMN IF NOT EXISTS processed_at TIMESTAMPTZ;
ALTER TABLE refunds ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- Fix employee_id to reference users table (not employees)
ALTER TABLE refunds DROP CONSTRAINT IF EXISTS refunds_employee_id_fkey;
ALTER TABLE refunds ADD COLUMN IF NOT EXISTS employee_id UUID;
ALTER TABLE refunds DROP CONSTRAINT IF EXISTS refunds_employee_id_users_fkey;
ALTER TABLE refunds ADD CONSTRAINT refunds_employee_id_users_fkey 
    FOREIGN KEY (employee_id) REFERENCES users(id) ON DELETE SET NULL;

-- Make refund_number unique (for existing rows, generate one if null)
UPDATE refunds 
SET refund_number = 'REF-' || TO_CHAR(created_at, 'YYYYMMDD') || '-' || SUBSTRING(id::TEXT, 1, 4)
WHERE refund_number IS NULL;

ALTER TABLE refunds ALTER COLUMN refund_number SET NOT NULL;

-- Create unique index on refund_number if not exists
CREATE UNIQUE INDEX IF NOT EXISTS idx_refunds_refund_number ON refunds(refund_number);

-- Create refund_items table if not exists
CREATE TABLE IF NOT EXISTS refund_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    refund_id UUID REFERENCES refunds(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id),
    product_name TEXT NOT NULL,
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    restock_status TEXT DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index on refund_items
CREATE INDEX IF NOT EXISTS idx_refund_items_refund_id ON refund_items(refund_id);

-- Enable RLS and create policies for REFUNDS table
ALTER TABLE refunds ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all read refunds" ON refunds;
DROP POLICY IF EXISTS "Allow all insert refunds" ON refunds;
DROP POLICY IF EXISTS "Allow all update refunds" ON refunds;
DROP POLICY IF EXISTS "Allow all delete refunds" ON refunds;
CREATE POLICY "Allow all read refunds" ON refunds FOR SELECT USING (true);
CREATE POLICY "Allow all insert refunds" ON refunds FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow all update refunds" ON refunds FOR UPDATE USING (true);
CREATE POLICY "Allow all delete refunds" ON refunds FOR DELETE USING (true);

-- Enable RLS and create policies for REFUND_ITEMS table
ALTER TABLE refund_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all read" ON refund_items;
DROP POLICY IF EXISTS "Allow all insert" ON refund_items;
DROP POLICY IF EXISTS "Allow all update" ON refund_items;
DROP POLICY IF EXISTS "Allow all delete" ON refund_items;
CREATE POLICY "Allow all read" ON refund_items FOR SELECT USING (true);
CREATE POLICY "Allow all insert" ON refund_items FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow all update" ON refund_items FOR UPDATE USING (true);
CREATE POLICY "Allow all delete" ON refund_items FOR DELETE USING (true);
