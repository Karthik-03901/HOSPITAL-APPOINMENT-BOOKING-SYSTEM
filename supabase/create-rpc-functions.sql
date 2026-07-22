-- Create RPC Functions for Appointment Management
-- Run this in Supabase SQL Editor

-- =====================================================
-- Function 1: Create Appointment with Queue Position
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
  -- Insert appointment
  INSERT INTO appointments (
    patient_id,
    doctor_id,
    department_id,
    appointment_date,
    appointment_time,
    token_number,
    status,
    reason
  ) VALUES (
    p_patient_id,
    p_doctor_id,
    p_department_id,
    p_appointment_date,
    p_appointment_time,
    p_token_number,
    'pending',
    p_reason
  )
  RETURNING id INTO v_appointment_id;
  
  -- Calculate queue position
  IF p_doctor_id IS NOT NULL THEN
    SELECT COALESCE(COUNT(*), 0) + 1 INTO v_queue_position
    FROM appointments
    WHERE doctor_id = p_doctor_id
      AND DATE(appointment_date) = p_appointment_date
      AND status IN ('pending', 'confirmed', 'checked_in')
      AND appointment_time <= p_appointment_time
      AND id != v_appointment_id;
  ELSE
    v_queue_position := 1;
  END IF;
  
  -- Wait a moment for trigger to create queue position
  PERFORM pg_sleep(0.1);
  
  -- Check if queue position was created by trigger
  IF NOT EXISTS (SELECT 1 FROM queue_positions WHERE appointment_id = v_appointment_id) THEN
    -- If not, create it manually
    INSERT INTO queue_positions (
      appointment_id,
      doctor_id,
      position,
      estimated_time,
      status
    ) VALUES (
      v_appointment_id,
      p_doctor_id,
      v_queue_position,
      p_appointment_date + p_appointment_time + (v_queue_position * INTERVAL '15 minutes'),
      'waiting'
    );
  END IF;
  
  -- Get the actual queue position that was created
  SELECT position INTO v_queue_position
  FROM queue_positions
  WHERE appointment_id = v_appointment_id;
  
  -- Build result JSON
  SELECT json_build_object(
    'success', true,
    'appointment_id', v_appointment_id,
    'token_number', p_token_number,
    'queue_position', v_queue_position,
    'appointment_date', p_appointment_date,
    'appointment_time', p_appointment_time,
    'message', 'Appointment created successfully'
  ) INTO v_result;
  
  RETURN v_result;
  
EXCEPTION WHEN OTHERS THEN
  RETURN json_build_object(
    'success', false,
    'error', SQLERRM,
    'message', 'Failed to create appointment'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- Function 2: Get Appointment Status with Queue Info
-- =====================================================

CREATE OR REPLACE FUNCTION get_appointment_status(
  p_appointment_id UUID
)
RETURNS JSON AS $$
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
      'position', qp.position,
      'estimated_time', qp.estimated_time,
      'status', qp.status
    ),
    'message', 'Appointment found'
  ) INTO v_result
  FROM appointments a
  LEFT JOIN queue_positions qp ON qp.appointment_id = a.id
  WHERE a.id = p_appointment_id;
  
  IF v_result IS NULL THEN
    v_result := json_build_object(
      'success', false,
      'error', 'Appointment not found',
      'message', 'No appointment exists with this ID'
    );
  END IF;
  
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
-- Function 3: Check In to Appointment
-- =====================================================

CREATE OR REPLACE FUNCTION check_in_appointment(
  p_appointment_id UUID
)
RETURNS JSON AS $$
DECLARE
  v_result JSON;
BEGIN
  -- Update appointment
  UPDATE appointments
  SET 
    check_in_time = NOW(),
    status = 'checked_in',
    updated_at = NOW()
  WHERE id = p_appointment_id;
  
  IF FOUND THEN
    v_result := json_build_object(
      'success', true,
      'appointment_id', p_appointment_id,
      'check_in_time', NOW(),
      'message', 'Checked in successfully'
    );
  ELSE
    v_result := json_build_object(
      'success', false,
      'error', 'Appointment not found',
      'message', 'No appointment exists with this ID'
    );
  END IF;
  
  RETURN v_result;
  
EXCEPTION WHEN OTHERS THEN
  RETURN json_build_object(
    'success', false,
    'error', SQLERRM,
    'message', 'Failed to check in'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- Function 4: Get All Appointments (for dashboard)
-- =====================================================

CREATE OR REPLACE FUNCTION get_appointments_with_queue()
RETURNS JSON AS $$
DECLARE
  v_result JSON;
BEGIN
  SELECT json_agg(
    json_build_object(
      'id', a.id,
      'token_number', a.token_number,
      'appointment_date', a.appointment_date,
      'appointment_time', a.appointment_time,
      'status', a.status,
      'queue_position', qp.position,
      'estimated_time', qp.estimated_time,
      'created_at', a.created_at
    )
    ORDER BY a.appointment_date DESC, a.appointment_time DESC
  ) INTO v_result
  FROM appointments a
  LEFT JOIN queue_positions qp ON qp.appointment_id = a.id
  LIMIT 100;
  
  RETURN json_build_object(
    'success', true,
    'appointments', COALESCE(v_result, '[]'::json),
    'count', (SELECT COUNT(*) FROM appointments)
  );
  
EXCEPTION WHEN OTHERS THEN
  RETURN json_build_object(
    'success', false,
    'error', SQLERRM,
    'message', 'Failed to fetch appointments'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- Grant Execute Permissions
-- =====================================================

GRANT EXECUTE ON FUNCTION create_appointment TO anon, authenticated;
GRANT EXECUTE ON FUNCTION get_appointment_status TO anon, authenticated;
GRANT EXECUTE ON FUNCTION check_in_appointment TO anon, authenticated;
GRANT EXECUTE ON FUNCTION get_appointments_with_queue TO anon, authenticated;

-- =====================================================
-- Success Message
-- =====================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '============================================';
  RAISE NOTICE '✅ RPC Functions Created Successfully!';
  RAISE NOTICE '============================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Functions available:';
  RAISE NOTICE '  1. create_appointment() - Create booking';
  RAISE NOTICE '  2. get_appointment_status() - Get status';
  RAISE NOTICE '  3. check_in_appointment() - Check in';
  RAISE NOTICE '  4. get_appointments_with_queue() - List all';
  RAISE NOTICE '';
  RAISE NOTICE 'All functions have public access granted';
  RAISE NOTICE '';
  RAISE NOTICE '============================================';
END $$;
