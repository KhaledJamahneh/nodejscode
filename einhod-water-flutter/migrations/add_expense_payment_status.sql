-- Add payment_status to worker_expenses
ALTER TABLE worker_expenses 
ADD COLUMN payment_status VARCHAR(20) DEFAULT 'unpaid' CHECK (payment_status IN ('paid', 'unpaid'));

-- Update existing records to unpaid (debt)
UPDATE worker_expenses SET payment_status = 'unpaid' WHERE payment_status IS NULL;
