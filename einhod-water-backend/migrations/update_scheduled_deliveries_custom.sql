-- Add custom interval columns to scheduled_deliveries
ALTER TABLE scheduled_deliveries 
ADD COLUMN IF NOT EXISTS custom_interval INTEGER,
ADD COLUMN IF NOT EXISTS custom_unit VARCHAR(20) CHECK (custom_unit IN ('days', 'weeks', 'months'));

-- Update the check constraint for schedule_type to include 'custom'
ALTER TABLE scheduled_deliveries DROP CONSTRAINT IF EXISTS scheduled_deliveries_schedule_type_check;
ALTER TABLE scheduled_deliveries ADD CONSTRAINT scheduled_deliveries_schedule_type_check 
CHECK (schedule_type IN ('daily', 'weekly', 'biweekly', 'monthly', 'custom'));

-- Update the generation function to support custom schedules
CREATE OR REPLACE FUNCTION generate_scheduled_deliveries()
RETURNS void AS $$
DECLARE
  schedule_record RECORD;
  should_create BOOLEAN;
  delivery_date DATE;
  weeks_diff INTEGER;
  months_diff INTEGER;
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
    
    CASE schedule_record.schedule_type
      WHEN 'daily' THEN
        should_create := true;
      WHEN 'weekly' THEN
        should_create := EXTRACT(DOW FROM delivery_date)::INTEGER = ANY(schedule_record.schedule_days);
      WHEN 'biweekly' THEN
        should_create := (EXTRACT(DOW FROM delivery_date)::INTEGER = ANY(schedule_record.schedule_days))
                        AND (EXTRACT(WEEK FROM delivery_date)::INTEGER % 2 = EXTRACT(WEEK FROM schedule_record.start_date)::INTEGER % 2);
      WHEN 'monthly' THEN
        should_create := EXTRACT(DAY FROM delivery_date) = EXTRACT(DAY FROM schedule_record.start_date);
      WHEN 'custom' THEN
        IF schedule_record.custom_unit = 'days' THEN
          should_create := (delivery_date - schedule_record.start_date) % schedule_record.custom_interval = 0;
        ELSIF schedule_record.custom_unit = 'weeks' THEN
          weeks_diff := (delivery_date - schedule_record.start_date) / 7;
          should_create := (EXTRACT(DOW FROM delivery_date)::INTEGER = ANY(schedule_record.schedule_days))
                          AND (weeks_diff % schedule_record.custom_interval = 0);
        ELSIF schedule_record.custom_unit = 'months' THEN
          months_diff := (EXTRACT(YEAR FROM delivery_date) - EXTRACT(YEAR FROM schedule_record.start_date)) * 12 
                         + (EXTRACT(MONTH FROM delivery_date) - EXTRACT(MONTH FROM schedule_record.start_date));
          should_create := (EXTRACT(DAY FROM delivery_date) = EXTRACT(DAY FROM schedule_record.start_date))
                          AND (months_diff % schedule_record.custom_interval = 0);
        END IF;
    END CASE;
    
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
