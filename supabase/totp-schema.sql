-- ================================================
-- TOTP (Two-Factor Authentication) Schema
-- ================================================

-- 2FA Settings table
CREATE TABLE IF NOT EXISTS user_2fa_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  totp_secret TEXT NOT NULL, -- Base32 encoded secret
  totp_enabled BOOLEAN DEFAULT TRUE,
  backup_codes TEXT[], -- Array of hashed backup codes
  backup_codes_used INTEGER DEFAULT 0,
  setup_completed_at TIMESTAMPTZ DEFAULT NOW(),
  last_used_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Trusted devices (30-day trusted period)
CREATE TABLE IF NOT EXISTS trusted_devices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  device_fingerprint TEXT NOT NULL,
  device_name TEXT,
  ip_address TEXT,
  user_agent TEXT,
  last_active_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '30 days',
  trusted BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, device_fingerprint)
);

-- Failed TOTP attempts (rate limiting)
CREATE TABLE IF NOT EXISTS totp_failed_attempts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  ip_address TEXT,
  attempt_count INTEGER DEFAULT 1,
  locked_until TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, ip_address)
);

-- TOTP audit log
CREATE TABLE IF NOT EXISTS totp_audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  event_type TEXT NOT NULL, -- 'setup', 'login_success', 'login_failure', 'disabled', 'backup_used', 'device_trusted'
  ip_address TEXT,
  user_agent TEXT,
  success BOOLEAN,
  failure_reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_user_2fa_settings ON user_2fa_settings(user_id, totp_enabled);
CREATE INDEX IF NOT EXISTS idx_trusted_devices_user ON trusted_devices(user_id, trusted, expires_at);
CREATE INDEX IF NOT EXISTS idx_totp_failed_attempts ON totp_failed_attempts(user_id, locked_until);
CREATE INDEX IF NOT EXISTS idx_totp_audit_log ON totp_audit_log(user_id, created_at DESC);

-- ================================================
-- Functions
-- ================================================

-- Check if user needs to re-setup TOTP (inactive for 15+ days)
CREATE OR REPLACE FUNCTION check_totp_reauth_required(p_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_last_used TIMESTAMPTZ;
  v_days_inactive INTEGER;
BEGIN
  SELECT last_used_at INTO v_last_used
  FROM user_2fa_settings
  WHERE user_id = p_user_id AND totp_enabled = TRUE;
  
  IF v_last_used IS NULL THEN
    RETURN TRUE; -- No TOTP setup, needs setup
  END IF;
  
  v_days_inactive := EXTRACT(DAY FROM NOW() - v_last_used);
  
  -- If inactive for 15+ days, require re-auth
  RETURN v_days_inactive >= 15;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update last used timestamp
CREATE OR REPLACE FUNCTION update_totp_last_used(p_user_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE user_2fa_settings
  SET last_used_at = NOW(),
      updated_at = NOW()
  WHERE user_id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check if device is trusted and not expired
CREATE OR REPLACE FUNCTION is_device_trusted(
  p_user_id UUID,
  p_device_fingerprint TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
  v_trusted BOOLEAN;
  v_expires_at TIMESTAMPTZ;
BEGIN
  SELECT trusted, expires_at INTO v_trusted, v_expires_at
  FROM trusted_devices
  WHERE user_id = p_user_id
    AND device_fingerprint = p_device_fingerprint
    AND trusted = TRUE;
  
  IF v_trusted IS NULL THEN
    RETURN FALSE;
  END IF;
  
  -- Check if expired
  IF v_expires_at < NOW() THEN
    -- Expire the device
    UPDATE trusted_devices
    SET trusted = FALSE
    WHERE user_id = p_user_id AND device_fingerprint = p_device_fingerprint;
    RETURN FALSE;
  END IF;
  
  -- Update last active
  UPDATE trusted_devices
  SET last_active_at = NOW()
  WHERE user_id = p_user_id AND device_fingerprint = p_device_fingerprint;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Increment failed TOTP attempts
CREATE OR REPLACE FUNCTION increment_totp_failed_attempts(
  p_user_id UUID,
  p_ip_address TEXT
)
RETURNS JSON AS $$
DECLARE
  v_attempt_count INTEGER;
  v_locked_until TIMESTAMPTZ;
BEGIN
  -- Check existing attempts
  SELECT attempt_count, locked_until INTO v_attempt_count, v_locked_until
  FROM totp_failed_attempts
  WHERE user_id = p_user_id AND ip_address = p_ip_address;
  
  -- Check if currently locked
  IF v_locked_until IS NOT NULL AND v_locked_until > NOW() THEN
    RETURN json_build_object(
      'locked', TRUE,
      'locked_until', v_locked_until,
      'attempts', v_attempt_count
    );
  END IF;
  
  IF v_attempt_count IS NULL THEN
    -- First failed attempt
    INSERT INTO totp_failed_attempts (user_id, ip_address, attempt_count)
    VALUES (p_user_id, p_ip_address, 1);
    
    RETURN json_build_object('locked', FALSE, 'attempts', 1);
  ELSE
    v_attempt_count := v_attempt_count + 1;
    
    -- Lock after 5 failed attempts
    IF v_attempt_count >= 5 THEN
      v_locked_until := NOW() + INTERVAL '15 minutes';
      
      UPDATE totp_failed_attempts
      SET attempt_count = v_attempt_count,
          locked_until = v_locked_until,
          updated_at = NOW()
      WHERE user_id = p_user_id AND ip_address = p_ip_address;
      
      RETURN json_build_object(
        'locked', TRUE,
        'locked_until', v_locked_until,
        'attempts', v_attempt_count
      );
    ELSE
      UPDATE totp_failed_attempts
      SET attempt_count = v_attempt_count,
          updated_at = NOW()
      WHERE user_id = p_user_id AND ip_address = p_ip_address;
      
      RETURN json_build_object('locked', FALSE, 'attempts', v_attempt_count);
    END IF;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Reset failed attempts on successful login
CREATE OR REPLACE FUNCTION reset_totp_failed_attempts(
  p_user_id UUID,
  p_ip_address TEXT
)
RETURNS VOID AS $$
BEGIN
  DELETE FROM totp_failed_attempts
  WHERE user_id = p_user_id AND ip_address = p_ip_address;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trust a device for 30 days
CREATE OR REPLACE FUNCTION trust_device(
  p_user_id UUID,
  p_device_fingerprint TEXT,
  p_device_name TEXT,
  p_ip_address TEXT,
  p_user_agent TEXT
)
RETURNS UUID AS $$
DECLARE
  v_device_id UUID;
BEGIN
  INSERT INTO trusted_devices (
    user_id,
    device_fingerprint,
    device_name,
    ip_address,
    user_agent,
    expires_at
  ) VALUES (
    p_user_id,
    p_device_fingerprint,
    p_device_name,
    p_ip_address,
    p_user_agent,
    NOW() + INTERVAL '30 days'
  )
  ON CONFLICT (user_id, device_fingerprint)
  DO UPDATE SET
    last_active_at = NOW(),
    expires_at = NOW() + INTERVAL '30 days',
    trusted = TRUE
  RETURNING id INTO v_device_id;
  
  -- Log event
  INSERT INTO totp_audit_log (user_id, event_type, ip_address, user_agent, success)
  VALUES (p_user_id, 'device_trusted', p_ip_address, p_user_agent, TRUE);
  
  RETURN v_device_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Revoke device trust
CREATE OR REPLACE FUNCTION revoke_device_trust(
  p_user_id UUID,
  p_device_id UUID
)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE trusted_devices
  SET trusted = FALSE
  WHERE id = p_device_id AND user_id = p_user_id;
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ================================================
-- Enable RLS (Row Level Security)
-- ================================================

ALTER TABLE user_2fa_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE trusted_devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE totp_failed_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE totp_audit_log ENABLE ROW LEVEL SECURITY;

-- Policies: Users can only access their own data
CREATE POLICY user_2fa_settings_policy ON user_2fa_settings
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY trusted_devices_policy ON trusted_devices
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY totp_audit_log_policy ON totp_audit_log
  FOR SELECT USING (auth.uid() = user_id);

-- Admin can view all (optional - add admin check)
-- CREATE POLICY admin_view_all ON user_2fa_settings
--   FOR SELECT USING (
--     EXISTS (
--       SELECT 1 FROM profiles 
--       WHERE id = auth.uid() AND role = 'admin'
--     )
--   );

COMMENT ON TABLE user_2fa_settings IS '2FA settings for users with TOTP secrets';
COMMENT ON TABLE trusted_devices IS 'Devices trusted for 30 days to skip TOTP';
COMMENT ON TABLE totp_failed_attempts IS 'Rate limiting for TOTP attempts';
COMMENT ON TABLE totp_audit_log IS 'Audit trail for all 2FA events';
