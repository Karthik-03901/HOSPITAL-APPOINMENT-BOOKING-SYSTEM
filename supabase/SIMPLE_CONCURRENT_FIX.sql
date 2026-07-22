-- =====================================================
-- SIMPLE CONCURRENT BOOKING PREVENTION
-- Clean version without errors
-- =====================================================

-- Step 1: Drop existing unique index if any
DROP INDEX IF EXISTS idx_unique_doctor_datetime_active;

-- Step 2: Create partial unique index
-- This prevents double booking for active appointments
CREATE UNIQUE INDEX idx_unique_doctor_datetime_active 
ON appointments (doctor_id, appointment_date, appointment_time)
WHERE status NOT IN ('cancelled', 'completed', 'no_show');

-- Step 3: Create booking attempts table
CREATE TABLE IF NOT EXISTS booking_attempts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID,
  patient_email TEXT,
  doctor_id UUID,
  appointment_date DATE,
  appointment_time TIME,
  attempt_timestamp TIMESTAMPTZ DEFAULT NOW(),
  success BOOLEAN DEFAULT FALSE,
  failure_reason TEXT,
  appointment_id UUID
);

CREATE INDEX IF NOT EXISTS idx_booking_attempts_timestamp ON booking_attempts(attempt_timestamp);

-- Enable RLS
ALTER TABLE booking_attempts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "booking_attempts_all" ON booking_attempts;
CREATE POLICY "booking_attempts_all" ON booking_attempts FOR ALL USING (true) WITH CHECK (true);

-- Step 4: Create atomic booking function
CREATE OR REPLACE FUNCTION create_appointment_atomic(
  p_appointment_date TEXT,
  p_appointment_time TEXT,
  p_token_number TEXT,
  p_reason TEXT DEFAULT 'General consultation',
  p_patient_id TEXT DEFAULT NULL,
  p_patient_email TEXT DEFAULT NULL,
  p_doctor_id TEXT DEFAULT NULL,
  p_department_id TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_appointment_id UUID;
  v_queue_position INT;
  v_date DATE;
  v_time TIME;
  v_doctor_uuid UUID;
  v_existing_booking UUID;
  v_booking_attempt_id UUID;
BEGIN
  -- Convert text to proper types
  BEGIN
    v_date := p_appointment_date::DATE;
    v_time := p_appointment_time::TIME;
    v_doctor_uuid := NULLIF(p_doctor_id, '')::UUID;
  EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Invalid date, time, or doctor ID format'
    );
  END;
  
  -- Log booking attempt
  INSERT INTO booking_attempts (
    patient_id, patient_email, doctor_id,
    appointment_date, appointment_time, success
  ) VALUES (
    NULLIF(p_patient_id, '')::UUID, p_patient_email, v_doctor_uuid,
    v_date, v_time, FALSE
  )
  RETURNING id INTO v_booking_attempt_id;
  
  -- Check if slot is already taken
  SELECT id INTO v_existing_booking
  FROM appointments
  WHERE doctor_id = v_doctor_uuid
    AND appointment_date = v_date
    AND appointment_time = v_time
    AND status NOT IN ('cancelled', 'completed', 'no_show')
  LIMIT 1;
  
  IF FOUND THEN
    -- Slot already booked
    UPDATE booking_attempts
    SET success = FALSE, failure_reason = 'Slot already booked'
    WHERE id = v_booking_attempt_id;
    
    RETURN json_build_object(
      'success', false,
      'error', 'This time slot is already booked',
      'message', 'Someone else just booked this slot. Please choose another time.',
      'slot_taken', true
    );
  END IF;
  
  -- Book the slot
  BEGIN
    INSERT INTO appointments (
      appointment_date, appointment_time, token_number,
      status, reason, patient_id, doctor_id, department_id
    ) VALUES (
      v_date, v_time, p_token_number, 'confirmed',
      COALESCE(p_reason, 'General consultation'),
      NULLIF(p_patient_id, '')::UUID, v_doctor_uuid,
      NULLIF(p_department_id, '')::UUID
    )
    RETURNING id INTO v_appointment_id;
    
  EXCEPTION 
    WHEN unique_violation THEN
      UPDATE booking_attempts
      SET success = FALSE, failure_reason = 'Concurrent conflict'
      WHERE id = v_booking_attempt_id;
      
      RETURN json_build_object(
        'success', false,
        'error', 'Slot was just booked',
        'slot_taken', true
      );
  END;
  
  -- Wait for trigger
  PERFORM pg_sleep(0.2);
  
  -- Get queue position
  SELECT position INTO v_queue_position
  FROM queue_positions
  WHERE appointment_id = v_appointment_id;
  
  -- Update as successful
  UPDATE booking_attempts
  SET success = TRUE, appointment_id = v_appointment_id
  WHERE id = v_booking_attempt_id;
  
  RETURN json_build_object(
    'success', true,
    'appointment_id', v_appointment_id::TEXT,
    'token_number', p_token_number,
    'queue_position', COALESCE(v_queue_position, 1),
    'message', 'Appointment booked successfully!'
  );
  
EXCEPTION WHEN OTHERS THEN
  UPDATE booking_attempts
  SET success = FALSE, failure_reason = SQLERRM
  WHERE id = v_booking_attempt_id;
  
  RETURN json_build_object('success', false, 'error', SQLERRM);
END;
$$;

GRANT EXECUTE ON FUNCTION create_appointment_atomic TO anon, authenticated;

-- Step 5: Complete consultation function
CREATE OR REPLACE FUNCTION complete_consultation(p_appointment_id UUID)
RETURNS JSON AS $$
BEGIN
  UPDATE appointments
  SET status = 'completed', updated_at = NOW()
  WHERE id = p_appointment_id AND status = 'confirmed';
  
  IF NOT FOUND THEN
    RETURN json_build_object('success', false, 'error', 'Not found');
  END IF;
  
  UPDATE queue_positions
  SET status = 'completed', updated_at = NOW()
  WHERE appointment_id = p_appointment_id;
  
  RETURN json_build_object('success', true, 'message', 'Completed');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION complete_consultation TO authenticated;

-- Step 6: Test it
DO $$
DECLARE
  v_test_doctor UUID := gen_random_uuid();
  v_date TEXT := (CURRENT_DATE + 1)::TEXT;
  v_time TEXT := '10:00';
  v_r1 JSON;
  v_r2 JSON;
BEGIN
  -- First booking
  SELECT create_appointment_atomic(
    v_date, v_time, 'TEST1', 'Test', NULL, 'p1@test.com', v_test_doctor::TEXT, NULL
  ) INTO v_r1;
  
  -- Second booking (should fail)
  SELECT create_appointment_atomic(
    v_date, v_time, 'TEST2', 'Test', NULL, 'p2@test.com', v_test_doctor::TEXT, NULL
  ) INTO v_r2;
  
  -- Check results
  IF (v_r1->>'success')::BOOLEAN AND NOT (v_r2->>'success')::BOOLEAN THEN
    RAISE NOTICE 'SUCCESS: First booked, second blocked';
  ELSE
    RAISE NOTICE 'ISSUE: Check results';
  END IF;
END $$;

-- Show stats
SELECT 
  success,
  COUNT(*) as count
FROM booking_attempts
GROUP BY success;
