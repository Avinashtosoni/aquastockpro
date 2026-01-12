-- =============================================
-- COMPLETE MIGRATION - Add ALL missing columns
-- Run this in Supabase SQL Editor
-- =============================================

-- 1. EMPLOYEES TABLE - Add ALL missing columns
ALTER TABLE employees 
ADD COLUMN IF NOT EXISTS pin TEXT,
ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'cashier',
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS address TEXT,
ADD COLUMN IF NOT EXISTS emergency_contact TEXT,
ADD COLUMN IF NOT EXISTS salary NUMERIC,
ADD COLUMN IF NOT EXISTS join_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- 2. ORDERS TABLE - Add customer phone for tracking
ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS customer_phone TEXT;

-- 3. CUSTOMERS TABLE - Ensure address column exists
ALTER TABLE customers
ADD COLUMN IF NOT EXISTS address TEXT;

-- Done! Refresh your app after running this.
