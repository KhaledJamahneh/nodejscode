-- Add partial payment tracking
ALTER TABLE deliveries 
ADD COLUMN IF NOT EXISTS partial_payment_amount DECIMAL(10, 2) DEFAULT 0;

-- Update existing records
UPDATE deliveries 
SET partial_payment_amount = 0 
WHERE partial_payment_amount IS NULL;
