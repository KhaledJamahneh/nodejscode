-- Fix missing columns in deliveries and client_profiles
ALTER TABLE deliveries 
ADD COLUMN IF NOT EXISTS delivery_latitude DECIMAL(10, 8) CHECK (delivery_latitude BETWEEN -90 AND 90),
ADD COLUMN IF NOT EXISTS delivery_longitude DECIMAL(11, 8) CHECK (delivery_longitude BETWEEN -180 AND 180);

ALTER TABLE client_profiles 
ADD COLUMN IF NOT EXISTS gallons_on_hand INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS coupon_book_size_id INTEGER REFERENCES coupon_sizes(id);
