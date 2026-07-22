-- Test Admin Dashboard Functions
-- Run this to verify all RPC functions are working

-- =====================================================
-- Test 1: Dashboard Statistics
-- =====================================================
SELECT 'Test 1: Dashboard Statistics' as test_name;
SELECT admin_get_dashboard_stats();

-- Expected: JSON object with all statistics
-- Should show total_appointments, today_appointments, etc.

-- =====================================================
-- Test 2: Get All Appointments  
-- =====================================================
SELECT 'Test 2: Get All Appointments' as test_name;
SELECT admin_get_all_appointments();

-- Expected: JSON array of appointments
-- Empty array if no appointments exist yet

-- =====================================================
-- Test 3: Create Test Appointment
-- =====================================================
SELECT 'Test 3: Create Test Appointment' as test_name;
SELECT create_appointment(
  CURRENT_DATE + INTERVAL '1 day',
  '14:00'::TIME,
  'TEST-ADMIN-' || floor(random() * 1000)::TEXT,
  'Test appointment for admin dashboard'
);

-- Expected: success: true, appointment_id, queue_position

-- =====================================================
-- Test 4: Get Updated Statistics
-- =====================================================
SELECT 'Test 4: Updated Statistics After New Appointment' as test_name;
SELECT admin_get_dashboard_stats();

-- Expected: total_appointments should be increased by 1

-- =====================================================
-- Test 5: System Settings
-- =====================================================
SELECT 'Test 5: System Settings' as test_name;
SELECT * FROM system_settings;

-- Expected: 7 default settings
-- hospital_name, consultation_base_fee, etc.

-- =====================================================
-- Test 6: Check Real-Time Publication
-- =====================================================
SELECT 'Test 6: Real-Time Publication Status' as test_name;
SELECT 
  schemaname,
  tablename,
  (SELECT array_agg(pubtable::regclass::text) 
   FROM pg_publication_tables 
   WHERE pubname = 'supabase_realtime') as realtime_tables
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN ('appointments', 'queue_positions', 'doctors', 'admin_activity_log', 'system_settings')
ORDER BY tablename;

-- Expected: All tables should be in realtime_tables array

-- =====================================================
-- Test 7: Function Permissions
-- =====================================================
SELECT 'Test 7: Function Permissions' as test_name;
SELECT 
  p.proname as function_name,
  pg_get_function_identity_arguments(p.oid) as arguments,
  p.prosecdef as security_definer,
  array_agg(pr.rolname) as granted_to
FROM pg_proc p
LEFT JOIN pg_proc_acl pa ON pa.oid = p.oid
LEFT JOIN pg_roles pr ON pr.oid = ANY(pa.grantee)
WHERE p.proname LIKE 'admin%' OR p.proname LIKE 'doctor%' OR p.proname LIKE 'create_appointment'
GROUP BY p.proname, p.oid, p.prosecdef
ORDER BY p.proname;

-- Expected: Functions should have security_definer = true
-- and be granted to anon, authenticated roles

-- =====================================================
-- Summary
-- =====================================================
DO $$
DECLARE
  v_total_appts INT;
  v_functions_count INT;
  v_settings_count INT;
BEGIN
  SELECT COUNT(*) INTO v_total_appts FROM appointments;
  SELECT COUNT(*) INTO v_functions_count FROM pg_proc WHERE proname LIKE 'admin%' OR proname LIKE 'doctor%';
  SELECT COUNT(*) INTO v_settings_count FROM system_settings;
  
  RAISE NOTICE '';
  RAISE NOTICE '============================================';
  RAISE NOTICE '✅ Test Results Summary';
  RAISE NOTICE '============================================';
  RAISE NOTICE 'Total Appointments: %', v_total_appts;
  RAISE NOTICE 'Admin/Doctor Functions: %', v_functions_count;
  RAISE NOTICE 'System Settings: %', v_settings_count;
  RAISE NOTICE '';
  
  IF v_functions_count >= 4 THEN
    RAISE NOTICE '✅ All RPC functions created';
  ELSE
    RAISE NOTICE '⚠️ Some RPC functions missing';
  END IF;
  
  IF v_settings_count >= 7 THEN
    RAISE NOTICE '✅ System settings configured';
  ELSE
    RAISE NOTICE '⚠️ Some system settings missing';
  END IF;
  
  RAISE NOTICE '';
  RAISE NOTICE '============================================';
  RAISE NOTICE 'Admin Dashboard Ready! 🚀';
  RAISE NOTICE '============================================';
END $$;
