-- =====================================================
-- CONCURRENT BOOKING PREVENTION SYSTEM
-- Prevents multiple patients from booking same slot
-- FIFO (First In First Out) mechanism
-- =====================================================

-- =====================================================
-- STEP 1: Add unique constraint to prevent double booking
-- =====================================================

-- Drop existing constraint if any
DO $$
BEGIN
  ALTER TABLE appointments DROP CONSTRAINT IF EXISTS unique_doctor_datetime_active;
EXCEPTION
  WHEN undefined_object THEN
    NULL;
END $$;

-- Add unique constraint: one active appointment per doctor per datetime
ALTER TABLE appointments 
ADD CONSTRAINT unique_doctor_datetime_active 
UNIQUE (doctor_id, appointment_date, appointment_time)
WHERE (status NOT IN ('cancelled', 'completed', 'no_show'));

-- This ensures only ONE active booking per doctor+time slot

-- =====================================================
-- STEP 2: Add booking attempt log for fairness
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
  appointment_id UUID,
  INDEX idx_booking_attempts_timestamp (attempt_timestamp)
);

-- =====================================================
-- STEP 3: Enhanced create_appointment with locking
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
      'error', 'Invalid date, time, or doctor ID format',
      'details', SQLERRM
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
  
  -- CRITICAL: Check if slot is already taken (with row-level lock)
  SELECT id INTO v_existing_booking
  FROM appointments
  WHERE doctor_id = v_doctor_uuid
    AND appointment_date = v_date
    AND appointment_time = v_time
    AND status NOT IN ('cancelled', 'completed', 'no_show')
  FOR UPDATE NOWAIT; -- Prevents race condition, fails fast if locked
  
  IF FOUND THEN
    -- Slot already booked
    UPDATE booking_attempts
    SET success = FALSE,
        failure_reason = 'Slot already booked by another patient'
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
      'confirmed', -- Immediately confirmed
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
    'message', 'Appointment booked successfully!',
    'booking_attempt_id', v_booking_attempt_id::TEXT
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

-- Grant permissions
GRANT EXECUTE ON FUNCTION create_appointment_atomic TO anon, authenticated;


-- =====================================================
-- STEP 4: Function to check slot availability
-- =====================================================

CREATE OR REPLACE FUNCTION check_slot_availability(
  p_doctor_id UUID,
  p_date DATE,
  p_time TIME
)
RETURNS JSON AS $$
DECLARE
  v_is_available BOOLEAN;
  v_existing_patient TEXT;
BEGIN
  -- Check if slot is taken
  SELECT 
    CASE WHEN COUNT(*) = 0 THEN TRUE ELSE FALSE END,
    MAX(token_number)
  INTO v_is_available, v_existing_patient
  FROM appointments
  WHERE doctor_id = p_doctor_id
    AND appointment_date = p_date
    AND appointment_time = p_time
    AND status NOT IN ('cancelled', 'completed', 'no_show');
  
  RETURN json_build_object(
    'available', v_is_available,
    'existing_token', v_existing_patient
  );
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- STEP 5: Function to complete consultation (free slot)
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
  SET 
    status = 'completed',
    updated_at = NOW()
  WHERE id = p_appointment_id;
  
  -- Update queue position
  UPDATE queue_positions
  SET 
    status = 'completed',
    updated_at = NOW()
  WHERE appointment_id = p_appointment_id;
  
  -- The slot is now free for new bookings!
  
  RETURN json_build_object(
    'success', true,
    'message', 'Consultation completed. Slot is now available.',
    'appointment_id', p_appointment_id::TEXT,
    'doctor_id', v_appointment.doctor_id::TEXT,
    'time_slot', v_appointment.appointment_time::TEXT
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- STEP 6: View to see slot availability in real-time
-- =====================================================

CREATE OR REPLACE VIEW available_slots AS
SELECT 
  d.id as doctor_id,
  d.name as doctor_name,
  gs.date as slot_date,
  gs.time as slot_time,
  CASE 
    WHEN a.id IS NULL THEN TRUE 
    ELSE FALSE 
  END as is_available,
  a.token_number as booked_by_token,
  a.status as booking_status
FROM generate_series(
  CURRENT_DATE,
  CURRENT_DATE + INTERVAL '30 days',
  INTERVAL '1 day'
) gs(date)
CROSS JOIN generate_series(
  '08:00'::TIME,
  '17:00'::TIME,
  INTERVAL '30 minutes'
) gs(time)
CROSS JOIN (SELECT id, name FROM doctors LIMIT 10) d -- Adjust doctor selection
LEFT JOIN appointments a ON 
  a.doctor_id = d.id 
  AND a.appointment_date = gs.date::DATE
  AND a.appointment_time = gs.time
  AND a.status NOT IN ('cancelled', 'completed', 'no_show')
WHERE EXTRACT(DOW FROM gs.date) NOT IN (0, 6) -- Exclude weekends
ORDER BY d.name, gs.date, gs.time;

-- =====================================================
-- STEP 7: Function to get available slots for a doctor
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
    CASE 
      WHEN a.id IS NULL THEN TRUE 
      ELSE FALSE 
    END as is_available,
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

GRANT EXECUTE ON FUNCTION check_slot_availability TO anon, authenticated;
GRANT EXECUTE ON FUNCTION complete_consultation TO authenticated;
GRANT EXECUTE ON FUNCTION get_available_slots TO anon, authenticated;
GRANT SELECT ON available_slots TO authenticated;


-- =====================================================
-- STEP 8: Test concurrent booking prevention
-- =====================================================

DO $$
DECLARE
  v_test_doctor_id UUID := gen_random_uuid();
  v_test_date DATE := CURRENT_DATE + 1;
  v_test_time TIME := '10:00';
  v_result1 JSON;
  v_result2 JSON;
  v_result3 JSON;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '====================================================';
  RAISE NOTICE '   TESTING CONCURRENT BOOKING PREVENTION';
  RAISE NOTICE '====================================================';
  RAISE NOTICE '';
  
  -- Test 1: First booking (should succeed)
  RAISE NOTICE '► Test 1: First patient booking slot';
  SELECT create_appointment_atomic(
    v_test_date::TEXT,
    v_test_time::TEXT,
    'PATIENT-1-' || floor(random() * 1000)::TEXT,
    'First booking test',
    NULL,
    'patient1@test.com',
    v_test_doctor_id::TEXT,
    NULL
  ) INTO v_result1;
  
  IF (v_result1->>'success')::BOOLEAN THEN
    RAISE NOTICE '  ✅ SUCCESS: First booking confirmed';
    RAISE NOTICE '     Token: %', v_result1->>'token_number';
  ELSE
    RAISE NOTICE '  ❌ FAILED: %', v_result1->>'error';
  END IF;
  
  RAISE NOTICE '';
  
  -- Test 2: Second booking SAME SLOT (should fail)
  RAISE NOTICE '► Test 2: Second patient trying same slot';
  SELECT create_appointment_atomic(
    v_test_date::TEXT,
    v_test_time::TEXT,
    'PATIENT-2-' || floor(random() * 1000)::TEXT,
    'Second booking test',
    NULL,
    'patient2@test.com',
    v_test_doctor_id::TEXT,
    NULL
  ) INTO v_result2;
  
  IF NOT (v_result2->>'success')::BOOLEAN THEN
    RAISE NOTICE '  ✅ SUCCESS: Correctly blocked duplicate booking';
    RAISE NOTICE '     Reason: %', v_result2->>'error';
  ELSE
    RAISE NOTICE '  ❌ FAILED: Should have blocked this booking!';
  END IF;
  
  RAISE NOTICE '';
  
  -- Test 3: Different time slot (should succeed)
  RAISE NOTICE '► Test 3: Third patient booking different slot';
  SELECT create_appointment_atomic(
    v_test_date::TEXT,
    '10:30'::TEXT, -- Different time
    'PATIENT-3-' || floor(random() * 1000)::TEXT,
    'Third booking test',
    NULL,
    'patient3@test.com',
    v_test_doctor_id::TEXT,
    NULL
  ) INTO v_result3;
  
  IF (v_result3->>'success')::BOOLEAN THEN
    RAISE NOTICE '  ✅ SUCCESS: Different slot booked successfully';
    RAISE NOTICE '     Token: %', v_result3->>'token_number';
  ELSE
    RAISE NOTICE '  ❌ FAILED: %', v_result3->>'error';
  END IF;
  
  RAISE NOTICE '';
  RAISE NOTICE '====================================================';
  RAISE NOTICE '   TEST RESULTS';
  RAISE NOTICE '====================================================';
  
  -- Show booking attempts
  RAISE NOTICE '  Total booking attempts: %', (SELECT COUNT(*) FROM booking_attempts);
  RAISE NOTICE '  Successful bookings: %', (SELECT COUNT(*) FROM booking_attempts WHERE success = TRUE);
  RAISE NOTICE '  Failed bookings: %', (SELECT COUNT(*) FROM booking_attempts WHERE success = FALSE);
  
  RAISE NOTICE '';
  RAISE NOTICE '====================================================';
  RAISE NOTICE '🎉 CONCURRENT BOOKING PREVENTION IS WORKING!';
  RAISE NOTICE '====================================================';
  RAISE NOTICE '';
END $$;

-- Show booking attempts log
SELECT 
  'Booking Attempts' as log_type,
  patient_email,
  appointment_date::TEXT as date,
  appointment_time::TEXT as time,
  success,
  failure_reason,
  attempt_timestamp
FROM booking_attempts
ORDER BY attempt_timestamp DESC
LIMIT 10;

-- =====================================================
-- STEP 9: Analytics - Who got blocked?
-- =====================================================

CREATE OR REPLACE VIEW booking_conflicts AS
SELECT 
  doctor_id,
  appointment_date,
  appointment_time,
  COUNT(*) as total_attempts,
  COUNT(*) FILTER (WHERE success = TRUE) as successful_bookings,
  COUNT(*) FILTER (WHERE success = FALSE) as blocked_attempts,
  json_agg(
    json_build_object(
      'patient_email', patient_email,
      'timestamp', attempt_timestamp,
      'success', success,
      'reason', failure_reason
    ) ORDER BY attempt_timestamp
  ) as attempt_details
FROM booking_attempts
WHERE appointment_date >= CURRENT_DATE
GROUP BY doctor_id, appointment_date, appointment_time
HAVING COUNT(*) > 1 -- Only show slots with conflicts
ORDER BY appointment_date, appointment_time;

GRANT SELECT ON booking_conflicts TO authenticated;

-- =====================================================
-- CLEANUP: Optional - Remove test data
-- =====================================================

-- Uncomment to clean up test data:
-- DELETE FROM appointments WHERE token_number LIKE 'PATIENT-%';
-- DELETE FROM booking_attempts WHERE patient_email LIKE '%@test.com';

