-- Add new product columns for enhanced inventory management
-- Run in Supabase SQL Editor

-- Add batch_number column
ALTER TABLE products ADD COLUMN IF NOT EXISTS batch_number TEXT;

-- Add expiry_date column
ALTER TABLE products ADD COLUMN IF NOT EXISTS expiry_date TIMESTAMP WITH TIME ZONE;

-- Add MRP column (Maximum Retail Price)
ALTER TABLE products ADD COLUMN IF NOT EXISTS mrp DECIMAL(10, 2);

-- Add GST rate column
ALTER TABLE products ADD COLUMN IF NOT EXISTS gst_rate DECIMAL(5, 2) DEFAULT 0;

-- Add brand column
ALTER TABLE products ADD COLUMN IF NOT EXISTS brand TEXT;

-- Create index on batch_number for faster lookups
CREATE INDEX IF NOT EXISTS idx_products_batch_number ON products(batch_number);

-- Create index on expiry_date for tracking expiring products
CREATE INDEX IF NOT EXISTS idx_products_expiry_date ON products(expiry_date);

-- Update RLS policies if not already set
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all read" ON products;
DROP POLICY IF EXISTS "Allow all insert" ON products;
DROP POLICY IF EXISTS "Allow all update" ON products;
DROP POLICY IF EXISTS "Allow all delete" ON products;
CREATE POLICY "Allow all read" ON products FOR SELECT USING (true);
CREATE POLICY "Allow all insert" ON products FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow all update" ON products FOR UPDATE USING (true);
CREATE POLICY "Allow all delete" ON products FOR DELETE USING (true);
