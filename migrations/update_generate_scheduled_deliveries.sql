-- Update generate_scheduled_deliveries function to handle custom schedules
CREATE OR REPLACE FUNCTION generate_scheduled_deliveries()
RETURNS void AS $$
DECLARE
  schedule_record RECORD;
  should_create BOOLEAN;
  delivery_date DATE;
  days_since_start INTEGER;
  deliveries_created INTEGER;
  interval_days INTEGER;
  total_deliveries INTEGER;
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
        
      WHEN 'custom' THEN
        -- Custom: every N days, N times
        -- frequency_per_week = interval in days (e.g., 3 = every 3 days)
        -- frequency_per_month = total number of deliveries
        IF schedule_record.frequency_per_week IS NOT NULL AND schedule_record.frequency_per_month IS NOT NULL THEN
          interval_days := schedule_record.frequency_per_week;
          total_deliveries := schedule_record.frequency_per_month;
          days_since_start := delivery_date - schedule_record.start_date;
          
          -- Count how many deliveries already created for this schedule
          SELECT COUNT(*) INTO deliveries_created
          FROM deliveries
          WHERE client_id = schedule_record.client_id
            AND delivery_date >= schedule_record.start_date
            AND notes LIKE '%schedule #' || schedule_record.id || '%';
          
          -- Create delivery if:
          -- 1. Haven't reached total_deliveries limit
          -- 2. Today is on the interval (days_since_start is divisible by interval_days)
          -- 3. Within the interval_days period from start
          IF deliveries_created < total_deliveries 
             AND days_since_start % interval_days = 0 
             AND days_since_start <= interval_days THEN
            should_create := true;
          END IF;
        END IF;
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
