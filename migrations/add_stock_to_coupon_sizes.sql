-- Add available_stock column to coupon_sizes table
ALTER TABLE coupon_sizes
ADD COLUMN IF NOT EXISTS available_stock INTEGER DEFAULT 100;
