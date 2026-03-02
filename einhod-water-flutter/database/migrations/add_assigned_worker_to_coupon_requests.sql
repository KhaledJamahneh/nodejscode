-- Add assigned_worker_id column to coupon_book_requests table
ALTER TABLE coupon_book_requests 
ADD COLUMN assigned_worker_id INTEGER REFERENCES worker_profiles(id) ON DELETE SET NULL;

-- Add index for performance
CREATE INDEX idx_coupon_requests_worker ON coupon_book_requests(assigned_worker_id);
