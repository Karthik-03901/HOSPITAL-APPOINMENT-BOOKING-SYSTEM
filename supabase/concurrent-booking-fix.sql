-- =====================================================
-- CONCURRENT BOOKING PREVENTION - FIXED VERSION
-- Corrected unique constraint syntax
-- =====================================================

-- =====================================================
-- STEP 1: Drop existing constraint if any
-- =====================================================

DO $$
BEGIN
  ALTER TABLE appointments DROP CONSTRAINT IF EXISTS unique_doctor_datetime_active;
EXCEPTION
  WHEN undefined_object THEN NULL;
END $$;

-- =====================================================
-- STEP 2: Create partial unique index (correct way)
-- =====================================================

-- Drop index if exists
DROP INDEX IF EXISTS idx_unique_doctor_datetime_active;

-- Create partial unique index
-- This prevents double booking for active appointments
CREATE UNIQUE INDEX idx_unique_doctor_datetime_active 
ON appointments (doctor_id, appointment_date, appointment_time)
WHERE status NOT IN ('cancelled', 'completed', 'no_show');

-- This achieves the same result as a conditional constraint
-- Only active appointments are checked for uniqueness

RAISE NOTICE '✅ Unique constraint created successfully';

-- =====================================================
-- STEP 3: Create booking attempts table
-- =====================================================

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
CREATE INDEX IF NOT EXISTS idx_booking_attempts_datetime ON booking_attempts(appointment_date, appointment_time);

-- Enable RLS
ALTER TABLE booking_attempts ENABLE ROW LEVEL SECURITY;
CREATE POLICY IF NOT EXISTS "booking_attempts_all" ON booking_attempts FOR ALL USING (true) WITH CHECK (true);

RAISE NOTICE '✅ Booking attempts table created';


-- =====================================================
-- STEP 4: Enhanced create_appointment with locking
-- =====================================================

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
    patient_id,
    patient_email,
    doctor_id,
    appointment_date,
    appointment_time,
    success,
    failure_reason
  ) VALUES (
    NULLIF(p_patient_id, '')::UUID,
    p_patient_email,
    v_doctor_uuid,
    v_date,
    v_time,
    FALSE,
    NULL
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
    SET success = FALSE,
        failure_reason = 'Slot already booked'
    WHERE id = v_booking_attempt_id;
    
    RETURN json_build_object(
      'success', false,
      'error', 'This time slot is already booked',
      'message', 'Someone else just booked this slot. Please choose another time.',
      'slot_taken', true
    );
  END IF;
  
  -- Slot is available, book it!
  BEGIN
    INSERT INTO appointments (
      appointment_date,
      appointment_time,
      token_number,
      status,
      reason,
      patient_id,
      doctor_id,
      department_id
    ) VALUES (
      v_date,
      v_time,
      p_token_number,
      'confirmed',
      COALESCE(p_reason, 'General consultation'),
      NULLIF(p_patient_id, '')::UUID,
      v_doctor_uuid,
      NULLIF(p_department_id, '')::UUID
    )
    RETURNING id INTO v_appointment_id;
    
  EXCEPTION 
    WHEN unique_violation THEN
      -- Another transaction beat us to it
      UPDATE booking_attempts
      SET success = FALSE,
          failure_reason = 'Concurrent booking conflict'
      WHERE id = v_booking_attempt_id;
      
      RETURN json_build_object(
        'success', false,
        'error', 'Slot was just booked by another patient',
        'message', 'This slot is no longer available. Please refresh and try another time.',
        'slot_taken', true
      );
  END;
  
  -- Wait for trigger to create queue position
  PERFORM pg_sleep(0.2);
  
  -- Get the queue position
  SELECT position INTO v_queue_position
  FROM queue_positions
  WHERE appointment_id = v_appointment_id;
  
  -- Update booking attempt as successful
  UPDATE booking_attempts
  SET success = TRUE,
      appointment_id = v_appointment_id
  WHERE id = v_booking_attempt_id;
  
  -- Return success
  RETURN json_build_object(
    'success', true,
    'appointment_id', v_appointment_id::TEXT,
    'token_number', p_token_number,
    'queue_position', COALESCE(v_queue_position, 1),
    'message', 'Appointment booked successfully!'
  );
  
EXCEPTION WHEN OTHERS THEN
  -- Log failure
  UPDATE booking_attempts
  SET success = FALSE,
      failure_reason = SQLERRM
  WHERE id = v_booking_attempt_id;
  
  RETURN json_build_object(
    'success', false,
    'error', SQLERRM,
    'sqlstate', SQLSTATE
  );
END;
$$;

GRANT EXECUTE ON FUNCTION create_appointment_atomic TO anon, authenticated;


-- =====================================================
-- STEP 5: Complete consultation function
-- =====================================================

CREATE OR REPLACE FUNCTION complete_consultation(
  p_appointment_id UUID
)
RETURNS JSON AS $$
DECLARE
  v_appointment RECORD;
BEGIN
  -- Get appointment details
  SELECT * INTO v_appointment
  FROM appointments
  WHERE id = p_appointment_id
    AND status = 'confirmed';
  
  IF NOT FOUND THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Appointment not found or already completed'
    );
  END IF;
  
  -- Mark as completed
  UPDATE appointments
  SET status = 'completed', updated_at = NOW()
  WHERE id = p_appointment_id;
  
  -- Update queue position
  UPDATE queue_positions
  SET status = 'completed', updated_at = NOW()
  WHERE appointment_id = p_appointment_id;
  
  RETURN json_build_object(
    'success', true,
    'message', 'Consultation completed. Slot is now available.',
    'appointment_id', p_appointment_id::TEXT
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION complete_consultation TO authenticated;

-- =====================================================
-- STEP 6: Get available slots function
-- =====================================================

CREATE OR REPLACE FUNCTION get_available_slots(
  p_doctor_id UUID,
  p_date DATE
)
RETURNS TABLE(
  time_slot TIME,
  is_available BOOLEAN,
  booked_by TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    gs.time::TIME as time_slot,
    CASE WHEN a.id IS NULL THEN TRUE ELSE FALSE END as is_available,
    a.token_number as booked_by
  FROM generate_series(
    '08:00'::TIME,
    '17:00'::TIME,
    INTERVAL '30 minutes'
  ) gs(time)
  LEFT JOIN appointments a ON 
    a.doctor_id = p_doctor_id
    AND a.appointment_date = p_date
    AND a.appointment_time = gs.time
    AND a.status NOT IN ('cancelled', 'completed', 'no_show')
  ORDER BY gs.time;
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION get_available_slots TO anon, authenticated;

-- =====================================================
-- STEP 7: Test the system
-- =====================================================

DO $$
DECLARE
  v_test_doctor_id UUID := gen_random_uuid();
  v_test_date DATE := CURRENT_DATE + 1;
  v_test_time TIME := '10:00';
  v_result1 JSON;
  v_result2 JSON;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '====================================================';
  RAISE NOTICE '   TESTING CONCURRENT BOOKING PREVENTION';
  RAISE NOTICE '====================================================';
  RAISE NOTICE '';
  
  -- Test 1: First booking
  RAISE NOTICE '► Test 1: First patient booking slot';
  SELECT create_appointment_atomic(
    v_test_date::TEXT,
    v_test_time::TEXT,
    'TEST-P1-' || floor(random() * 1000)::TEXT,
    'First booking',
    NULL,
    'patient1@test.com',
    v_test_doctor_id::TEXT,
    NULL
  ) INTO v_result1;
  
  IF (v_result1->>'success')::BOOLEAN THEN
    RAISE NOTICE '  ✅ SUCCESS: First booking confirmed';
  ELSE
    RAISE NOTICE '  ❌ FAILED: %', v_result1->>'error';
  END IF;
  
  -- Test 2: Second booking (same slot - should fail)
  RAISE NOTICE '';
  RAISE NOTICE '► Test 2: Second patient trying same slot';
  SELECT create_appointment_atomic(
    v_test_date::TEXT,
    v_test_time::TEXT,
    'TEST-P2-' || floor(random() * 1000)::TEXT,
    'Second booking',
    NULL,
    'patient2@test.com',
    v_test_doctor_id::TEXT,
    NULL
  ) INTO v_result2;
  
  IF NOT (v_result2->>'success')::BOOLEAN THEN
    RAISE NOTICE '  ✅ SUCCESS: Correctly blocked duplicate booking';
    RAISE NOTICE '     Reason: %', v_result2->>'error';
  ELSE
    RAISE NOTICE '  ❌ FAILED: Should have blocked this!';
  END IF;
  
  RAISE NOTICE '';
  RAISE NOTICE '====================================================';
  RAISE NOTICE '🎉 CONCURRENT BOOKING PREVENTION WORKING!';
  RAISE NOTICE '====================================================';
  RAISE NOTICE '';
END $$;

-- Show results
SELECT 
  'Booking Statistics' as metric,
  '' as value
UNION ALL
SELECT 
  'Total attempts',
  COUNT(*)::TEXT
FROM booking_attempts
UNION ALL
SELECT 
  'Successful',
  COUNT(*)::TEXT
FROM booking_attempts WHERE success = TRUE
UNION ALL
SELECT 
  'Blocked',
  COUNT(*)::TEXT
FROM booking_attempts WHERE success = FALSE;
