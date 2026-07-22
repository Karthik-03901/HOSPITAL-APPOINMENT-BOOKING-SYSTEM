-- =====================================================
-- COMPLETE REAL-TIME QUEUE TRACKING SYSTEM
-- =====================================================
-- This schema works with existing appointments table
-- Run this in Supabase SQL Editor

-- =====================================================
-- Step 1: Create Queue Positions Table
-- =====================================================

CREATE TABLE IF NOT EXISTS queue_positions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  appointment_id UUID REFERENCES appointments(id) ON DELETE CASCADE UNIQUE,
  position INT NOT NULL DEFAULT 0,
  estimated_time TIMESTAMPTZ,
  actual_call_time TIMESTAMPTZ,
  status TEXT DEFAULT 'waiting' CHECK (status IN ('waiting', 'called', 'consulting', 'completed', 'no_show')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_queue_appointment ON queue_positions(appointment_id);
CREATE INDEX IF NOT EXISTS idx_queue_status ON queue_positions(status);
CREATE INDEX IF NOT EXISTS idx_queue_position ON queue_positions(position);

-- =====================================================
-- Step 2: Enable Realtime
-- =====================================================

-- Enable realtime on queue_positions
ALTER PUBLICATION supabase_realtime ADD TABLE IF NOT EXISTS queue_positions;

-- Enable realtime on appointments for status updates
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' 
    AND tablename = 'appointments'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE appointments;
  END IF;
END $$;

-- =====================================================
-- Step 3: Row Level Security (RLS)
-- =====================================================

ALTER TABLE queue_positions ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "queue_select_own" ON queue_positions;
DROP POLICY IF EXISTS "queue_select_all" ON queue_positions;

-- Allow users to see their own queue position
CREATE POLICY "queue_select_own" ON queue_positions
  FOR SELECT
  USING (
    appointment_id IN (
      SELECT id FROM appointments 
      WHERE patient_email = auth.jwt()->>'email'
    )
  );

-- Allow public read for demo/development (remove in production)
CREATE POLICY "queue_select_all" ON queue_positions
  FOR SELECT
  USING (true);

-- =====================================================
-- Step 4: Helper Functions
-- =====================================================

-- Function to initialize queue position when appointment is created
CREATE OR REPLACE FUNCTION initialize_queue_position()
RETURNS TRIGGER AS $$
DECLARE
  current_position INT;
  v_department TEXT;
  v_date DATE;
BEGIN
  -- Get department and date
  v_department := NEW.department_name;
  v_date := NEW.appointment_date::DATE;
  
  -- Calculate position based on appointments on same day, same department
  SELECT COALESCE(COUNT(*), 0) + 1 INTO current_position
  FROM appointments
  WHERE department_name = v_department
    AND appointment_date::DATE = v_date
    AND status IN ('pending', 'confirmed', 'checked_in')
    AND appointment_time <= NEW.appointment_time
    AND id != NEW.id;
  
  -- Insert queue position
  INSERT INTO queue_positions (
    appointment_id,
    position,
    estimated_time,
    status
  ) VALUES (
    NEW.id,
    current_position,
    NEW.appointment_date + NEW.appointment_time + (current_position * INTERVAL '15 minutes'),
    'waiting'
  )
  ON CONFLICT (appointment_id) DO NOTHING;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS trigger_initialize_queue ON appointments;
CREATE TRIGGER trigger_initialize_queue
  AFTER INSERT ON appointments
  FOR EACH ROW
  EXECUTE FUNCTION initialize_queue_position();


-- Function to update queue positions when appointment status changes
CREATE OR REPLACE FUNCTION update_queue_positions()
RETURNS TRIGGER AS $$
BEGIN
  -- Only recalculate if status changed to completed, cancelled, or no_show
  IF (TG_OP = 'UPDATE' AND NEW.status IN ('completed', 'cancelled', 'no_show', 'consulting')) THEN
    
    -- Recalculate positions for remaining appointments
    WITH ranked AS (
      SELECT 
        qp.id as queue_id,
        ROW_NUMBER() OVER (
          PARTITION BY a.department_name, a.appointment_date::DATE 
          ORDER BY a.appointment_time
        ) as new_position
      FROM appointments a
      JOIN queue_positions qp ON qp.appointment_id = a.id
      WHERE a.department_name = NEW.department_name
        AND a.appointment_date::DATE = NEW.appointment_date::DATE
        AND a.status IN ('pending', 'confirmed', 'checked_in', 'called')
        AND qp.status IN ('waiting', 'called')
        AND a.id != NEW.id
    )
    UPDATE queue_positions qp
    SET 
      position = r.new_position,
      estimated_time = NOW() + (r.new_position * INTERVAL '15 minutes'),
      updated_at = NOW()
    FROM ranked r
    WHERE qp.id = r.queue_id;
    
    -- Mark current appointment's queue position
    IF NEW.status = 'completed' THEN
      UPDATE queue_positions
      SET 
        status = 'completed',
        updated_at = NOW()
      WHERE appointment_id = NEW.id;
    ELSIF NEW.status = 'consulting' THEN
      UPDATE queue_positions
      SET 
        status = 'consulting',
        actual_call_time = NOW(),
        updated_at = NOW()
      WHERE appointment_id = NEW.id;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS trigger_update_queue ON appointments;
CREATE TRIGGER trigger_update_queue
  AFTER UPDATE ON appointments
  FOR EACH ROW
  EXECUTE FUNCTION update_queue_positions();

-- =====================================================
-- Step 5: RPC Functions for Frontend
-- =====================================================

-- Function to get appointment status with queue position
CREATE OR REPLACE FUNCTION get_appointment_status(p_appointment_id UUID)
RETURNS JSON AS $$
DECLARE
  v_appointment RECORD;
  v_queue RECORD;
  v_result JSON;
BEGIN
  -- Get appointment details
  SELECT * INTO v_appointment
  FROM appointments
  WHERE id = p_appointment_id;
  
  IF NOT FOUND THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Appointment not found'
    );
  END IF;
  
  -- Get queue position
  SELECT * INTO v_queue
  FROM queue_positions
  WHERE appointment_id = p_appointment_id;
  
  -- Build result
  v_result := json_build_object(
    'success', true,
    'appointment', row_to_json(v_appointment),
    'queue', row_to_json(v_queue)
  );
  
  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check in to appointment
CREATE OR REPLACE FUNCTION check_in_appointment(p_appointment_id UUID)
RETURNS JSON AS $$
DECLARE
  v_appointment RECORD;
BEGIN
  -- Update appointment check-in time
  UPDATE appointments
  SET 
    check_in_time = NOW(),
    status = CASE WHEN status = 'pending' THEN 'confirmed' ELSE status END,
    updated_at = NOW()
  WHERE id = p_appointment_id
  RETURNING * INTO v_appointment;
  
  IF NOT FOUND THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Appointment not found'
    );
  END IF;
  
  -- Update queue status
  UPDATE queue_positions
  SET 
    status = 'waiting',
    updated_at = NOW()
  WHERE appointment_id = p_appointment_id;
  
  RETURN json_build_object(
    'success', true,
    'message', 'Checked in successfully',
    'appointment', row_to_json(v_appointment)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to call next patient (for doctor/admin dashboard)
CREATE OR REPLACE FUNCTION call_next_patient(p_department TEXT, p_date DATE)
RETURNS JSON AS $$
DECLARE
  v_next_appointment RECORD;
BEGIN
  -- Find next patient in queue
  SELECT a.* INTO v_next_appointment
  FROM appointments a
  JOIN queue_positions qp ON qp.appointment_id = a.id
  WHERE a.department_name = p_department
    AND a.appointment_date::DATE = p_date
    AND a.status IN ('confirmed', 'checked_in')
    AND qp.status = 'waiting'
  ORDER BY qp.position ASC
  LIMIT 1;
  
  IF NOT FOUND THEN
    RETURN json_build_object(
      'success', false,
      'message', 'No patients in queue'
    );
  END IF;
  
  -- Update appointment status
  UPDATE appointments
  SET 
    status = 'called',
    updated_at = NOW()
  WHERE id = v_next_appointment.id;
  
  -- Update queue position
  UPDATE queue_positions
  SET 
    status = 'called',
    actual_call_time = NOW(),
    updated_at = NOW()
  WHERE appointment_id = v_next_appointment.id;
  
  RETURN json_build_object(
    'success', true,
    'message', 'Patient called',
    'appointment', row_to_json(v_next_appointment)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- Verification & Success Message
-- =====================================================

DO $$
BEGIN
  RAISE NOTICE '============================================';
  RAISE NOTICE '✅ Real-time Queue System Complete!';
  RAISE NOTICE '============================================';
  RAISE NOTICE 'Tables:';
  RAISE NOTICE '  ✓ queue_positions';
  RAISE NOTICE '';
  RAISE NOTICE 'Realtime enabled:';
  RAISE NOTICE '  ✓ queue_positions';
  RAISE NOTICE '  ✓ appointments';
  RAISE NOTICE '';
  RAISE NOTICE 'RPC Functions:';
  RAISE NOTICE '  ✓ get_appointment_status()';
  RAISE NOTICE '  ✓ check_in_appointment()';
  RAISE NOTICE '  ✓ call_next_patient()';
  RAISE NOTICE '';
  RAISE NOTICE 'Next: Use the queue status page!';
  RAISE NOTICE '============================================';
END $$;
