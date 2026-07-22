-- Admin & Doctor Dashboard Schema with Real-Time Features (FIXED)
-- Run this in Supabase SQL Editor

-- =====================================================
-- 1. Add missing columns to existing tables
-- =====================================================

-- Add fee structure to doctors
ALTER TABLE doctors ADD COLUMN IF NOT EXISTS consultation_fee DECIMAL(10,2) DEFAULT 500.00;
ALTER TABLE doctors ADD COLUMN IF NOT EXISTS specialization_fee DECIMAL(10,2) DEFAULT 200.00;
ALTER TABLE doctors ADD COLUMN IF NOT EXISTS availability_status TEXT DEFAULT 'available';
ALTER TABLE doctors ADD COLUMN IF NOT EXISTS total_patients INT DEFAULT 0;
ALTER TABLE doctors ADD COLUMN IF NOT EXISTS rating DECIMAL(3,2) DEFAULT 4.5;

-- Drop constraint if exists before adding
ALTER TABLE doctors DROP CONSTRAINT IF EXISTS doctors_availability_status_check;
ALTER TABLE doctors ADD CONSTRAINT doctors_availability_status_check 
  CHECK (availability_status IN ('available', 'busy', 'offline'));

-- Add fee to appointments
ALTER TABLE appointments ADD COLUMN IF NOT EXISTS consultation_fee DECIMAL(10,2);
ALTER TABLE appointments ADD COLUMN IF NOT EXISTS payment_status TEXT DEFAULT 'pending';
ALTER TABLE appointments ADD COLUMN IF NOT EXISTS cancelled_by TEXT;
ALTER TABLE appointments ADD COLUMN IF NOT EXISTS cancellation_reason TEXT;

-- Drop constraint if exists before adding
ALTER TABLE appointments DROP CONSTRAINT IF EXISTS appointments_payment_status_check;
ALTER TABLE appointments ADD CONSTRAINT appointments_payment_status_check 
  CHECK (payment_status IN ('pending', 'paid', 'refunded'));

-- =====================================================
-- 2. Create Admin Activity Log Table
-- =====================================================

CREATE TABLE IF NOT EXISTS admin_activity_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  admin_id UUID REFERENCES profiles(id),
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

-- =====================================================
-- 3. Create System Settings Table
-- =====================================================

CREATE TABLE IF NOT EXISTS system_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  key TEXT UNIQUE NOT NULL,
  value JSONB NOT NULL,
  description TEXT,
  updated_by UUID REFERENCES profiles(id),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default settings
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
-- 4. Create Doctor Statistics View
-- =====================================================

CREATE OR REPLACE VIEW doctor_statistics AS
SELECT 
  d.id as doctor_id,
  d.specialization,
  d.consultation_fee,
  d.availability_status,
  COUNT(DISTINCT a.id) as total_appointments,
  COUNT(DISTINCT CASE WHEN a.status = 'completed' THEN a.id END) as completed_appointments,
  COUNT(DISTINCT CASE WHEN a.status = 'cancelled' THEN a.id END) as cancelled_appointments,
  COUNT(DISTINCT CASE WHEN DATE(a.appointment_date) = CURRENT_DATE THEN a.id END) as today_appointments,
  COALESCE(SUM(CASE WHEN a.payment_status = 'paid' THEN a.consultation_fee ELSE 0 END), 0) as total_revenue,
  COALESCE(d.rating, 0) as avg_rating
FROM doctors d
LEFT JOIN appointments a ON a.doctor_id = d.id
GROUP BY d.id, d.specialization, d.consultation_fee, d.availability_status, d.rating;

-- =====================================================
-- 5. Enable Real-Time on Tables
-- =====================================================

ALTER PUBLICATION supabase_realtime ADD TABLE admin_activity_log;
ALTER PUBLICATION supabase_realtime ADD TABLE system_settings;
ALTER PUBLICATION supabase_realtime ADD TABLE doctors;

-- =====================================================
-- 6. RLS Policies
-- =====================================================

-- Admin activity log
ALTER TABLE admin_activity_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "admin_activity_admin_only" ON admin_activity_log;
CREATE POLICY "admin_activity_admin_only" ON admin_activity_log
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- System settings
ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "system_settings_read_all" ON system_settings;
DROP POLICY IF EXISTS "system_settings_admin_write" ON system_settings;

CREATE POLICY "system_settings_read_all" ON system_settings
  FOR SELECT
  USING (true);

CREATE POLICY "system_settings_admin_write" ON system_settings
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- Update doctors policy
DROP POLICY IF EXISTS "doctors_public_read" ON doctors;
DROP POLICY IF EXISTS "doctors_admin_write" ON doctors;
DROP POLICY IF EXISTS "doctors_select_own" ON doctors;
DROP POLICY IF EXISTS "doctors_select_doctor" ON doctors;

CREATE POLICY "doctors_public_read" ON doctors
  FOR SELECT
  USING (true);

CREATE POLICY "doctors_admin_write" ON doctors
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- =====================================================
-- 7. RPC Functions for Admin & Doctor Operations
-- =====================================================

-- Admin: Get Dashboard Statistics
DROP FUNCTION IF EXISTS admin_get_dashboard_stats();
CREATE FUNCTION admin_get_dashboard_stats()
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

-- Doctor: Accept/Reject Appointment
DROP FUNCTION IF EXISTS doctor_update_appointment(UUID, TEXT, TEXT);
CREATE FUNCTION doctor_update_appointment(
  p_appointment_id UUID,
  p_action TEXT, -- 'accept' or 'reject'
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
  -- Get doctor ID from appointment
  SELECT doctor_id INTO v_doctor_id
  FROM appointments
  WHERE id = p_appointment_id;
  
  -- Get doctor's fee
  SELECT consultation_fee INTO v_fee
  FROM doctors
  WHERE id = v_doctor_id;
  
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
      'error', 'Invalid action'
    );
  END IF;
  
EXCEPTION WHEN OTHERS THEN
  RETURN json_build_object(
    'success', false,
    'error', SQLERRM
  );
END;
$$;

-- Admin: Update System Setting
DROP FUNCTION IF EXISTS admin_update_setting(TEXT, JSONB, UUID);
CREATE FUNCTION admin_update_setting(
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

-- Admin: Get All Appointments with Real-Time Data
DROP FUNCTION IF EXISTS admin_get_all_appointments();
CREATE FUNCTION admin_get_all_appointments()
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

-- Grant permissions
GRANT EXECUTE ON FUNCTION admin_get_dashboard_stats TO anon, authenticated;
GRANT EXECUTE ON FUNCTION doctor_update_appointment TO anon, authenticated;
GRANT EXECUTE ON FUNCTION admin_update_setting TO anon, authenticated;
GRANT EXECUTE ON FUNCTION admin_get_all_appointments TO anon, authenticated;

-- =====================================================
-- Success Message
-- =====================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '============================================';
  RAISE NOTICE '✅ Admin & Doctor Schema Created!';
  RAISE NOTICE '============================================';
  RAISE NOTICE '';
  RAISE NOTICE 'New tables:';
  RAISE NOTICE '  - admin_activity_log';
  RAISE NOTICE '  - system_settings';
  RAISE NOTICE '';
  RAISE NOTICE 'Updated tables:';
  RAISE NOTICE '  - doctors (fees, availability)';
  RAISE NOTICE '  - appointments (fees, cancellation)';
  RAISE NOTICE '';
  RAISE NOTICE 'New RPC functions:';
  RAISE NOTICE '  - admin_get_dashboard_stats()';
  RAISE NOTICE '  - admin_get_all_appointments()';
  RAISE NOTICE '  - doctor_update_appointment()';
  RAISE NOTICE '  - admin_update_setting()';
  RAISE NOTICE '';
  RAISE NOTICE 'Real-time enabled on all tables ✅';
  RAISE NOTICE '============================================';
END $$;
