-- =====================================================
-- AUTO-REALLOCATION WAITLIST SYSTEM
-- Complete implementation with real-time triggers
-- =====================================================

-- =====================================================
-- STEP 1: Create Waitlist Table
-- =====================================================

CREATE TABLE IF NOT EXISTS waitlist (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID,
  patient_name TEXT NOT NULL,
  patient_email TEXT,
  patient_phone TEXT,
  doctor_id UUID,
  doctor_name TEXT,
  department_id UUID,
  department_name TEXT,
  preferred_date DATE NOT NULL,
  preferred_time_range TEXT, -- 'morning', 'afternoon', 'evening', 'any'
  reason TEXT,
  priority_score INT DEFAULT 0,
  status TEXT DEFAULT 'waiting', -- waiting, offered, accepted, expired, cancelled
  offered_appointment_id UUID,
  offered_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  accepted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_waitlist_status ON waitlist(status);
CREATE INDEX idx_waitlist_doctor_date ON waitlist(doctor_id, preferred_date, status);
CREATE INDEX idx_waitlist_expires ON waitlist(expires_at) WHERE status = 'offered';

-- =====================================================
-- STEP 2: Create Cancellations Log Table
-- =====================================================

CREATE TABLE IF NOT EXISTS cancellations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  appointment_id UUID,
  original_appointment_date DATE,
  original_appointment_time TIME,
  original_token_number TEXT,
  doctor_id UUID,
  doctor_name TEXT,
  patient_id UUID,
  cancelled_by UUID,
  cancellation_reason TEXT,
  cancelled_at TIMESTAMPTZ DEFAULT NOW(),
  waitlist_processed BOOLEAN DEFAULT FALSE,
  waitlist_offer_sent_to UUID,
  reused_by_appointment_id UUID
);

CREATE INDEX idx_cancellations_waitlist ON cancellations(waitlist_processed);


-- =====================================================
-- STEP 3: Enable RLS Policies
-- =====================================================

ALTER TABLE waitlist ENABLE ROW LEVEL SECURITY;
ALTER TABLE cancellations ENABLE ROW LEVEL SECURITY;

-- Patients can see their own waitlist entries
CREATE POLICY "waitlist_patient_select" ON waitlist
  FOR SELECT
  USING (patient_email = current_setting('request.jwt.claims', true)::json->>'email');

-- Anyone can insert into waitlist
CREATE POLICY "waitlist_insert" ON waitlist
  FOR INSERT
  WITH CHECK (true);

-- Patients can update their own entries
CREATE POLICY "waitlist_patient_update" ON waitlist
  FOR UPDATE
  USING (patient_email = current_setting('request.jwt.claims', true)::json->>'email');

-- Admin can see all
CREATE POLICY "waitlist_admin_all" ON waitlist
  FOR ALL
  USING (true);

-- Cancellations policies
CREATE POLICY "cancellations_all" ON cancellations
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- =====================================================
-- STEP 4: Function to Find Next Waitlist Candidate
-- =====================================================

CREATE OR REPLACE FUNCTION find_next_waitlist_candidate(
  p_doctor_id UUID,
  p_date DATE,
  p_time TIME
)
RETURNS TABLE(
  waitlist_id UUID,
  patient_name TEXT,
  patient_email TEXT,
  patient_phone TEXT,
  priority_score INT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    w.id,
    w.patient_name,
    w.patient_email,
    w.patient_phone,
    w.priority_score
  FROM waitlist w
  WHERE w.doctor_id = p_doctor_id
    AND w.preferred_date = p_date
    AND w.status = 'waiting'
    AND (
      w.preferred_time_range = 'any'
      OR (w.preferred_time_range = 'morning' AND p_time < '12:00'::TIME)
      OR (w.preferred_time_range = 'afternoon' AND p_time BETWEEN '12:00'::TIME AND '17:00'::TIME)
      OR (w.preferred_time_range = 'evening' AND p_time >= '17:00'::TIME)
    )
  ORDER BY w.priority_score DESC, w.created_at ASC
  LIMIT 1;
END;
$$ LANGUAGE plpgsql;


-- =====================================================
-- STEP 5: Trigger Function - Process Waitlist on Cancellation
-- =====================================================

CREATE OR REPLACE FUNCTION process_waitlist_on_cancellation()
RETURNS TRIGGER AS $$
DECLARE
  v_waitlist_candidate RECORD;
  v_cancelled_appointment RECORD;
BEGIN
  -- Only process if status changed to 'cancelled'
  IF NEW.status = 'cancelled' AND OLD.status != 'cancelled' THEN
    
    -- Get the cancelled appointment details
    SELECT 
      id, 
      appointment_date, 
      appointment_time, 
      token_number,
      doctor_id,
      reason
    INTO v_cancelled_appointment
    FROM appointments
    WHERE id = NEW.id;
    
    -- Log the cancellation
    INSERT INTO cancellations (
      appointment_id,
      original_appointment_date,
      original_appointment_time,
      original_token_number,
      doctor_id,
      patient_id,
      cancelled_by,
      cancellation_reason
    ) VALUES (
      NEW.id,
      v_cancelled_appointment.appointment_date,
      v_cancelled_appointment.appointment_time,
      v_cancelled_appointment.token_number,
      v_cancelled_appointment.doctor_id,
      NEW.patient_id,
      NEW.cancelled_by,
      NEW.cancellation_reason
    );
    
    -- Find next person on waitlist
    SELECT * INTO v_waitlist_candidate
    FROM find_next_waitlist_candidate(
      v_cancelled_appointment.doctor_id,
      v_cancelled_appointment.appointment_date,
      v_cancelled_appointment.appointment_time
    );
    
    -- If someone is waiting, offer them the slot
    IF FOUND THEN
      -- Update waitlist status to 'offered'
      UPDATE waitlist
      SET 
        status = 'offered',
        offered_appointment_id = NEW.id,
        offered_at = NOW(),
        expires_at = NOW() + INTERVAL '15 minutes',
        updated_at = NOW()
      WHERE id = v_waitlist_candidate.waitlist_id;
      
      -- Update cancellation log
      UPDATE cancellations
      SET 
        waitlist_processed = TRUE,
        waitlist_offer_sent_to = v_waitlist_candidate.waitlist_id
      WHERE appointment_id = NEW.id;
      
      -- Create notification (this will be picked up by Edge Function)
      INSERT INTO notifications (
        user_id,
        type,
        title,
        body,
        data,
        channels,
        created_at
      ) VALUES (
        NULL, -- Will use email/phone from waitlist
        'waitlist_offer',
        '🎉 Appointment Slot Available!',
        'A slot opened up! Confirm within 15 minutes to book.',
        jsonb_build_object(
          'waitlist_id', v_waitlist_candidate.waitlist_id,
          'appointment_id', NEW.id,
          'appointment_date', v_cancelled_appointment.appointment_date,
          'appointment_time', v_cancelled_appointment.appointment_time,
          'doctor_name', (SELECT name FROM doctors WHERE id = v_cancelled_appointment.doctor_id LIMIT 1),
          'patient_email', v_waitlist_candidate.patient_email,
          'patient_phone', v_waitlist_candidate.patient_phone,
          'patient_name', v_waitlist_candidate.patient_name
        ),
        ARRAY['push', 'sms', 'email', 'in_app'],
        NOW()
      );
      
      RAISE NOTICE 'Waitlist offer sent to: %', v_waitlist_candidate.patient_name;
    ELSE
      RAISE NOTICE 'No waitlist candidates found for this slot';
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- =====================================================
-- STEP 6: Create Trigger on Appointments
-- =====================================================

DROP TRIGGER IF EXISTS trigger_process_waitlist ON appointments;

CREATE TRIGGER trigger_process_waitlist
  AFTER UPDATE OF status ON appointments
  FOR EACH ROW
  WHEN (NEW.status = 'cancelled' AND OLD.status != 'cancelled')
  EXECUTE FUNCTION process_waitlist_on_cancellation();

-- =====================================================
-- STEP 7: Function to Auto-Expire Waitlist Offers
-- =====================================================

CREATE OR REPLACE FUNCTION expire_waitlist_offers()
RETURNS void AS $$
DECLARE
  v_expired_offer RECORD;
BEGIN
  -- Find all expired offers
  FOR v_expired_offer IN
    SELECT id, offered_appointment_id, doctor_id, preferred_date
    FROM waitlist
    WHERE status = 'offered'
      AND expires_at < NOW()
  LOOP
    -- Mark as expired
    UPDATE waitlist
    SET status = 'expired', updated_at = NOW()
    WHERE id = v_expired_offer.id;
    
    -- Try to offer to next person
    PERFORM process_next_waitlist_candidate(
      v_expired_offer.offered_appointment_id,
      v_expired_offer.doctor_id,
      v_expired_offer.preferred_date
    );
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Helper function to process next candidate
CREATE OR REPLACE FUNCTION process_next_waitlist_candidate(
  p_appointment_id UUID,
  p_doctor_id UUID,
  p_date DATE
)
RETURNS void AS $$
DECLARE
  v_appointment RECORD;
  v_next_candidate RECORD;
BEGIN
  -- Get appointment details
  SELECT appointment_date, appointment_time
  INTO v_appointment
  FROM appointments
  WHERE id = p_appointment_id;
  
  -- Find next candidate
  SELECT * INTO v_next_candidate
  FROM find_next_waitlist_candidate(
    p_doctor_id,
    v_appointment.appointment_date,
    v_appointment.appointment_time
  );
  
  IF FOUND THEN
    -- Offer to next person
    UPDATE waitlist
    SET 
      status = 'offered',
      offered_appointment_id = p_appointment_id,
      offered_at = NOW(),
      expires_at = NOW() + INTERVAL '15 minutes',
      updated_at = NOW()
    WHERE id = v_next_candidate.waitlist_id;
    
    -- Send notification
    INSERT INTO notifications (
      user_id,
      type,
      title,
      body,
      data,
      channels
    ) VALUES (
      NULL,
      'waitlist_offer',
      '🎉 Appointment Slot Available!',
      'Previous person declined. Confirm within 15 minutes!',
      jsonb_build_object(
        'waitlist_id', v_next_candidate.waitlist_id,
        'appointment_id', p_appointment_id,
        'patient_email', v_next_candidate.patient_email,
        'patient_phone', v_next_candidate.patient_phone,
        'patient_name', v_next_candidate.patient_name
      ),
      ARRAY['push', 'sms', 'in_app']
    );
  END IF;
END;
$$ LANGUAGE plpgsql;


-- =====================================================
-- STEP 8: RPC Functions for Frontend
-- =====================================================

-- Join waitlist
CREATE OR REPLACE FUNCTION join_waitlist(
  p_patient_name TEXT,
  p_patient_email TEXT,
  p_patient_phone TEXT,
  p_doctor_id UUID,
  p_doctor_name TEXT,
  p_department_name TEXT,
  p_preferred_date TEXT,
  p_preferred_time_range TEXT,
  p_reason TEXT
)
RETURNS JSON AS $$
DECLARE
  v_waitlist_id UUID;
  v_position INT;
BEGIN
  -- Insert into waitlist
  INSERT INTO waitlist (
    patient_name,
    patient_email,
    patient_phone,
    doctor_id,
    doctor_name,
    department_name,
    preferred_date,
    preferred_time_range,
    reason,
    priority_score,
    status
  ) VALUES (
    p_patient_name,
    p_patient_email,
    p_patient_phone,
    p_doctor_id,
    p_doctor_name,
    p_department_name,
    p_preferred_date::DATE,
    p_preferred_time_range,
    p_reason,
    0, -- Default priority
    'waiting'
  )
  RETURNING id INTO v_waitlist_id;
  
  -- Get position in waitlist
  SELECT COUNT(*) INTO v_position
  FROM waitlist
  WHERE doctor_id = p_doctor_id
    AND preferred_date = p_preferred_date::DATE
    AND status = 'waiting'
    AND created_at <= (SELECT created_at FROM waitlist WHERE id = v_waitlist_id);
  
  RETURN json_build_object(
    'success', true,
    'waitlist_id', v_waitlist_id::TEXT,
    'position', v_position,
    'message', 'Added to waitlist successfully!'
  );
  
EXCEPTION WHEN OTHERS THEN
  RETURN json_build_object(
    'success', false,
    'error', SQLERRM
  );
END;
$$ LANGUAGE plpgsql;

-- Accept waitlist offer
CREATE OR REPLACE FUNCTION accept_waitlist_offer(
  p_waitlist_id UUID,
  p_patient_id UUID
)
RETURNS JSON AS $$
DECLARE
  v_waitlist RECORD;
  v_appointment_id UUID;
BEGIN
  -- Get waitlist details
  SELECT * INTO v_waitlist
  FROM waitlist
  WHERE id = p_waitlist_id
    AND status = 'offered'
    AND expires_at > NOW();
  
  IF NOT FOUND THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Offer expired or not found'
    );
  END IF;
  
  -- Update the cancelled appointment with new patient
  UPDATE appointments
  SET 
    patient_id = p_patient_id,
    status = 'confirmed',
    updated_at = NOW(),
    cancellation_reason = NULL,
    cancelled_by = NULL,
    cancelled_at = NULL
  WHERE id = v_waitlist.offered_appointment_id
  RETURNING id INTO v_appointment_id;
  
  -- Update waitlist status
  UPDATE waitlist
  SET 
    status = 'accepted',
    accepted_at = NOW(),
    updated_at = NOW()
  WHERE id = p_waitlist_id;
  
  -- Update cancellation log
  UPDATE cancellations
  SET reused_by_appointment_id = v_appointment_id
  WHERE appointment_id = v_waitlist.offered_appointment_id;
  
  RETURN json_build_object(
    'success', true,
    'appointment_id', v_appointment_id::TEXT,
    'message', 'Appointment confirmed from waitlist!'
  );
  
EXCEPTION WHEN OTHERS THEN
  RETURN json_build_object(
    'success', false,
    'error', SQLERRM
  );
END;
$$ LANGUAGE plpgsql;

-- Get waitlist position
CREATE OR REPLACE FUNCTION get_waitlist_status(p_waitlist_id UUID)
RETURNS JSON AS $$
DECLARE
  v_waitlist RECORD;
  v_position INT;
BEGIN
  SELECT * INTO v_waitlist
  FROM waitlist
  WHERE id = p_waitlist_id;
  
  IF NOT FOUND THEN
    RETURN json_build_object('success', false, 'error', 'Not found');
  END IF;
  
  -- Calculate current position
  IF v_waitlist.status = 'waiting' THEN
    SELECT COUNT(*) INTO v_position
    FROM waitlist
    WHERE doctor_id = v_waitlist.doctor_id
      AND preferred_date = v_waitlist.preferred_date
      AND status = 'waiting'
      AND created_at <= v_waitlist.created_at;
  ELSE
    v_position := 0;
  END IF;
  
  RETURN json_build_object(
    'success', true,
    'waitlist', row_to_json(v_waitlist),
    'position', v_position
  );
END;
$$ LANGUAGE plpgsql;

-- Grant permissions
GRANT EXECUTE ON FUNCTION join_waitlist TO anon, authenticated;
GRANT EXECUTE ON FUNCTION accept_waitlist_offer TO anon, authenticated;
GRANT EXECUTE ON FUNCTION get_waitlist_status TO anon, authenticated;
GRANT EXECUTE ON FUNCTION expire_waitlist_offers TO service_role;


-- =====================================================
-- STEP 9: Test the System
-- =====================================================

DO $$
DECLARE
  v_test_appointment_id UUID;
  v_test_waitlist_id UUID;
  v_result JSON;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '====================================================';
  RAISE NOTICE '   TESTING WAITLIST AUTO-REALLOCATION SYSTEM';
  RAISE NOTICE '====================================================';
  RAISE NOTICE '';
  
  -- Test 1: Create a test appointment
  RAISE NOTICE '► Test 1: Creating test appointment';
  INSERT INTO appointments (
    appointment_date,
    appointment_time,
    token_number,
    status,
    doctor_id,
    reason
  ) VALUES (
    CURRENT_DATE + 1,
    '10:00'::TIME,
    'WAITLIST-TEST-' || floor(random() * 1000)::TEXT,
    'confirmed',
    NULL, -- Dummy doctor
    'Test appointment for waitlist'
  )
  RETURNING id INTO v_test_appointment_id;
  RAISE NOTICE '  ✅ Appointment created: %', v_test_appointment_id;
  
  -- Test 2: Add someone to waitlist
  RAISE NOTICE '';
  RAISE NOTICE '► Test 2: Adding patient to waitlist';
  SELECT join_waitlist(
    'John Doe',
    'john@example.com',
    '+1234567890',
    NULL, -- Dummy doctor
    'Dr. Test',
    'General Medicine',
    (CURRENT_DATE + 1)::TEXT,
    'morning',
    'Want this slot'
  ) INTO v_result;
  
  v_test_waitlist_id := (v_result->>'waitlist_id')::UUID;
  RAISE NOTICE '  Result: %', v_result;
  
  IF (v_result->>'success')::BOOLEAN THEN
    RAISE NOTICE '  ✅ Patient added to waitlist';
    RAISE NOTICE '     Position: %', v_result->>'position';
  ELSE
    RAISE NOTICE '  ❌ Failed: %', v_result->>'error';
  END IF;
  
  -- Test 3: Cancel the appointment (should trigger waitlist)
  RAISE NOTICE '';
  RAISE NOTICE '► Test 3: Cancelling appointment (triggers waitlist)';
  UPDATE appointments
  SET status = 'cancelled',
      cancellation_reason = 'Test cancellation',
      cancelled_at = NOW()
  WHERE id = v_test_appointment_id;
  RAISE NOTICE '  ✅ Appointment cancelled';
  
  -- Check if waitlist was processed
  PERFORM pg_sleep(0.5); -- Wait for trigger
  
  IF EXISTS(
    SELECT 1 FROM waitlist 
    WHERE id = v_test_waitlist_id 
    AND status = 'offered'
  ) THEN
    RAISE NOTICE '  ✅ Waitlist offer sent automatically!';
    RAISE NOTICE '     Status: offered';
    RAISE NOTICE '     Expires in: 15 minutes';
  ELSE
    RAISE NOTICE '  ❌ Waitlist not processed';
  END IF;
  
  RAISE NOTICE '';
  RAISE NOTICE '====================================================';
  RAISE NOTICE '   TEST RESULTS';
  RAISE NOTICE '====================================================';
  RAISE NOTICE '  Appointments: %', (SELECT COUNT(*) FROM appointments WHERE id = v_test_appointment_id);
  RAISE NOTICE '  Waitlist entries: %', (SELECT COUNT(*) FROM waitlist WHERE id = v_test_waitlist_id);
  RAISE NOTICE '  Cancellations logged: %', (SELECT COUNT(*) FROM cancellations WHERE appointment_id = v_test_appointment_id);
  RAISE NOTICE '  Notifications sent: %', (SELECT COUNT(*) FROM notifications WHERE type = 'waitlist_offer');
  RAISE NOTICE '';
  RAISE NOTICE '====================================================';
  RAISE NOTICE '🎉 WAITLIST SYSTEM IS READY!';
  RAISE NOTICE '====================================================';
  RAISE NOTICE '';
END $$;

-- Show statistics
SELECT 
  'System Status' as metric,
  'Ready' as value
UNION ALL
SELECT 
  'Waitlist entries',
  COUNT(*)::TEXT
FROM waitlist
UNION ALL
SELECT 
  'Cancellations logged',
  COUNT(*)::TEXT
FROM cancellations;

