-- Add integrity constraints to prevent negative or extreme values

DO $$
BEGIN
    -- 1. Delivery Requests: Gallons must be between 1 and 1000
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'positive_requested_gallons') THEN
        ALTER TABLE delivery_requests ADD CONSTRAINT positive_requested_gallons CHECK (requested_gallons > 0 AND requested_gallons <= 1000);
    END IF;

    -- 2. Deliveries: Gallons delivered must be non-negative and <= 1000
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'positive_delivered_gallons') THEN
        ALTER TABLE deliveries ADD CONSTRAINT positive_delivered_gallons CHECK (gallons_delivered >= 0 AND gallons_delivered <= 1000);
    END IF;

    -- 3. Worker Profiles: Vehicle inventory cannot be negative
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'positive_vehicle_inventory') THEN
        ALTER TABLE worker_profiles ADD CONSTRAINT positive_vehicle_inventory CHECK (vehicle_current_gallons >= 0);
    END IF;

    -- 4. Client Profiles: Coupons and Debt constraints
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'positive_remaining_coupons') THEN
        ALTER TABLE client_profiles ADD CONSTRAINT positive_remaining_coupons CHECK (remaining_coupons >= 0);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'reasonable_current_debt') THEN
        ALTER TABLE client_profiles ADD CONSTRAINT reasonable_current_debt CHECK (current_debt >= 0 AND current_debt <= 1000000);
    END IF;
END $$;
