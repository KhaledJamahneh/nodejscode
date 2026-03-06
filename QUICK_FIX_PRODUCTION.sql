-- Quick fix: Add debt tracking columns to production database
-- Run this SQL directly on your production database

-- Add columns if they don't exist
ALTER TABLE deliveries 
ADD COLUMN IF NOT EXISTS debt_paid BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS debt_paid_at TIMESTAMP,
ADD COLUMN IF NOT EXISTS debt_payment_method VARCHAR(20);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_deliveries_debt_paid ON deliveries(debt_paid);

-- Verify columns were added
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'deliveries' 
  AND column_name IN ('debt_paid', 'debt_paid_at', 'debt_payment_method');
