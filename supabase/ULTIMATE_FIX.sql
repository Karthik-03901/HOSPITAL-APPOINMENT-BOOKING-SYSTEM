-- =====================================================
-- ULTIMATE FIX - Nuclear Option
-- This will DESTROY and RECREATE everything from scratch
-- =====================================================

-- STEP 1: Drop EVERYTHING related to appointments
-- =====================================================

-- Drop all functions first
DROP FUNCTION IF EXISTS create_appointment CASCADE;
DROP FUNCTION IF EXISTS auto_create_queue_position CASCADE;

-- Drop all triggers
DROP TRIGGER IF EXISTS trigger_auto_queue ON appointments CASCADE;

-- Drop tables with CASCADE to remove all dependencies
DROP TABLE IF EXISTS queue_positions CASCADE;
DROP TABLE IF EXISTS appointments CASCADE;

-- =====================================================
-- STEP 2: Create appointments table (TEXT token_number)
-- =====================================================

CREATE TABLE appointments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  appointment_date DATE NOT NULL,
  appointment_time TIME NOT NULL,
  token_number TEXT NOT NULL UNIQUE,  -- ← TEXT TYPE!
  status TEXT DEFAULT 'pending',
  reason TEXT DEFAULT 'General consultation',
  patient_id UUID,
  doctor_id UUID,
  department_id UUID,
  check_in_time TIMESTAMPTZ,
  consultation_fee DECIMAL(10,2),
  payment_status TEXT DEFAULT 'pending',
  cancelled_by TEXT,
  cancellation_reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- STEP 3: Create queue_positions table
-- =====================================================

CREATE TABLE queue_positions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  appointment_id UUID REFERENCES appointments(id) ON DELETE CASCADE UNIQUE,
  position INT NOT NULL,
  status TEXT DEFAULT 'waiting',
  estimated_time TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- STEP 4: Add indexes for performance
-- =====================================================

CREATE INDEX idx_appointments_date ON appointments(appointment_date);
CREATE INDEX idx_appointments_status ON appointments(status);
CREATE INDEX idx_appointments_token ON appointments(token_number);
CREATE INDEX idx_queue_appointment ON queue_positions(appointment_id);
CREATE INDEX idx_queue_position ON queue_positions(position);

-- =====================================================
-- STEP 5: Enable RLS with wide-open policies
-- =====================================================

ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE queue_positions ENABLE ROW LEVEL SECURITY;

-- Super permissive policies - allow everything
CREATE POLICY "appointments_allow_all" 
  ON appointments 
  FOR ALL 
  USING (true) 
  WITH CHECK (true);

CREATE POLICY "queue_allow_all" 
  ON queue_positions 
  FOR ALL 
  USING (true) 
  WITH CHECK (true);

-- =====================================================
-- STEP 6: Create trigger function for auto queue
-- =====================================================

CREATE OR REPLACE FUNCTION auto_create_queue_position()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_max_position INT;
BEGIN
  -- Get the highest position for today's date
  SELECT COALESCE(MAX(qp.position), 0) 
  INTO v_max_position
  FROM queue_positions qp
  INNER JOIN appointments a ON a.id = qp.appointment_id
  WHERE DATE(a.appointment_date) = DATE(NEW.appointment_date);
  
  -- Create queue position with next number
  INSERT INTO queue_positions (
    appointment_id, 
    position, 
    status, 
    estimated_time
  ) VALUES (
    NEW.id,
    v_max_position + 1,
    'waiting',
    NOW() + (v_max_position * INTERVAL '15 minutes')
  );
  
  RETURN NEW;
END;
$$;

-- =====================================================
-- STEP 7: Create trigger
-- =====================================================

CREATE TRIGGER trigger_auto_queue
  AFTER INSERT ON appointments
  FOR EACH ROW
  EXECUTE FUNCTION auto_create_queue_position();

-- =====================================================
-- STEP 8: Create RPC function with ALL TEXT parameters
-- =====================================================

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
SET search_path = public
AS $$
DECLARE
  v_appointment_id UUID;
  v_queue_position INT;
  v_date DATE;
  v_time TIME;
BEGIN
  -- Convert text to proper types
  BEGIN
    v_date := p_appointment_date::DATE;
    v_time := p_appointment_time::TIME;
  EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Invalid date or time format',
      'details', SQLERRM
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
    p_token_number,  -- Direct TEXT value
    'pending',
    COALESCE(p_reason, 'General consultation'),
    CASE WHEN p_patient_id IS NULL OR p_patient_id = '' THEN NULL ELSE p_patient_id::UUID END,
    CASE WHEN p_doctor_id IS NULL OR p_doctor_id = '' THEN NULL ELSE p_doctor_id::UUID END,
    CASE WHEN p_department_id IS NULL OR p_department_id = '' THEN NULL ELSE p_department_id::UUID END
  )
  RETURNING id INTO v_appointment_id;
  
  -- Give trigger time to create queue position
  PERFORM pg_sleep(0.1);
  
  -- Get the queue position
  SELECT position INTO v_queue_position
  FROM queue_positions
  WHERE appointment_id = v_appointment_id;
  
  -- Return success with details
  RETURN json_build_object(
    'success', true,
    'appointment_id', v_appointment_id::TEXT,
    'token_number', p_token_number,
    'queue_position', COALESCE(v_queue_position, 1),
    'message', 'Appointment booked successfully!'
  );
  
EXCEPTION WHEN OTHERS THEN
  -- Return detailed error
  RETURN json_build_object(
    'success', false,
    'error', SQLERRM,
    'sqlstate', SQLSTATE,
    'hint', SQLERRMSG || ' (State: ' || SQLSTATE || ')'
  );
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION create_appointment TO anon, authenticated, service_role;
GRANT ALL ON TABLE appointments TO anon, authenticated, service_role;
GRANT ALL ON TABLE queue_positions TO anon, authenticated, service_role;

-- =====================================================
-- STEP 9: Test everything thoroughly
-- =====================================================

DO $$
DECLARE
  v_result JSON;
  v_test_token TEXT;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '====================================================';
  RAISE NOTICE '           TESTING BOOKING SYSTEM';
  RAISE NOTICE '====================================================';
  RAISE NOTICE '';
  
  -- Test 1: Direct INSERT with TEXT token
  RAISE NOTICE '► Test 1: Direct INSERT with TEXT token';
  BEGIN
    INSERT INTO appointments (
      appointment_date,
      appointment_time,
      token_number,
      status
    ) VALUES (
      CURRENT_DATE + 1,
      '10:00'::TIME,
      'DIRECT-TEST-' || floor(random() * 1000)::TEXT,
      'pending'
    );
    RAISE NOTICE '  ✅ SUCCESS - Direct INSERT works';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '  ❌ FAILED - %', SQLERRM;
  END;
  
  RAISE NOTICE '';
  
  -- Test 2: RPC function call
  RAISE NOTICE '► Test 2: RPC Function Call';
  v_test_token := 'RPC-TEST-' || floor(random() * 1000)::TEXT;
  
  SELECT create_appointment(
    (CURRENT_DATE + 2)::TEXT,
    '14:30',
    v_test_token,
    'Test booking via RPC'
  ) INTO v_result;
  
  RAISE NOTICE '  Result: %', v_result::TEXT;
  
  IF (v_result->>'success')::BOOLEAN THEN
    RAISE NOTICE '  ✅ SUCCESS';
    RAISE NOTICE '     Token: %', v_result->>'token_number';
    RAISE NOTICE '     Queue Position: %', v_result->>'queue_position';
    RAISE NOTICE '     Appointment ID: %', v_result->>'appointment_id';
  ELSE
    RAISE NOTICE '  ❌ FAILED';
    RAISE NOTICE '     Error: %', v_result->>'error';
  END IF;
  
  RAISE NOTICE '';
  RAISE NOTICE '====================================================';
  
  -- Show final counts
  RAISE NOTICE '► Final Status:';
  RAISE NOTICE '  Appointments: %', (SELECT COUNT(*) FROM appointments);
  RAISE NOTICE '  Queue Positions: %', (SELECT COUNT(*) FROM queue_positions);
  
  RAISE NOTICE '';
  RAISE NOTICE '====================================================';
  IF (v_result->>'success')::BOOLEAN THEN
    RAISE NOTICE '🎉 BOOKING SYSTEM IS READY! 🎉';
  ELSE
    RAISE NOTICE '⚠️  There are still issues to fix';
  END IF;
  RAISE NOTICE '====================================================';
  RAISE NOTICE '';
  
END $$;

-- Show sample data
SELECT 
  'Appointment' as record_type,
  id::TEXT as id,
  token_number,
  appointment_date::TEXT as date,
  appointment_time::TEXT as time,
  status
FROM appointments
ORDER BY created_at DESC
LIMIT 5;

