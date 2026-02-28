-- Add CHECK constraints to validate GPS coordinates
-- Latitude must be between -90 and 90
-- Longitude must be between -180 and 180

DO $$
BEGIN
    -- Deliveries table
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'valid_delivery_latitude') THEN
        ALTER TABLE deliveries ADD CONSTRAINT valid_delivery_latitude CHECK (delivery_latitude BETWEEN -90 AND 90);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'valid_delivery_longitude') THEN
        ALTER TABLE deliveries ADD CONSTRAINT valid_delivery_longitude CHECK (delivery_longitude BETWEEN -180 AND 180);
    END IF;

    -- Client profiles table
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'valid_home_latitude') THEN
        ALTER TABLE client_profiles ADD CONSTRAINT valid_home_latitude CHECK (home_latitude BETWEEN -90 AND 90);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'valid_home_longitude') THEN
        ALTER TABLE client_profiles ADD CONSTRAINT valid_home_longitude CHECK (home_longitude BETWEEN -180 AND 180);
    END IF;

    -- Worker locations table
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'valid_worker_latitude') THEN
        ALTER TABLE worker_locations ADD CONSTRAINT valid_worker_latitude CHECK (latitude BETWEEN -90 AND 90);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'valid_worker_longitude') THEN
        ALTER TABLE worker_locations ADD CONSTRAINT valid_worker_longitude CHECK (longitude BETWEEN -180 AND 180);
    END IF;
END $$;
