-- Diagnose what's wrong with the appointments table

-- Check 1: Does the table exist?
SELECT 'Table exists:' as check, 
       EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'appointments') as result;

-- Check 2: What columns does it have?
SELECT 'Columns:' as check, column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'appointments'
ORDER BY ordinal_position;

-- Check 3: What's the token_number column type?
SELECT 'Token number type:' as check, data_type
FROM information_schema.columns
WHERE table_name = 'appointments' AND column_name = 'token_number';

-- Check 4: Try a simple INSERT
DO $$
DECLARE
  v_id UUID;
BEGIN
  BEGIN
    INSERT INTO appointments (
      appointment_date,
      appointment_time,
      token_number,
      status
    ) VALUES (
      CURRENT_DATE + 1,
      '14:30'::TIME,
      'DIAGNOSTIC-TEST-123',
      'pending'
    )
    RETURNING id INTO v_id;
    
    RAISE NOTICE '✅ Direct INSERT worked! ID: %', v_id;
    
    -- Clean up
    DELETE FROM appointments WHERE id = v_id;
    
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Direct INSERT failed: %', SQLERRM;
  END;
END $$;

-- Check 5: Test the RPC function with detailed error
SELECT create_appointment(
  '2026-07-23',
  '14:30',
  'RPC-TEST-456',
  'Test from diagnostic'
) as result;
