-- Add paid_amount and total_price columns to deliveries table
ALTER TABLE deliveries 
ADD COLUMN IF NOT EXISTS paid_amount DECIMAL(10, 2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS total_price DECIMAL(10, 2) DEFAULT 0;
