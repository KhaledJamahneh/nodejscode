-- Add CHECK constraints to prevent invalid payment amounts
-- Financial compliance: Database is the last line of defense

-- 1. Payments table: Ensure positive amounts only
ALTER TABLE payments 
ADD CONSTRAINT check_payment_amount_positive 
CHECK (amount > 0);

-- 2. Expenses table: Ensure positive amounts only
ALTER TABLE expenses 
ADD CONSTRAINT check_expense_amount_positive 
CHECK (amount > 0);

-- 3. Deliveries table: Ensure non-negative paid amounts
ALTER TABLE deliveries 
ADD CONSTRAINT check_delivery_paid_amount_non_negative 
CHECK (paid_amount >= 0);

ALTER TABLE deliveries 
ADD CONSTRAINT check_delivery_total_price_non_negative 
CHECK (total_price >= 0);

-- 4. Coupon sizes: Ensure positive prices
ALTER TABLE coupon_sizes 
ADD CONSTRAINT check_coupon_price_positive 
CHECK (price > 0);

-- Fix any existing invalid data
UPDATE payments SET amount = 0.01 WHERE amount <= 0;
UPDATE expenses SET amount = 0.01 WHERE amount <= 0;
UPDATE deliveries SET paid_amount = 0 WHERE paid_amount < 0;
UPDATE deliveries SET total_price = 0 WHERE total_price < 0;
UPDATE coupon_sizes SET price = 0.01 WHERE price <= 0;
