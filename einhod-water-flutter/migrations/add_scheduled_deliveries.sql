-- Create scheduled_deliveries table for recurring delivery schedules
CREATE TABLE IF NOT EXISTS scheduled_deliveries (
  id SERIAL PRIMARY KEY,
  client_id INTEGER NOT NULL REFERENCES client_profiles(id) ON DELETE CASCADE,
  worker_id INTEGER REFERENCES worker_profiles(id) ON DELETE SET NULL,
  gallons INTEGER NOT NULL,
  schedule_type VARCHAR(20) NOT NULL CHECK (schedule_type IN ('daily', 'weekly', 'biweekly', 'monthly')),
  schedule_time TIME NOT NULL,
  schedule_days INTEGER[], -- For weekly: [1,3,5] = Mon, Wed, Fri
  start_date DATE NOT NULL DEFAULT CURRENT_DATE,
  end_date DATE,
  is_active BOOLEAN DEFAULT true,
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index for active schedules
CREATE INDEX IF NOT EXISTS idx_scheduled_deliveries_active ON scheduled_deliveries(is_active, start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_scheduled_deliveries_worker ON scheduled_deliveries(worker_id);
CREATE INDEX IF NOT EXISTS idx_scheduled_deliveries_client ON scheduled_deliveries(client_id);

-- Function to generate deliveries from schedules (run daily via cron)
CREATE OR REPLACE FUNCTION generate_scheduled_deliveries()
RETURNS void AS $$
DECLARE
  schedule_record RECORD;
  should_create BOOLEAN;
  delivery_date DATE;
BEGIN
  delivery_date := CURRENT_DATE;
  
  FOR schedule_record IN 
    SELECT sd.*, cp.user_id as client_user_id
    FROM scheduled_deliveries sd
    JOIN client_profiles cp ON sd.client_id = cp.id
    WHERE sd.is_active = true
      AND sd.start_date <= delivery_date
      AND (sd.end_date IS NULL OR sd.end_date >= delivery_date)
  LOOP
    should_create := false;
    
    -- Check if delivery should be created based on schedule type
    CASE schedule_record.schedule_type
      WHEN 'daily' THEN
        should_create := true;
      WHEN 'weekly' THEN
        should_create := EXTRACT(DOW FROM delivery_date)::INTEGER = ANY(schedule_record.schedule_days);
      WHEN 'biweekly' THEN
        should_create := (EXTRACT(DOW FROM delivery_date)::INTEGER = ANY(schedule_record.schedule_days))
                        AND (EXTRACT(WEEK FROM delivery_date) % 2 = EXTRACT(WEEK FROM schedule_record.start_date) % 2);
      WHEN 'monthly' THEN
        should_create := EXTRACT(DAY FROM delivery_date) = EXTRACT(DAY FROM schedule_record.start_date);
    END CASE;
    
    -- Create delivery if it should be created and doesn't already exist
    IF should_create THEN
      INSERT INTO deliveries (
        client_id, worker_id, delivery_date, scheduled_time, 
        gallons_delivered, status, notes
      )
      SELECT 
        schedule_record.client_id,
        schedule_record.worker_id,
        delivery_date,
        schedule_record.schedule_time,
        schedule_record.gallons,
        'pending',
        'Auto-generated from schedule #' || schedule_record.id
      WHERE NOT EXISTS (
        SELECT 1 FROM deliveries 
        WHERE client_id = schedule_record.client_id 
          AND delivery_date = delivery_date
          AND scheduled_time = schedule_record.schedule_time
      );
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql;
