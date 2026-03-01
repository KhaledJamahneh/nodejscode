-- Add assigned_worker_id to coupon_book_requests table
ALTER TABLE coupon_book_requests 
ADD COLUMN IF NOT EXISTS assigned_worker_id INTEGER REFERENCES worker_profiles(id);

CREATE INDEX IF NOT EXISTS idx_coupon_requests_worker ON coupon_book_requests(assigned_worker_id);
