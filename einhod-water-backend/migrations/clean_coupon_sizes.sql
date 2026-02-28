-- Clean coupon sizes implementation

-- Create coupon_sizes table
CREATE TABLE coupon_sizes (
    id SERIAL PRIMARY KEY,
    size INTEGER NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Add coupon_book_size_id to client_profiles
ALTER TABLE client_profiles 
ADD COLUMN coupon_book_size_id INTEGER REFERENCES coupon_sizes(id) ON DELETE SET NULL;

-- Create index
CREATE INDEX idx_client_coupon_size ON client_profiles(coupon_book_size_id);

-- Create trigger for updated_at
CREATE TRIGGER update_coupon_sizes_updated_at
    BEFORE UPDATE ON coupon_sizes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Insert default sizes
INSERT INTO coupon_sizes (size) VALUES (100), (200), (300), (400), (500);

-- Set default size for existing coupon_book clients
UPDATE client_profiles 
SET coupon_book_size_id = (SELECT id FROM coupon_sizes WHERE size = 200 LIMIT 1)
WHERE subscription_type = 'coupon_book' AND coupon_book_size_id IS NULL;
