-- Add bonus field to coupon_sizes table
ALTER TABLE coupon_sizes 
ADD COLUMN IF NOT EXISTS bonus_gallons INTEGER DEFAULT 0;

-- Update existing records with bonus based on size
UPDATE coupon_sizes SET bonus_gallons = 1 WHERE size = 10;
UPDATE coupon_sizes SET bonus_gallons = 2 WHERE size = 20;
UPDATE coupon_sizes SET bonus_gallons = FLOOR(size / 10.0) WHERE size > 20;

-- Add comment
COMMENT ON COLUMN coupon_sizes.bonus_gallons IS 'Bonus gallons added when purchasing this coupon book size';
