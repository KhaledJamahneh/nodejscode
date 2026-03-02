-- Create coupon sizes configuration table

CREATE TABLE coupon_sizes (
    id SERIAL PRIMARY KEY,
    size INTEGER NOT NULL UNIQUE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default sizes
INSERT INTO coupon_sizes (size) VALUES (100), (200), (300), (400), (500);

-- Create trigger for updated_at
CREATE TRIGGER update_coupon_sizes_updated_at
    BEFORE UPDATE ON coupon_sizes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
