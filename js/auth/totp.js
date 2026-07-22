/**
 * TOTP (Two-Factor Authentication) Module
 * Uses otplib for TOTP generation/verification and qrcode for QR code display
 */

import * as OTPAuth from 'https://esm.sh/otplib@12.0.1';
import QRCode from 'https://esm.sh/qrcode@1.5.3';
import { supabase } from '../supabaseClient.js';
import { toast } from '../components/Toast.js';

const authenticator = OTPAuth.authenticator;

class TOTPManager {
  constructor() {
    this.secret = null;
    this.backupCodes = [];
    
    // Configure TOTP options
    authenticator.options = {
      step: 30,      // 30-second time window
      window: 1,     // Allow ±1 time step for clock drift
      digits: 6      // 6-digit codes
    };
  }

  /**
   * Check if user needs TOTP setup or re-auth
   */
  async checkTOTPStatus(userId) {
    try {
      // Check if TOTP is enabled
      const { data: settings, error } = await supabase
        .from('user_2fa_settings')
        .select('totp_enabled, last_used_at')
        .eq('user_id', userId)
        .single();

      if (error && error.code !== 'PGRST116') {
        throw error;
      }

      // No TOTP setup
      if (!settings) {
        return { required: true, reason: 'not_setup' };
      }

      // Check if inactive for 15+ days
      const { data: reauthRequired } = await supabase
        .rpc('check_totp_reauth_required', { p_user_id: userId });

      if (reauthRequired) {
        return { required: true, reason: 'inactive_15_days' };
      }

      // Check if device is trusted
      const deviceFingerprint = await this.generateDeviceFingerprint();
      const { data: isTrusted } = await supabase
        .rpc('is_device_trusted', {
          p_user_id: userId,
          p_device_fingerprint: deviceFingerprint
        });

      if (isTrusted) {
        return { required: false, reason: 'trusted_device' };
      }

      return { required: true, reason: 'totp_enabled' };
    } catch (error) {
      console.error('Error checking TOTP status:', error);
      return { required: true, reason: 'error' };
    }
  }

  /**
   * Generate a new TOTP secret
   */
  generateSecret() {
    this.secret = authenticator.generateSecret();
    return this.secret;
  }

  /**
   * Generate QR code for authenticator apps
   */
  async generateQRCode(email) {
    if (!this.secret) {
      throw new Error('Secret not generated. Call generateSecret() first.');
    }

    const otpauthUrl = authenticator.keyuri(
      email,
      'MediQueue',
      this.secret
    );

    const qrCodeDataURL = await QRCode.toDataURL(otpauthUrl, {
      width: 300,
      margin: 2,
      color: {
        dark: '#0E9384',
        light: '#FFFFFF'
      }
    });

    return { qrCodeDataURL, otpauthUrl, secret: this.secret };
  }

  /**
   * Verify TOTP token
   */
  verifyToken(token, secret) {
    try {
      return authenticator.verify({ token, secret });
    } catch (error) {
      console.error('TOTP verification error:', error);
      return false;
    }
  }

  /**
   * Generate backup codes
   */
  generateBackupCodes(count = 10) {
    this.backupCodes = [];
    for (let i = 0; i < count; i++) {
      const code = this.generateRandomCode(8);
      this.backupCodes.push(code);
    }
    return this.backupCodes;
  }

  /**
   * Hash backup codes before storage
   */
  async hashBackupCodes(codes) {
    const hashedCodes = [];
    for (const code of codes) {
      const hash = await this.hashString(code);
      hashedCodes.push(hash);
    }
    return hashedCodes;
  }

  /**
   * Save TOTP settings to database
   */
  async saveTOTPSettings(userId, secret, backupCodes) {
    try {
      const hashedCodes = await this.hashBackupCodes(backupCodes);

      const { data, error } = await supabase
        .from('user_2fa_settings')
        .upsert({
          user_id: userId,
          totp_secret: secret,
          totp_enabled: true,
          backup_codes: hashedCodes,
          setup_completed_at: new Date().toISOString(),
          last_used_at: new Date().toISOString()
        })
        .select()
        .single();

      if (error) throw error;

      // Log setup event
      await this.logAuditEvent(userId, 'setup', true);

      return { success: true, data };
    } catch (error) {
      console.error('Error saving TOTP settings:', error);
      return { success: false, error };
    }
  }

  /**
   * Verify TOTP during login
   */
  async verifyTOTPLogin(userId, token, ipAddress) {
    try {
      // Check rate limiting
      const { data: lockStatus } = await supabase
        .rpc('increment_totp_failed_attempts', {
          p_user_id: userId,
          p_ip_address: ipAddress
        });

      if (lockStatus.locked) {
        return {
          success: false,
          error: 'Account temporarily locked. Try again later.',
          lockedUntil: lockStatus.locked_until
        };
      }

      // Get user's TOTP secret
      const { data: settings, error } = await supabase
        .from('user_2fa_settings')
        .select('totp_secret')
        .eq('user_id', userId)
        .single();

      if (error) throw error;

      // Verify token
      const isValid = this.verifyToken(token, settings.totp_secret);

      if (isValid) {
        // Reset failed attempts
        await supabase.rpc('reset_totp_failed_attempts', {
          p_user_id: userId,
          p_ip_address: ipAddress
        });

        // Update last used
        await supabase.rpc('update_totp_last_used', {
          p_user_id: userId
        });

        // Log success
        await this.logAuditEvent(userId, 'login_success', true, ipAddress);

        return { success: true };
      } else {
        // Log failure
        await this.logAuditEvent(userId, 'login_failure', false, ipAddress, 'Invalid TOTP code');

        return {
          success: false,
          error: 'Invalid code. Please try again.',
          attemptsLeft: 5 - lockStatus.attempts
        };
      }
    } catch (error) {
      console.error('TOTP verification error:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * Verify backup code
   */
  async verifyBackupCode(userId, code, ipAddress) {
    try {
      const { data: settings, error } = await supabase
        .from('user_2fa_settings')
        .select('backup_codes, backup_codes_used')
        .eq('user_id', userId)
        .single();

      if (error) throw error;

      // Check each backup code
      const codeHash = await this.hashString(code);
      const codeIndex = settings.backup_codes.indexOf(codeHash);

      if (codeIndex === -1) {
        await this.logAuditEvent(userId, 'backup_used', false, ipAddress, 'Invalid backup code');
        return { success: false, error: 'Invalid backup code' };
      }

      // Mark code as used (replace with null)
      const updatedCodes = [...settings.backup_codes];
      updatedCodes[codeIndex] = null;

      await supabase
        .from('user_2fa_settings')
        .update({
          backup_codes: updatedCodes,
          backup_codes_used: settings.backup_codes_used + 1,
          last_used_at: new Date().toISOString()
        })
        .eq('user_id', userId);

      // Log success
      await this.logAuditEvent(userId, 'backup_used', true, ipAddress);

      return { success: true, codesRemaining: updatedCodes.filter(c => c !== null).length };
    } catch (error) {
      console.error('Backup code verification error:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * Trust current device for 30 days
   */
  async trustCurrentDevice(userId, ipAddress) {
    try {
      const deviceFingerprint = await this.generateDeviceFingerprint();
      const deviceName = this.getDeviceName();
      const userAgent = navigator.userAgent;

      const { data: deviceId } = await supabase
        .rpc('trust_device', {
          p_user_id: userId,
          p_device_fingerprint: deviceFingerprint,
          p_device_name: deviceName,
          p_ip_address: ipAddress,
          p_user_agent: userAgent
        });

      return { success: true, deviceId };
    } catch (error) {
      console.error('Error trusting device:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * Get list of trusted devices
   */
  async getTrustedDevices(userId) {
    try {
      const { data, error } = await supabase
        .from('trusted_devices')
        .select('*')
        .eq('user_id', userId)
        .eq('trusted', true)
        .order('last_active_at', { ascending: false });

      if (error) throw error;

      return { success: true, devices: data };
    } catch (error) {
      console.error('Error fetching trusted devices:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * Revoke device trust
   */
  async revokeDevice(userId, deviceId) {
    try {
      const { data } = await supabase
        .rpc('revoke_device_trust', {
          p_user_id: userId,
          p_device_id: deviceId
        });

      return { success: data };
    } catch (error) {
      console.error('Error revoking device:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * Generate device fingerprint
   */
  async generateDeviceFingerprint() {
    const data = [
      navigator.userAgent,
      navigator.language,
      new Date().getTimezoneOffset(),
      screen.width + 'x' + screen.height,
      screen.colorDepth,
      navigator.hardwareConcurrency || 'unknown'
    ].join('|');

    return await this.hashString(data);
  }

  /**
   * Get device name
   */
  getDeviceName() {
    const ua = navigator.userAgent;
    let browser = 'Unknown';
    let os = 'Unknown';

    if (ua.includes('Chrome')) browser = 'Chrome';
    else if (ua.includes('Firefox')) browser = 'Firefox';
    else if (ua.includes('Safari')) browser = 'Safari';
    else if (ua.includes('Edge')) browser = 'Edge';

    if (ua.includes('Windows')) os = 'Windows';
    else if (ua.includes('Mac')) os = 'macOS';
    else if (ua.includes('Linux')) os = 'Linux';
    else if (ua.includes('Android')) os = 'Android';
    else if (ua.includes('iOS')) os = 'iOS';

    return `${browser} on ${os}`;
  }

  /**
   * Log audit event
   */
  async logAuditEvent(userId, eventType, success, ipAddress = null, failureReason = null) {
    try {
      await supabase.from('totp_audit_log').insert({
        user_id: userId,
        event_type: eventType,
        ip_address: ipAddress,
        user_agent: navigator.userAgent,
        success,
        failure_reason: failureReason
      });
    } catch (error) {
      console.error('Error logging audit event:', error);
    }
  }

  /**
   * Hash string using SHA-256
   */
  async hashString(text) {
    const encoder = new TextEncoder();
    const data = encoder.encode(text);
    const hashBuffer = await crypto.subtle.digest('SHA-256', data);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
  }

  /**
   * Generate random code
   */
  generateRandomCode(length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    let code = '';
    const array = new Uint8Array(length);
    crypto.getRandomValues(array);
    for (let i = 0; i < length; i++) {
      code += chars[array[i] % chars.length];
    }
    return code;
  }
}

// Export singleton instance
export const totpManager = new TOTPManager();
