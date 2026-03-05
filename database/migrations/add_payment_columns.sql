-- Add payment tracking columns to deliveries table
ALTER TABLE deliveries 
ADD COLUMN IF NOT EXISTS paid_amount DECIMAL(10, 2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS total_price DECIMAL(10, 2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS paid_coupons_count INTEGER DEFAULT 0;

-- Add comment
COMMENT ON COLUMN deliveries.paid_amount IS 'Amount paid in cash for this delivery';
COMMENT ON COLUMN deliveries.total_price IS 'Total price for this delivery';
COMMENT ON COLUMN deliveries.paid_coupons_count IS 'Number of coupons used for this delivery';
