-- Add destination field to worker_expenses
ALTER TABLE worker_expenses 
ADD COLUMN destination VARCHAR(200);
