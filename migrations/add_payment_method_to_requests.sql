-- Add payment_method to delivery_requests
ALTER TABLE delivery_requests 
ADD COLUMN IF NOT EXISTS payment_method payment_method DEFAULT 'cash';
