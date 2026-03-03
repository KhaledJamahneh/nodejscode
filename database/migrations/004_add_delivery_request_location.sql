-- Migration: Add delivery location fields to delivery_requests
-- Date: 2026-03-03
-- Purpose: Allow clients to specify different delivery address per request

ALTER TABLE delivery_requests 
  ADD COLUMN IF NOT EXISTS delivery_address TEXT,
  ADD COLUMN IF NOT EXISTS delivery_latitude DECIMAL(10,8) CHECK (delivery_latitude BETWEEN -90 AND 90),
  ADD COLUMN IF NOT EXISTS delivery_longitude DECIMAL(11,8) CHECK (delivery_longitude BETWEEN -180 AND 180);

CREATE INDEX IF NOT EXISTS idx_delivery_requests_location 
  ON delivery_requests(delivery_latitude, delivery_longitude);

COMMENT ON COLUMN delivery_requests.delivery_address IS 'Optional custom delivery address (overrides client profile address)';
COMMENT ON COLUMN delivery_requests.delivery_latitude IS 'Optional custom delivery latitude';
COMMENT ON COLUMN delivery_requests.delivery_longitude IS 'Optional custom delivery longitude';
