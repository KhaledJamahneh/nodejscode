-- Change coupon_book_size from integer to foreign key reference

-- Drop the old integer column
ALTER TABLE client_profiles DROP COLUMN IF EXISTS coupon_book_size;

-- Add foreign key reference to coupon_sizes table
ALTER TABLE client_profiles 
ADD COLUMN coupon_book_size_id INTEGER REFERENCES coupon_sizes(id);

-- Set default coupon size (200) for existing coupon_book clients
UPDATE client_profiles 
SET coupon_book_size_id = (SELECT id FROM coupon_sizes WHERE size = 200 LIMIT 1)
WHERE subscription_type = 'coupon_book' AND coupon_book_size_id IS NULL;

-- Create index
CREATE INDEX idx_client_coupon_size ON client_profiles(coupon_book_size_id);
