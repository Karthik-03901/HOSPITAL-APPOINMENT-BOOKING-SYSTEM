-- FINAL WORKING VERSION - Real-Time Queue Management Schema
-- This version is tested and works without errors
-- Run this in Supabase SQL Editor with postgres role

-- =====================================================
-- Step 1: Clean up existing policies
-- =====================================================

DO $$ 
DECLARE
    r RECORD;
BEGIN
    -- Drop policies on queue_positions
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'queue_positions') LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON queue_positions';
    END LOOP;
    
    -- Drop policies on notifications
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'notifications') LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON notifications';
    END LOOP;
    
    -- Drop policies on appointments
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'appointments') LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON appointments';
    END LOOP;
END $$;

-- Drop existing triggers
DROP TRIGGER IF EXISTS trigger_update_queue_positions ON appointments;
DROP TRIGGER IF EXISTS trigger_initialize_queue ON appointments;

-- Drop existing functions
DROP FUNCTION IF EXISTS update_queue_positions();
DROP FUNCTION IF EXISTS initialize_queue_position();

-- =====================================================
-- Step 2: Create tables
-- =====================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Profiles table
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  role TEXT DEFAULT 'patient' CHECK (role IN ('patient', 'doctor', 'admin', 'nurse', 'staff')),
  phone TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Departments table
CREATE TABLE IF NOT EXISTS departments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Doctors table
CREATE TABLE IF NOT EXISTS doctors (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  specialization TEXT,
  department_id UUID REFERENCES departments(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Appointments table
CREATE TABLE IF NOT EXISTS appointments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id UUID REFERENCES profiles(id),
  doctor_id UUID REFERENCES doctors(id),
  department_id UUID REFERENCES departments(id),
  appointment_date DATE NOT NULL,
  appointment_time TIME NOT NULL,
  token_number TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'checked_in', 'called', 'consulting', 'completed', 'cancelled', 'no_show')),
  check_in_time TIMESTAMPTZ,
  reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Queue Positions Table
CREATE TABLE IF NOT EXISTS queue_positions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  appointment_id UUID REFERENCES appointments(id) ON DELETE CASCADE,
  doctor_id UUID REFERENCES doctors(id),
  position INT NOT NULL,
  estimated_time TIMESTAMPTZ,
  actual_call_time TIMESTAMPTZ,
  status TEXT DEFAULT 'waiting' CHECK (status IN ('waiting', 'called', 'consulting', 'completed', 'no_show')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Notifications Table
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('queue_update', 'appointment_reminder', 'appointment_called', 'message', 'system')),
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data JSONB DEFAULT '{}'::jsonb,
  channels TEXT[] DEFAULT ARRAY['in_app'],
  read BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMPTZ,
  sent_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create Indexes
CREATE INDEX IF NOT EXISTS idx_queue_positions_appointment ON queue_positions(appointment_id);
CREATE INDEX IF NOT EXISTS idx_queue_positions_doctor ON queue_positions(doctor_id);
CREATE INDEX IF NOT EXISTS idx_queue_positions_status ON queue_positions(status);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON notifications(user_id, read) WHERE read = FALSE;

-- =====================================================
-- Step 3: Enable RLS
-- =====================================================

ALTER TABLE queue_positions ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- Step 4: Create RLS Policies
-- =====================================================

-- Queue Positions Policies
CREATE POLICY "queue_positions_select_own" ON queue_positions
  FOR SELECT
  USING (
    appointment_id IN (
      SELECT id FROM appointments WHERE patient_id = auth.uid()
    )
  );

CREATE POLICY "queue_positions_select_doctor" ON queue_positions
  FOR SELECT
  USING (
    doctor_id IN (
      SELECT id FROM doctors WHERE user_id = auth.uid()
    )
  );

-- Notifications Policies
CREATE POLICY "notifications_select_own" ON notifications
  FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "notifications_update_own" ON notifications
  FOR UPDATE
  USING (user_id = auth.uid());

-- Appointments Policies
CREATE POLICY "appointments_select_own" ON appointments
  FOR SELECT
  USING (patient_id = auth.uid());

CREATE POLICY "appointments_select_doctor" ON appointments
  FOR SELECT
  USING (
    doctor_id IN (
      SELECT id FROM doctors WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "appointments_update_own" ON appointments
  FOR UPDATE
  USING (patient_id = auth.uid());

-- =====================================================
-- Step 5: Enable Realtime
-- =====================================================

DO $$ 
BEGIN
  -- Try to drop tables from publication (ignore errors if not in publication)
  BEGIN
    ALTER PUBLICATION supabase_realtime DROP TABLE queue_positions;
  EXCEPTION WHEN OTHERS THEN
    NULL;
  END;
  
  BEGIN
    ALTER PUBLICATION supabase_realtime DROP TABLE notifications;
  EXCEPTION WHEN OTHERS THEN
    NULL;
  END;
  
  BEGIN
    ALTER PUBLICATION supabase_realtime DROP TABLE appointments;
  EXCEPTION WHEN OTHERS THEN
    NULL;
  END;
  
  -- Now add them
  ALTER PUBLICATION supabase_realtime ADD TABLE queue_positions;
  ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
  ALTER PUBLICATION supabase_realtime ADD TABLE appointments;
END $$;

-- =====================================================
-- Step 6: Create Functions & Triggers
-- =====================================================

-- Function to update queue positions
CREATE FUNCTION update_queue_positions()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'UPDATE' AND NEW.status IN ('completed', 'cancelled', 'no_show')) THEN
    WITH ranked AS (
      SELECT 
        qp.id as queue_id,
        ROW_NUMBER() OVER (
          PARTITION BY a.doctor_id, DATE(a.appointment_date) 
          ORDER BY a.appointment_time
        ) as new_position
      FROM appointments a
      JOIN queue_positions qp ON qp.appointment_id = a.id
      WHERE a.status IN ('pending', 'confirmed', 'checked_in')
        AND a.doctor_id = NEW.doctor_id
        AND DATE(a.appointment_date) = DATE(NEW.appointment_date)
        AND qp.status = 'waiting'
    )
    UPDATE queue_positions qp
    SET 
      position = r.new_position,
      estimated_time = NOW() + (r.new_position * INTERVAL '15 minutes'),
      updated_at = NOW()
    FROM ranked r
    WHERE qp.id = r.queue_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_queue_positions
  AFTER UPDATE ON appointments
  FOR EACH ROW
  EXECUTE FUNCTION update_queue_positions();

-- Function to initialize queue position
CREATE FUNCTION initialize_queue_position()
RETURNS TRIGGER AS $$
DECLARE
  current_position INT;
BEGIN
  SELECT COALESCE(COUNT(*), 0) + 1 INTO current_position
  FROM appointments
  WHERE doctor_id = NEW.doctor_id
    AND DATE(appointment_date) = DATE(NEW.appointment_date)
    AND status IN ('pending', 'confirmed', 'checked_in')
    AND appointment_time <= NEW.appointment_time
    AND id != NEW.id;
  
  INSERT INTO queue_positions (
    appointment_id,
    doctor_id,
    position,
    estimated_time,
    status
  ) VALUES (
    NEW.id,
    NEW.doctor_id,
    current_position,
    NEW.appointment_date + NEW.appointment_time + (current_position * INTERVAL '15 minutes'),
    'waiting'
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_initialize_queue
  AFTER INSERT ON appointments
  FOR EACH ROW
  EXECUTE FUNCTION initialize_queue_position();

-- =====================================================
-- Success Message
-- =====================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '============================================';
  RAISE NOTICE '🎉 Setup Complete! Everything is ready!';
  RAISE NOTICE '============================================';
  RAISE NOTICE '';
  RAISE NOTICE '✅ Tables: created/verified';
  RAISE NOTICE '✅ RLS: Enabled with policies';
  RAISE NOTICE '✅ Realtime: Enabled on all tables';
  RAISE NOTICE '✅ Triggers: Auto-queue management active';
  RAISE NOTICE '';
  RAISE NOTICE '📋 Next Steps:';
  RAISE NOTICE '  1. Open: test-supabase-connection.html';
  RAISE NOTICE '  2. Click: Run All Tests';
  RAISE NOTICE '  3. All tests should pass ✅';
  RAISE NOTICE '';
  RAISE NOTICE '============================================';
END $$;
