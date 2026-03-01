-- Add preferred_language to worker_profiles
ALTER TABLE worker_profiles 
ADD COLUMN IF NOT EXISTS preferred_language VARCHAR(10) DEFAULT 'en';
