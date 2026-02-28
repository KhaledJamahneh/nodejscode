-- Create notifications table
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
      'Coupon Request ' || INITCAP(v_status_text),
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
      'Delivery ' || INITCAP(NEW.status),
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

COMMENT ON TABLE notifications IS 'System notifications for users';
