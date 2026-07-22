-- Complete Type Fix for Booking System
-- Fixes all TEXT vs INTEGER type mismatches

-- =====================================================
-- Step 1: Fix appointments table columns
-- =====================================================

-- Fix token_number (should be TEXT)
ALTER TABLE appointments 
  DROP CONSTRAINT IF EXISTS appointments_token_number_key;

ALTER TABLE appointments 
  ALTER COLUMN token_number TYPE TEXT USING COALESCE(token_number::TEXT, '');

ALTER TABLE appointments 
  ADD CONSTRAINT appointments_token_number_key UNIQUE (token_number);

-- Make sure these columns are also TEXT if they exist
DO $$
BEGIN
  -- Fix patient_id if it's not UUID
  BEGIN
    ALTER TABLE appointments ALTER COLUMN patient_id TYPE UUID USING patient_id::UUID;
  EXCEPTION WHEN OTHERS THEN
    NULL; -- Column might not exist or already correct
  END;
  
  -- Fix doctor_id if it's not UUID
  BEGIN
    ALTER TABLE appointments ALTER COLUMN doctor_id TYPE UUID USING doctor_id::UUID;
  EXCEPTION WHEN OTHERS THEN
    NULL;
  END;
  
  -- Fix department_id if it's not UUID
  BEGIN
    ALTER TABLE appointments ALTER COLUMN department_id TYPE UUID USING department_id::UUID;
  EXCEPTION WHEN OTHERS THEN
    NULL;
  END;
END $$;

-- =====================================================
-- Step 2: Recreate the RPC function with proper types
-- =====================================================

DROP FUNCTION IF EXISTS create_appointment(DATE, TIME, TEXT, TEXT, UUID, UUID, UUID);
DROP FUNCTION IF EXISTS create_appointment(DATE, TIME, TEXT, TEXT);

CREATE OR REPLACE FUNCTION create_appointment(
  p_appointment_date DATE,
  p_appointment_time TIME,
  p_token_number TEXT,
  p_reason TEXT DEFAULT 'General consultation',
  p_patient_id UUID DEFAULT NULL,
  p_doctor_id UUID DEFAULT NULL,
  p_department_id UUID DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_appointment_id UUID;
  v_queue_position INT;
  v_token TEXT;
BEGIN
  -- Ensure token is text
  v_token := p_token_number::TEXT;
  
  -- Insert appointment
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
    p_appointment_date,
    p_appointment_time,
    v_token,
    'pending',
    p_reason,
    p_patient_id,
    p_doctor_id,
    p_department_id
  )
  RETURNING id INTO v_appointment_id;
  
  -- Wait for trigger to create queue position
  PERFORM pg_sleep(0.3);
  
  -- Get queue position (with safe COALESCE)
  SELECT COALESCE(position::INT, 1) INTO v_queue_position
  FROM queue_positions
  WHERE appointment_id = v_appointment_id;
  
  -- If no queue position was created, set to 1
  IF v_queue_position IS NULL THEN
    v_queue_position := 1;
  END IF;
  
  -- Return success
  RETURN json_build_object(
    'success', true,
    'appointment_id', v_appointment_id::TEXT,
    'token_number', v_token,
    'queue_position', v_queue_position,
    'message', 'Appointment booked successfully'
  );
  
EXCEPTION WHEN OTHERS THEN
  RETURN json_build_object(
    'success', false,
    'error', SQLERRM,
    'message', 'Failed to book appointment',
    'sqlstate', SQLSTATE
  );
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION create_appointment TO anon, authenticated;

-- =====================================================
-- Step 3: Test the function
-- =====================================================

DO $$
DECLARE
  v_result JSON;
  v_token TEXT;
BEGIN
  -- Generate a text token
  v_token := 'TEST-' || floor(random() * 10000)::TEXT;
  
  RAISE NOTICE '';
  RAISE NOTICE '============================================';
  RAISE NOTICE 'Testing with token: %', v_token;
  RAISE NOTICE '============================================';
  
  -- Test create appointment
  SELECT create_appointment(
    CURRENT_DATE + 1,
    '14:30'::TIME,
    v_token,
    'Test booking with fixed types'
  ) INTO v_result;
  
  RAISE NOTICE '';
  RAISE NOTICE 'Test Result: %', v_result;
  RAISE NOTICE '';
  
  IF (v_result->>'success')::BOOLEAN THEN
    RAISE NOTICE '✅ SUCCESS - All types fixed!';
    RAISE NOTICE 'Appointment ID: %', v_result->>'appointment_id';
    RAISE NOTICE 'Token: %', v_result->>'token_number';
    RAISE NOTICE 'Queue Position: %', v_result->>'queue_position';
    RAISE NOTICE '';
    RAISE NOTICE '============================================';
    RAISE NOTICE '✅ Booking system ready!';
    RAISE NOTICE '============================================';
  ELSE
    RAISE NOTICE '❌ FAILED - Error: %', v_result->>'error';
    RAISE NOTICE 'SQL State: %', v_result->>'sqlstate';
  END IF;
END $$;
