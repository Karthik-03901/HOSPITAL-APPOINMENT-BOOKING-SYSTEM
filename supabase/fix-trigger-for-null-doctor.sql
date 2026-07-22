-- Fix trigger to handle NULL doctor_id
-- Run this in Supabase SQL Editor

-- Drop and recreate the initialize_queue_position function
DROP FUNCTION IF EXISTS initialize_queue_position() CASCADE;

CREATE FUNCTION initialize_queue_position()
RETURNS TRIGGER AS $$
DECLARE
  current_position INT;
BEGIN
  -- Only create queue position if doctor_id is provided
  IF NEW.doctor_id IS NOT NULL THEN
    -- Calculate position based on existing appointments
    SELECT COALESCE(COUNT(*), 0) + 1 INTO current_position
    FROM appointments
    WHERE doctor_id = NEW.doctor_id
      AND DATE(appointment_date) = DATE(NEW.appointment_date)
      AND status IN ('pending', 'confirmed', 'checked_in')
      AND appointment_time <= NEW.appointment_time
      AND id != NEW.id;
    
    -- Insert queue position
    INSERT INTO queue_positions (
      appointment_id,
      doctor_id,
      position,
      estimated_time,
      status
    ) VALUES (
      NEW.id,
      NEW.doctor_id,
      current_position,
      NEW.appointment_date + NEW.appointment_time + (current_position * INTERVAL '15 minutes'),
      'waiting'
    );
  ELSE
    -- If no doctor_id, just create a simple queue position with position 1
    INSERT INTO queue_positions (
      appointment_id,
      doctor_id,
      position,
      estimated_time,
      status
    ) VALUES (
      NEW.id,
      NULL,
      1,
      NEW.appointment_date + NEW.appointment_time + INTERVAL '15 minutes',
      'waiting'
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate the trigger
CREATE TRIGGER trigger_initialize_queue
  AFTER INSERT ON appointments
  FOR EACH ROW
  EXECUTE FUNCTION initialize_queue_position();

DO $$
BEGIN
  RAISE NOTICE '============================================';
  RAISE NOTICE '✅ Trigger fixed to handle NULL doctor_id';
  RAISE NOTICE '============================================';
  RAISE NOTICE '';
  RAISE NOTICE 'The trigger now works even without doctor_id';
  RAISE NOTICE 'Try booking again!';
  RAISE NOTICE '';
END $$;
