-- Fix test client display names
-- Replace technical usernames with proper full names

UPDATE client_profiles 
SET full_name = 'Grace Johnson'
WHERE full_name = 'test_client_grace';

UPDATE client_profiles 
SET full_name = 'Compatible Coupon Client'
WHERE full_name = 'compat_coupon_client';

-- Update any other test clients with technical names
UPDATE client_profiles 
SET full_name = INITCAP(REPLACE(REPLACE(full_name, '_', ' '), 'test client ', ''))
WHERE full_name LIKE 'test_%' OR full_name LIKE '%_client%';
