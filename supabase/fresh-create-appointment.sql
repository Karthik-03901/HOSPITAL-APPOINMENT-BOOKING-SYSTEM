-- Fresh Create Appointment Function
-- Drop ALL versions and create a clean one

-- Drop ALL possible versions of the function
DROP FUNCTION IF EXISTS create_appointment CASCADE;
DROP FUNCTION IF EXISTS public.create_appointment CASCADE;
DROP FUNCTION IF EXISTS create_appointment(DATE, TIME, TEXT, TEXT, UUID, UUID, UUID) CASCADE;
DROP FUNCTION IF EXISTS create_appointment(DATE, TIME, TEXT, TEXT) CASCADE;
DROP FUNCTION IF EXISTS create_appointment(DATE, TIME, INTEGER, TEXT) CASCADE;

-- Create the function with ALL parameters as TEXT first, then cast
CREATE OR REPLACE FUNCTION create_appointment(
  p_appointment_date TEXT,  -- Accept as TEXT
  p_appointment_time TEXT,  -- Accept as TEXT
  p_token_number TEXT,      -- Accept as TEXT
  p_reason TEXT DEFAULT 'General consultation',
  p_patient_id TEXT DEFAULT NULL,  -- Accept as TEXT
  p_doctor_id TEXT DEFAULT NULL,   -- Accept as TEXT
  p_department_id TEXT DEFAULT NULL  -- Accept as TEXT
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
  v_patient UUID;
  v_doctor UUID;
  v_department UUID;
BEGIN
  -- Convert text inputs to proper types
  BEGIN
    v_date := p_appointment_date::DATE;
    v_time := p_appointment_time::TIME;
    
    -- Convert UUIDs if provided
    IF p_patient_id IS NOT NULL AND p_patient_id != '' THEN
      v_patient := p_patient_id::UUID;
    END IF;
    
    IF p_doctor_id IS NOT NULL AND p_doctor_id != '' THEN
      v_doctor := p_doctor_id::UUID;
    END IF;
    
    IF p_department_id IS NOT NULL AND p_department_id != '' THEN
      v_department := p_department_id::UUID;
    END IF;
    
  EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Invalid date/time format',
      'message', SQLERRM
    );
  END;
  
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
    v_date,
    v_time,
    p_token_number,  -- Use as-is (TEXT)
    'pending',
    p_reason,
    v_patient,
    v_doctor,
    v_department
  )
  RETURNING id INTO v_appointment_id;
  
  -- Wait a moment for trigger to create queue position
  PERFORM pg_sleep(0.2);
  
  -- Get queue position
  SELECT position INTO v_queue_position
  FROM queue_positions
  WHERE appointment_id = v_appointment_id;
  
  -- If no queue position, default to 1
  IF v_queue_position IS NULL THEN
    v_queue_position := 1;
  END IF;
  
  -- Return success
  RETURN json_build_object(
    'success', true,
    'appointment_id', v_appointment_id::TEXT,
    'token_number', p_token_number,
    'queue_position', v_queue_position,
    'message', 'Appointment booked successfully!'
  );
  
EXCEPTION WHEN OTHERS THEN
  RETURN json_build_object(
    'success', false,
    'error', SQLERRM,
    'sqlstate', SQLSTATE,
    'message', 'Database error occurred'
  );
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION create_appointment TO anon, authenticated;

-- Test it
DO $$
DECLARE
  v_result JSON;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '============================================';
  RAISE NOTICE 'Testing create_appointment function';
  RAISE NOTICE '============================================';
  
  SELECT create_appointment(
    '2026-07-23',           -- date as text
    '14:30',                -- time as text
    'TEST-' || floor(random() * 10000)::TEXT,  -- token as text
    'Test appointment',
    null,
    null,
    null
  ) INTO v_result;
  
  RAISE NOTICE 'Result: %', v_result;
  
  IF (v_result->>'success')::BOOLEAN THEN
    RAISE NOTICE '';
    RAISE NOTICE '✅ SUCCESS!';
    RAISE NOTICE 'Token: %', v_result->>'token_number';
    RAISE NOTICE 'Queue: %', v_result->>'queue_position';
    RAISE NOTICE '';
    RAISE NOTICE '============================================';
    RAISE NOTICE '✅ Booking system ready to use!';
    RAISE NOTICE '============================================';
  ELSE
    RAISE NOTICE '';
    RAISE NOTICE '❌ FAILED';
    RAISE NOTICE 'Error: %', v_result->>'error';
    RAISE NOTICE '============================================';
  END IF;
END $$;
