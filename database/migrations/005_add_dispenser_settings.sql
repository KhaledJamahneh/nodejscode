-- Migration: Add dispenser_settings column to client_profiles
-- Date: 2026-03-03
-- Description: Add JSONB column for storing client dispenser preferences

ALTER TABLE client_profiles 
ADD COLUMN IF NOT EXISTS dispenser_settings JSONB 
DEFAULT '{"auto_refill": true, "notifications_enabled": true, "low_water_threshold": 2}'::jsonb;

-- Add comment
COMMENT ON COLUMN client_profiles.dispenser_settings IS 'Client dispenser preferences and settings';
