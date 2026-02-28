-- Add gallons_on_hand column to track reserved gallons at client location
ALTER TABLE client_profiles 
ADD COLUMN IF NOT EXISTS gallons_on_hand INTEGER DEFAULT 0;

-- Add comment for clarity
COMMENT ON COLUMN client_profiles.gallons_on_hand IS 'Number of gallons currently at client location (delivered but not yet returned as empties)';
