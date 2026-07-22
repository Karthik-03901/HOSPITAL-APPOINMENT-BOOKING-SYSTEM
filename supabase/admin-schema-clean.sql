-- Clean Admin Dashboard Schema
-- Run this in Supabase SQL Editor
-- This version removes all existing conflicts first

-- =====================================================
-- STEP 1: Clean up existing objects
-- =====================================================

-- Drop existing functions
DROP FUNCTION IF EXISTS admin_get_dashboard_stats() CASCADE;
DROP FUNCTION IF EXISTS admin_get_all_appointments() CASCADE;
DROP FUNCTION IF EXISTS doctor_update_appointment(UUID, TEXT, TEXT) CASCADE;
DROP FUNCTION IF EXISTS admin_update_setting(TEXT, JSONB, UUID) CASCADE;

-- Drop existing views
DROP VIEW IF EXISTS doctor_statistics CASCADE;

-- =====================================================
-- STEP 2: Add columns to existing tables (safe)
-- =====================================================

-- Add columns to doctors table (only if not exists)
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'doctors' AND column_name = 'consultation_fee') THEN
    ALTER TABLE doctors ADD COLUMN consultation_fee DECIMAL(10,2) DEFAULT 500.00;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'doctors' AND column_name = 'specialization_fee') THEN
    ALTER TABLE doctors ADD COLUMN specialization_fee DECIMAL(10,2) DEFAULT 200.00;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'doctors' AND column_name = 'availability_status') THEN
    ALTER TABLE doctors ADD COLUMN availability_status TEXT DEFAULT 'available';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'doctors' AND column_name = 'total_patients') THEN
    ALTER TABLE doctors ADD COLUMN total_patients INT DEFAULT 0;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'doctors' AND column_name = 'rating') THEN
    ALTER TABLE doctors ADD COLUMN rating DECIMAL(3,2) DEFAULT 4.5;
  END IF;
END $$;

-- Add columns to appointments table (only if not exists)
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'appointments' AND column_name = 'consultation_fee') THEN
    ALTER TABLE appointments ADD COLUMN consultation_fee DECIMAL(10,2);
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'appointments' AND column_name = 'payment_status') THEN
    ALTER TABLE appointments ADD COLUMN payment_status TEXT DEFAULT 'pending';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'appointments' AND column_name = 'cancelled_by') THEN
    ALTER TABLE appointments ADD COLUMN cancelled_by TEXT;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'appointments' AND column_name = 'cancellation_reason') THEN
    ALTER TABLE appointments ADD COLUMN cancellation_reason TEXT;
  END IF;
END $$;

-- =====================================================
-- STEP 3: Create new tables
-- =====================================================

-- Admin activity log
CREATE TABLE IF NOT EXISTS admin_activity_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id UUID,
  action TEXT NOT NULL,
  target_table TEXT,
  target_id UUID,
  old_values JSONB,
  new_values JSONB,
  ip_address TEXT,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_admin_activity_admin ON admin_activity_log(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_activity_created ON admin_activity_log(created_at DESC);

-- System settings
CREATE TABLE IF NOT EXISTS system_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key TEXT UNIQUE NOT NULL,
  value JSONB NOT NULL,
  description TEXT,
  updated_by UUID,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default settings (skip if exists)
INSERT INTO system_settings (key, value, description) VALUES
  ('hospital_name', '"MediQueue Hospital"', 'Hospital name'),
  ('consultation_base_fee', '500', 'Base consultation fee'),
  ('booking_advance_days', '30', 'How many days in advance can book'),
  ('cancellation_policy_hours', '24', 'Hours before appointment for free cancellation'),
  ('working_hours_start', '"09:00"', 'Hospital start time'),
  ('working_hours_end', '"18:00"', 'Hospital end time'),
  ('max_appointments_per_slot', '3', 'Max appointments per time slot')
ON CONFLICT (key) DO NOTHING;

-- =====================================================
-- STEP 4: Enable RLS on new tables
-- =====================================================

ALTER TABLE admin_activity_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;

-- Drop all existing policies on these tables
DROP POLICY IF EXISTS "admin_activity_admin_only" ON admin_activity_log;
DROP POLICY IF EXISTS "system_settings_read_all" ON system_settings;
DROP POLICY IF EXISTS "system_settings_admin_write" ON system_settings;

-- Create simple permissive policies (for demo - adjust for production)
CREATE POLICY "admin_activity_admin_only" ON admin_activity_log
  FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "system_settings_read_all" ON system_settings
  FOR SELECT USING (true);

CREATE POLICY "system_settings_admin_write" ON system_settings
  FOR ALL USING (true) WITH CHECK (true);

-- =====================================================
-- STEP 5: Create RPC Functions
-- =====================================================

-- Function 1: Get Dashboard Statistics
CREATE OR REPLACE FUNCTION admin_get_dashboard_stats()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result JSON;
BEGIN
  SELECT json_build_object(
    'total_appointments', (SELECT COUNT(*) FROM appointments),
    'today_appointments', (SELECT COUNT(*) FROM appointments WHERE DATE(appointment_date) = CURRENT_DATE),
    'pending_appointments', (SELECT COUNT(*) FROM appointments WHERE status = 'pending'),
    'completed_appointments', (SELECT COUNT(*) FROM appointments WHERE status = 'completed'),
    'total_patients', (SELECT COUNT(DISTINCT patient_id) FROM appointments WHERE patient_id IS NOT NULL),
    'total_doctors', (SELECT COUNT(*) FROM doctors),
    'active_doctors', (SELECT COUNT(*) FROM doctors WHERE availability_status = 'available'),
    'total_revenue', (SELECT COALESCE(SUM(consultation_fee), 0) FROM appointments WHERE payment_status = 'paid'),
    'pending_revenue', (SELECT COALESCE(SUM(consultation_fee), 0) FROM appointments WHERE payment_status = 'pending' AND status != 'cancelled')
  ) INTO v_result;
  
  RETURN v_result;
END;
$$;

-- Function 2: Get All Appointments
CREATE OR REPLACE FUNCTION admin_get_all_appointments()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
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
      'reason', a.reason,
      'consultation_fee', a.consultation_fee,
      'payment_status', a.payment_status,
      'queue_position', qp.position,
      'created_at', a.created_at
    )
  ) INTO v_result
  FROM appointments a
  LEFT JOIN queue_positions qp ON qp.appointment_id = a.id
  ORDER BY a.created_at DESC
  LIMIT 100;
  
  RETURN COALESCE(v_result, '[]'::json);
END;
$$;

-- Function 3: Doctor Update Appointment
CREATE OR REPLACE FUNCTION doctor_update_appointment(
  p_appointment_id UUID,
  p_action TEXT,
  p_reason TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_doctor_id UUID;
  v_fee DECIMAL;
BEGIN
  -- Get doctor info
  SELECT doctor_id INTO v_doctor_id
  FROM appointments
  WHERE id = p_appointment_id;
  
  IF v_doctor_id IS NOT NULL THEN
    SELECT consultation_fee INTO v_fee
    FROM doctors
    WHERE id = v_doctor_id;
  ELSE
    v_fee := 500.00; -- Default fee
  END IF;
  
  IF p_action = 'accept' THEN
    UPDATE appointments
    SET 
      status = 'confirmed',
      consultation_fee = v_fee,
      updated_at = NOW()
    WHERE id = p_appointment_id;
    
    RETURN json_build_object(
      'success', true,
      'message', 'Appointment accepted',
      'fee', v_fee
    );
    
  ELSIF p_action = 'reject' THEN
    UPDATE appointments
    SET 
      status = 'cancelled',
      cancelled_by = 'doctor',
      cancellation_reason = p_reason,
      updated_at = NOW()
    WHERE id = p_appointment_id;
    
    RETURN json_build_object(
      'success', true,
      'message', 'Appointment rejected'
    );
  ELSE
    RETURN json_build_object(
      'success', false,
      'error', 'Invalid action. Use accept or reject'
    );
  END IF;
  
EXCEPTION WHEN OTHERS THEN
  RETURN json_build_object(
    'success', false,
    'error', SQLERRM
  );
END;
$$;

-- Function 4: Update System Setting
CREATE OR REPLACE FUNCTION admin_update_setting(
  p_key TEXT,
  p_value JSONB,
  p_admin_id UUID
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE system_settings
  SET value = p_value, updated_by = p_admin_id, updated_at = NOW()
  WHERE key = p_key;
  
  -- Log activity
  INSERT INTO admin_activity_log (admin_id, action, target_table, old_values, new_values)
  VALUES (p_admin_id, 'update_setting', 'system_settings', 
          json_build_object('key', p_key)::jsonb, 
          json_build_object('value', p_value)::jsonb);
  
  RETURN json_build_object('success', true, 'message', 'Setting updated');
  
EXCEPTION WHEN OTHERS THEN
  RETURN json_build_object('success', false, 'error', SQLERRM);
END;
$$;

-- =====================================================
-- STEP 6: Grant Permissions
-- =====================================================

GRANT EXECUTE ON FUNCTION admin_get_dashboard_stats TO anon, authenticated;
GRANT EXECUTE ON FUNCTION admin_get_all_appointments TO anon, authenticated;
GRANT EXECUTE ON FUNCTION doctor_update_appointment TO anon, authenticated;
GRANT EXECUTE ON FUNCTION admin_update_setting TO anon, authenticated;

-- =====================================================
-- STEP 7: Enable Real-Time (safe operation)
-- =====================================================

-- Remove tables from publication first (if they exist)
DO $$
BEGIN
  -- Try to add tables, ignore if already exists
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE admin_activity_log;
  EXCEPTION WHEN duplicate_object THEN
    NULL;
  END;
  
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE system_settings;
  EXCEPTION WHEN duplicate_object THEN
    NULL;
  END;
  
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE doctors;
  EXCEPTION WHEN duplicate_object THEN
    NULL;
  END;
END $$;

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================

DO $$
DECLARE
  v_appointments_count INT;
  v_functions_count INT;
  v_settings_count INT;
BEGIN
  SELECT COUNT(*) INTO v_appointments_count FROM appointments;
  SELECT COUNT(*) INTO v_functions_count 
  FROM pg_proc 
  WHERE proname IN ('admin_get_dashboard_stats', 'admin_get_all_appointments', 'doctor_update_appointment', 'admin_update_setting');
  SELECT COUNT(*) INTO v_settings_count FROM system_settings;
  
  RAISE NOTICE '';
  RAISE NOTICE '============================================';
  RAISE NOTICE '✅ Admin Dashboard Schema Installed!';
  RAISE NOTICE '============================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Database Status:';
  RAISE NOTICE '  📊 Appointments: %', v_appointments_count;
  RAISE NOTICE '  ⚙️  System Settings: %', v_settings_count;
  RAISE NOTICE '  🔧 RPC Functions: %', v_functions_count;
  RAISE NOTICE '';
  RAISE NOTICE 'Available Functions:';
  RAISE NOTICE '  ✓ admin_get_dashboard_stats()';
  RAISE NOTICE '  ✓ admin_get_all_appointments()';
  RAISE NOTICE '  ✓ doctor_update_appointment()';
  RAISE NOTICE '  ✓ admin_update_setting()';
  RAISE NOTICE '';
  RAISE NOTICE 'Next Steps:';
  RAISE NOTICE '  1. Login: karthiksaravanavel18@gmail.com / admin123';
  RAISE NOTICE '  2. Go to: pages/dashboard-admin.html';
  RAISE NOTICE '  3. Test real-time by booking appointment!';
  RAISE NOTICE '';
  RAISE NOTICE '============================================';
  RAISE NOTICE '🚀 Ready to use!';
  RAISE NOTICE '============================================';
END $$;
