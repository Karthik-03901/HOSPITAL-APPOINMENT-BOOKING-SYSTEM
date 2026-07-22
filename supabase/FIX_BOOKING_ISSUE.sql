-- =====================================================
-- FIX BOOKING ISSUE
-- Add doctor_name and department_name columns
-- =====================================================

-- Add new columns to store doctor and department names directly
ALTER TABLE appointments
ADD COLUMN IF NOT EXISTS doctor_name TEXT,
ADD COLUMN IF NOT EXISTS department_name TEXT,
ADD COLUMN IF NOT EXISTS patient_name TEXT;

-- Drop existing function first (to avoid "not unique" error)
DROP FUNCTION IF EXISTS create_appointment_atomic(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS create_appointment_atomic(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT);

-- Update the RPC function to accept and store names
CREATE OR REPLACE FUNCTION create_appointment_atomic(
  p_appointment_date TEXT,
  p_appointment_time TEXT,
  p_token_number TEXT,
  p_reason TEXT DEFAULT 'General consultation',
  p_patient_id TEXT DEFAULT NULL,
  p_patient_email TEXT DEFAULT NULL,
  p_patient_name TEXT DEFAULT NULL,
  p_doctor_id TEXT DEFAULT NULL,
  p_doctor_name TEXT DEFAULT NULL,
  p_department_id TEXT DEFAULT NULL,
  p_department_name TEXT DEFAULT NULL
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
    
    -- Only try to convert doctor_id if it's a valid UUID format
    IF p_doctor_id IS NOT NULL AND p_doctor_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN
      v_doctor_uuid := p_doctor_id::UUID;
    ELSE
      v_doctor_uuid := NULL;
    END IF;
    
  EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Invalid date or time format. Expected YYYY-MM-DD and HH:MM'
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
  
  -- Check if slot is already taken (only if doctor_uuid is provided)
  IF v_doctor_uuid IS NOT NULL THEN
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
  END IF;
  
  -- Book the slot
  BEGIN
    INSERT INTO appointments (
      appointment_date, 
      appointment_time, 
      token_number,
      status, 
      reason, 
      patient_id, 
      patient_email,
      patient_name,
      doctor_id, 
      doctor_name,
      department_id,
      department_name
    ) VALUES (
      v_date, 
      v_time, 
      p_token_number, 
      'confirmed',
      COALESCE(p_reason, 'General consultation'),
      NULLIF(p_patient_id, '')::UUID,
      p_patient_email,
      p_patient_name,
      v_doctor_uuid,
      p_doctor_name,
      NULLIF(p_department_id, '')::UUID,
      p_department_name
    )
    RETURNING id INTO v_appointment_id;
    
  EXCEPTION 
    WHEN unique_violation THEN
      UPDATE booking_attempts
      SET success = FALSE, failure_reason = 'Concurrent conflict'
      WHERE id = v_booking_attempt_id;
      
      RETURN json_build_object(
        'success', false,
        'error', 'Slot was just booked by another patient',
        'slot_taken', true
      );
  END;
  
  -- Wait for trigger to create queue position
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
  
  RETURN json_build_object(
    'success', false, 
    'error', SQLERRM,
    'details', 'Database error occurred'
  );
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION create_appointment_atomic TO anon, authenticated;

-- Test the function
DO $$
DECLARE
  v_test_result JSON;
BEGIN
  -- Test booking with names only (no UUIDs)
  SELECT create_appointment_atomic(
    (CURRENT_DATE + 1)::TEXT,  -- tomorrow
    '10:30',                    -- time
    'TEST-001',                 -- token
    'Test appointment',         -- reason
    NULL,                       -- patient_id
    'test@example.com',         -- patient_email
    'Test Patient',             -- patient_name
    NULL,                       -- doctor_id (NULL)
    'Dr. John Smith',           -- doctor_name
    NULL,                       -- department_id (NULL)
    'Cardiology'                -- department_name
  ) INTO v_test_result;
  
  RAISE NOTICE 'Test result: %', v_test_result;
  
  IF (v_test_result->>'success')::BOOLEAN THEN
    RAISE NOTICE '✅ SUCCESS: Booking function works!';
    RAISE NOTICE 'Appointment ID: %', v_test_result->>'appointment_id';
  ELSE
    RAISE NOTICE '❌ FAILED: %', v_test_result->>'error';
  END IF;
END $$;

-- Verify the test appointment was created
SELECT 
  id,
  token_number,
  appointment_date,
  appointment_time,
  doctor_name,
  department_name,
  patient_email,
  status
FROM appointments
WHERE token_number = 'TEST-001';

SELECT 'Fix applied successfully! Now update booking.js to pass doctor_name and department_name.' as status;
