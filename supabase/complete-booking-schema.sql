-- Complete Booking System Schema
-- Run this ONCE in Supabase SQL Editor
-- Creates all tables, triggers, and RPC functions needed for booking

-- =====================================================
-- STEP 1: Create Tables (if not exist)
-- =====================================================

-- Appointments table
CREATE TABLE IF NOT EXISTS appointments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  appointment_date DATE NOT NULL,
  appointment_time TIME NOT NULL,
  token_number TEXT UNIQUE NOT NULL,
  status TEXT DEFAULT 'pending',
  reason TEXT,
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

-- Queue positions table
CREATE TABLE IF NOT EXISTS queue_positions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  appointment_id UUID REFERENCES appointments(id) ON DELETE CASCADE,
  position INT NOT NULL,
  status TEXT DEFAULT 'waiting',
  estimated_time TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Doctors table (minimal)
CREATE TABLE IF NOT EXISTS doctors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  specialization TEXT,
  consultation_fee DECIMAL(10,2) DEFAULT 500.00,
  availability_status TEXT DEFAULT 'available',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Departments table (minimal)
CREATE TABLE IF NOT EXISTS departments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Profiles table (minimal)
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY,
  email TEXT,
  full_name TEXT,
  role TEXT DEFAULT 'patient',
  phone TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- STEP 2: Create Indexes
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_appointments_date ON appointments(appointment_date);
CREATE INDEX IF NOT EXISTS idx_appointments_status ON appointments(status);
CREATE INDEX IF NOT EXISTS idx_appointments_token ON appointments(token_number);
CREATE INDEX IF NOT EXISTS idx_queue_appointment ON queue_positions(appointment_id);

-- =====================================================
-- STEP 3: Enable RLS (Row Level Security)
-- =====================================================

ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE queue_positions ENABLE ROW LEVEL SECURITY;
ALTER TABLE doctors ENABLE ROW LEVEL SECURITY;
ALTER TABLE departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "appointments_select_all" ON appointments;
DROP POLICY IF EXISTS "appointments_insert_all" ON appointments;
DROP POLICY IF EXISTS "appointments_update_all" ON appointments;
DROP POLICY IF EXISTS "queue_select_all" ON queue_positions;
DROP POLICY IF EXISTS "queue_insert_all" ON queue_positions;
DROP POLICY IF EXISTS "doctors_select_all" ON doctors;
DROP POLICY IF EXISTS "departments_select_all" ON departments;
DROP POLICY IF EXISTS "profiles_select_all" ON profiles;

-- Create permissive policies (for demo - adjust for production)
CREATE POLICY "appointments_select_all" ON appointments FOR SELECT USING (true);
CREATE POLICY "appointments_insert_all" ON appointments FOR INSERT WITH CHECK (true);
CREATE POLICY "appointments_update_all" ON appointments FOR UPDATE USING (true);
CREATE POLICY "queue_select_all" ON queue_positions FOR SELECT USING (true);
CREATE POLICY "queue_insert_all" ON queue_positions FOR INSERT WITH CHECK (true);
CREATE POLICY "doctors_select_all" ON doctors FOR SELECT USING (true);
CREATE POLICY "departments_select_all" ON departments FOR SELECT USING (true);
CREATE POLICY "profiles_select_all" ON profiles FOR SELECT USING (true);

-- =====================================================
-- STEP 4: Create Trigger for Queue Position
-- =====================================================

-- Drop existing trigger and function
DROP TRIGGER IF EXISTS create_queue_position_trigger ON appointments;
DROP FUNCTION IF EXISTS create_queue_position();

-- Create function to auto-create queue position
CREATE OR REPLACE FUNCTION create_queue_position()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_max_position INT;
BEGIN
  -- Get max position for the appointment date
  SELECT COALESCE(MAX(position), 0) INTO v_max_position
  FROM queue_positions qp
  JOIN appointments a ON a.id = qp.appointment_id
  WHERE DATE(a.appointment_date) = DATE(NEW.appointment_date);
  
  -- Insert queue position
  INSERT INTO queue_positions (appointment_id, position, status, estimated_time)
  VALUES (
    NEW.id,
    v_max_position + 1,
    'waiting',
    NOW() + (v_max_position * INTERVAL '15 minutes')
  );
  
  RETURN NEW;
END;
$$;

-- Create trigger
CREATE TRIGGER create_queue_position_trigger
AFTER INSERT ON appointments
FOR EACH ROW
EXECUTE FUNCTION create_queue_position();

-- =====================================================
-- STEP 5: Drop and Recreate RPC Functions
-- =====================================================

-- Drop existing functions
DROP FUNCTION IF EXISTS create_appointment(DATE, TIME, TEXT, TEXT, UUID, UUID, UUID);
DROP FUNCTION IF EXISTS create_appointment(DATE, TIME, TEXT, TEXT);
DROP FUNCTION IF EXISTS get_appointment_status(UUID);
DROP FUNCTION IF EXISTS check_in_appointment(UUID);

-- Function 1: Create Appointment
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
  
  -- Wait for trigger to create queue position
  PERFORM pg_sleep(0.3);
  
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
    'message', 'Appointment booked successfully'
  );
  
EXCEPTION WHEN OTHERS THEN
  RETURN json_build_object(
    'success', false,
    'error', SQLERRM,
    'message', 'Failed to book appointment',
    'details', SQLSTATE
  );
END;
$$;

-- Function 2: Get Appointment Status
CREATE OR REPLACE FUNCTION get_appointment_status(p_appointment_id UUID)
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

-- Function 3: Check In
CREATE OR REPLACE FUNCTION check_in_appointment(p_appointment_id UUID)
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
-- STEP 6: Grant Permissions
-- =====================================================

GRANT EXECUTE ON FUNCTION create_appointment TO anon, authenticated;
GRANT EXECUTE ON FUNCTION get_appointment_status TO anon, authenticated;
GRANT EXECUTE ON FUNCTION check_in_appointment TO anon, authenticated;

-- =====================================================
-- STEP 7: Test the Function
-- =====================================================

DO $$
DECLARE
  v_result JSON;
BEGIN
  -- Test create appointment
  SELECT create_appointment(
    CURRENT_DATE + 1,
    '14:30'::TIME,
    'TEST-' || floor(random() * 10000)::TEXT,
    'Test booking from schema'
  ) INTO v_result;
  
  RAISE NOTICE '';
  RAISE NOTICE '============================================';
  RAISE NOTICE '✅ Booking System Schema Installed!';
  RAISE NOTICE '============================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Test Result: %', v_result;
  RAISE NOTICE '';
  
  IF (v_result->>'success')::BOOLEAN THEN
    RAISE NOTICE '✅ TEST PASSED - Booking system working!';
    RAISE NOTICE 'Appointment ID: %', v_result->>'appointment_id';
    RAISE NOTICE 'Token: %', v_result->>'token_number';
    RAISE NOTICE 'Queue Position: %', v_result->>'queue_position';
  ELSE
    RAISE NOTICE '❌ TEST FAILED - Error: %', v_result->>'error';
  END IF;
  
  RAISE NOTICE '';
  RAISE NOTICE '============================================';
  RAISE NOTICE 'Ready to use! Try booking an appointment.';
  RAISE NOTICE '============================================';
END $$;
