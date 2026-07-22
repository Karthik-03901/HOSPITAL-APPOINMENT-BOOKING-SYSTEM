-- Create Admin, Doctor, and Patient Users
-- Run this in Supabase SQL Editor

-- =====================================================
-- Option 1: Create users directly in profiles table
-- (For demo/testing - works with demo login system)
-- =====================================================

-- First, ensure profiles table exists and has the right structure
DO $$
BEGIN
  -- Add role column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'role'
  ) THEN
    ALTER TABLE profiles ADD COLUMN role TEXT DEFAULT 'patient';
  END IF;
END $$;

-- Create demo profiles (these work with the demo login system)
INSERT INTO profiles (id, email, full_name, role, phone)
VALUES 
  (gen_random_uuid(), 'admin@mediqueue.com', 'System Administrator', 'admin', '+1234567890'),
  (gen_random_uuid(), 'doctor@mediqueue.com', 'Dr. John Smith', 'doctor', '+1234567891'),
  (gen_random_uuid(), 'patient@mediqueue.com', 'Jane Doe', 'patient', '+1234567892')
ON CONFLICT (email) DO UPDATE
  SET role = EXCLUDED.role, full_name = EXCLUDED.full_name;

-- =====================================================
-- Option 2: Create users in Supabase Auth
-- (For production - requires Supabase Auth enabled)
-- =====================================================

-- Note: You need to create auth users through Supabase Dashboard or API
-- After creating auth users, update their profiles:

-- Example: After creating user in Supabase Auth Dashboard,
-- update their role:
-- UPDATE profiles SET role = 'admin' WHERE email = 'youradmin@example.com';

-- =====================================================
-- Create sample doctors with fees
-- =====================================================

-- Insert some doctors
INSERT INTO doctors (id, name, specialization, consultation_fee, specialization_fee, availability_status, rating)
VALUES 
  (gen_random_uuid(), 'Dr. Sarah Johnson', 'Cardiology', 800.00, 300.00, 'available', 4.8),
  (gen_random_uuid(), 'Dr. Michael Chen', 'Neurology', 900.00, 400.00, 'available', 4.9),
  (gen_random_uuid(), 'Dr. Emily Brown', 'Pediatrics', 600.00, 200.00, 'available', 4.7),
  (gen_random_uuid(), 'Dr. James Wilson', 'Orthopedics', 750.00, 250.00, 'available', 4.6),
  (gen_random_uuid(), 'Dr. Lisa Anderson', 'Dermatology', 650.00, 220.00, 'busy', 4.8)
ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- Create sample departments
-- =====================================================

INSERT INTO departments (id, name, description)
VALUES 
  (gen_random_uuid(), 'Cardiology', 'Heart and cardiovascular care'),
  (gen_random_uuid(), 'Neurology', 'Brain and nervous system'),
  (gen_random_uuid(), 'Pediatrics', 'Child healthcare'),
  (gen_random_uuid(), 'Orthopedics', 'Bone and joint care'),
  (gen_random_uuid(), 'Dermatology', 'Skin care'),
  (gen_random_uuid(), 'General Medicine', 'General health checkups'),
  (gen_random_uuid(), 'Emergency', 'Emergency care'),
  (gen_random_uuid(), 'Dental', 'Dental care')
ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- Verification
-- =====================================================

DO $$
DECLARE
  admin_count INT;
  doctor_count INT;
BEGIN
  SELECT COUNT(*) INTO admin_count FROM profiles WHERE role = 'admin';
  SELECT COUNT(*) INTO doctor_count FROM doctors;
  
  RAISE NOTICE '';
  RAISE NOTICE '============================================';
  RAISE NOTICE '✅ Admin & Sample Data Created!';
  RAISE NOTICE '============================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Demo Login Credentials:';
  RAISE NOTICE '  Admin:   admin@mediqueue.com / admin123';
  RAISE NOTICE '  Doctor:  doctor@mediqueue.com / doctor123';
  RAISE NOTICE '  Patient: patient@mediqueue.com / patient123';
  RAISE NOTICE '';
  RAISE NOTICE 'Database Status:';
  RAISE NOTICE '  - Admin users: %', admin_count;
  RAISE NOTICE '  - Doctors: %', doctor_count;
  RAISE NOTICE '';
  RAISE NOTICE '📝 Note: Demo credentials work immediately!';
  RAISE NOTICE '   No Supabase Auth setup required.';
  RAISE NOTICE '';
  RAISE NOTICE 'To use real Supabase Auth:';
  RAISE NOTICE '  1. Create users in Supabase Auth Dashboard';
  RAISE NOTICE '  2. Run: UPDATE profiles SET role = ''admin''';
  RAISE NOTICE '     WHERE email = ''your@email.com'';';
  RAISE NOTICE '';
  RAISE NOTICE '============================================';
END $$;
