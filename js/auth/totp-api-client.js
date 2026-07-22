/**
 * TOTP API Client
 * Frontend client for interacting with the TOTP backend API
 */

const TOTP_API_BASE = 'http://localhost:3001/api/totp';

/**
 * TOTP Manager using Backend API
 */
class TOTPManager {
  constructor() {
    this.secret = null;
    this.backupCodes = [];
  }

  /**
   * Generate new TOTP secret and QR code
   */
  async generateSecret(email, userId) {
    try {
      const response = await fetch(`${TOTP_API_BASE}/generate`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ email, userId })
      });

      if (!response.ok) {
        throw new Error('Failed to generate TOTP secret');
      }

      const data = await response.json();
      this.secret = data.secret;
      
      return {
        secret: data.secret,
        qrCode: data.qrCode,
        manual: data.manual
      };
    } catch (error) {
      console.error('Error generating secret:', error);
      throw error;
    }
  }

  /**
   * Verify TOTP token
   */
  async verifyToken(secret, token) {
    try {
      const response = await fetch(`${TOTP_API_BASE}/verify`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ secret, token })
      });

      if (!response.ok) {
        throw new Error('Failed to verify token');
      }

      const data = await response.json();
      return data.valid;
    } catch (error) {
      console.error('Error verifying token:', error);
      throw error;
    }
  }

  /**
   * Generate backup codes
   */
  async generateBackupCodes(userId) {
    try {
      const response = await fetch(`${TOTP_API_BASE}/backup-codes`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ userId })
      });

      if (!response.ok) {
        throw new Error('Failed to generate backup codes');
      }

      const data = await response.json();
      this.backupCodes = data.backupCodes;
      
      return data.backupCodes;
    } catch (error) {
      console.error('Error generating backup codes:', error);
      throw error;
    }
  }

  /**
   * Verify backup code
   */
  async verifyBackupCode(userId, code) {
    try {
      const response = await fetch(`${TOTP_API_BASE}/verify-backup`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ userId, code })
      });

      if (!response.ok) {
        throw new Error('Failed to verify backup code');
      }

      const data = await response.json();
      return data.valid;
    } catch (error) {
      console.error('Error verifying backup code:', error);
      throw error;
    }
  }

  /**
   * Check if user needs TOTP setup or re-auth
   */
  async checkTOTPStatus(userId) {
    try {
      const response = await fetch(`${TOTP_API_BASE}/status/${userId}`);

      if (!response.ok) {
        throw new Error('Failed to check TOTP status');
      }

      const data = await response.json();
      return data;
    } catch (error) {
      console.error('Error checking TOTP status:', error);
      throw error;
    }
  }

  /**
   * Save TOTP settings to database
   */
  async saveTOTPSettings(userId, secret, backupCodes) {
    try {
      const response = await fetch(`${TOTP_API_BASE}/save`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ userId, secret, backupCodes })
      });

      if (!response.ok) {
        throw new Error('Failed to save TOTP settings');
      }

      const data = await response.json();
      return data.success;
    } catch (error) {
      console.error('Error saving TOTP settings:', error);
      throw error;
    }
  }

  /**
   * Update last used timestamp
   */
  async updateLastUsed(userId) {
    try {
      const response = await fetch(`${TOTP_API_BASE}/update-last-used`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ userId })
      });

      if (!response.ok) {
        throw new Error('Failed to update last used timestamp');
      }

      return true;
    } catch (error) {
      console.error('Error updating last used:', error);
      throw error;
    }
  }

  /**
   * Generate device fingerprint
   */
  generateDeviceFingerprint() {
    const components = [
      navigator.userAgent,
      navigator.language,
      screen.width + 'x' + screen.height,
      new Date().getTimezoneOffset(),
      navigator.hardwareConcurrency || 'unknown'
    ];
    
    return btoa(components.join('|'));
  }
}

// Export singleton instance
export const totpManager = new TOTPManager();
export { TOTPManager };
