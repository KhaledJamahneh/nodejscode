-- Add work shifts and leave management

-- Create leave type enum
CREATE TYPE leave_type AS ENUM ('vacation', 'sick_leave', 'other');

-- Create work_shifts table
CREATE TABLE work_shifts (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    days_of_week INTEGER[] NOT NULL, -- 0=Sunday, 1=Monday, ..., 6=Saturday
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create worker_leaves table
CREATE TABLE worker_leaves (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    leave_type leave_type NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    reason TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Add shift_id to worker_profiles
ALTER TABLE worker_profiles 
ADD COLUMN shift_id INTEGER REFERENCES work_shifts(id);

-- Create indexes
CREATE INDEX idx_worker_leaves_user_id ON worker_leaves(user_id);
CREATE INDEX idx_worker_leaves_dates ON worker_leaves(start_date, end_date);
CREATE INDEX idx_worker_profiles_shift_id ON worker_profiles(shift_id);

-- Create trigger for work_shifts updated_at
CREATE TRIGGER update_work_shifts_updated_at
    BEFORE UPDATE ON work_shifts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Create trigger for worker_leaves updated_at
CREATE TRIGGER update_worker_leaves_updated_at
    BEFORE UPDATE ON worker_leaves
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Insert default shifts
INSERT INTO work_shifts (name, days_of_week, start_time, end_time) VALUES
('Morning Shift', ARRAY[1,2,3,4,5], '08:00:00', '16:00:00'),
('Evening Shift', ARRAY[1,2,3,4,5], '16:00:00', '00:00:00'),
('Full Day', ARRAY[1,2,3,4,5,6], '08:00:00', '20:00:00');

-- Function to check if worker is currently active (on shift and not on leave)
CREATE OR REPLACE FUNCTION is_worker_active_now(p_user_id INTEGER)
RETURNS BOOLEAN AS $$
DECLARE
    v_shift_id INTEGER;
    v_days_of_week INTEGER[];
    v_start_time TIME;
    v_end_time TIME;
    v_current_day INTEGER;
    v_current_time TIME;
    v_on_leave BOOLEAN;
BEGIN
    -- Get worker's shift
    SELECT shift_id INTO v_shift_id
    FROM worker_profiles
    WHERE user_id = p_user_id;
    
    -- If no shift assigned, return false
    IF v_shift_id IS NULL THEN
        RETURN false;
    END IF;
    
    -- Get shift details
    SELECT days_of_week, start_time, end_time
    INTO v_days_of_week, v_start_time, v_end_time
    FROM work_shifts
    WHERE id = v_shift_id AND is_active = true;
    
    -- If shift not found or inactive, return false
    IF NOT FOUND THEN
        RETURN false;
    END IF;
    
    -- Check if worker is on leave today
    SELECT EXISTS(
        SELECT 1 FROM worker_leaves
        WHERE user_id = p_user_id
        AND CURRENT_DATE BETWEEN start_date AND end_date
    ) INTO v_on_leave;
    
    IF v_on_leave THEN
        RETURN false;
    END IF;
    
    -- Get current day (0=Sunday, 1=Monday, etc.)
    v_current_day := EXTRACT(DOW FROM CURRENT_DATE);
    v_current_time := CURRENT_TIME;
    
    -- Check if current day is in shift days
    IF NOT (v_current_day = ANY(v_days_of_week)) THEN
        RETURN false;
    END IF;
    
    -- Check if current time is within shift hours
    IF v_end_time > v_start_time THEN
        -- Normal shift (doesn't cross midnight)
        RETURN v_current_time BETWEEN v_start_time AND v_end_time;
    ELSE
        -- Shift crosses midnight
        RETURN v_current_time >= v_start_time OR v_current_time <= v_end_time;
    END IF;
END;
$$ LANGUAGE plpgsql;
