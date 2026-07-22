-- ================================================
-- TOTP (Two-Factor Authentication) Schema - CLEAN VERSION
-- Drops existing objects before creating new ones
-- ================================================

-- Drop existing policies
DROP POLICY IF EXISTS user_2fa_settings_policy ON user_2fa_settings;
DROP POLICY IF EXISTS trusted_devices_policy ON trusted_devices;
DROP POLICY IF EXISTS totp_audit_log_policy ON totp_audit_log;

-- Drop existing functions
DROP FUNCTION IF EXISTS check_totp_reauth_required(UUID);
DROP FUNCTION IF EXISTS update_totp_last_used(UUID);
DROP FUNCTION IF EXISTS is_device_trusted(UUID, TEXT);
DROP FUNCTION IF EXISTS increment_totp_failed_attempts(UUID, TEXT);
DROP FUNCTION IF EXISTS reset_totp_failed_attempts(UUID, TEXT);
DROP FUNCTION IF EXISTS trust_device(UUID, TEXT, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS revoke_device_trust(UUID, UUID);

-- Drop existing tables
DROP TABLE IF EXISTS totp_audit_log CASCADE;
DROP TABLE IF EXISTS totp_failed_attempts CASCADE;
DROP TABLE IF EXISTS trusted_devices CASCADE;
DROP TABLE IF EXISTS user_2fa_settings CASCADE;

-- ================================================
-- Create Tables
-- ================================================

-- 2FA Settings table
CREATE TABLE user_2fa_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  totp_secret TEXT NOT NULL,
  totp_enabled BOOLEAN DEFAULT TRUE,
  backup_codes TEXT[],
  backup_codes_used INTEGER DEFAULT 0,
  setup_completed_at TIMESTAMPTZ DEFAULT NOW(),
  last_used_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Trusted devices
CREATE TABLE trusted_devices (
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

-- Failed TOTP attempts
CREATE TABLE totp_failed_attempts (
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
CREATE TABLE totp_audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  event_type TEXT NOT NULL,
  ip_address TEXT,
  user_agent TEXT,
  success BOOLEAN,
  failure_reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes
CREATE INDEX idx_user_2fa_settings ON user_2fa_settings(user_id, totp_enabled);
CREATE INDEX idx_trusted_devices_user ON trusted_devices(user_id, trusted, expires_at);
CREATE INDEX idx_totp_failed_attempts ON totp_failed_attempts(user_id, locked_until);
CREATE INDEX idx_totp_audit_log ON totp_audit_log(user_id, created_at DESC);

-- ================================================
-- Functions
-- ================================================

-- Check if user needs to re-setup TOTP (inactive for 15+ days)
CREATE FUNCTION check_totp_reauth_required(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_last_used TIMESTAMPTZ;
  v_days_inactive INTEGER;
BEGIN
  SELECT last_used_at INTO v_last_used
  FROM user_2fa_settings
  WHERE user_id = p_user_id AND totp_enabled = TRUE;
  
  IF v_last_used IS NULL THEN
    RETURN TRUE;
  END IF;
  
  v_days_inactive := EXTRACT(DAY FROM NOW() - v_last_used);
  
  RETURN v_days_inactive >= 15;
END;
$$;

-- Update last used timestamp
CREATE FUNCTION update_totp_last_used(p_user_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE user_2fa_settings
  SET last_used_at = NOW(),
      updated_at = NOW()
  WHERE user_id = p_user_id;
END;
$$;

-- Check if device is trusted
CREATE FUNCTION is_device_trusted(
  p_user_id UUID,
  p_device_fingerprint TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
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
  
  IF v_expires_at < NOW() THEN
    UPDATE trusted_devices
    SET trusted = FALSE
    WHERE user_id = p_user_id AND device_fingerprint = p_device_fingerprint;
    RETURN FALSE;
  END IF;
  
  UPDATE trusted_devices
  SET last_active_at = NOW()
  WHERE user_id = p_user_id AND device_fingerprint = p_device_fingerprint;
  
  RETURN TRUE;
END;
$$;

-- Increment failed TOTP attempts
CREATE FUNCTION increment_totp_failed_attempts(
  p_user_id UUID,
  p_ip_address TEXT
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_attempt_count INTEGER;
  v_locked_until TIMESTAMPTZ;
BEGIN
  SELECT attempt_count, locked_until INTO v_attempt_count, v_locked_until
  FROM totp_failed_attempts
  WHERE user_id = p_user_id AND ip_address = p_ip_address;
  
  IF v_locked_until IS NOT NULL AND v_locked_until > NOW() THEN
    RETURN json_build_object(
      'locked', TRUE,
      'locked_until', v_locked_until,
      'attempts', v_attempt_count
    );
  END IF;
  
  IF v_attempt_count IS NULL THEN
    INSERT INTO totp_failed_attempts (user_id, ip_address, attempt_count)
    VALUES (p_user_id, p_ip_address, 1);
    
    RETURN json_build_object('locked', FALSE, 'attempts', 1);
  ELSE
    v_attempt_count := v_attempt_count + 1;
    
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
$$;

-- Reset failed attempts
CREATE FUNCTION reset_totp_failed_attempts(
  p_user_id UUID,
  p_ip_address TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  DELETE FROM totp_failed_attempts
  WHERE user_id = p_user_id AND ip_address = p_ip_address;
END;
$$;

-- Trust a device
CREATE FUNCTION trust_device(
  p_user_id UUID,
  p_device_fingerprint TEXT,
  p_device_name TEXT,
  p_ip_address TEXT,
  p_user_agent TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
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
  
  INSERT INTO totp_audit_log (user_id, event_type, ip_address, user_agent, success)
  VALUES (p_user_id, 'device_trusted', p_ip_address, p_user_agent, TRUE);
  
  RETURN v_device_id;
END;
$$;

-- Revoke device trust
CREATE FUNCTION revoke_device_trust(
  p_user_id UUID,
  p_device_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE trusted_devices
  SET trusted = FALSE
  WHERE id = p_device_id AND user_id = p_user_id;
  
  RETURN FOUND;
END;
$$;

-- ================================================
-- Enable RLS
-- ================================================

ALTER TABLE user_2fa_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE trusted_devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE totp_failed_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE totp_audit_log ENABLE ROW LEVEL SECURITY;

-- ================================================
-- Create Policies
-- ================================================

CREATE POLICY user_2fa_settings_policy ON user_2fa_settings
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY trusted_devices_policy ON trusted_devices
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY totp_audit_log_policy ON totp_audit_log
  FOR SELECT USING (auth.uid() = user_id);

-- ================================================
-- Comments
-- ================================================

COMMENT ON TABLE user_2fa_settings IS '2FA settings for users with TOTP secrets';
COMMENT ON TABLE trusted_devices IS 'Devices trusted for 30 days to skip TOTP';
COMMENT ON TABLE totp_failed_attempts IS 'Rate limiting for TOTP attempts';
COMMENT ON TABLE totp_audit_log IS 'Audit trail for all 2FA events';

-- ================================================
-- Success Message
-- ================================================

DO $$
BEGIN
  RAISE NOTICE '✅ TOTP schema created successfully!';
  RAISE NOTICE '📋 Tables created: user_2fa_settings, trusted_devices, totp_failed_attempts, totp_audit_log';
  RAISE NOTICE '⚙️  Functions created: 7 TOTP functions';
  RAISE NOTICE '🔒 RLS policies enabled';
END $$;
