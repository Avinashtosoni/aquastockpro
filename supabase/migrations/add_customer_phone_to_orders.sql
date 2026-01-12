-- Add customer_phone column to orders table
ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS customer_phone TEXT;

-- Update existing records to pull phone from customers table (optional but good for history)
UPDATE orders o
SET customer_phone = c.phone
FROM customers c
WHERE o.customer_id = c.id;
