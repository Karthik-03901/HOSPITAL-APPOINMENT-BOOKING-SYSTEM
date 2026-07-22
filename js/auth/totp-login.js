/**
 * TOTP Login Verification Module
 * Handles 2FA verification during login
 */

import { totpManager } from './totp-api-client.js';
import { toast } from '../components/Toast.js';

class TOTPLogin {
  constructor() {
    this.userId = null;
    this.userEmail = null;
    this.onSuccess = null;
    this.countdownInterval = null;
  }

  /**
   * Show TOTP verification modal
   */
  async show(userId, userEmail, onSuccess) {
    this.userId = userId;
    this.userEmail = userEmail;
    this.onSuccess = onSuccess;

    // Create modal if it doesn't exist
    if (!document.getElementById('totp-modal')) {
      this.createModal();
    }

    // Reset form
    document.getElementById('totp-input').value = '';
    document.getElementById('totp-error').classList.add('hidden');
    document.getElementById('totp-input-container').classList.remove('hidden');
    document.getElementById('backup-code-container').classList.add('hidden');

    // Show modal
    document.getElementById('totp-modal').classList.remove('hidden');
    document.getElementById('totp-input').focus();

    // Start countdown
    this.startCountdown();
  }

  /**
   * Create TOTP modal HTML
   */
  createModal() {
    const modalHTML = `
      <div id="totp-modal" class="fixed inset-0 bg-black/50 backdrop-blur-sm hidden z-50 flex items-center justify-center p-4">
        <div class="bg-white rounded-2xl shadow-2xl max-w-md w-full p-8 animate-scale-in">
          <!-- Header -->
          <div class="text-center mb-6">
            <div class="w-16 h-16 bg-teal-100 rounded-full flex items-center justify-center mx-auto mb-4">
              <svg class="w-8 h-8 text-teal-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
              </svg>
            </div>
            <h2 class="text-2xl font-bold text-slate-800">Two-Factor Authentication</h2>
            <p class="text-sm text-slate-600 mt-2">Enter the 6-digit code from your authenticator app</p>
          </div>

          <!-- TOTP Input -->
          <div id="totp-input-container">
            <form id="totp-form" class="space-y-4">
              <div>
                <input 
                  type="text" 
                  id="totp-input" 
                  placeholder="000000"
                  maxlength="6"
                  pattern="[0-9]{6}"
                  class="w-full text-center text-3xl font-mono tracking-widest px-4 py-4 border-2 border-slate-300 rounded-xl focus:border-teal-500 focus:ring-4 focus:ring-teal-200 transition-all"
                  required
                  autocomplete="off"
                />
                <p id="totp-error" class="text-sm text-red-600 mt-2 hidden"></p>
                <p class="text-xs text-slate-500 mt-2 text-center">Only numbers, no spaces</p>
              </div>

              <!-- Countdown Progress -->
              <div class="space-y-2">
                <div class="flex items-center justify-between text-xs text-slate-600">
                  <span id="totp-countdown">Code refreshes in 30s</span>
                </div>
                <div class="w-full h-1 bg-slate-200 rounded-full overflow-hidden">
                  <div id="totp-progress" class="h-full bg-teal-500 transition-all duration-1000" style="width: 100%"></div>
                </div>
              </div>

              <!-- Trust Device -->
              <label class="flex items-center gap-2 cursor-pointer">
                <input type="checkbox" id="trust-device" class="w-4 h-4 text-teal-600 rounded">
                <span class="text-sm text-slate-700">Trust this device for 30 days</span>
              </label>

              <!-- Submit Button -->
              <button type="submit" id="verify-totp-btn" class="btn-primary w-full py-3 text-lg">
                Verify & Login
              </button>
            </form>

            <!-- Backup Code Link -->
            <div class="text-center mt-4">
              <button type="button" id="show-backup-code" class="text-sm text-teal-600 hover:text-teal-700 underline">
                Lost your device? Use backup code
              </button>
            </div>
          </div>

          <!-- Backup Code Input (Hidden by default) -->
          <div id="backup-code-container" class="hidden">
            <form id="backup-code-form" class="space-y-4">
              <div>
                <label class="block text-sm font-medium text-slate-700 mb-2">Backup Code</label>
                <input 
                  type="text" 
                  id="backup-code-input" 
                  placeholder="XXXXXXXX"
                  maxlength="8"
                  class="w-full text-center text-xl font-mono tracking-wider px-4 py-3 border-2 border-slate-300 rounded-xl focus:border-teal-500 focus:ring-4 focus:ring-teal-200 transition-all uppercase"
                  required
                />
                <p class="text-xs text-slate-500 mt-2">Enter one of your 8-character backup codes</p>
              </div>

              <button type="submit" id="verify-backup-btn" class="btn-primary w-full py-3">
                Verify Backup Code
              </button>

              <button type="button" id="back-to-totp" class="btn-secondary w-full py-2">
                Back to TOTP
              </button>
            </form>
          </div>

          <!-- Help Text -->
          <div class="mt-6 p-4 bg-blue-50 rounded-lg border border-blue-200">
            <p class="text-xs text-blue-800">
              <strong>💡 Tip:</strong> Open your authenticator app and look for "MediQueue". The code refreshes every 30 seconds.
            </p>
          </div>
        </div>
      </div>
    `;

    document.body.insertAdjacentHTML('beforeend', modalHTML);

    // Setup event listeners
    this.setupEventListeners();
  }

  /**
   * Setup event listeners
   */
  setupEventListeners() {
    // TOTP form submission
    document.getElementById('totp-form').addEventListener('submit', (e) => {
      e.preventDefault();
      this.verifyTOTP();
    });

    // Backup code form submission
    document.getElementById('backup-code-form').addEventListener('submit', (e) => {
      e.preventDefault();
      this.verifyBackupCode();
    });

    // Show backup code option
    document.getElementById('show-backup-code').addEventListener('click', () => {
      document.getElementById('totp-input-container').classList.add('hidden');
      document.getElementById('backup-code-container').classList.remove('hidden');
    });

    // Back to TOTP
    document.getElementById('back-to-totp').addEventListener('click', () => {
      document.getElementById('backup-code-container').classList.add('hidden');
      document.getElementById('totp-input-container').classList.remove('hidden');
      document.getElementById('totp-input').focus();
    });
  }

  /**
   * Verify TOTP code
   */
  async verifyTOTP() {
    const token = document.getElementById('totp-input').value.trim();
    const btn = document.getElementById('verify-totp-btn');
    const originalText = btn.innerHTML;

    if (token.length !== 6) {
      this.showError('Please enter a 6-digit code');
      return;
    }

    // Show loading
    btn.disabled = true;
    btn.innerHTML = '<div class="animate-spin rounded-full h-5 w-5 border-b-2 border-white mx-auto"></div>';

    try {
      const ipAddress = await this.getIPAddress();
      const result = await totpManager.verifyTOTPLogin(this.userId, token, ipAddress);

      if (result.success) {
        // Check if user wants to trust device
        if (document.getElementById('trust-device').checked) {
          await totpManager.trustCurrentDevice(this.userId, ipAddress);
        }

        toast.success('2FA verification successful!');
        this.hide();

        // Call success callback
        if (this.onSuccess) {
          this.onSuccess();
        }
      } else {
        if (result.lockedUntil) {
          const minutes = Math.ceil((new Date(result.lockedUntil) - new Date()) / 60000);
          this.showError(`Account locked. Try again in ${minutes} minutes.`);
        } else {
          this.showError(result.error || 'Invalid code. Please try again.');
          document.getElementById('totp-input').value = '';
          document.getElementById('totp-input').focus();
        }
      }
    } catch (error) {
      console.error('TOTP verification error:', error);
      this.showError('Verification failed. Please try again.');
    } finally {
      btn.disabled = false;
      btn.innerHTML = originalText;
    }
  }

  /**
   * Verify backup code
   */
  async verifyBackupCode() {
    const code = document.getElementById('backup-code-input').value.trim().toUpperCase();
    const btn = document.getElementById('verify-backup-btn');
    const originalText = btn.innerHTML;

    if (code.length !== 8) {
      toast.error('Please enter an 8-character backup code');
      return;
    }

    // Show loading
    btn.disabled = true;
    btn.innerHTML = '<div class="animate-spin rounded-full h-5 w-5 border-b-2 border-white mx-auto"></div>';

    try {
      const ipAddress = await this.getIPAddress();
      const result = await totpManager.verifyBackupCode(this.userId, code, ipAddress);

      if (result.success) {
        toast.success(`Backup code accepted! ${result.codesRemaining} codes remaining.`);
        toast.info('Consider re-enabling 2FA in your account settings.');
        this.hide();

        // Call success callback
        if (this.onSuccess) {
          this.onSuccess();
        }
      } else {
        toast.error(result.error || 'Invalid backup code');
        document.getElementById('backup-code-input').value = '';
      }
    } catch (error) {
      console.error('Backup code verification error:', error);
      toast.error('Verification failed. Please try again.');
    } finally {
      btn.disabled = false;
      btn.innerHTML = originalText;
    }
  }

  /**
   * Start countdown timer
   */
  startCountdown() {
    const countdownEl = document.getElementById('totp-countdown');
    const progressEl = document.getElementById('totp-progress');

    if (this.countdownInterval) {
      clearInterval(this.countdownInterval);
    }

    const updateCountdown = () => {
      const now = Math.floor(Date.now() / 1000);
      const remaining = 30 - (now % 30);
      const percentage = (remaining / 30) * 100;

      countdownEl.textContent = `Code refreshes in ${remaining}s`;
      progressEl.style.width = `${percentage}%`;

      if (remaining === 30) {
        progressEl.classList.add('animate-pulse');
        setTimeout(() => progressEl.classList.remove('animate-pulse'), 500);
      }
    };

    updateCountdown();
    this.countdownInterval = setInterval(updateCountdown, 1000);
  }

  /**
   * Show error message
   */
  showError(message) {
    const errorEl = document.getElementById('totp-error');
    errorEl.textContent = message;
    errorEl.classList.remove('hidden');

    setTimeout(() => {
      errorEl.classList.add('hidden');
    }, 5000);
  }

  /**
   * Hide modal
   */
  hide() {
    document.getElementById('totp-modal').classList.add('hidden');
    if (this.countdownInterval) {
      clearInterval(this.countdownInterval);
    }
  }

  /**
   * Get user's IP address
   */
  async getIPAddress() {
    try {
      const response = await fetch('https://api.ipify.org?format=json');
      const data = await response.json();
      return data.ip;
    } catch {
      return 'unknown';
    }
  }
}

// Export singleton instance
export const totpLogin = new TOTPLogin();
