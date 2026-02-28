-- Add bonus_gallons to client_profiles
ALTER TABLE client_profiles 
ADD COLUMN IF NOT EXISTS bonus_gallons INTEGER DEFAULT 0;
