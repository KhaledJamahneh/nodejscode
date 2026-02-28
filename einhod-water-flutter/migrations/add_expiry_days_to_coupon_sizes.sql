-- Add expiry_days column to coupon_sizes table
ALTER TABLE coupon_sizes 
ADD COLUMN IF NOT EXISTS expiry_days INTEGER DEFAULT 365;

COMMENT ON COLUMN coupon_sizes.expiry_days IS 'Number of days the coupon book is valid for after purchase';
