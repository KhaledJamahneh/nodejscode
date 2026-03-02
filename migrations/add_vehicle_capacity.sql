-- Add vehicle_capacity column and constraint to worker_profiles
ALTER TABLE worker_profiles
ADD COLUMN IF NOT EXISTS vehicle_capacity INTEGER DEFAULT 1000;

-- Ensure current gallons does not exceed capacity
-- Note: We use a DO block to safely add the constraint
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'vehicle_capacity_limit') THEN
        ALTER TABLE worker_profiles ADD CONSTRAINT vehicle_capacity_limit CHECK (vehicle_current_gallons <= vehicle_capacity);
    END IF;
END $$;
