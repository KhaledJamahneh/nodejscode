-- ============================================================================
-- FIX ALL LOGICAL ISSUES - COMPREHENSIVE MIGRATION
-- Date: 2026-02-28
-- ============================================================================

-- 1. ENABLE MULTIPLE ROLES: Change role from single ENUM to array
ALTER TABLE users DROP COLUMN role;
ALTER TABLE users ADD COLUMN roles user_role[] NOT NULL DEFAULT ARRAY['client']::user_role[];
CREATE INDEX idx_users_roles ON users USING GIN(roles);

-- 2. FIX TIMEZONE ISSUES: Convert all TIMESTAMP to TIMESTAMPTZ
ALTER TABLE users 
  ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE 'Asia/Jerusalem',
  ALTER COLUMN updated_at TYPE TIMESTAMPTZ USING updated_at AT TIME ZONE 'Asia/Jerusalem',
  ALTER COLUMN last_login TYPE TIMESTAMPTZ USING last_login AT TIME ZONE 'Asia/Jerusalem';

ALTER TABLE client_profiles
  ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE 'Asia/Jerusalem',
  ALTER COLUMN updated_at TYPE TIMESTAMPTZ USING updated_at AT TIME ZONE 'Asia/Jerusalem';

ALTER TABLE worker_profiles
  ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE 'Asia/Jerusalem',
  ALTER COLUMN updated_at TYPE TIMESTAMPTZ USING updated_at AT TIME ZONE 'Asia/Jerusalem';

ALTER TABLE delivery_requests
  ALTER COLUMN request_date TYPE TIMESTAMPTZ USING request_date AT TIME ZONE 'Asia/Jerusalem',
  ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE 'Asia/Jerusalem',
  ALTER COLUMN updated_at TYPE TIMESTAMPTZ USING updated_at AT TIME ZONE 'Asia/Jerusalem';

ALTER TABLE deliveries
  ALTER COLUMN actual_delivery_time TYPE TIMESTAMPTZ USING actual_delivery_time AT TIME ZONE 'Asia/Jerusalem',
  ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE 'Asia/Jerusalem',
  ALTER COLUMN updated_at TYPE TIMESTAMPTZ USING updated_at AT TIME ZONE 'Asia/Jerusalem';

ALTER TABLE gps_locations
  ALTER COLUMN recorded_at TYPE TIMESTAMPTZ USING recorded_at AT TIME ZONE 'Asia/Jerusalem';

ALTER TABLE payments
  ALTER COLUMN payment_date TYPE TIMESTAMPTZ USING payment_date AT TIME ZONE 'Asia/Jerusalem',
  ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE 'Asia/Jerusalem';

ALTER TABLE coupon_book_requests
  ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE 'Asia/Jerusalem',
  ALTER COLUMN updated_at TYPE TIMESTAMPTZ USING updated_at AT TIME ZONE 'Asia/Jerusalem';

ALTER TABLE coupon_sizes
  ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE 'Asia/Jerusalem',
  ALTER COLUMN updated_at TYPE TIMESTAMPTZ USING updated_at AT TIME ZONE 'Asia/Jerusalem';

ALTER TABLE dispensers
  ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE 'Asia/Jerusalem',
  ALTER COLUMN updated_at TYPE TIMESTAMPTZ USING updated_at AT TIME ZONE 'Asia/Jerusalem';

ALTER TABLE dispenser_maintenance
  ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE 'Asia/Jerusalem';

ALTER TABLE client_assets
  ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE 'Asia/Jerusalem';

ALTER TABLE dispenser_deliveries
  ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE 'Asia/Jerusalem';

-- 3. FIX GPS LOCATION DUPLICATION: Remove redundant lat/lng fields
ALTER TABLE client_profiles DROP COLUMN IF EXISTS latitude;
ALTER TABLE client_profiles DROP COLUMN IF EXISTS longitude;
-- Keep home_latitude/home_longitude as they serve different purpose (home vs current)

-- 4. ADD COMPOSITE INDEXES for better query performance
CREATE INDEX IF NOT EXISTS idx_delivery_requests_client_status ON delivery_requests(client_id, status);
CREATE INDEX IF NOT EXISTS idx_deliveries_client_date ON deliveries(client_id, delivery_date);
CREATE INDEX IF NOT EXISTS idx_deliveries_worker_date ON deliveries(worker_id, delivery_date);
CREATE INDEX IF NOT EXISTS idx_payments_payer_date ON payments(payer_id, payment_date);

-- 5. ADD PAYMENT METHOD CONSTRAINT for coupon book requests
ALTER TABLE coupon_book_requests DROP CONSTRAINT IF EXISTS chk_coupon_payment_method;
ALTER TABLE coupon_book_requests ADD CONSTRAINT chk_coupon_payment_method 
  CHECK (payment_method IN ('cash', 'credit_card', 'bank_transfer'));

-- 6. ADD SUBSCRIPTION TYPE FIELD to delivery_requests for validation
ALTER TABLE delivery_requests ADD COLUMN IF NOT EXISTS payment_method payment_method;

-- 7. ADD GRACE PERIOD FIELD to client_profiles (only for cash subscriptions)
ALTER TABLE client_profiles ADD COLUMN IF NOT EXISTS grace_period_days INTEGER DEFAULT 10;

-- 8. ADD CONFIGURABLE PENDING REQUEST LIMIT
CREATE TABLE IF NOT EXISTS system_config (
  key VARCHAR(100) PRIMARY KEY,
  value TEXT NOT NULL,
  description TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO system_config (key, value, description) VALUES
  ('max_pending_requests', '3', 'Maximum pending delivery requests per client'),
  ('debt_limit_ils', '10000', 'Maximum debt limit in ILS for cash subscriptions'),
  ('default_grace_period_days', '10', 'Default grace period for cash subscriptions')
ON CONFLICT (key) DO NOTHING;

-- 9. STATE MACHINE ENFORCEMENT: Add trigger for delivery status transitions
CREATE OR REPLACE FUNCTION validate_delivery_status_transition()
RETURNS TRIGGER AS $$
BEGIN
  -- Allow any transition from NULL (new record)
  IF OLD.status IS NULL THEN
    RETURN NEW;
  END IF;

  -- Valid transitions
  IF (OLD.status = 'pending' AND NEW.status IN ('in_progress', 'cancelled')) OR
     (OLD.status = 'in_progress' AND NEW.status IN ('completed', 'cancelled')) OR
     (OLD.status = 'completed' AND NEW.status = 'completed') OR
     (OLD.status = 'cancelled' AND NEW.status = 'cancelled') THEN
    RETURN NEW;
  END IF;

  RAISE EXCEPTION 'Invalid status transition from % to %', OLD.status, NEW.status;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_validate_delivery_status ON deliveries;
CREATE TRIGGER trg_validate_delivery_status
  BEFORE UPDATE OF status ON deliveries
  FOR EACH ROW
  EXECUTE FUNCTION validate_delivery_status_transition();

DROP TRIGGER IF EXISTS trg_validate_request_status ON delivery_requests;
CREATE TRIGGER trg_validate_request_status
  BEFORE UPDATE OF status ON delivery_requests
  FOR EACH ROW
  EXECUTE FUNCTION validate_delivery_status_transition();

-- 10. ATOMIC COUPON DEDUCTION: Add function for safe coupon usage
CREATE OR REPLACE FUNCTION use_coupons(
  p_client_id INTEGER,
  p_coupons_needed INTEGER
) RETURNS BOOLEAN AS $$
DECLARE
  v_remaining INTEGER;
BEGIN
  -- Lock row and get current coupons
  SELECT remaining_coupons INTO v_remaining
  FROM client_profiles
  WHERE id = p_client_id
  FOR UPDATE;

  -- Check if enough coupons
  IF v_remaining < p_coupons_needed THEN
    RETURN FALSE;
  END IF;

  -- Deduct coupons atomically
  UPDATE client_profiles
  SET remaining_coupons = remaining_coupons - p_coupons_needed,
      updated_at = NOW()
  WHERE id = p_client_id;

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- 11. ATOMIC VEHICLE INVENTORY: Add function for safe inventory updates
CREATE OR REPLACE FUNCTION update_vehicle_inventory(
  p_worker_id INTEGER,
  p_gallons_change INTEGER
) RETURNS BOOLEAN AS $$
DECLARE
  v_current INTEGER;
  v_capacity INTEGER;
  v_new_amount INTEGER;
BEGIN
  -- Lock row and get current values
  SELECT vehicle_current_gallons, vehicle_capacity 
  INTO v_current, v_capacity
  FROM worker_profiles
  WHERE id = p_worker_id
  FOR UPDATE;

  v_new_amount := v_current + p_gallons_change;

  -- Validate constraints
  IF v_new_amount < 0 THEN
    RAISE EXCEPTION 'Insufficient inventory: current=%, requested=%', v_current, ABS(p_gallons_change);
  END IF;

  IF v_new_amount > v_capacity THEN
    RAISE EXCEPTION 'Exceeds capacity: capacity=%, attempted=%', v_capacity, v_new_amount;
  END IF;

  -- Update atomically
  UPDATE worker_profiles
  SET vehicle_current_gallons = v_new_amount,
      updated_at = NOW()
  WHERE id = p_worker_id;

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- 12. ADD TRIGGER to auto-update updated_at columns
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables with updated_at
DROP TRIGGER IF EXISTS trg_users_updated_at ON users;
CREATE TRIGGER trg_users_updated_at BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trg_client_profiles_updated_at ON client_profiles;
CREATE TRIGGER trg_client_profiles_updated_at BEFORE UPDATE ON client_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trg_worker_profiles_updated_at ON worker_profiles;
CREATE TRIGGER trg_worker_profiles_updated_at BEFORE UPDATE ON worker_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trg_delivery_requests_updated_at ON delivery_requests;
CREATE TRIGGER trg_delivery_requests_updated_at BEFORE UPDATE ON delivery_requests
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trg_deliveries_updated_at ON deliveries;
CREATE TRIGGER trg_deliveries_updated_at BEFORE UPDATE ON deliveries
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 13. FIX EXISTING DATA: Convert single role to array
UPDATE users SET roles = ARRAY[role]::user_role[] WHERE roles IS NULL;
