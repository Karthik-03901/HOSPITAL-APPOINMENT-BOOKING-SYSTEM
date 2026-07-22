-- =====================================================
-- NO-SHOW RISK FLAG SYSTEM
-- =====================================================
-- Rule-based system to predict and prevent no-shows
-- Flags high-risk patients for extra reminders

-- =====================================================
-- Step 1: Add Risk Fields to Appointments
-- =====================================================

-- Add no-show risk fields to appointments table
ALTER TABLE appointments 
ADD COLUMN IF NOT EXISTS no_show_risk TEXT DEFAULT 'LOW' CHECK (no_show_risk IN ('LOW', 'MEDIUM', 'HIGH'));

ALTER TABLE appointments 
ADD COLUMN IF NOT EXISTS risk_score INT DEFAULT 0;

ALTER TABLE appointments 
ADD COLUMN IF NOT EXISTS risk_factors JSONB DEFAULT '[]'::jsonb;

-- Create index for risk queries
CREATE INDEX IF NOT EXISTS idx_appointments_risk ON appointments(no_show_risk) WHERE no_show_risk IN ('MEDIUM', 'HIGH');

-- =====================================================
-- Step 2: Patient History Table
-- =====================================================

-- Track patient no-show history
CREATE TABLE IF NOT EXISTS patient_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_email TEXT NOT NULL,
  total_appointments INT DEFAULT 0,
  completed_appointments INT DEFAULT 0,
  no_show_count INT DEFAULT 0,
  cancelled_count INT DEFAULT 0,
  last_no_show_date DATE,
  last_appointment_date DATE,
  reliability_score NUMERIC(3,2) DEFAULT 1.00, -- 0.00 to 1.00
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(patient_email)
);

-- Create index
CREATE INDEX IF NOT EXISTS idx_patient_history_email ON patient_history(patient_email);
CREATE INDEX IF NOT EXISTS idx_patient_history_score ON patient_history(reliability_score);

-- =====================================================
-- Step 3: Risk Calculation Function
-- =====================================================

-- Function to calculate no-show risk based on rules
CREATE OR REPLACE FUNCTION calculate_no_show_risk(
  p_patient_email TEXT,
  p_appointment_date DATE,
  p_appointment_time TIME,
  p_department TEXT DEFAULT NULL
)
RETURNS TABLE(
  risk_level TEXT,
  risk_score INT,
  risk_factors JSONB
) AS $$
DECLARE
  v_no_show_count INT := 0;
  v_total_appointments INT := 0;
  v_last_no_show_date DATE;
  v_reliability_score NUMERIC;
  v_score INT := 0;
  v_factors JSONB := '[]'::jsonb;
  v_days_until_appointment INT;
  v_is_weekend BOOLEAN;
  v_is_early_morning BOOLEAN;
  v_booking_lead_time INT;
BEGIN
  -- Get patient history
  SELECT 
    COALESCE(no_show_count, 0),
    COALESCE(total_appointments, 0),
    last_no_show_date,
    COALESCE(reliability_score, 1.00)
  INTO 
    v_no_show_count,
    v_total_appointments,
    v_last_no_show_date,
    v_reliability_score
  FROM patient_history
  WHERE patient_email = p_patient_email;

  -- Calculate days until appointment
  v_days_until_appointment := p_appointment_date - CURRENT_DATE;
  
  -- Check if weekend
  v_is_weekend := EXTRACT(DOW FROM p_appointment_date) IN (0, 6);
  
  -- Check if early morning (before 9 AM)
  v_is_early_morning := p_appointment_time < '09:00:00';
  
  -- Calculate booking lead time (how far in advance)
  v_booking_lead_time := v_days_until_appointment;

  -- =====================================================
  -- RULE 1: Historical No-Shows (Weight: 40 points)
  -- =====================================================
  
  IF v_no_show_count >= 3 THEN
    v_score := v_score + 40;
    v_factors := v_factors || jsonb_build_object(
      'factor', 'Multiple No-Shows',
      'detail', format('%s no-shows in history', v_no_show_count),
      'weight', 40
    );
  ELSIF v_no_show_count = 2 THEN
    v_score := v_score + 25;
    v_factors := v_factors || jsonb_build_object(
      'factor', 'Recent No-Shows',
      'detail', '2 no-shows in past 6 months',
      'weight', 25
    );
  ELSIF v_no_show_count = 1 AND v_total_appointments < 5 THEN
    v_score := v_score + 15;
    v_factors := v_factors || jsonb_build_object(
      'factor', 'One No-Show',
      'detail', 'Limited history with 1 no-show',
      'weight', 15
    );
  END IF;

  -- =====================================================
  -- RULE 2: Recent No-Show (Weight: 20 points)
  -- =====================================================
  
  IF v_last_no_show_date IS NOT NULL AND 
     v_last_no_show_date > CURRENT_DATE - INTERVAL '60 days' THEN
    v_score := v_score + 20;
    v_factors := v_factors || jsonb_build_object(
      'factor', 'Recent No-Show',
      'detail', format('Last no-show was %s days ago', CURRENT_DATE - v_last_no_show_date),
      'weight', 20
    );
  END IF;

  -- =====================================================
  -- RULE 3: Reliability Score (Weight: 15 points)
  -- =====================================================
  
  IF v_reliability_score < 0.70 THEN
    v_score := v_score + 15;
    v_factors := v_factors || jsonb_build_object(
      'factor', 'Low Reliability',
      'detail', format('Reliability score: %.0f%%', v_reliability_score * 100),
      'weight', 15
    );
  ELSIF v_reliability_score < 0.85 THEN
    v_score := v_score + 8;
    v_factors := v_factors || jsonb_build_object(
      'factor', 'Below Average Reliability',
      'detail', format('Reliability score: %.0f%%', v_reliability_score * 100),
      'weight', 8
    );
  END IF;

  -- =====================================================
  -- RULE 4: New Patient (Weight: 10 points)
  -- =====================================================
  
  IF v_total_appointments = 0 THEN
    v_score := v_score + 10;
    v_factors := v_factors || jsonb_build_object(
      'factor', 'New Patient',
      'detail', 'First appointment with hospital',
      'weight', 10
    );
  END IF;

  -- =====================================================
  -- RULE 5: Same-Day/Next-Day Booking (Weight: 10 points)
  -- =====================================================
  
  IF v_booking_lead_time <= 1 THEN
    v_score := v_score + 10;
    v_factors := v_factors || jsonb_build_object(
      'factor', 'Last-Minute Booking',
      'detail', format('Booked %s days in advance', v_booking_lead_time),
      'weight', 10
    );
  END IF;

  -- =====================================================
  -- RULE 6: Weekend Appointment (Weight: 5 points)
  -- =====================================================
  
  IF v_is_weekend THEN
    v_score := v_score + 5;
    v_factors := v_factors || jsonb_build_object(
      'factor', 'Weekend Appointment',
      'detail', 'Appointments on weekends have higher no-show rates',
      'weight', 5
    );
  END IF;

  -- =====================================================
  -- RULE 7: Early Morning (Weight: 5 points)
  -- =====================================================
  
  IF v_is_early_morning THEN
    v_score := v_score + 5;
    v_factors := v_factors || jsonb_build_object(
      'factor', 'Early Morning Slot',
      'detail', format('Appointment before 9 AM (%s)', p_appointment_time),
      'weight', 5
    );
  END IF;

  -- =====================================================
  -- Determine Risk Level
  -- =====================================================
  
  IF v_score >= 50 THEN
    risk_level := 'HIGH';
  ELSIF v_score >= 25 THEN
    risk_level := 'MEDIUM';
  ELSE
    risk_level := 'LOW';
  END IF;

  risk_score := v_score;
  risk_factors := v_factors;

  RETURN NEXT;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Step 4: Auto-Flag Trigger
-- =====================================================

-- Trigger to automatically calculate risk on appointment creation
CREATE OR REPLACE FUNCTION flag_no_show_risk()
RETURNS TRIGGER AS $$
DECLARE
  v_risk RECORD;
BEGIN
  -- Calculate risk
  SELECT * INTO v_risk
  FROM calculate_no_show_risk(
    NEW.patient_email,
    NEW.appointment_date,
    NEW.appointment_time,
    NEW.department_name
  );

  -- Set risk fields
  NEW.no_show_risk := v_risk.risk_level;
  NEW.risk_score := v_risk.risk_score;
  NEW.risk_factors := v_risk.risk_factors;

  -- Log high-risk appointments
  IF v_risk.risk_level = 'HIGH' THEN
    RAISE NOTICE '⚠️  HIGH RISK APPOINTMENT: Patient %, Score: %, Factors: %', 
      NEW.patient_email, v_risk.risk_score, v_risk.risk_factors;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS trigger_flag_no_show_risk ON appointments;
CREATE TRIGGER trigger_flag_no_show_risk
  BEFORE INSERT OR UPDATE OF patient_email, appointment_date, appointment_time
  ON appointments
  FOR EACH ROW
  EXECUTE FUNCTION flag_no_show_risk();

-- =====================================================
-- Step 5: Update Patient History
-- =====================================================

-- Function to update patient history after appointment
CREATE OR REPLACE FUNCTION update_patient_history()
RETURNS TRIGGER AS $$
DECLARE
  v_completed INT;
  v_no_shows INT;
  v_total INT;
  v_reliability NUMERIC;
BEGIN
  -- Only process completed or no-show appointments
  IF NEW.status IN ('completed', 'no_show') AND OLD.status != NEW.status THEN
    
    -- Upsert patient history
    INSERT INTO patient_history (
      patient_email,
      total_appointments,
      completed_appointments,
      no_show_count,
      last_no_show_date,
      last_appointment_date
    ) VALUES (
      NEW.patient_email,
      1,
      CASE WHEN NEW.status = 'completed' THEN 1 ELSE 0 END,
      CASE WHEN NEW.status = 'no_show' THEN 1 ELSE 0 END,
      CASE WHEN NEW.status = 'no_show' THEN NEW.appointment_date ELSE NULL END,
      NEW.appointment_date
    )
    ON CONFLICT (patient_email) DO UPDATE SET
      total_appointments = patient_history.total_appointments + 1,
      completed_appointments = patient_history.completed_appointments + 
        CASE WHEN NEW.status = 'completed' THEN 1 ELSE 0 END,
      no_show_count = patient_history.no_show_count + 
        CASE WHEN NEW.status = 'no_show' THEN 1 ELSE 0 END,
      last_no_show_date = CASE 
        WHEN NEW.status = 'no_show' THEN NEW.appointment_date 
        ELSE patient_history.last_no_show_date 
      END,
      last_appointment_date = NEW.appointment_date,
      updated_at = NOW();

    -- Calculate reliability score
    SELECT 
      completed_appointments,
      no_show_count,
      total_appointments
    INTO v_completed, v_no_shows, v_total
    FROM patient_history
    WHERE patient_email = NEW.patient_email;

    -- Reliability = (completed / total) with penalty for no-shows
    v_reliability := CASE 
      WHEN v_total > 0 THEN 
        GREATEST(0, (v_completed::NUMERIC / v_total) - (v_no_shows::NUMERIC * 0.15))
      ELSE 1.00 
    END;

    UPDATE patient_history
    SET reliability_score = v_reliability
    WHERE patient_email = NEW.patient_email;

    RAISE NOTICE 'Updated history for %: Reliability %.2f, No-shows: %', 
      NEW.patient_email, v_reliability, v_no_shows;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS trigger_update_patient_history ON appointments;
CREATE TRIGGER trigger_update_patient_history
  AFTER UPDATE ON appointments
  FOR EACH ROW
  EXECUTE FUNCTION update_patient_history();

-- =====================================================
-- Step 6: RPC Functions for Frontend
-- =====================================================

-- Get high-risk appointments for admin dashboard
CREATE OR REPLACE FUNCTION get_high_risk_appointments(p_date DATE DEFAULT CURRENT_DATE)
RETURNS TABLE(
  id UUID,
  patient_email TEXT,
  patient_name TEXT,
  token_number TEXT,
  appointment_time TIME,
  department_name TEXT,
  risk_level TEXT,
  risk_score INT,
  risk_factors JSONB
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    a.id,
    a.patient_email,
    a.patient_name,
    a.token_number,
    a.appointment_time,
    a.department_name,
    a.no_show_risk,
    a.risk_score,
    a.risk_factors
  FROM appointments a
  WHERE a.appointment_date = p_date
    AND a.no_show_risk IN ('MEDIUM', 'HIGH')
    AND a.status IN ('pending', 'confirmed')
  ORDER BY a.risk_score DESC, a.appointment_time;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get patient reliability report
CREATE OR REPLACE FUNCTION get_patient_reliability(p_email TEXT)
RETURNS JSON AS $$
DECLARE
  v_history RECORD;
  v_recent_appointments INT;
BEGIN
  SELECT * INTO v_history
  FROM patient_history
  WHERE patient_email = p_email;

  IF NOT FOUND THEN
    RETURN json_build_object(
      'found', false,
      'message', 'No history found'
    );
  END IF;

  -- Count recent appointments (last 6 months)
  SELECT COUNT(*) INTO v_recent_appointments
  FROM appointments
  WHERE patient_email = p_email
    AND appointment_date > CURRENT_DATE - INTERVAL '6 months';

  RETURN json_build_object(
    'found', true,
    'total_appointments', v_history.total_appointments,
    'completed', v_history.completed_appointments,
    'no_shows', v_history.no_show_count,
    'cancelled', v_history.cancelled_count,
    'reliability_score', v_history.reliability_score,
    'reliability_percentage', ROUND(v_history.reliability_score * 100, 0),
    'last_no_show', v_history.last_no_show_date,
    'recent_appointments_6m', v_recent_appointments,
    'rating', CASE 
      WHEN v_history.reliability_score >= 0.95 THEN 'Excellent'
      WHEN v_history.reliability_score >= 0.85 THEN 'Good'
      WHEN v_history.reliability_score >= 0.70 THEN 'Fair'
      ELSE 'Poor'
    END
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- Success Message
-- =====================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '============================================';
  RAISE NOTICE '✅ No-Show Risk System Complete!';
  RAISE NOTICE '============================================';
  RAISE NOTICE 'Features:';
  RAISE NOTICE '  ✓ Rule-based risk calculation (7 rules)';
  RAISE NOTICE '  ✓ Auto-flagging on booking';
  RAISE NOTICE '  ✓ Patient history tracking';
  RAISE NOTICE '  ✓ Reliability scoring';
  RAISE NOTICE '  ✓ Admin dashboard functions';
  RAISE NOTICE '';
  RAISE NOTICE 'Risk Levels:';
  RAISE NOTICE '  🔴 HIGH (50+ points) - Multiple no-shows';
  RAISE NOTICE '  🟡 MEDIUM (25-49 points) - Some concerns';
  RAISE NOTICE '  🟢 LOW (0-24 points) - Reliable patient';
  RAISE NOTICE '';
  RAISE NOTICE 'Next: Book appointment to see risk flagging!';
  RAISE NOTICE '============================================';
  RAISE NOTICE '';
END $$;
