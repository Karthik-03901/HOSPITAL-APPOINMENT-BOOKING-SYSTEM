-- =====================================================
-- WAITLIST SYSTEM - FIXED VERSION
-- Fixed the "relation already exists" error
-- =====================================================

-- Drop existing objects if they exist
DROP TRIGGER IF EXISTS trigger_process_waitlist ON appointments;
DROP FUNCTION IF EXISTS process_waitlist_on_cancellation CASCADE;
DROP FUNCTION IF EXISTS find_next_waitlist_candidate CASCADE;
DROP FUNCTION IF EXISTS expire_waitlist_offers CASCADE;
DROP FUNCTION IF EXISTS process_next_waitlist_candidate CASCADE;
DROP FUNCTION IF EXISTS join_waitlist CASCADE;
DROP FUNCTION IF EXISTS accept_waitlist_offer CASCADE;
DROP FUNCTION IF EXISTS get_waitlist_status CASCADE;

DROP TABLE IF EXISTS waitlist CASCADE;
DROP TABLE IF EXISTS cancellations CASCADE;

-- =====================================================
-- STEP 1: Create Tables
-- =====================================================

CREATE TABLE waitlist (
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
  preferred_time_range TEXT,
  reason TEXT,
  priority_score INT DEFAULT 0,
  status TEXT DEFAULT 'waiting',
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

CREATE TABLE cancellations (
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
-- STEP 2: RLS Policies
-- =====================================================

ALTER TABLE waitlist ENABLE ROW LEVEL SECURITY;
ALTER TABLE cancellations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "waitlist_all" ON waitlist FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "cancellations_all" ON cancellations FOR ALL USING (true) WITH CHECK (true);


-- =====================================================
-- STEP 3: Core Functions
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
  WHERE (w.doctor_id = p_doctor_id OR w.doctor_id IS NULL)
    AND w.preferred_date = p_date
    AND w.status = 'waiting'
    AND (
      w.preferred_time_range = 'any'
      OR (w.preferred_time_range = 'morning' AND p_time < '12:00'::TIME)
      OR (w.preferred_time_range = 'afternoon' AND p_time BETWEEN '12:00'::TIME AND '17:00'::TIME)
      OR (w.preferred_time_range = 'evening' AND p_time >= '17:00'::TIME)
      OR w.preferred_time_range IS NULL
    )
  ORDER BY w.priority_score DESC, w.created_at ASC
  LIMIT 1;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION process_waitlist_on_cancellation()
RETURNS TRIGGER AS $$
DECLARE
  v_waitlist_candidate RECORD;
  v_cancelled_appointment RECORD;
BEGIN
  IF NEW.status = 'cancelled' AND OLD.status != 'cancelled' THEN
    SELECT 
      id, appointment_date, appointment_time, token_number, doctor_id, reason
    INTO v_cancelled_appointment
    FROM appointments
    WHERE id = NEW.id;
    
    INSERT INTO cancellations (
      appointment_id, original_appointment_date, original_appointment_time,
      original_token_number, doctor_id, patient_id, cancelled_by, cancellation_reason
    ) VALUES (
      NEW.id, v_cancelled_appointment.appointment_date, v_cancelled_appointment.appointment_time,
      v_cancelled_appointment.token_number, v_cancelled_appointment.doctor_id,
      NEW.patient_id, NEW.cancelled_by, NEW.cancellation_reason
    );
    
    SELECT * INTO v_waitlist_candidate
    FROM find_next_waitlist_candidate(
      v_cancelled_appointment.doctor_id,
      v_cancelled_appointment.appointment_date,
      v_cancelled_appointment.appointment_time
    );
    
    IF FOUND THEN
      UPDATE waitlist
      SET status = 'offered',
          offered_appointment_id = NEW.id,
          offered_at = NOW(),
          expires_at = NOW() + INTERVAL '15 minutes',
          updated_at = NOW()
      WHERE id = v_waitlist_candidate.waitlist_id;
      
      UPDATE cancellations
      SET waitlist_processed = TRUE,
          waitlist_offer_sent_to = v_waitlist_candidate.waitlist_id
      WHERE appointment_id = NEW.id;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_process_waitlist
  AFTER UPDATE OF status ON appointments
  FOR EACH ROW
  WHEN (NEW.status = 'cancelled' AND OLD.status != 'cancelled')
  EXECUTE FUNCTION process_waitlist_on_cancellation();

-- =====================================================
-- STEP 4: RPC Functions
-- =====================================================

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
  INSERT INTO waitlist (
    patient_name, patient_email, patient_phone, doctor_id, doctor_name,
    department_name, preferred_date, preferred_time_range, reason, priority_score, status
  ) VALUES (
    p_patient_name, p_patient_email, p_patient_phone, p_doctor_id, p_doctor_name,
    p_department_name, p_preferred_date::DATE, p_preferred_time_range, p_reason, 0, 'waiting'
  )
  RETURNING id INTO v_waitlist_id;
  
  SELECT COUNT(*) INTO v_position
  FROM waitlist
  WHERE (doctor_id = p_doctor_id OR (doctor_id IS NULL AND p_doctor_id IS NULL))
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
  RETURN json_build_object('success', false, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION accept_waitlist_offer(
  p_waitlist_id UUID,
  p_patient_id UUID
)
RETURNS JSON AS $$
DECLARE
  v_waitlist RECORD;
  v_appointment_id UUID;
BEGIN
  SELECT * INTO v_waitlist
  FROM waitlist
  WHERE id = p_waitlist_id AND status = 'offered' AND expires_at > NOW();
  
  IF NOT FOUND THEN
    RETURN json_build_object('success', false, 'error', 'Offer expired or not found');
  END IF;
  
  UPDATE appointments
  SET patient_id = p_patient_id, status = 'confirmed', updated_at = NOW(),
      cancellation_reason = NULL, cancelled_by = NULL, cancelled_at = NULL
  WHERE id = v_waitlist.offered_appointment_id
  RETURNING id INTO v_appointment_id;
  
  UPDATE waitlist
  SET status = 'accepted', accepted_at = NOW(), updated_at = NOW()
  WHERE id = p_waitlist_id;
  
  UPDATE cancellations
  SET reused_by_appointment_id = v_appointment_id
  WHERE appointment_id = v_waitlist.offered_appointment_id;
  
  RETURN json_build_object(
    'success', true,
    'appointment_id', v_appointment_id::TEXT,
    'message', 'Appointment confirmed from waitlist!'
  );
EXCEPTION WHEN OTHERS THEN
  RETURN json_build_object('success', false, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_waitlist_status(p_waitlist_id UUID)
RETURNS JSON AS $$
DECLARE
  v_waitlist RECORD;
  v_position INT;
BEGIN
  SELECT * INTO v_waitlist FROM waitlist WHERE id = p_waitlist_id;
  IF NOT FOUND THEN
    RETURN json_build_object('success', false, 'error', 'Not found');
  END IF;
  
  IF v_waitlist.status = 'waiting' THEN
    SELECT COUNT(*) INTO v_position
    FROM waitlist
    WHERE (doctor_id = v_waitlist.doctor_id OR (doctor_id IS NULL AND v_waitlist.doctor_id IS NULL))
      AND preferred_date = v_waitlist.preferred_date
      AND status = 'waiting'
      AND created_at <= v_waitlist.created_at;
  ELSE
    v_position := 0;
  END IF;
  
  RETURN json_build_object('success', true, 'waitlist', row_to_json(v_waitlist), 'position', v_position);
END;
$$ LANGUAGE plpgsql;

-- Grant permissions
GRANT EXECUTE ON FUNCTION join_waitlist TO anon, authenticated;
GRANT EXECUTE ON FUNCTION accept_waitlist_offer TO anon, authenticated;
GRANT EXECUTE ON FUNCTION get_waitlist_status TO anon, authenticated;

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '====================================================';
  RAISE NOTICE '🎉 WAITLIST SYSTEM INSTALLED SUCCESSFULLY!';
  RAISE NOTICE '====================================================';
  RAISE NOTICE '';
END $$;
