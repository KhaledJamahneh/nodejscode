-- Add coupon book size to client profiles

-- Add coupon_book_size column as integer
ALTER TABLE client_profiles 
ADD COLUMN coupon_book_size INTEGER;

-- Set default size for existing coupon_book clients
UPDATE client_profiles 
SET coupon_book_size = 200 
WHERE subscription_type = 'coupon_book' AND coupon_book_size IS NULL;
