-- FORCE DELETE ALL create_appointment functions
-- This removes every single version

-- Method 1: Drop by specific signatures
DROP FUNCTION IF EXISTS create_appointment(date, time without time zone, text, text, uuid, uuid, uuid) CASCADE;
DROP FUNCTION IF EXISTS create_appointment(date, text, text, text, text, text, text) CASCADE;
DROP FUNCTION IF EXISTS create_appointment(text, text, text, text, uuid, uuid, uuid) CASCADE;
DROP FUNCTION IF EXISTS create_appointment(text, text, text, text, text, text, text) CASCADE;
DROP FUNCTION IF EXISTS create_appointment(date, time, text, text) CASCADE;
DROP FUNCTION IF EXISTS create_appointment(uuid, uuid) CASCADE;
DROP FUNCTION IF EXISTS create_appointment(uuid) CASCADE;

-- Method 2: Force drop using pg_proc
DO $$
DECLARE
  func_record RECORD;
BEGIN
  FOR func_record IN 
    SELECT p.oid::regprocedure as func_signature
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE p.proname = 'create_appointment'
      AND n.nspname = 'public'
  LOOP
    EXECUTE format('DROP FUNCTION IF EXISTS %s CASCADE', func_record.func_signature);
    RAISE NOTICE 'Dropped: %', func_record.func_signature;
  END LOOP;
END $$;

-- Verify all are gone
DO $$
DECLARE
  v_count INT;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM pg_proc p
  JOIN pg_namespace n ON p.pronamespace = n.oid
  WHERE p.proname = 'create_appointment'
    AND n.nspname = 'public';
  
  IF v_count = 0 THEN
    RAISE NOTICE '';
    RAISE NOTICE '============================================';
    RAISE NOTICE '✅ ALL create_appointment functions deleted!';
    RAISE NOTICE '============================================';
  ELSE
    RAISE NOTICE '⚠️ Still % functions remaining', v_count;
  END IF;
END $$;

-- Now create THE ONLY ONE with all TEXT parameters
CREATE OR REPLACE FUNCTION create_appointment(
  p_appointment_date TEXT,
  p_appointment_time TEXT,
  p_token_number TEXT,
  p_reason TEXT DEFAULT 'General consultation',
  p_patient_id TEXT DEFAULT NULL,
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
BEGIN
  -- Convert text to date/time
  v_date := p_appointment_date::DATE;
  v_time := p_appointment_time::TIME;
  
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
    p_token_number,
    'pending',
    p_reason,
    CASE WHEN p_patient_id IS NOT NULL AND p_patient_id != '' THEN p_patient_id::UUID ELSE NULL END,
    CASE WHEN p_doctor_id IS NOT NULL AND p_doctor_id != '' THEN p_doctor_id::UUID ELSE NULL END,
    CASE WHEN p_department_id IS NOT NULL AND p_department_id != '' THEN p_department_id::UUID ELSE NULL END
  )
  RETURNING id INTO v_appointment_id;
  
  -- Wait for trigger
  PERFORM pg_sleep(0.2);
  
  -- Get queue position
  SELECT COALESCE(position, 1) INTO v_queue_position
  FROM queue_positions
  WHERE appointment_id = v_appointment_id;
  
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
    'message', 'Failed to book'
  );
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION create_appointment TO anon, authenticated;

-- Verify only ONE function exists now
DO $$
DECLARE
  v_count INT;
  v_params TEXT;
BEGIN
  SELECT COUNT(*), string_agg(pg_get_function_identity_arguments(p.oid), '; ')
  INTO v_count, v_params
  FROM pg_proc p
  JOIN pg_namespace n ON p.pronamespace = n.oid
  WHERE p.proname = 'create_appointment'
    AND n.nspname = 'public';
  
  RAISE NOTICE '';
  RAISE NOTICE '============================================';
  RAISE NOTICE 'Functions named create_appointment: %', v_count;
  RAISE NOTICE 'Parameters: %', v_params;
  RAISE NOTICE '============================================';
END $$;

-- Test it
SELECT create_appointment(
  '2026-07-23',
  '14:30',
  'TEST-' || floor(random() * 10000)::TEXT,
  'Test booking'
);
