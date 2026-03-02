-- Remove expiry_days column from coupon_sizes table
ALTER TABLE coupon_sizes DROP COLUMN IF EXISTS expiry_days;

-- Remove subscription_expiry_date column from client_profiles table
ALTER TABLE client_profiles DROP COLUMN IF EXISTS subscription_expiry_date;

-- Remove subscription expiry warning setting
DELETE FROM system_settings WHERE key = 'subscription_expiry_warning_days';
