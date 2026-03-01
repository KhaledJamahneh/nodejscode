-- Consolidate language preference to users table
-- Single source of truth for all user language preferences

-- Step 1: Add preferred_language to users table
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS preferred_language VARCHAR(10) DEFAULT 'en';

-- Step 2: Migrate existing client language preferences
UPDATE users u
SET preferred_language = cp.preferred_language
FROM client_profiles cp
WHERE u.id = cp.user_id 
AND cp.preferred_language IS NOT NULL
AND cp.preferred_language != 'en';

-- Step 3: Migrate existing worker language preferences (overwrites for dual-role users)
UPDATE users u
SET preferred_language = wp.preferred_language
FROM worker_profiles wp
WHERE u.id = wp.user_id 
AND wp.preferred_language IS NOT NULL
AND wp.preferred_language != 'en';

-- Step 4: Remove redundant columns (optional - uncomment to execute)
-- ALTER TABLE client_profiles DROP COLUMN IF EXISTS preferred_language;
-- ALTER TABLE worker_profiles DROP COLUMN IF EXISTS preferred_language;
