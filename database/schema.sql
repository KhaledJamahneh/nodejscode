-- Einhod Pure Water Database Schema
-- PostgreSQL with PostGIS extension for geospatial features

-- Enable PostGIS extension for GPS functionality
CREATE EXTENSION IF NOT EXISTS postgis;

-- ============================================================================
-- USERS AND AUTHENTICATION
-- ============================================================================

-- Enum types for better type safety
CREATE TYPE user_role AS ENUM ('client', 'delivery_worker', 'onsite_worker', 'administrator', 'owner');
CREATE TYPE subscription_type AS ENUM ('coupon_book', 'cash');
CREATE TYPE delivery_priority AS ENUM ('urgent', 'mid_urgent', 'non_urgent');
CREATE TYPE delivery_status AS ENUM ('pending', 'in_progress', 'completed', 'cancelled');
CREATE TYPE dispenser_status AS ENUM ('new', 'used', 'disabled', 'in_maintenance');
CREATE TYPE dispenser_type AS ENUM ('touch', 'manual', 'electric');
CREATE TYPE payment_method AS ENUM ('cash', 'credit_card', 'bank_transfer');
CREATE TYPE payment_status AS ENUM ('pending', 'completed', 'failed', 'refunded');
CREATE TYPE expense_payment_method AS ENUM ('worker_pocket', 'company_pocket', 'unpaid');
CREATE TYPE expense_status AS ENUM ('pending', 'approved', 'rejected');
CREATE TYPE station_status AS ENUM ('open', 'closed_temporarily', 'closed_until_tomorrow');
CREATE TYPE notification_category AS ENUM ('important', 'mid_importance', 'normal');

-- Main Users table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255),
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role user_role NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP
);

-- Index for faster lookups
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_phone ON users(phone_number);
CREATE INDEX idx_users_role ON users(role);

-- ============================================================================
-- COUPON SYSTEM CONFIGURATION
-- ============================================================================

CREATE TABLE coupon_sizes (
    id SERIAL PRIMARY KEY,
    size INTEGER NOT NULL UNIQUE, -- Number of pages/coupons
    price_per_page DECIMAL(10, 2) DEFAULT 0.50,
    bonus_gallons INTEGER DEFAULT 0,
    available_stock INTEGER DEFAULT 100,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default sizes
INSERT INTO coupon_sizes (size, price_per_page, bonus_gallons) VALUES 
(100, 0.50, 0), (200, 0.45, 10), (300, 0.40, 20), (400, 0.35, 30), (500, 0.30, 50);

CREATE TRIGGER update_coupon_sizes_updated_at BEFORE UPDATE ON coupon_sizes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- CLIENT PROFILES
-- ============================================================================

CREATE TABLE client_profiles (
    id SERIAL PRIMARY KEY,
    user_id INTEGER UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    full_name VARCHAR(255) NOT NULL,
    address TEXT NOT NULL,
    location GEOGRAPHY(POINT, 4326), -- GPS coordinates (longitude, latitude)
    subscription_type subscription_type NOT NULL,
    subscription_start_date DATE,
    subscription_end_date DATE,
    remaining_coupons INTEGER DEFAULT 0,
    bonus_gallons INTEGER DEFAULT 0,
    monthly_usage_gallons DECIMAL(10, 2) DEFAULT 0,
    current_debt DECIMAL(10, 2) DEFAULT 0,
    preferred_language VARCHAR(10) DEFAULT 'en',
    proximity_notifications_enabled BOOLEAN DEFAULT TRUE,
    home_latitude  DECIMAL(10, 8) CHECK (home_latitude BETWEEN -90 AND 90),
    home_longitude DECIMAL(11, 8) CHECK (home_longitude BETWEEN -180 AND 180),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_client_user_id ON client_profiles(user_id);
CREATE INDEX idx_client_location ON client_profiles USING GIST(location);

-- ============================================================================
-- WORKER PROFILES
-- ============================================================================

CREATE TABLE worker_profiles (
    id SERIAL PRIMARY KEY,
    user_id INTEGER UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    full_name VARCHAR(255) NOT NULL,
    worker_type VARCHAR(50) NOT NULL, -- 'delivery', 'onsite', 'social_media'
    hire_date DATE NOT NULL,
    current_salary DECIMAL(10, 2),
    debt_advances DECIMAL(10, 2) DEFAULT 0,
    vehicle_current_gallons INTEGER DEFAULT 0,
    vehicle_capacity INTEGER DEFAULT 1000,
    gps_sharing_enabled BOOLEAN DEFAULT FALSE,
    is_dual_role BOOLEAN DEFAULT FALSE, -- If worker is also a client
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT vehicle_capacity_limit CHECK (vehicle_current_gallons <= vehicle_capacity)
);

CREATE INDEX idx_worker_user_id ON worker_profiles(user_id);
CREATE INDEX idx_worker_type ON worker_profiles(worker_type);

-- ============================================================================
-- DISPENSERS
-- ============================================================================

CREATE TABLE dispensers (
    id SERIAL PRIMARY KEY,
    serial_number VARCHAR(100) UNIQUE NOT NULL,
    dispenser_type dispenser_type NOT NULL,
    status dispenser_status DEFAULT 'new',
    purchase_date DATE NOT NULL,
    purchase_price DECIMAL(10, 2),
    current_location_type VARCHAR(20) DEFAULT 'warehouse', -- 'warehouse', 'client', 'maintenance'
    current_client_id INTEGER REFERENCES client_profiles(id),
    image_url TEXT,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_dispenser_serial ON dispensers(serial_number);
CREATE INDEX idx_dispenser_status ON dispensers(status);
CREATE INDEX idx_dispenser_client ON dispensers(current_client_id);

-- Dispenser maintenance history
CREATE TABLE dispenser_maintenance (
    id SERIAL PRIMARY KEY,
    dispenser_id INTEGER REFERENCES dispensers(id) ON DELETE CASCADE,
    maintenance_date DATE NOT NULL,
    description TEXT,
    cost DECIMAL(10, 2),
    performed_by INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- CLIENT ASSETS (Junction table)
-- ============================================================================

CREATE TABLE client_assets (
    id SERIAL PRIMARY KEY,
    client_id INTEGER REFERENCES client_profiles(id) ON DELETE CASCADE,
    dispenser_id INTEGER REFERENCES dispensers(id),
    asset_type VARCHAR(50), -- 'dispenser', '5_gallon_bottle', etc.
    quantity INTEGER DEFAULT 1,
    assigned_date DATE NOT NULL,
    returned_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_client_assets_client ON client_assets(client_id);
CREATE INDEX idx_client_assets_dispenser ON client_assets(dispenser_id);

CREATE TABLE coupon_book_requests (
    id SERIAL PRIMARY KEY,
    client_id INTEGER REFERENCES client_profiles(id) ON DELETE CASCADE,
    book_type VARCHAR(20) NOT NULL, -- 'physical', 'electronic'
    coupon_size_id INTEGER REFERENCES coupon_sizes(id),
    total_price DECIMAL(10, 2) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'approved', 'assigned', 'completed', 'cancelled'
    payment_method payment_method DEFAULT 'cash',
    assigned_worker_id INTEGER REFERENCES worker_profiles(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_coupon_requests_client ON coupon_book_requests(client_id);
CREATE INDEX idx_coupon_requests_status ON coupon_book_requests(status);
CREATE INDEX idx_coupon_requests_worker ON coupon_book_requests(assigned_worker_id);

CREATE TRIGGER update_coupon_requests_updated_at BEFORE UPDATE ON coupon_book_requests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- DELIVERY SYSTEM
-- ============================================================================

-- Delivery Requests (Secondary List)
CREATE TABLE delivery_requests (
    id SERIAL PRIMARY KEY,
    client_id INTEGER REFERENCES client_profiles(id) ON DELETE CASCADE,
    priority delivery_priority DEFAULT 'non_urgent',
    requested_gallons INTEGER NOT NULL,
    request_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status delivery_status DEFAULT 'pending',
    assigned_worker_id INTEGER REFERENCES worker_profiles(id),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_delivery_requests_client ON delivery_requests(client_id);
CREATE INDEX idx_delivery_requests_status ON delivery_requests(status);
CREATE INDEX idx_delivery_requests_priority ON delivery_requests(priority);

-- Deliveries (Main List + Completed Deliveries)
CREATE TABLE deliveries (
    id SERIAL PRIMARY KEY,
    client_id INTEGER REFERENCES client_profiles(id) ON DELETE CASCADE,
    worker_id INTEGER REFERENCES worker_profiles(id),
    delivery_date DATE NOT NULL,
    scheduled_time TIME,
    actual_delivery_time TIMESTAMP,
    gallons_delivered INTEGER NOT NULL,
    delivery_location GEOGRAPHY(POINT, 4326),
    status delivery_status DEFAULT 'pending',
    empty_gallons_returned INTEGER DEFAULT 0,
    notes TEXT,
    photo_url TEXT,
    is_main_list BOOLEAN DEFAULT TRUE, -- TRUE for scheduled, FALSE for request-based
    request_id INTEGER REFERENCES delivery_requests(id), -- Link to request if applicable
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_deliveries_client ON deliveries(client_id);
CREATE INDEX idx_deliveries_worker ON deliveries(worker_id);
CREATE INDEX idx_deliveries_date ON deliveries(delivery_date);
CREATE INDEX idx_deliveries_status ON deliveries(status);

-- Dispenser Deliveries (special tracking)
CREATE TABLE dispenser_deliveries (
    id SERIAL PRIMARY KEY,
    delivery_id INTEGER REFERENCES deliveries(id) ON DELETE CASCADE,
    dispenser_id INTEGER REFERENCES dispensers(id),
    condition dispenser_status, -- 'new' or 'used' at delivery
    photo_url TEXT,
    delivery_location GEOGRAPHY(POINT, 4326),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- GPS TRACKING
-- ============================================================================

CREATE TABLE gps_locations (
    id SERIAL PRIMARY KEY,
    worker_id INTEGER REFERENCES worker_profiles(id) ON DELETE CASCADE,
    location GEOGRAPHY(POINT, 4326) NOT NULL,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    accuracy_meters DECIMAL(10, 2),
    speed_kmh DECIMAL(10, 2)
);

CREATE INDEX idx_gps_worker ON gps_locations(worker_id);
CREATE INDEX idx_gps_location ON gps_locations USING GIST(location);
CREATE INDEX idx_gps_time ON gps_locations(recorded_at);

-- Worker live location (upsert table)
CREATE TABLE worker_locations (
  worker_id      INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  delivery_id    INTEGER REFERENCES deliveries(id) ON DELETE SET NULL,
  latitude       DECIMAL(10, 8) NOT NULL CHECK (latitude BETWEEN -90 AND 90),
  longitude      DECIMAL(11, 8) NOT NULL CHECK (longitude BETWEEN -180 AND 180),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_worker_locations_updated_at ON worker_locations(updated_at);

-- ============================================================================
-- PAYMENTS
-- ============================================================================

CREATE TABLE payments (
    id SERIAL PRIMARY KEY,
    payer_id INTEGER REFERENCES users(id),
    receiver_type VARCHAR(20) DEFAULT 'company', -- 'company' or 'worker'
    receiver_id INTEGER REFERENCES users(id),
    amount DECIMAL(10, 2) NOT NULL,
    payment_method payment_method NOT NULL,
    payment_status payment_status DEFAULT 'pending',
    transaction_id VARCHAR(255),
    payment_gateway_response JSONB,
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_payments_payer ON payments(payer_id);
CREATE INDEX idx_payments_status ON payments(payment_status);
CREATE INDEX idx_payments_date ON payments(payment_date);

-- ============================================================================
-- EXPENSES
-- ============================================================================

CREATE TABLE expenses (
    id SERIAL PRIMARY KEY,
    worker_id INTEGER REFERENCES worker_profiles(id),
    amount DECIMAL(10, 2) NOT NULL,
    description TEXT NOT NULL,
    merchant_name VARCHAR(255),
    expense_date DATE NOT NULL,
    payment_method expense_payment_method NOT NULL,
    status expense_status DEFAULT 'pending',
    receipt_photo_url TEXT,
    approved_by INTEGER REFERENCES users(id),
    approval_date TIMESTAMP,
    admin_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_expenses_worker ON expenses(worker_id);
CREATE INDEX idx_expenses_status ON expenses(status);
CREATE INDEX idx_expenses_date ON expenses(expense_date);

-- Expense categories for better tracking
CREATE TABLE expense_categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT
);

INSERT INTO expense_categories (name, description) VALUES
    ('Worker Salaries', 'Employee compensation'),
    ('Gallon Production', 'Water production costs'),
    ('Dispenser Purchases', 'New dispenser acquisitions'),
    ('Operational Expenses', 'General operations'),
    ('Marketing', 'Advertising and promotions'),
    ('Vehicle Maintenance', 'Delivery vehicle upkeep'),
    ('Fuel', 'Vehicle fuel costs');

ALTER TABLE expenses ADD COLUMN category_id INTEGER REFERENCES expense_categories(id);

-- ============================================================================
-- JOB DESCRIPTIONS
-- ============================================================================

CREATE TABLE job_descriptions (
    id SERIAL PRIMARY KEY,
    worker_id INTEGER REFERENCES worker_profiles(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    responsibilities TEXT NOT NULL,
    fixed_salary DECIMAL(10, 2),
    version INTEGER DEFAULT 1,
    created_by INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    approved_by_worker BOOLEAN DEFAULT FALSE,
    worker_approval_date TIMESTAMP,
    is_active BOOLEAN DEFAULT FALSE
);

CREATE INDEX idx_job_descriptions_worker ON job_descriptions(worker_id);

-- ============================================================================
-- FILLING STATIONS
-- ============================================================================

CREATE TABLE filling_stations (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    location GEOGRAPHY(POINT, 4326),
    address TEXT,
    current_status station_status DEFAULT 'open',
    manager_id INTEGER REFERENCES worker_profiles(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE filling_sessions (
    id SERIAL PRIMARY KEY,
    station_id INTEGER REFERENCES filling_stations(id) ON DELETE CASCADE,
    worker_id INTEGER REFERENCES worker_profiles(id),
    gallons_filled INTEGER NOT NULL,
    session_number INTEGER,
    start_time TIMESTAMP,
    completion_time TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_filling_sessions_station ON filling_sessions(station_id);
CREATE INDEX idx_filling_sessions_date ON filling_sessions(completion_time);

-- ============================================================================
-- NOTIFICATIONS
-- ============================================================================

CREATE TABLE notifications (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    category notification_category DEFAULT 'normal',
    is_read BOOLEAN DEFAULT FALSE,
    action_url TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP
);

CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_read ON notifications(is_read);
CREATE INDEX idx_notifications_created ON notifications(created_at);

-- ============================================================================
-- MARKETING & COMMUNICATIONS
-- ============================================================================

-- Company Announcements
CREATE TABLE announcements (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    image_url TEXT,
    external_link TEXT,
    created_by INTEGER REFERENCES users(id),
    is_active BOOLEAN DEFAULT TRUE,
    start_date DATE,
    end_date DATE,
    view_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Social Media Posts tracking
CREATE TABLE social_media_posts (
    id SERIAL PRIMARY KEY,
    worker_id INTEGER REFERENCES worker_profiles(id),
    platform VARCHAR(50) NOT NULL, -- 'facebook', 'instagram', etc.
    topic VARCHAR(255) NOT NULL,
    post_link TEXT,
    post_date DATE NOT NULL,
    engagement_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_social_posts_worker ON social_media_posts(worker_id);
CREATE INDEX idx_social_posts_date ON social_media_posts(post_date);

-- Apology Messages
CREATE TABLE apology_messages (
    id SERIAL PRIMARY KEY,
    worker_id INTEGER REFERENCES worker_profiles(id),
    client_id INTEGER REFERENCES client_profiles(id),
    delivery_request_id INTEGER REFERENCES delivery_requests(id),
    message_template TEXT NOT NULL,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- UNIFORMS TRACKING
-- ============================================================================

CREATE TABLE uniform_distributions (
    id SERIAL PRIMARY KEY,
    worker_id INTEGER REFERENCES worker_profiles(id) ON DELETE CASCADE,
    item_type VARCHAR(100) NOT NULL, -- 'shirt', 'pants', 'hat', etc.
    quantity INTEGER NOT NULL,
    distribution_date DATE NOT NULL,
    size VARCHAR(20),
    distributed_by INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- SYSTEM CONFIGURATION
-- ============================================================================

CREATE TABLE system_settings (
    id SERIAL PRIMARY KEY,
    setting_key VARCHAR(100) UNIQUE NOT NULL,
    setting_value TEXT,
    description TEXT,
    updated_by INTEGER REFERENCES users(id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Default settings
INSERT INTO system_settings (setting_key, setting_value, description) VALUES
    ('gps_update_interval_seconds', '30', 'GPS location update frequency'),
    ('proximity_notification_radius_km', '1', 'Distance for proximity notifications'),
    ('low_inventory_threshold_gallons', '10', 'Alert threshold for vehicle inventory'),
    ('subscription_expiry_warning_days', '7,1', 'Days before expiry to send warnings'),
    ('session_timeout_hours', '24', 'User session timeout duration');

-- ============================================================================
-- AUDIT LOG
-- ============================================================================

CREATE TABLE audit_log (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    action VARCHAR(100) NOT NULL,
    table_name VARCHAR(100),
    record_id INTEGER,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audit_user ON audit_log(user_id);
CREATE INDEX idx_audit_action ON audit_log(action);
CREATE INDEX idx_audit_created ON audit_log(created_at);

-- ============================================================================
-- TRIGGERS FOR UPDATED_AT
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply trigger to all tables with updated_at column
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_client_profiles_updated_at BEFORE UPDATE ON client_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_worker_profiles_updated_at BEFORE UPDATE ON worker_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_dispensers_updated_at BEFORE UPDATE ON dispensers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_delivery_requests_updated_at BEFORE UPDATE ON delivery_requests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_deliveries_updated_at BEFORE UPDATE ON deliveries
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_expenses_updated_at BEFORE UPDATE ON expenses
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- VIEWS FOR COMMON QUERIES
-- ============================================================================

-- Active deliveries with client and worker info
CREATE VIEW active_deliveries_view AS
SELECT 
    d.id,
    d.delivery_date,
    d.status,
    d.gallons_delivered,
    c.full_name as client_name,
    c.address as client_address,
    w.full_name as worker_name,
    u.phone_number as worker_phone
FROM deliveries d
JOIN client_profiles c ON d.client_id = c.id
JOIN worker_profiles w ON d.worker_id = w.id
JOIN users u ON w.user_id = u.id
WHERE d.status IN ('pending', 'in_progress');

-- Client subscription status
CREATE VIEW client_subscription_status AS
SELECT 
    c.id,
    c.full_name,
    u.username,
    u.phone_number,
    c.subscription_type,
    c.remaining_coupons,
    c.subscription_expiry_date,
    CASE 
        WHEN c.subscription_expiry_date < CURRENT_DATE THEN 'expired'
        WHEN c.subscription_expiry_date < CURRENT_DATE + INTERVAL '7 days' THEN 'expiring_soon'
        ELSE 'active'
    END as status,
    c.current_debt
FROM client_profiles c
JOIN users u ON c.user_id = u.id
WHERE u.is_active = TRUE;

-- Worker performance metrics
CREATE VIEW worker_performance AS
SELECT 
    w.id,
    w.full_name,
    w.worker_type,
    COUNT(DISTINCT d.id) as total_deliveries,
    SUM(d.gallons_delivered) as total_gallons_delivered,
    COUNT(DISTINCT CASE WHEN d.status = 'completed' THEN d.id END) as completed_deliveries,
    COUNT(DISTINCT e.id) as total_expenses,
    SUM(e.amount) as total_expense_amount
FROM worker_profiles w
LEFT JOIN deliveries d ON w.id = d.worker_id
LEFT JOIN expenses e ON w.id = e.worker_id
GROUP BY w.id, w.full_name, w.worker_type;

-- ============================================================================
-- NOTIFICATIONS SYSTEM
-- ============================================================================

CREATE TABLE IF NOT EXISTS notifications (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  message TEXT NOT NULL,
  type VARCHAR(50) NOT NULL, -- 'coupon_request', 'delivery_request', 'payment', 'status_update', etc.
  reference_id INTEGER, -- ID of related entity (request_id, delivery_id, etc.)
  reference_type VARCHAR(50), -- 'coupon_request', 'delivery', 'payment', etc.
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  read_at TIMESTAMP
);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at DESC);

-- Function to create notification for admins
CREATE OR REPLACE FUNCTION notify_admins(
  p_title VARCHAR,
  p_message TEXT,
  p_type VARCHAR,
  p_reference_id INTEGER DEFAULT NULL,
  p_reference_type VARCHAR DEFAULT NULL
) RETURNS void AS $$
BEGIN
  INSERT INTO notifications (user_id, title, message, type, reference_id, reference_type)
  SELECT u.id, p_title, p_message, p_type, p_reference_id, p_reference_type
  FROM users u
  WHERE u.role::text = ANY(ARRAY['owner', 'administrator'])
  AND u.is_active = true
  AND NOT EXISTS (
    SELECT 1 FROM notifications n
    WHERE n.user_id = u.id
    AND n.title = p_title
    AND n.message = p_message
    AND n.created_at > NOW() - INTERVAL '1 minute'
  );
END;
$$ LANGUAGE plpgsql;

-- Function to create notification for specific user
CREATE OR REPLACE FUNCTION notify_user(
  p_user_id INTEGER,
  p_title VARCHAR,
  p_message TEXT,
  p_type VARCHAR,
  p_reference_id INTEGER DEFAULT NULL,
  p_reference_type VARCHAR DEFAULT NULL
) RETURNS void AS $$
BEGIN
  -- Prevent spamming identical notifications within 1 minute
  IF EXISTS (
    SELECT 1 FROM notifications 
    WHERE user_id = p_user_id 
    AND title = p_title 
    AND message = p_message 
    AND created_at > NOW() - INTERVAL '1 minute'
  ) THEN
    RETURN;
  END IF;

  INSERT INTO notifications (user_id, title, message, type, reference_id, reference_type)
  VALUES (p_user_id, p_title, p_message, p_type, p_reference_id, p_reference_type);
END;
$$ LANGUAGE plpgsql;

-- Trigger: Notify admins when coupon book request is created
CREATE OR REPLACE FUNCTION notify_coupon_request_created() RETURNS TRIGGER AS $$
DECLARE
  v_client_name VARCHAR;
  v_book_size INTEGER;
  v_book_type VARCHAR;
BEGIN
  -- Get client details
  SELECT cp.full_name, cs.size, NEW.book_type
  INTO v_client_name, v_book_size, v_book_type
  FROM client_profiles cp
  JOIN coupon_sizes cs ON cs.id = NEW.coupon_size_id
  WHERE cp.id = NEW.client_id;

  -- Only notify for physical books (electronic are auto-completed)
  IF NEW.book_type = 'physical' THEN
    PERFORM notify_admins(
      'New Coupon Book Request',
      v_client_name || ' requested a ' || v_book_size || ' gallon ' || v_book_type || ' coupon book',
      'coupon_request',
      NEW.id,
      'coupon_book_request'
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_notify_coupon_request
AFTER INSERT ON coupon_book_requests
FOR EACH ROW
EXECUTE FUNCTION notify_coupon_request_created();

-- Trigger: Notify client when coupon request status changes
CREATE OR REPLACE FUNCTION notify_coupon_status_changed() RETURNS TRIGGER AS $$
DECLARE
  v_user_id INTEGER;
  v_status_text VARCHAR;
BEGIN
  IF OLD.status != NEW.status THEN
    -- Get client user_id
    SELECT cp.user_id INTO v_user_id
    FROM client_profiles cp
    WHERE cp.id = NEW.client_id;

    -- Set friendly status text
    v_status_text := CASE NEW.status
      WHEN 'approved' THEN 'approved'
      WHEN 'delivered' THEN 'delivered'
      WHEN 'cancelled' THEN 'cancelled'
      ELSE NEW.status
    END;

    PERFORM notify_user(
      v_user_id,
      'Coupon Request ' || INITCAP(v_status_text::text),
      'Your coupon book request has been ' || v_status_text,
      'coupon_status',
      NEW.id,
      'coupon_book_request'
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_notify_coupon_status
AFTER UPDATE ON coupon_book_requests
FOR EACH ROW
EXECUTE FUNCTION notify_coupon_status_changed();

-- Trigger: Notify admins when delivery request is created
CREATE OR REPLACE FUNCTION notify_delivery_request_created() RETURNS TRIGGER AS $$
DECLARE
  v_client_name VARCHAR;
BEGIN
  SELECT cp.full_name INTO v_client_name
  FROM client_profiles cp
  WHERE cp.id = NEW.client_id;

  PERFORM notify_admins(
    'New Delivery Request',
    v_client_name || ' requested ' || NEW.requested_gallons || ' gallons',
    'delivery_request',
    NEW.id,
    'delivery_request'
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_notify_delivery_request
AFTER INSERT ON delivery_requests
FOR EACH ROW
EXECUTE FUNCTION notify_delivery_request_created();

-- Trigger: Notify client when delivery request status changes
CREATE OR REPLACE FUNCTION notify_delivery_status_changed() RETURNS TRIGGER AS $$
DECLARE
  v_user_id INTEGER;
BEGIN
  IF OLD.status != NEW.status AND NEW.status IN ('in_progress', 'completed', 'cancelled') THEN
    SELECT cp.user_id INTO v_user_id
    FROM client_profiles cp
    WHERE cp.id = NEW.client_id;

    PERFORM notify_user(
      v_user_id,
      'Delivery ' || INITCAP(NEW.status::text),
      'Your delivery request is now ' || NEW.status,
      'delivery_status',
      NEW.id,
      'delivery_request'
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_notify_delivery_status
AFTER UPDATE ON delivery_requests
FOR EACH ROW
EXECUTE FUNCTION notify_delivery_status_changed();

-- Trigger: Notify worker when assigned to delivery
CREATE OR REPLACE FUNCTION notify_worker_assignment() RETURNS TRIGGER AS $$
DECLARE
  v_user_id INTEGER;
  v_client_name VARCHAR;
BEGIN
  IF OLD.assigned_worker_id IS NULL AND NEW.assigned_worker_id IS NOT NULL THEN
    SELECT wp.user_id INTO v_user_id
    FROM worker_profiles wp
    WHERE wp.id = NEW.assigned_worker_id;

    SELECT cp.full_name INTO v_client_name
    FROM client_profiles cp
    WHERE cp.id = NEW.client_id;

    PERFORM notify_user(
      v_user_id,
      'New Delivery Assignment',
      'You have been assigned to deliver ' || NEW.requested_gallons || ' gallons to ' || v_client_name,
      'worker_assignment',
      NEW.id,
      'delivery_request'
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_notify_worker_assignment
AFTER UPDATE ON delivery_requests
FOR EACH ROW
EXECUTE FUNCTION notify_worker_assignment();

-- ============================================================================
-- INITIAL DATA (DEMO/TESTING)
-- ============================================================================

-- Create default owner account (password: Admin123!)
-- Note: In production, this should be changed immediately
INSERT INTO users (username, email, phone_number, password_hash, role) VALUES
('owner', 'owner@einhodwater.com', '+1234567890', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyVdJ3o9OQzi', 'owner');

-- Create sample expense categories (already inserted above)

COMMENT ON DATABASE postgres IS 'Einhod Pure Water Management System Database';
