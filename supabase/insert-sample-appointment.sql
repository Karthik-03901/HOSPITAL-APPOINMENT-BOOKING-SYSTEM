-- Insert Sample Appointment for Testing
-- This creates a test appointment so you can see the queue system working
-- Run this in Supabase SQL Editor

-- Insert a sample appointment
INSERT INTO appointments (
  appointment_date,
  appointment_time,
  token_number,
  status,
  reason
) VALUES (
  CURRENT_DATE,
  '10:00:00',
  'T-001',
  'pending',
  'Regular checkup'
);

-- Get the appointment ID we just created
DO $$
DECLARE
  new_appointment_id UUID;
BEGIN
  -- Get the ID of the appointment we just created
  SELECT id INTO new_appointment_id 
  FROM appointments 
  WHERE token_number = 'T-001' 
  ORDER BY created_at DESC 
  LIMIT 1;
  
  RAISE NOTICE '';
  RAISE NOTICE '============================================';
  RAISE NOTICE '✅ Sample appointment created!';
  RAISE NOTICE '============================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Appointment ID: %', new_appointment_id;
  RAISE NOTICE 'Token: T-001';
  RAISE NOTICE 'Date: Today';
  RAISE NOTICE 'Time: 10:00 AM';
  RAISE NOTICE '';
  RAISE NOTICE '📋 Next steps:';
  RAISE NOTICE '1. Check appointments table';
  RAISE NOTICE '2. Check queue_positions table (auto-created by trigger)';
  RAISE NOTICE '3. Open queue-status.html?id=%', new_appointment_id;
  RAISE NOTICE '';
  RAISE NOTICE '============================================';
END $$;
