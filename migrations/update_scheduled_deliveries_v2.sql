-- Add missing fields to scheduled_deliveries table
ALTER TABLE scheduled_deliveries 
  ADD COLUMN IF NOT EXISTS frequency_per_week INTEGER,
  ADD COLUMN IF NOT EXISTS frequency_per_month INTEGER;

-- Update schedule_type constraint to include 'custom'
ALTER TABLE scheduled_deliveries 
  DROP CONSTRAINT IF EXISTS scheduled_deliveries_schedule_type_check;

ALTER TABLE scheduled_deliveries 
  ADD CONSTRAINT scheduled_deliveries_schedule_type_check 
  CHECK (schedule_type IN ('daily', 'weekly', 'biweekly', 'monthly', 'custom'));
