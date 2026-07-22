-- Working RPC Function for Appointment Creation
-- Run this in Supabase SQL Editor

-- Drop existing functions
DROP FUNCTION IF EXISTS create_appointment(DATE, TIME, TEXT, TEXT, UUID, UUID, UUID);
DROP FUNCTION IF EXISTS create_appointment(DATE, TIME, TEXT, TEXT);
DROP FUNCTION IF EXISTS get_appointment_status(UUID);
DROP FUNCTION IF EXISTS check_in_appointment(UUID);

-- =====================================================
-- Function 1: Create Appointment
-- =====================================================

CREATE FUNCTION create_appointment(
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
BEGIN
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
    p_token_number,
    'pending',
    p_reason,
    p_patient_id,
    p_doctor_id,
    p_department_id
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
    'appointment_id', v_appointment_id,
    'token_number', p_token_number,
    'queue_position', v_queue_position,
    'message', 'Appointment created successfully'
  );
  
EXCEPTION WHEN OTHERS THEN
  RETURN json_build_object(
    'success', false,
    'error', SQLERRM,
    'message', 'Failed to create appointment'
  );
END;
$$;

-- =====================================================
-- Function 2: Get Appointment Status
-- =====================================================

CREATE FUNCTION get_appointment_status(p_appointment_id UUID)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result JSON;
BEGIN
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
    )
  ) INTO v_result
  FROM appointments a
  LEFT JOIN queue_positions qp ON qp.appointment_id = a.id
  WHERE a.id = p_appointment_id;
  
  IF v_result IS NULL THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Appointment not found'
    );
  END IF;
  
  RETURN v_result;
  
EXCEPTION WHEN OTHERS THEN
  RETURN json_build_object(
    'success', false,
    'error', SQLERRM
  );
END;
$$;

-- =====================================================
-- Function 3: Check In
-- =====================================================

CREATE FUNCTION check_in_appointment(p_appointment_id UUID)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE appointments
  SET check_in_time = NOW(), status = 'checked_in', updated_at = NOW()
  WHERE id = p_appointment_id;
  
  IF FOUND THEN
    RETURN json_build_object(
      'success', true,
      'message', 'Checked in successfully'
    );
  ELSE
    RETURN json_build_object(
      'success', false,
      'error', 'Appointment not found'
    );
  END IF;
  
EXCEPTION WHEN OTHERS THEN
  RETURN json_build_object(
    'success', false,
    'error', SQLERRM
  );
END;
$$;

-- =====================================================
-- Grant Permissions
-- =====================================================

GRANT EXECUTE ON FUNCTION create_appointment TO anon, authenticated;
GRANT EXECUTE ON FUNCTION get_appointment_status TO anon, authenticated;
GRANT EXECUTE ON FUNCTION check_in_appointment TO anon, authenticated;

-- =====================================================
-- Test
-- =====================================================

SELECT create_appointment(
  CURRENT_DATE,
  '15:00'::TIME,
  'TEST-' || floor(random() * 1000)::TEXT,
  'Test booking'
);
