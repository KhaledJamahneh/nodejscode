-- Add CHECK constraints to prevent negative inventory and capacity violations
-- This ensures data integrity at the database level

-- 1. Prevent negative inventory
ALTER TABLE worker_profiles 
ADD CONSTRAINT check_vehicle_current_gallons_non_negative 
CHECK (vehicle_current_gallons >= 0);

-- 2. Prevent inventory exceeding capacity
ALTER TABLE worker_profiles 
ADD CONSTRAINT check_vehicle_current_gallons_within_capacity 
CHECK (vehicle_current_gallons <= vehicle_capacity);

-- 3. Ensure capacity is positive
ALTER TABLE worker_profiles 
ADD CONSTRAINT check_vehicle_capacity_positive 
CHECK (vehicle_capacity > 0);

-- Fix any existing invalid data first (set negative to 0)
UPDATE worker_profiles 
SET vehicle_current_gallons = 0 
WHERE vehicle_current_gallons < 0;

-- Fix any existing over-capacity data
UPDATE worker_profiles 
SET vehicle_current_gallons = vehicle_capacity 
WHERE vehicle_current_gallons > vehicle_capacity;
