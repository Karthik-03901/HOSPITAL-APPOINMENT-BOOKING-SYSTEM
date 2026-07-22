-- =====================================================
-- BRUTE FORCE PROTECTION SYSTEM
-- =====================================================
-- This schema implements security measures to prevent brute force attacks:
-- 1. Login attempt tracking
-- 2. Account lockout after failed attempts
-- 3. Rate limiting
-- 4. IP-based blocking
-- 5. Audit logging

-- =====================================================
-- TABLE: login_attempts
-- Tracks all login attempts (successful and failed)
-- =====================================================
CREATE TABLE IF NOT EXISTS login_attempts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- User identification
  email TEXT NOT NULL,
  ip_address INET,
  user_agent TEXT,
  
  -- Attempt details
  attempt_type VARCHAR(20) DEFAULT 'password', -- password, otp, biometric
  status VARCHAR(20) NOT NULL, -- success, failed, blocked
  failure_reason VARCHAR(100), -- wrong_password, account_locked, rate_limited
  
  -- Timestamps
  attempted_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Geolocation (optional)
  country VARCHAR(50),
  city VARCHAR(100),
  
  -- Additional metadata
  metadata JSONB DEFAULT '{}'::JSONB
);

-- =====================================================
-- TABLE: account_locks
-- Manages locked accounts due to failed attempts
-- =====================================================
CREATE TABLE IF NOT EXISTS account_locks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- User identification
  email TEXT NOT NULL UNIQUE,
  
  -- Lock details
  locked_at TIMESTAMPTZ DEFAULT NOW(),
  locked_until TIMESTAMPTZ NOT NULL,
  lock_reason VARCHAR(100) DEFAULT 'too_many_failed_attempts',
  failed_attempts INT DEFAULT 0,
  
  -- Unlock details
  is_locked BOOLEAN DEFAULT TRUE,
  unlocked_at TIMESTAMPTZ,
  unlocked_by TEXT, -- 'auto', 'admin', 'user'
  
  -- Metadata
  metadata JSONB DEFAULT '{}'::JSONB
);

-- =====================================================
-- TABLE: ip_blacklist
-- Blocks malicious IP addresses
-- =====================================================
CREATE TABLE IF NOT EXISTS ip_blacklist (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- IP details
  ip_address INET NOT NULL UNIQUE,
  blocked_at TIMESTAMPTZ DEFAULT NOW(),
  blocked_until TIMESTAMPTZ,
  
  -- Block details
  reason VARCHAR(200),
  failed_attempts INT DEFAULT 0,
  is_permanent BOOLEAN DEFAULT FALSE,
  
  -- Unblock details
  is_blocked BOOLEAN DEFAULT TRUE,
  unblocked_at TIMESTAMPTZ,
  unblocked_by TEXT
);

-- =====================================================
-- TABLE: security_audit_log
-- Comprehensive security event logging
-- =====================================================
CREATE TABLE IF NOT EXISTS security_audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Event details
  event_type VARCHAR(50) NOT NULL, -- login_failed, login_success, account_locked, ip_blocked
  severity VARCHAR(20) DEFAULT 'info', -- info, warning, critical
  
  -- User identification
  email TEXT,
  ip_address INET,
  
  -- Event data
  description TEXT,
  metadata JSONB DEFAULT '{}'::JSONB,
  
  -- Timestamp
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- INDEXES for performance
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_login_attempts_email ON login_attempts(email);
CREATE INDEX IF NOT EXISTS idx_login_attempts_ip ON login_attempts(ip_address);
CREATE INDEX IF NOT EXISTS idx_login_attempts_attempted_at ON login_attempts(attempted_at DESC);
CREATE INDEX IF NOT EXISTS idx_login_attempts_status ON login_attempts(status);

CREATE INDEX IF NOT EXISTS idx_account_locks_email ON account_locks(email);
CREATE INDEX IF NOT EXISTS idx_account_locks_locked_until ON account_locks(locked_until);
CREATE INDEX IF NOT EXISTS idx_account_locks_is_locked ON account_locks(is_locked);

CREATE INDEX IF NOT EXISTS idx_ip_blacklist_ip ON ip_blacklist(ip_address);
CREATE INDEX IF NOT EXISTS idx_ip_blacklist_is_blocked ON ip_blacklist(is_blocked);

CREATE INDEX IF NOT EXISTS idx_security_audit_event_type ON security_audit_log(event_type);
CREATE INDEX IF NOT EXISTS idx_security_audit_created_at ON security_audit_log(created_at DESC);

-- =====================================================
-- CONFIGURATION TABLE
-- Stores security settings
-- =====================================================
CREATE TABLE IF NOT EXISTS security_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key VARCHAR(100) UNIQUE NOT NULL,
  value TEXT NOT NULL,
  description TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default security settings
INSERT INTO security_config (key, value, description) VALUES
  ('max_failed_attempts', '5', 'Maximum failed login attempts before lockout'),
  ('lockout_duration_minutes', '30', 'Account lockout duration in minutes'),
  ('rate_limit_per_minute', '10', 'Maximum login attempts per minute per IP'),
  ('ip_ban_threshold', '20', 'Failed attempts before IP ban'),
  ('ip_ban_duration_minutes', '60', 'IP ban duration in minutes'),
  ('require_captcha_after_attempts', '3', 'Show CAPTCHA after N failed attempts'),
  ('permanent_ban_threshold', '50', 'Failed attempts before permanent IP ban')
ON CONFLICT (key) DO NOTHING;

-- =====================================================
-- RPC FUNCTION: check_login_allowed
-- Checks if user can attempt login
-- =====================================================
CREATE OR REPLACE FUNCTION check_login_allowed(
  p_email TEXT,
  p_ip_address INET
)
RETURNS TABLE(
  allowed BOOLEAN,
  reason VARCHAR(100),
  locked_until TIMESTAMPTZ,
  requires_captcha BOOLEAN
) AS $$
DECLARE
  v_account_locked BOOLEAN := FALSE;
  v_ip_blocked BOOLEAN := FALSE;
  v_locked_until TIMESTAMPTZ;
  v_failed_attempts INT := 0;
  v_captcha_threshold INT;
BEGIN
  -- Get CAPTCHA threshold
  SELECT value::INT INTO v_captcha_threshold 
  FROM security_config 
  WHERE key = 'require_captcha_after_attempts';
  
  -- Check if account is locked
  SELECT is_locked, locked_until, failed_attempts
  INTO v_account_locked, v_locked_until, v_failed_attempts
  FROM account_locks
  WHERE email = p_email AND is_locked = TRUE;
  
  IF v_account_locked THEN
    -- Check if lock has expired
    IF v_locked_until < NOW() THEN
      -- Auto-unlock
      UPDATE account_locks
      SET is_locked = FALSE, unlocked_at = NOW(), unlocked_by = 'auto'
      WHERE email = p_email;
      
      v_account_locked := FALSE;
    ELSE
      RETURN QUERY SELECT FALSE, 'account_locked'::VARCHAR, v_locked_until, FALSE;
      RETURN;
    END IF;
  END IF;
  
  -- Check if IP is blocked
  SELECT is_blocked INTO v_ip_blocked
  FROM ip_blacklist
  WHERE ip_address = p_ip_address AND is_blocked = TRUE;
  
  IF v_ip_blocked THEN
    RETURN QUERY SELECT FALSE, 'ip_blocked'::VARCHAR, NULL::TIMESTAMPTZ, FALSE;
    RETURN;
  END IF;
  
  -- Check rate limiting (attempts in last minute)
  SELECT COUNT(*) INTO v_failed_attempts
  FROM login_attempts
  WHERE ip_address = p_ip_address
    AND attempted_at > NOW() - INTERVAL '1 minute';
  
  -- Check if rate limit exceeded
  IF v_failed_attempts >= (SELECT value::INT FROM security_config WHERE key = 'rate_limit_per_minute') THEN
    RETURN QUERY SELECT FALSE, 'rate_limited'::VARCHAR, NULL::TIMESTAMPTZ, FALSE;
    RETURN;
  END IF;
  
  -- Check if CAPTCHA required
  SELECT COUNT(*) INTO v_failed_attempts
  FROM login_attempts
  WHERE email = p_email
    AND status = 'failed'
    AND attempted_at > NOW() - INTERVAL '1 hour';
  
  -- Login allowed
  RETURN QUERY SELECT TRUE, 'allowed'::VARCHAR, NULL::TIMESTAMPTZ, (v_failed_attempts >= v_captcha_threshold);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- RPC FUNCTION: record_login_attempt
-- Records login attempt and handles lockout logic
-- =====================================================
CREATE OR REPLACE FUNCTION record_login_attempt(
  p_email TEXT,
  p_ip_address INET,
  p_user_agent TEXT,
  p_status VARCHAR(20),
  p_failure_reason VARCHAR(100) DEFAULT NULL
)
RETURNS TABLE(
  success BOOLEAN,
  account_locked BOOLEAN,
  locked_until TIMESTAMPTZ,
  message TEXT
) AS $$
DECLARE
  v_max_attempts INT;
  v_lockout_duration INT;
  v_failed_count INT;
  v_ip_failed_count INT;
  v_ip_ban_threshold INT;
  v_locked_until TIMESTAMPTZ;
BEGIN
  -- Get configuration
  SELECT value::INT INTO v_max_attempts 
  FROM security_config WHERE key = 'max_failed_attempts';
  
  SELECT value::INT INTO v_lockout_duration 
  FROM security_config WHERE key = 'lockout_duration_minutes';
  
  SELECT value::INT INTO v_ip_ban_threshold 
  FROM security_config WHERE key = 'ip_ban_threshold';
  
  -- Record the attempt
  INSERT INTO login_attempts (email, ip_address, user_agent, status, failure_reason)
  VALUES (p_email, p_ip_address, p_user_agent, p_status, p_failure_reason);
  
  -- Log to audit
  INSERT INTO security_audit_log (event_type, severity, email, ip_address, description)
  VALUES (
    CASE WHEN p_status = 'success' THEN 'login_success' ELSE 'login_failed' END,
    CASE WHEN p_status = 'success' THEN 'info' ELSE 'warning' END,
    p_email,
    p_ip_address,
    COALESCE(p_failure_reason, 'Login attempt')
  );
  
  -- If successful, clear any locks
  IF p_status = 'success' THEN
    DELETE FROM account_locks WHERE email = p_email;
    RETURN QUERY SELECT TRUE, FALSE, NULL::TIMESTAMPTZ, 'Login successful'::TEXT;
    RETURN;
  END IF;
  
  -- Count recent failed attempts for this email
  SELECT COUNT(*) INTO v_failed_count
  FROM login_attempts
  WHERE email = p_email
    AND status = 'failed'
    AND attempted_at > NOW() - INTERVAL '30 minutes';
  
  -- Lock account if threshold exceeded
  IF v_failed_count >= v_max_attempts THEN
    v_locked_until := NOW() + (v_lockout_duration || ' minutes')::INTERVAL;
    
    INSERT INTO account_locks (email, locked_until, failed_attempts)
    VALUES (p_email, v_locked_until, v_failed_count)
    ON CONFLICT (email) DO UPDATE
    SET locked_until = v_locked_until,
        failed_attempts = v_failed_count,
        is_locked = TRUE,
        locked_at = NOW();
    
    -- Log lockout
    INSERT INTO security_audit_log (event_type, severity, email, ip_address, description)
    VALUES ('account_locked', 'critical', p_email, p_ip_address, 
            'Account locked due to ' || v_failed_count || ' failed attempts');
    
    RETURN QUERY SELECT FALSE, TRUE, v_locked_until, 
                        'Account locked due to too many failed attempts'::TEXT;
    RETURN;
  END IF;
  
  -- Check IP-based failed attempts
  SELECT COUNT(*) INTO v_ip_failed_count
  FROM login_attempts
  WHERE ip_address = p_ip_address
    AND status = 'failed'
    AND attempted_at > NOW() - INTERVAL '1 hour';
  
  -- Block IP if threshold exceeded
  IF v_ip_failed_count >= v_ip_ban_threshold THEN
    INSERT INTO ip_blacklist (ip_address, reason, failed_attempts, blocked_until)
    VALUES (p_ip_address, 'Too many failed attempts', v_ip_failed_count,
            NOW() + INTERVAL '60 minutes')
    ON CONFLICT (ip_address) DO UPDATE
    SET failed_attempts = v_ip_failed_count,
        is_blocked = TRUE,
        blocked_at = NOW();
    
    -- Log IP block
    INSERT INTO security_audit_log (event_type, severity, ip_address, description)
    VALUES ('ip_blocked', 'critical', p_ip_address,
            'IP blocked due to ' || v_ip_failed_count || ' failed attempts');
  END IF;
  
  RETURN QUERY SELECT FALSE, FALSE, NULL::TIMESTAMPTZ, 
                      'Login failed. ' || (v_max_attempts - v_failed_count) || ' attempts remaining'::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- RPC FUNCTION: unlock_account
-- Manually unlock an account (admin function)
-- =====================================================
CREATE OR REPLACE FUNCTION unlock_account(
  p_email TEXT,
  p_unlocked_by TEXT DEFAULT 'admin'
)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE account_locks
  SET is_locked = FALSE,
      unlocked_at = NOW(),
      unlocked_by = p_unlocked_by
  WHERE email = p_email;
  
  -- Log unlock
  INSERT INTO security_audit_log (event_type, severity, email, description)
  VALUES ('account_unlocked', 'info', p_email, 'Account manually unlocked by ' || p_unlocked_by);
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- RPC FUNCTION: get_security_stats
-- Get security statistics for monitoring
-- =====================================================
CREATE OR REPLACE FUNCTION get_security_stats()
RETURNS TABLE(
  total_attempts_today INT,
  failed_attempts_today INT,
  locked_accounts INT,
  blocked_ips INT,
  critical_events_today INT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    (SELECT COUNT(*)::INT FROM login_attempts WHERE DATE(attempted_at) = CURRENT_DATE),
    (SELECT COUNT(*)::INT FROM login_attempts WHERE DATE(attempted_at) = CURRENT_DATE AND status = 'failed'),
    (SELECT COUNT(*)::INT FROM account_locks WHERE is_locked = TRUE),
    (SELECT COUNT(*)::INT FROM ip_blacklist WHERE is_blocked = TRUE),
    (SELECT COUNT(*)::INT FROM security_audit_log WHERE DATE(created_at) = CURRENT_DATE AND severity = 'critical');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- CLEANUP FUNCTION: Auto-expire old records
-- =====================================================
CREATE OR REPLACE FUNCTION cleanup_security_data()
RETURNS VOID AS $$
BEGIN
  -- Delete old login attempts (older than 90 days)
  DELETE FROM login_attempts WHERE attempted_at < NOW() - INTERVAL '90 days';
  
  -- Delete old audit logs (older than 1 year)
  DELETE FROM security_audit_log WHERE created_at < NOW() - INTERVAL '1 year';
  
  -- Auto-unlock expired account locks
  UPDATE account_locks
  SET is_locked = FALSE, unlocked_at = NOW(), unlocked_by = 'auto'
  WHERE is_locked = TRUE AND locked_until < NOW();
  
  -- Auto-unblock expired IP blocks
  UPDATE ip_blacklist
  SET is_blocked = FALSE, unblocked_at = NOW(), unblocked_by = 'auto'
  WHERE is_blocked = TRUE AND is_permanent = FALSE AND blocked_until < NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- Enable RLS
-- =====================================================
ALTER TABLE login_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE account_locks ENABLE ROW LEVEL SECURITY;
ALTER TABLE ip_blacklist ENABLE ROW LEVEL SECURITY;
ALTER TABLE security_audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE security_config ENABLE ROW LEVEL SECURITY;

-- RLS Policies (Admin only for security tables)
CREATE POLICY "Admin full access" ON login_attempts FOR ALL USING (auth.jwt() ->> 'role' = 'admin');
CREATE POLICY "Admin full access" ON account_locks FOR ALL USING (auth.jwt() ->> 'role' = 'admin');
CREATE POLICY "Admin full access" ON ip_blacklist FOR ALL USING (auth.jwt() ->> 'role' = 'admin');
CREATE POLICY "Admin full access" ON security_audit_log FOR ALL USING (auth.jwt() ->> 'role' = 'admin');
CREATE POLICY "Admin full access" ON security_config FOR ALL USING (auth.jwt() ->> 'role' = 'admin');

-- Grant permissions
GRANT SELECT, INSERT ON login_attempts TO anon, authenticated;
GRANT SELECT, INSERT ON security_audit_log TO anon, authenticated;
GRANT EXECUTE ON FUNCTION check_login_allowed TO anon, authenticated;
GRANT EXECUTE ON FUNCTION record_login_attempt TO anon, authenticated;
GRANT EXECUTE ON FUNCTION unlock_account TO authenticated;
GRANT EXECUTE ON FUNCTION get_security_stats TO authenticated;

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ Brute force protection system created successfully!';
  RAISE NOTICE '📝 Security features enabled:';
  RAISE NOTICE '  - Login attempt tracking';
  RAISE NOTICE '  - Account lockout (5 failed attempts, 30min lock)';
  RAISE NOTICE '  - Rate limiting (10 attempts/min per IP)';
  RAISE NOTICE '  - IP blacklisting (20 failed attempts, 60min ban)';
  RAISE NOTICE '  - CAPTCHA trigger (after 3 failed attempts)';
  RAISE NOTICE '  - Comprehensive audit logging';
END $$;
