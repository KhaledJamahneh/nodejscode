-- Add debt tracking columns to deliveries table
ALTER TABLE deliveries 
ADD COLUMN IF NOT EXISTS debt_paid BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS debt_paid_at TIMESTAMP,
ADD COLUMN IF NOT EXISTS debt_payment_method VARCHAR(20);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_deliveries_debt_paid ON deliveries(debt_paid);
