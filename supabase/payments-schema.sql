-- =====================================================
-- PAYMENTS TABLE SCHEMA FOR RAZORPAY INTEGRATION
-- =====================================================
-- This table stores all payment transactions for appointments
-- Run this SQL in your Supabase SQL Editor

-- Create payments table
CREATE TABLE IF NOT EXISTS payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  appointment_id UUID REFERENCES appointments(id) ON DELETE CASCADE,
  
  -- Payment details
  amount DECIMAL(10, 2) NOT NULL,
  currency VARCHAR(3) DEFAULT 'INR',
  status VARCHAR(50) DEFAULT 'pending', -- pending, success, failed, refunded
  
  -- Razorpay IDs
  razorpay_order_id VARCHAR(255) UNIQUE,
  razorpay_payment_id VARCHAR(255) UNIQUE,
  razorpay_signature VARCHAR(500),
  
  -- User info
  patient_email TEXT NOT NULL,
  patient_name TEXT,
  patient_contact VARCHAR(20),
  
  -- Payment method
  method VARCHAR(50), -- card, netbanking, upi, wallet
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  paid_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Additional metadata (JSON for flexibility)
  metadata JSONB DEFAULT '{}'::JSONB,
  
  -- Error tracking
  error_code VARCHAR(100),
  error_description TEXT
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_payments_appointment ON payments(appointment_id);
CREATE INDEX IF NOT EXISTS idx_payments_patient_email ON payments(patient_email);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);
CREATE INDEX IF NOT EXISTS idx_payments_razorpay_order ON payments(razorpay_order_id);
CREATE INDEX IF NOT EXISTS idx_payments_razorpay_payment ON payments(razorpay_payment_id);
CREATE INDEX IF NOT EXISTS idx_payments_created_at ON payments(created_at DESC);

-- Add payment_status to appointments table
ALTER TABLE appointments 
ADD COLUMN IF NOT EXISTS payment_status VARCHAR(50) DEFAULT 'pending';

-- Add payment_id to appointments table
ALTER TABLE appointments 
ADD COLUMN IF NOT EXISTS payment_id UUID REFERENCES payments(id);

-- Create trigger to update updated_at
CREATE OR REPLACE FUNCTION update_payments_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS payments_updated_at_trigger ON payments;
CREATE TRIGGER payments_updated_at_trigger
  BEFORE UPDATE ON payments
  FOR EACH ROW
  EXECUTE FUNCTION update_payments_updated_at();

-- Helper function to get current user email (CREATE FIRST before RLS policies)
CREATE OR REPLACE FUNCTION current_user_email()
RETURNS TEXT AS $$
BEGIN
  RETURN COALESCE(
    auth.jwt() ->> 'email',
    current_setting('request.jwt.claims', true)::json ->> 'email',
    ''
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enable RLS (Row Level Security)
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

-- RLS Policies for payments table

-- Policy: Users can read their own payments
DROP POLICY IF EXISTS "Users can view own payments" ON payments;
CREATE POLICY "Users can view own payments"
  ON payments
  FOR SELECT
  USING (patient_email = auth.jwt() ->> 'email' OR patient_email = current_user_email());

-- Policy: Anyone can create payments (needed for booking)
DROP POLICY IF EXISTS "Anyone can create payments" ON payments;
CREATE POLICY "Anyone can create payments"
  ON payments
  FOR INSERT
  WITH CHECK (true);

-- Policy: Users can update their own payment status
DROP POLICY IF EXISTS "Users can update own payments" ON payments;
CREATE POLICY "Users can update own payments"
  ON payments
  FOR UPDATE
  USING (patient_email = auth.jwt() ->> 'email' OR patient_email = current_user_email());

-- RPC Function: Create payment record
CREATE OR REPLACE FUNCTION create_payment(
  p_appointment_id UUID,
  p_amount DECIMAL,
  p_currency VARCHAR,
  p_patient_email TEXT,
  p_patient_name TEXT,
  p_patient_contact VARCHAR,
  p_razorpay_order_id VARCHAR
)
RETURNS UUID AS $$
DECLARE
  v_payment_id UUID;
BEGIN
  INSERT INTO payments (
    appointment_id,
    amount,
    currency,
    patient_email,
    patient_name,
    patient_contact,
    razorpay_order_id,
    status
  ) VALUES (
    p_appointment_id,
    p_amount,
    p_currency,
    p_patient_email,
    p_patient_name,
    p_patient_contact,
    p_razorpay_order_id,
    'pending'
  )
  RETURNING id INTO v_payment_id;
  
  -- Update appointment with payment_id
  UPDATE appointments
  SET payment_id = v_payment_id,
      payment_status = 'pending'
  WHERE id = p_appointment_id;
  
  RETURN v_payment_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC Function: Update payment status after Razorpay callback
CREATE OR REPLACE FUNCTION update_payment_status(
  p_razorpay_order_id VARCHAR,
  p_razorpay_payment_id VARCHAR,
  p_razorpay_signature VARCHAR,
  p_status VARCHAR,
  p_method VARCHAR DEFAULT NULL,
  p_error_code VARCHAR DEFAULT NULL,
  p_error_description TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
  v_payment_id UUID;
  v_appointment_id UUID;
BEGIN
  -- Update payment record
  UPDATE payments
  SET 
    razorpay_payment_id = p_razorpay_payment_id,
    razorpay_signature = p_razorpay_signature,
    status = p_status,
    method = COALESCE(p_method, method),
    error_code = p_error_code,
    error_description = p_error_description,
    paid_at = CASE WHEN p_status = 'success' THEN NOW() ELSE paid_at END
  WHERE razorpay_order_id = p_razorpay_order_id
  RETURNING id, appointment_id INTO v_payment_id, v_appointment_id;
  
  -- Update appointment payment status
  IF v_appointment_id IS NOT NULL THEN
    UPDATE appointments
    SET payment_status = p_status
    WHERE id = v_appointment_id;
  END IF;
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC Function: Get payment details by order ID
CREATE OR REPLACE FUNCTION get_payment_by_order_id(p_order_id VARCHAR)
RETURNS TABLE(
  payment_id UUID,
  appointment_id UUID,
  amount DECIMAL,
  currency VARCHAR,
  status VARCHAR,
  razorpay_order_id VARCHAR,
  razorpay_payment_id VARCHAR,
  patient_email TEXT,
  patient_name TEXT,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id,
    p.appointment_id,
    p.amount,
    p.currency,
    p.status,
    p.razorpay_order_id,
    p.razorpay_payment_id,
    p.patient_email,
    p.patient_name,
    p.created_at
  FROM payments p
  WHERE p.razorpay_order_id = p_order_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT SELECT, INSERT, UPDATE ON payments TO anon, authenticated;
GRANT EXECUTE ON FUNCTION create_payment TO anon, authenticated;
GRANT EXECUTE ON FUNCTION update_payment_status TO anon, authenticated;
GRANT EXECUTE ON FUNCTION get_payment_by_order_id TO anon, authenticated;
GRANT EXECUTE ON FUNCTION current_user_email TO anon, authenticated;

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ Payments table and RPC functions created successfully!';
  RAISE NOTICE '📝 Next steps:';
  RAISE NOTICE '1. Add your Razorpay keys to .env file';
  RAISE NOTICE '2. Test payment flow in booking page';
  RAISE NOTICE '3. Verify payments table in Supabase dashboard';
END $$;
