-- AquaStock Pro Database Schema for Supabase
-- Run this in Supabase SQL Editor to set up all tables

-- =====================================================
-- USERS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    role TEXT NOT NULL DEFAULT 'cashier',
    pin TEXT,
    pin_hash TEXT,
    password_hash TEXT,
    avatar_url TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- CATEGORIES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    icon_name TEXT,
    color_hex TEXT,
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- PRODUCTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    sku TEXT,
    barcode TEXT,
    price DECIMAL(10,2) NOT NULL,
    cost_price DECIMAL(10,2),
    stock_quantity INTEGER DEFAULT 0,
    low_stock_threshold INTEGER DEFAULT 10,
    category_id UUID REFERENCES categories(id),
    image_url TEXT,
    unit TEXT DEFAULT 'pcs',
    track_inventory BOOLEAN DEFAULT true,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- CUSTOMERS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    phone TEXT,
    email TEXT,
    address TEXT,
    customer_type TEXT DEFAULT 'retail',
    credit_balance DECIMAL(10,2) DEFAULT 0,
    credit_limit DECIMAL(10,2) DEFAULT 5000,
    total_purchases DECIMAL(10,2) DEFAULT 0,
    visit_count INTEGER DEFAULT 0,
    loyalty_points INTEGER DEFAULT 0,
    discount_percentage DECIMAL(5,2) DEFAULT 0,
    notes TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- ORDERS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_number TEXT NOT NULL UNIQUE,
    customer_id UUID REFERENCES customers(id),
    customer_name TEXT,
    user_id UUID REFERENCES users(id),
    employee_name TEXT,
    status TEXT DEFAULT 'pending',
    payment_method TEXT DEFAULT 'cash',
    subtotal DECIMAL(10,2) DEFAULT 0,
    tax_amount DECIMAL(10,2) DEFAULT 0,
    discount_amount DECIMAL(10,2) DEFAULT 0,
    total_amount DECIMAL(10,2) DEFAULT 0,
    paid_amount DECIMAL(10,2) DEFAULT 0,
    change_amount DECIMAL(10,2) DEFAULT 0,
    item_count INTEGER DEFAULT 0,
    notes TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- ORDER ITEMS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id),
    product_name TEXT NOT NULL,
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    discount_amount DECIMAL(10,2) DEFAULT 0,
    tax_amount DECIMAL(10,2) DEFAULT 0,
    total_price DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- SUPPLIERS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS suppliers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    contact_person TEXT,
    phone TEXT NOT NULL,
    email TEXT,
    address TEXT,
    gstin TEXT,
    outstanding_amount DECIMAL(10,2) DEFAULT 0,
    bank_details TEXT,
    notes TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- EMPLOYEES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS employees (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    phone TEXT,
    email TEXT,
    pin TEXT,
    role TEXT DEFAULT 'cashier',
    is_active BOOLEAN DEFAULT true,
    join_date TIMESTAMPTZ DEFAULT NOW(),
    salary DECIMAL(10,2),
    address TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- BUSINESS SETTINGS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS business_settings (
    id TEXT PRIMARY KEY DEFAULT 'default',
    business_name TEXT DEFAULT 'AquaStock Pro',
    tagline TEXT,
    logo_url TEXT,
    email TEXT,
    phone TEXT,
    address TEXT,
    city TEXT,
    state TEXT,
    postal_code TEXT,
    gstin TEXT,
    currency_symbol TEXT DEFAULT '₹',
    currency_code TEXT DEFAULT 'INR',
    tax_rate DECIMAL(5,2) DEFAULT 5.0,
    tax_label TEXT DEFAULT 'GST',
    receipt_header TEXT,
    receipt_footer TEXT,
    thank_you_message TEXT,
    show_logo BOOLEAN DEFAULT true,
    show_tax_breakdown BOOLEAN DEFAULT true,
    enable_loyalty_points BOOLEAN DEFAULT false,
    loyalty_points_per_amount DECIMAL(10,2) DEFAULT 100,
    sms_enabled BOOLEAN DEFAULT false,
    sms_method TEXT DEFAULT 'sim',
    sms_provider TEXT DEFAULT 'msg91',
    sms_api_key TEXT,
    sms_sender_id TEXT,
    sms_template_id TEXT,
    sms_template TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- STOCK ADJUSTMENTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS stock_adjustments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES products(id),
    product_name TEXT NOT NULL,
    employee_id UUID,
    employee_name TEXT,
    previous_quantity INTEGER NOT NULL,
    adjusted_quantity INTEGER NOT NULL,
    new_quantity INTEGER NOT NULL,
    reason TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- CREDIT TRANSACTIONS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS credit_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID REFERENCES customers(id),
    order_id UUID REFERENCES orders(id),
    type TEXT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    balance_after DECIMAL(10,2) NOT NULL,
    notes TEXT,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- DISCOUNTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS discounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    code TEXT UNIQUE,
    type TEXT DEFAULT 'percentage',
    value DECIMAL(10,2) NOT NULL,
    min_order_amount DECIMAL(10,2),
    max_discount_amount DECIMAL(10,2),
    valid_from TIMESTAMPTZ,
    valid_until TIMESTAMPTZ,
    usage_limit INTEGER,
    usage_count INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- REFUNDS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS refunds (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES orders(id),
    customer_id UUID REFERENCES customers(id),
    employee_id UUID REFERENCES users(id),
    refund_number TEXT UNIQUE NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    reason TEXT,
    status TEXT DEFAULT 'pending',
    notes TEXT,
    processed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- REFUND ITEMS TABLE
-- =====================================================
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

-- =====================================================
-- ROW LEVEL SECURITY POLICIES
-- Enable RLS on all tables and allow public access
-- =====================================================

-- Users
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all read" ON users;
DROP POLICY IF EXISTS "Allow all insert" ON users;
DROP POLICY IF EXISTS "Allow all update" ON users;
DROP POLICY IF EXISTS "Allow all delete" ON users;
DROP POLICY IF EXISTS "Users can view own data" ON users;
DROP POLICY IF EXISTS "Admins can view all users" ON users;
CREATE POLICY "Allow all read" ON users FOR SELECT USING (true);
CREATE POLICY "Allow all insert" ON users FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow all update" ON users FOR UPDATE USING (true);
CREATE POLICY "Allow all delete" ON users FOR DELETE USING (true);

-- Categories
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all read" ON categories;
DROP POLICY IF EXISTS "Allow all insert" ON categories;
DROP POLICY IF EXISTS "Allow all update" ON categories;
DROP POLICY IF EXISTS "Allow all delete" ON categories;
CREATE POLICY "Allow all read" ON categories FOR SELECT USING (true);
CREATE POLICY "Allow all insert" ON categories FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow all update" ON categories FOR UPDATE USING (true);
CREATE POLICY "Allow all delete" ON categories FOR DELETE USING (true);

-- Products
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all read" ON products;
DROP POLICY IF EXISTS "Allow all insert" ON products;
DROP POLICY IF EXISTS "Allow all update" ON products;
DROP POLICY IF EXISTS "Allow all delete" ON products;
CREATE POLICY "Allow all read" ON products FOR SELECT USING (true);
CREATE POLICY "Allow all insert" ON products FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow all update" ON products FOR UPDATE USING (true);
CREATE POLICY "Allow all delete" ON products FOR DELETE USING (true);

-- Customers
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all read" ON customers;
DROP POLICY IF EXISTS "Allow all insert" ON customers;
DROP POLICY IF EXISTS "Allow all update" ON customers;
DROP POLICY IF EXISTS "Allow all delete" ON customers;
CREATE POLICY "Allow all read" ON customers FOR SELECT USING (true);
CREATE POLICY "Allow all insert" ON customers FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow all update" ON customers FOR UPDATE USING (true);
CREATE POLICY "Allow all delete" ON customers FOR DELETE USING (true);

-- Orders
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all read" ON orders;
DROP POLICY IF EXISTS "Allow all insert" ON orders;
DROP POLICY IF EXISTS "Allow all update" ON orders;
DROP POLICY IF EXISTS "Allow all delete" ON orders;
CREATE POLICY "Allow all read" ON orders FOR SELECT USING (true);
CREATE POLICY "Allow all insert" ON orders FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow all update" ON orders FOR UPDATE USING (true);
CREATE POLICY "Allow all delete" ON orders FOR DELETE USING (true);

-- Order Items
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all read" ON order_items;
DROP POLICY IF EXISTS "Allow all insert" ON order_items;
DROP POLICY IF EXISTS "Allow all update" ON order_items;
DROP POLICY IF EXISTS "Allow all delete" ON order_items;
CREATE POLICY "Allow all read" ON order_items FOR SELECT USING (true);
CREATE POLICY "Allow all insert" ON order_items FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow all update" ON order_items FOR UPDATE USING (true);
CREATE POLICY "Allow all delete" ON order_items FOR DELETE USING (true);

-- Suppliers
ALTER TABLE suppliers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all read" ON suppliers;
DROP POLICY IF EXISTS "Allow all insert" ON suppliers;
DROP POLICY IF EXISTS "Allow all update" ON suppliers;
DROP POLICY IF EXISTS "Allow all delete" ON suppliers;
CREATE POLICY "Allow all read" ON suppliers FOR SELECT USING (true);
CREATE POLICY "Allow all insert" ON suppliers FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow all update" ON suppliers FOR UPDATE USING (true);
CREATE POLICY "Allow all delete" ON suppliers FOR DELETE USING (true);

-- Employees
ALTER TABLE employees ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all read" ON employees;
DROP POLICY IF EXISTS "Allow all insert" ON employees;
DROP POLICY IF EXISTS "Allow all update" ON employees;
DROP POLICY IF EXISTS "Allow all delete" ON employees;
CREATE POLICY "Allow all read" ON employees FOR SELECT USING (true);
CREATE POLICY "Allow all insert" ON employees FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow all update" ON employees FOR UPDATE USING (true);
CREATE POLICY "Allow all delete" ON employees FOR DELETE USING (true);

-- Business Settings
ALTER TABLE business_settings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all read" ON business_settings;
DROP POLICY IF EXISTS "Allow all insert" ON business_settings;
DROP POLICY IF EXISTS "Allow all update" ON business_settings;
DROP POLICY IF EXISTS "Allow all delete" ON business_settings;
CREATE POLICY "Allow all read" ON business_settings FOR SELECT USING (true);
CREATE POLICY "Allow all insert" ON business_settings FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow all update" ON business_settings FOR UPDATE USING (true);
CREATE POLICY "Allow all delete" ON business_settings FOR DELETE USING (true);

-- Stock Adjustments
ALTER TABLE stock_adjustments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all read" ON stock_adjustments;
DROP POLICY IF EXISTS "Allow all insert" ON stock_adjustments;
DROP POLICY IF EXISTS "Allow all update" ON stock_adjustments;
DROP POLICY IF EXISTS "Allow all delete" ON stock_adjustments;
CREATE POLICY "Allow all read" ON stock_adjustments FOR SELECT USING (true);
CREATE POLICY "Allow all insert" ON stock_adjustments FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow all update" ON stock_adjustments FOR UPDATE USING (true);
CREATE POLICY "Allow all delete" ON stock_adjustments FOR DELETE USING (true);

-- Credit Transactions
ALTER TABLE credit_transactions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all read" ON credit_transactions;
DROP POLICY IF EXISTS "Allow all insert" ON credit_transactions;
DROP POLICY IF EXISTS "Allow all update" ON credit_transactions;
DROP POLICY IF EXISTS "Allow all delete" ON credit_transactions;
CREATE POLICY "Allow all read" ON credit_transactions FOR SELECT USING (true);
CREATE POLICY "Allow all insert" ON credit_transactions FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow all update" ON credit_transactions FOR UPDATE USING (true);
CREATE POLICY "Allow all delete" ON credit_transactions FOR DELETE USING (true);

-- Discounts
ALTER TABLE discounts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all read" ON discounts;
DROP POLICY IF EXISTS "Allow all insert" ON discounts;
DROP POLICY IF EXISTS "Allow all update" ON discounts;
DROP POLICY IF EXISTS "Allow all delete" ON discounts;
CREATE POLICY "Allow all read" ON discounts FOR SELECT USING (true);
CREATE POLICY "Allow all insert" ON discounts FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow all update" ON discounts FOR UPDATE USING (true);
CREATE POLICY "Allow all delete" ON discounts FOR DELETE USING (true);

-- Refunds
ALTER TABLE refunds ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all read" ON refunds;
DROP POLICY IF EXISTS "Allow all insert" ON refunds;
DROP POLICY IF EXISTS "Allow all update" ON refunds;
DROP POLICY IF EXISTS "Allow all delete" ON refunds;
CREATE POLICY "Allow all read" ON refunds FOR SELECT USING (true);
CREATE POLICY "Allow all insert" ON refunds FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow all update" ON refunds FOR UPDATE USING (true);
CREATE POLICY "Allow all delete" ON refunds FOR DELETE USING (true);

-- =====================================================
-- STORAGE BUCKETS
-- Create public buckets for images
-- =====================================================

-- Create product-images bucket (simpler approach)
INSERT INTO storage.buckets (id, name, public)
VALUES ('product-images', 'product-images', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Create logos bucket  
INSERT INTO storage.buckets (id, name, public)
VALUES ('logos', 'logos', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Create receipts bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('receipts', 'receipts', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- =====================================================
-- STORAGE POLICIES
-- Allow all operations on public buckets
-- =====================================================

-- Drop ALL existing policies on storage.objects to avoid conflicts
DO $$ 
BEGIN
    -- Try to drop policies, ignore errors if they don't exist
    EXECUTE 'DROP POLICY IF EXISTS "Allow public read on product-images" ON storage.objects';
    EXECUTE 'DROP POLICY IF EXISTS "Allow public insert on product-images" ON storage.objects';
    EXECUTE 'DROP POLICY IF EXISTS "Allow public update on product-images" ON storage.objects';
    EXECUTE 'DROP POLICY IF EXISTS "Allow public delete on product-images" ON storage.objects';
    EXECUTE 'DROP POLICY IF EXISTS "Allow public read on logos" ON storage.objects';
    EXECUTE 'DROP POLICY IF EXISTS "Allow public insert on logos" ON storage.objects';
    EXECUTE 'DROP POLICY IF EXISTS "Allow public update on logos" ON storage.objects';
    EXECUTE 'DROP POLICY IF EXISTS "Allow public delete on logos" ON storage.objects';
    EXECUTE 'DROP POLICY IF EXISTS "Allow public read on receipts" ON storage.objects';
    EXECUTE 'DROP POLICY IF EXISTS "Allow public insert on receipts" ON storage.objects';
    EXECUTE 'DROP POLICY IF EXISTS "Allow public update on receipts" ON storage.objects';
    EXECUTE 'DROP POLICY IF EXISTS "Allow public delete on receipts" ON storage.objects';
    EXECUTE 'DROP POLICY IF EXISTS "Public read product-images" ON storage.objects';
    EXECUTE 'DROP POLICY IF EXISTS "Public upload product-images" ON storage.objects';
    EXECUTE 'DROP POLICY IF EXISTS "Public delete product-images" ON storage.objects';
    EXECUTE 'DROP POLICY IF EXISTS "Public read logos" ON storage.objects';
    EXECUTE 'DROP POLICY IF EXISTS "Public upload logos" ON storage.objects';
    EXECUTE 'DROP POLICY IF EXISTS "Public delete logos" ON storage.objects';
    EXECUTE 'DROP POLICY IF EXISTS "Public read receipts" ON storage.objects';
    EXECUTE 'DROP POLICY IF EXISTS "Public upload receipts" ON storage.objects';
    EXECUTE 'DROP POLICY IF EXISTS "Public delete receipts" ON storage.objects';
END $$;

-- Product Images policies
CREATE POLICY "Allow public read on product-images" ON storage.objects
    FOR SELECT TO public USING (bucket_id = 'product-images');

CREATE POLICY "Allow public insert on product-images" ON storage.objects
    FOR INSERT TO public WITH CHECK (bucket_id = 'product-images');

CREATE POLICY "Allow public update on product-images" ON storage.objects
    FOR UPDATE TO public USING (bucket_id = 'product-images');

CREATE POLICY "Allow public delete on product-images" ON storage.objects
    FOR DELETE TO public USING (bucket_id = 'product-images');

-- Logos policies
CREATE POLICY "Allow public read on logos" ON storage.objects
    FOR SELECT TO public USING (bucket_id = 'logos');

CREATE POLICY "Allow public insert on logos" ON storage.objects
    FOR INSERT TO public WITH CHECK (bucket_id = 'logos');

CREATE POLICY "Allow public update on logos" ON storage.objects
    FOR UPDATE TO public USING (bucket_id = 'logos');

CREATE POLICY "Allow public delete on logos" ON storage.objects
    FOR DELETE TO public USING (bucket_id = 'logos');

-- Receipts policies
CREATE POLICY "Allow public read on receipts" ON storage.objects
    FOR SELECT TO public USING (bucket_id = 'receipts');

CREATE POLICY "Allow public insert on receipts" ON storage.objects
    FOR INSERT TO public WITH CHECK (bucket_id = 'receipts');

CREATE POLICY "Allow public update on receipts" ON storage.objects
    FOR UPDATE TO public USING (bucket_id = 'receipts');

CREATE POLICY "Allow public delete on receipts" ON storage.objects
    FOR DELETE TO public USING (bucket_id = 'receipts');
