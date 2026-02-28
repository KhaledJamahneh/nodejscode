-- Change scheduled_deliveries to support multiple clients
-- Option 1: Change client_id to array
ALTER TABLE scheduled_deliveries 
  DROP CONSTRAINT scheduled_deliveries_client_id_fkey;

ALTER TABLE scheduled_deliveries 
  ALTER COLUMN client_id TYPE INTEGER[] USING ARRAY[client_id];

-- Add new constraint for array
ALTER TABLE scheduled_deliveries
  ADD CONSTRAINT scheduled_deliveries_client_ids_check 
  CHECK (array_length(client_id, 1) > 0);

-- Update the generate function to handle arrays
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
  client_id_item INTEGER;
BEGIN
  delivery_date := CURRENT_DATE;
  
  FOR schedule_record IN 
    SELECT sd.*
    FROM scheduled_deliveries sd
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
                        AND (EXTRACT(WEEK FROM delivery_date) % 2 = EXTRACT(WEEK FROM schedule_record.start_date) % 2);
      WHEN 'monthly' THEN
        should_create := EXTRACT(DAY FROM delivery_date) = EXTRACT(DAY FROM schedule_record.start_date);
      WHEN 'custom' THEN
        IF schedule_record.frequency_per_week IS NOT NULL AND schedule_record.frequency_per_month IS NOT NULL THEN
          interval_days := schedule_record.frequency_per_week;
          total_deliveries := schedule_record.frequency_per_month;
          days_since_start := delivery_date - schedule_record.start_date;
          
          SELECT COUNT(*) INTO deliveries_created
          FROM deliveries
          WHERE delivery_date >= schedule_record.start_date
            AND notes LIKE '%schedule #' || schedule_record.id || '%';
          
          IF deliveries_created < total_deliveries 
             AND days_since_start % interval_days = 0 
             AND days_since_start <= interval_days THEN
            should_create := true;
          END IF;
        END IF;
    END CASE;
    
    IF should_create THEN
      -- Create delivery for each client in the array
      FOREACH client_id_item IN ARRAY schedule_record.client_id
      LOOP
        INSERT INTO deliveries (
          client_id, worker_id, delivery_date, scheduled_time, 
          gallons_delivered, status, notes
        )
        SELECT 
          client_id_item,
          schedule_record.worker_id,
          delivery_date,
          schedule_record.schedule_time,
          schedule_record.gallons,
          'pending',
          'Auto-generated from schedule #' || schedule_record.id
        WHERE NOT EXISTS (
          SELECT 1 FROM deliveries 
          WHERE client_id = client_id_item
            AND delivery_date = delivery_date
            AND scheduled_time = schedule_record.schedule_time
        );
      END LOOP;
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql;
