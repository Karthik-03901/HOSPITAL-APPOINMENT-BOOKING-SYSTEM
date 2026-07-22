-- Fix token_number column type
-- Change from INTEGER to TEXT to support alphanumeric tokens like "U-383"

-- Step 1: Drop the unique constraint if it exists
ALTER TABLE appointments DROP CONSTRAINT IF EXISTS appointments_token_number_key;

-- Step 2: Change column type from INTEGER to TEXT
ALTER TABLE appointments ALTER COLUMN token_number TYPE TEXT USING token_number::TEXT;

-- Step 3: Re-add unique constraint
ALTER TABLE appointments ADD CONSTRAINT appointments_token_number_key UNIQUE (token_number);

-- Step 4: Test it works
DO $$
DECLARE
  v_result JSON;
BEGIN
  -- Test create appointment with text token
  SELECT create_appointment(
    CURRENT_DATE + 1,
    '14:30'::TIME,
    'TEST-' || floor(random() * 10000)::TEXT,
    'Test booking with text token'
  ) INTO v_result;
  
  RAISE NOTICE '';
  RAISE NOTICE '============================================';
  RAISE NOTICE '✅ Token Number Type Fixed!';
  RAISE NOTICE '============================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Test Result: %', v_result;
  RAISE NOTICE '';
  
  IF (v_result->>'success')::BOOLEAN THEN
    RAISE NOTICE '✅ TEST PASSED - Now accepts text tokens!';
    RAISE NOTICE 'Token: %', v_result->>'token_number';
    RAISE NOTICE 'Queue Position: %', v_result->>'queue_position';
  ELSE
    RAISE NOTICE '❌ TEST FAILED - Error: %', v_result->>'error';
  END IF;
  
  RAISE NOTICE '';
  RAISE NOTICE 'Ready to book appointments! ✅';
  RAISE NOTICE '============================================';
END $$;
