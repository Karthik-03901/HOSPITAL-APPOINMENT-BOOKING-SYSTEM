-- Simplified RPC Function for Appointment Creation
-- This version is simpler and more reliable
-- Run this in Supabase SQL Editor

-- Drop existing function
DROP FUNCTION IF EXISTS create_appointment;
DROP FUNCTION IF EXISTS get_appointment_status;
DROP FUNCTION IF EXISTS check_in_appointment;

-- =====================================================
-- Function 1: Create Appointment (Simplified)
-- Let the trigger handle queue_positions creation
-- =====================================================

CREATE OR REPLACE FUNCTION create_appointment(
  p_appointment_date DATE,
  p_appointment_time TIME,
  p_token_number TEXT,
  p_reason TEXT DEFAULT 'General consultation',
  p_patient_id UUID DEFAULT NULL,
  p_doctor_id UUID DEFAULT NULL,
  p_department_id UUID DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
  v_appointment_id UUID;
  v_queue_position INT;
  v_result JSON;
BEGIN
  -- Insert appointment (trigger will create queue position)
  INSERT INTO appointments (
    appointment_date,
    appointment_time,
    token_number,
    status,
    reason
  ) VALUES (
    p_appointment_date,
    p_appointment_time,
    p_token_number,
    'pending',
    p_reason
  )
  RETURNING id INTO v_appointment_id;
  
  -- Wait a tiny bit for trigger to complete
  PERFORM pg_sleep(0.2);
  
  -- Get the queue position that was created
  SELECT COALESCE(position, 1) INTO v_queue_position
  FROM queue_positions
  WHERE appointment_id = v_appointment_id;
  
  -- Build success response
  v_result := json_build_object(
    'success', true,
    'appointment_id', v_appointment_id,
    'token_number', p_token_number,
    'queue_position', v_queue_position,
    'appointment_date', p_appointment_date,
    'appointment_time', p_appointment_time,
    'message', 'Appointment created successfully'
  );
  
  RETURN v_result;
  
EXCEPTION WHEN OTHERS THEN
  RETURN json_build_object(
    'success', false,
    'error', SQLERRM,
    'error_detail', SQLSTATE,
    'message', 'Failed to create appointment: ' || SQLERRM
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- Function 2: Get Appointment Status
-- =====================================================

CREATE OR REPLACE FUNCTION get_appointment_status(
  p_appointment_id UUID
)
RETURNS JSON AS $$
DECLARE
  v_result JSON;
  v_found BOOLEAN;
BEGIN
  -- Check if appointment exists
  SELECT EXISTS(SELECT 1 FROM appointments WHERE id = p_appointment_id) INTO v_found;
  
  IF NOT v_found THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Appointment not found',
      'message', 'No appointment exists with this ID'
    );
  END IF;
  
  -- Build result with appointment and queue info
  SELECT json_build_object(
    'success', true,
    'appointment', json_build_object(
      'id', a.id,
      'token_number', a.token_number,
      'appointment_date', a.appointment_date,
      'appointment_time', a.appointment_time,
      'status', a.status,
      'reason', a.reason,
      'check_in_time', a.check_in_time
    ),
    'queue', json_build_object(
      'position', COALESCE(qp.position, 1),
      'estimated_time', qp.estimated_time,
      'status', COALESCE(qp.status, 'waiting')
    ),
    'message', 'Appointment found'
  ) INTO v_result
  FROM appointments a
  LEFT JOIN queue_positions qp ON qp.appointment_id = a.id
  WHERE a.id = p_appointment_id;
  
  RETURN v_result;
  
EXCEPTION WHEN OTHERS THEN
  RETURN json_build_object(
    'success', false,
    'error', SQLERRM,
    'message', 'Failed to fetch appointment status'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- Function 3: Check In
-- =====================================================

CREATE OR REPLACE FUNCTION check_in_appointment(
  p_appointment_id UUID
)
RETURNS JSON AS $$
DECLARE
  v_updated BOOLEAN;
BEGIN
  -- Update appointment
  UPDATE appointments
  SET 
    check_in_time = NOW(),
    status = 'checked_in',
    updated_at = NOW()
  WHERE id = p_appointment_id;
  
  GET DIAGNOSTICS v_updated = ROW_COUNT;
  
  IF v_updated THEN
    RETURN json_build_object(
      'success', true,
      'appointment_id', p_appointment_id,
      'check_in_time', NOW(),
      'message', 'Checked in successfully'
    );
  ELSE
    RETURN json_build_object(
      'success', false,
      'error', 'Appointment not found',
      'message', 'No appointment exists with this ID'
    );
  END IF;
  
EXCEPTION WHEN OTHERS THEN
  RETURN json_build_object(
    'success', false,
    'error', SQLERRM,
    'message', 'Failed to check in'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- Grant Permissions
-- =====================================================

GRANT EXECUTE ON FUNCTION create_appointment TO anon, authenticated;
GRANT EXECUTE ON FUNCTION get_appointment_status TO anon, authenticated;
GRANT EXECUTE ON FUNCTION check_in_appointment TO anon, authenticated;

-- =====================================================
-- Test the function
-- =====================================================

DO $$
DECLARE
  test_result JSON;
BEGIN
  -- Test create_appointment
  SELECT create_appointment(
    CURRENT_DATE,
    '14:30'::TIME,
    'TEST-RPC-' || floor(random() * 1000)::TEXT,
    'RPC test booking'
  ) INTO test_result;
  
  RAISE NOTICE '';
  RAISE NOTICE '============================================';
  RAISE NOTICE '✅ RPC Functions Created & Tested!';
  RAISE NOTICE '============================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Test result: %', test_result;
  RAISE NOTICE '';
  
  IF (test_result->>'success')::BOOLEAN THEN
    RAISE NOTICE '✅ Test PASSED - Functions working correctly!';
    RAISE NOTICE 'Appointment ID: %', test_result->>'appointment_id';
    RAISE NOTICE 'Queue Position: %', test_result->>'queue_position';
  ELSE
    RAISE NOTICE '❌ Test FAILED - Check error: %', test_result->>'error';
  END IF;
  
  RAISE NOTICE '';
  RAISE NOTICE 'Functions available:';
  RAISE NOTICE '  - create_appointment()';
  RAISE NOTICE '  - get_appointment_status()';
  RAISE NOTICE '  - check_in_appointment()';
  RAISE NOTICE '';
  RAISE NOTICE '============================================';
END $$;
