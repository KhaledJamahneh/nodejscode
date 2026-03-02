-- Drop redundant preferred_language columns from profile tables
-- Single source of truth is now users.preferred_language

BEGIN;

-- Drop from client_profiles
ALTER TABLE client_profiles DROP COLUMN IF EXISTS preferred_language;

COMMIT;
