-- Fixed Real-Time Queue Management Schema
-- This version handles existing policies gracefully
-- Run this in Supabase SQL Editor

-- =====================================================
-- Step 1: Create core tables (if they don't exist)
-- =====================================================

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

-- =====================================================
-- Step 2: Create Real-Time Tables
-- =====================================================

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

-- Indexes
CREATE INDEX IF NOT EXISTS idx_queue_positions_appointment ON queue_positions(appointment_id);
CREATE INDEX IF NOT EXISTS idx_queue_positions_doctor ON queue_positions(doctor_id);
CREATE INDEX IF NOT EXISTS idx_queue_positions_status ON queue_positions(status);

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

-- Indexes
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON notifications(user_id, read) WHERE read = FALSE;

-- =====================================================
-- Step 3: Enable Realtime (IMPORTANT!)
-- =====================================================

DO $$ 
BEGIN
  -- Check if tables are already in publication
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' 
    AND tablename = 'queue_positions'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE queue_positions;
    RAISE NOTICE '✅ Added queue_positions to realtime';
  ELSE
    RAISE NOTICE '⚠️  queue_positions already in realtime publication';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' 
    AND tablename = 'notifications'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
    RAISE NOTICE '✅ Added notifications to realtime';
  ELSE
    RAISE NOTICE '⚠️  notifications already in realtime publication';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' 
    AND tablename = 'appointments'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE appointments;
    RAISE NOTICE '✅ Added appointments to realtime';
  ELSE
    RAISE NOTICE '⚠️  appointments already in realtime publication';
  END IF;
END $$;

-- =====================================================
-- Step 4: Row Level Security (RLS)
-- =====================================================

-- Enable RLS on tables
ALTER TABLE queue_positions ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;

-- Drop existing policies first to avoid conflicts
DROP POLICY IF EXISTS "queue_positions_select_own" ON queue_positions;
DROP POLICY IF EXISTS "queue_positions_select_doctor" ON queue_positions;
DROP POLICY IF EXISTS "notifications_select_own" ON notifications;
DROP POLICY IF EXISTS "notifications_update_own" ON notifications;
DROP POLICY IF EXISTS "appointments_select_own" ON appointments;
DROP POLICY IF EXISTS "appointments_select_doctor" ON appointments;
DROP POLICY IF EXISTS "appointments_update_own" ON appointments;

-- Queue Positions - Patients can see their own
CREATE POLICY "queue_positions_select_own" ON queue_positions
  FOR SELECT
  USING (
    appointment_id IN (
      SELECT id FROM appointments WHERE patient_id = auth.uid()
    )
  );

-- Queue Positions - Doctors can see their queue
CREATE POLICY "queue_positions_select_doctor" ON queue_positions
  FOR SELECT
  USING (
    doctor_id IN (
      SELECT id FROM doctors WHERE user_id = auth.uid()
    )
  );

-- Notifications - Users see their own
CREATE POLICY "notifications_select_own" ON notifications
  FOR SELECT
  USING (user_id = auth.uid());

-- Notifications - Users can update their own (mark as read)
CREATE POLICY "notifications_update_own" ON notifications
  FOR UPDATE
  USING (user_id = auth.uid());

-- Appointments - Patients see their own
CREATE POLICY "appointments_select_own" ON appointments
  FOR SELECT
  USING (patient_id = auth.uid());

-- Appointments - Doctors see their appointments
CREATE POLICY "appointments_select_doctor" ON appointments
  FOR SELECT
  USING (
    doctor_id IN (
      SELECT id FROM doctors WHERE user_id = auth.uid()
    )
  );

-- Appointments - Allow authenticated users to update (for check-in)
CREATE POLICY "appointments_update_own" ON appointments
  FOR UPDATE
  USING (patient_id = auth.uid());

-- =====================================================
-- Step 5: Helper Functions & Triggers
-- =====================================================

-- Function to update queue positions when appointment changes
CREATE OR REPLACE FUNCTION update_queue_positions()
RETURNS TRIGGER AS $$
BEGIN
  -- Only recalculate if status changed to completed, cancelled, or called
  IF (TG_OP = 'UPDATE' AND NEW.status IN ('completed', 'cancelled', 'no_show', 'consulting')) THEN
    -- Recalculate positions for remaining appointments
    WITH ranked AS (
      SELECT 
        qp.id as queue_id,
        qp.appointment_id,
        ROW_NUMBER() OVER (
          PARTITION BY a.doctor_id, DATE(a.appointment_date) 
          ORDER BY a.appointment_time
        ) as new_position
      FROM appointments a
      JOIN queue_positions qp ON qp.appointment_id = a.id
      WHERE a.status IN ('pending', 'confirmed', 'checked_in', 'called')
        AND a.doctor_id = NEW.doctor_id
        AND DATE(a.appointment_date) = DATE(NEW.appointment_date)
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
    
    -- If current appointment is completed, mark its queue position
    IF NEW.status = 'completed' THEN
      UPDATE queue_positions
      SET 
        status = 'completed',
        updated_at = NOW()
      WHERE appointment_id = NEW.id;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop and recreate trigger
DROP TRIGGER IF EXISTS trigger_update_queue_positions ON appointments;
CREATE TRIGGER trigger_update_queue_positions
  AFTER UPDATE ON appointments
  FOR EACH ROW
  EXECUTE FUNCTION update_queue_positions();

-- Function to initialize queue position when appointment is created
CREATE OR REPLACE FUNCTION initialize_queue_position()
RETURNS TRIGGER AS $$
DECLARE
  current_position INT;
BEGIN
  -- Calculate position based on existing appointments
  SELECT COALESCE(COUNT(*), 0) + 1 INTO current_position
  FROM appointments
  WHERE doctor_id = NEW.doctor_id
    AND DATE(appointment_date) = DATE(NEW.appointment_date)
    AND status IN ('pending', 'confirmed', 'checked_in')
    AND appointment_time <= NEW.appointment_time
    AND id != NEW.id;
  
  -- Insert queue position
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

-- Drop and recreate trigger
DROP TRIGGER IF EXISTS trigger_initialize_queue ON appointments;
CREATE TRIGGER trigger_initialize_queue
  AFTER INSERT ON appointments
  FOR EACH ROW
  EXECUTE FUNCTION initialize_queue_position();

-- =====================================================
-- Verification & Success Message
-- =====================================================

DO $$
BEGIN
  RAISE NOTICE '============================================';
  RAISE NOTICE '✅ Real-time schema setup complete!';
  RAISE NOTICE '============================================';
  RAISE NOTICE 'Tables created:';
  RAISE NOTICE '  - queue_positions';
  RAISE NOTICE '  - notifications';
  RAISE NOTICE '';
  RAISE NOTICE 'Realtime enabled on:';
  RAISE NOTICE '  - queue_positions';
  RAISE NOTICE '  - notifications';
  RAISE NOTICE '  - appointments';
  RAISE NOTICE '';
  RAISE NOTICE 'RLS policies: ✅ Configured';
  RAISE NOTICE 'Triggers: ✅ Created';
  RAISE NOTICE '';
  RAISE NOTICE 'Next steps:';
  RAISE NOTICE '1. Test connection: test-supabase-connection.html';
  RAISE NOTICE '2. Book an appointment';
  RAISE NOTICE '3. Watch queue position update live!';
  RAISE NOTICE '============================================';
END $$;
