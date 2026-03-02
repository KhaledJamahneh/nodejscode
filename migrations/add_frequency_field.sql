-- Add frequency_per_week field for custom schedule frequencies
ALTER TABLE scheduled_deliveries 
ADD COLUMN IF NOT EXISTS frequency_per_week INTEGER CHECK (frequency_per_week >= 1 AND frequency_per_week <= 7);

COMMENT ON COLUMN scheduled_deliveries.frequency_per_week IS 'Number of deliveries per week (1-7). Used with weekly schedule type.';

-- Add frequency_per_month field for monthly schedules
ALTER TABLE scheduled_deliveries 
ADD COLUMN IF NOT EXISTS frequency_per_month INTEGER CHECK (frequency_per_month >= 1 AND frequency_per_month <= 31);

COMMENT ON COLUMN scheduled_deliveries.frequency_per_month IS 'Number of deliveries per month (1-31). Used with monthly schedule type.';
