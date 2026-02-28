-- Add location tracking table
CREATE TABLE worker_locations (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    accuracy DOUBLE PRECISION,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_worker_locations_user_id ON worker_locations(user_id);
CREATE INDEX idx_worker_locations_updated_at ON worker_locations(updated_at);

-- Function to calculate distance between two points (in meters)
CREATE OR REPLACE FUNCTION calculate_distance(
    lat1 DOUBLE PRECISION,
    lon1 DOUBLE PRECISION,
    lat2 DOUBLE PRECISION,
    lon2 DOUBLE PRECISION
) RETURNS DOUBLE PRECISION AS $$
DECLARE
    R CONSTANT DOUBLE PRECISION := 6371000; -- Earth radius in meters
    dLat DOUBLE PRECISION;
    dLon DOUBLE PRECISION;
    a DOUBLE PRECISION;
    c DOUBLE PRECISION;
BEGIN
    dLat := radians(lat2 - lat1);
    dLon := radians(lon2 - lon1);
    
    a := sin(dLat/2) * sin(dLat/2) +
         cos(radians(lat1)) * cos(radians(lat2)) *
         sin(dLon/2) * sin(dLon/2);
    
    c := 2 * atan2(sqrt(a), sqrt(1-a));
    
    RETURN R * c;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function to check nearby clients (within 500m)
CREATE OR REPLACE FUNCTION get_nearby_clients(
    p_worker_id INTEGER,
    p_distance_meters INTEGER DEFAULT 500
) RETURNS TABLE (
    client_id INTEGER,
    client_name TEXT,
    distance DOUBLE PRECISION
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        cp.user_id,
        cp.full_name,
        calculate_distance(
            wl.latitude, wl.longitude,
            cp.latitude, cp.longitude
        ) as dist
    FROM worker_locations wl
    JOIN client_profiles cp ON calculate_distance(
        wl.latitude, wl.longitude,
        cp.latitude, cp.longitude
    ) <= p_distance_meters
    WHERE wl.user_id = p_worker_id
    AND wl.updated_at > NOW() - INTERVAL '5 minutes'
    ORDER BY dist;
END;
$$ LANGUAGE plpgsql;
