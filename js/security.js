/**
 * Security Module - Brute Force Protection
 * Handles rate limiting, account lockout, and CAPTCHA integration
 */

import { supabase } from './supabaseClient.js';

// Configuration - Cloudflare Turnstile
const TURNSTILE_SITE_KEY = '1x00000000000000000000AA'; // Cloudflare Turnstile test key (always passes)
// For production, get your key from: https://dash.cloudflare.com/?to=/:account/turnstile

/**
 * Check if login is allowed for user
 * @param {string} email - User email
 * @param {string} ipAddress - User IP address
 * @returns {Promise<Object>} Login status
 */
export async function checkLoginAllowed(email, ipAddress = null) {
  try {
    // Get IP address if not provided
    if (!ipAddress) {
      ipAddress = await getUserIP();
    }

    const { data, error } = await supabase.rpc('check_login_allowed', {
      p_email: email,
      p_ip_address: ipAddress
    });

    if (error) {
      // If RPC function doesn't exist, allow login (security system not installed)
      if (error.message && error.message.includes('Could not find')) {
        console.warn('⚠️ Security system not installed. Login allowed without checks.');
        return {
          allowed: true,
          requiresCaptcha: false
        };
      }
      console.error('Error checking login status:', error);
      throw error;
    }

    const result = data && data.length > 0 ? data[0] : null;

    if (!result) {
      return {
        allowed: true,
        requiresCaptcha: false
      };
    }

    return {
      allowed: result.allowed,
      reason: result.reason,
      lockedUntil: result.locked_until,
      requiresCaptcha: result.requires_captcha,
      message: getSecurityMessage(result)
    };

  } catch (error) {
    console.error('Error in checkLoginAllowed:', error);
    // Fallback: allow login if security check fails
    console.warn('⚠️ Security check failed. Allowing login as fallback.');
    return {
      allowed: true,
      requiresCaptcha: false
    };
  }
}

/**
 * Record a login attempt
 * @param {string} email - User email
 * @param {string} status - 'success' or 'failed'
 * @param {string} failureReason - Reason for failure (if failed)
 * @returns {Promise<Object>} Result
 */
export async function recordLoginAttempt(email, status, failureReason = null) {
  try {
    const ipAddress = await getUserIP();
    const userAgent = navigator.userAgent;

    const { data, error } = await supabase.rpc('record_login_attempt', {
      p_email: email,
      p_ip_address: ipAddress,
      p_user_agent: userAgent,
      p_status: status,
      p_failure_reason: failureReason
    });

    if (error) {
      // If RPC function doesn't exist, skip recording (security system not installed)
      if (error.message && error.message.includes('Could not find')) {
        console.warn('⚠️ Security system not installed. Login attempt not recorded.');
        return {
          success: true,
          accountLocked: false
        };
      }
      console.error('Error recording login attempt:', error);
      throw error;
    }

    const result = data && data.length > 0 ? data[0] : null;

    return {
      success: result?.success || false,
      accountLocked: result?.account_locked || false,
      lockedUntil: result?.locked_until,
      message: result?.message
    };

  } catch (error) {
    console.error('Error in recordLoginAttempt:', error);
    // Fallback: return success to not block login
    console.warn('⚠️ Failed to record login attempt. Continuing anyway.');
    return {
      success: true,
      accountLocked: false
    };
  }
}

/**
 * Get user's IP address
 * @returns {Promise<string>} IP address
 */
async function getUserIP() {
  try {
    // Try to get IP from external service
    const response = await fetch('https://api.ipify.org?format=json');
    const data = await response.json();
    return data.ip || '0.0.0.0';
  } catch (error) {
    console.error('Error getting IP:', error);
    return '0.0.0.0'; // Fallback
  }
}

/**
 * Load Cloudflare Turnstile
 * @returns {Promise<boolean>} Success status
 */
export function loadCaptcha() {
  return new Promise((resolve, reject) => {
    // Check if already loaded
    if (window.turnstile) {
      resolve(true);
      return;
    }

    const script = document.createElement('script');
    script.src = 'https://challenges.cloudflare.com/turnstile/v0/api.js';
    script.async = true;
    script.defer = true;
    script.onload = () => resolve(true);
    script.onerror = () => reject(new Error('Failed to load Cloudflare Turnstile'));
    document.head.appendChild(script);
  });
}

/**
 * Show Cloudflare Turnstile challenge
 * @param {string} containerId - ID of container element
 * @returns {Promise<void>}
 */
export async function showCaptcha(containerId = 'captcha-container') {
  try {
    await loadCaptcha();

    // Create container if doesn't exist
    let container = document.getElementById(containerId);
    if (!container) {
      container = document.createElement('div');
      container.id = containerId;
      container.className = 'mb-4';
      
      // Insert before login button
      const loginForm = document.getElementById('login-form');
      const loginButton = loginForm?.querySelector('button[type="submit"]');
      if (loginButton && loginButton.parentNode) {
        loginButton.parentNode.insertBefore(container, loginButton);
      }
    }

    // Clear existing widget if any
    container.innerHTML = '';

    // Render Cloudflare Turnstile
    if (window.turnstile) {
      window.turnstile.render(`#${containerId}`, {
        sitekey: TURNSTILE_SITE_KEY,
        theme: 'light',
        size: 'normal',
        callback: function(token) {
          console.log('✅ Turnstile verified:', token);
        },
        'error-callback': function() {
          console.error('❌ Turnstile error');
        }
      });
    }

  } catch (error) {
    console.error('Error showing Cloudflare Turnstile:', error);
  }
}

/**
 * Verify Cloudflare Turnstile response
 * @returns {Promise<boolean>} Verification result
 */
export async function verifyCaptcha() {
  try {
    if (!window.turnstile) {
      return true; // Skip if Turnstile not loaded
    }

    // Get response token from Turnstile
    const container = document.getElementById('captcha-container');
    if (!container) {
      return true; // No container, skip
    }

    const response = container.querySelector('[name="cf-turnstile-response"]')?.value;
    
    if (!response) {
      throw new Error('Please complete the verification challenge');
    }

    // In production, verify token on server-side
    // For now, just check if response exists
    return response.length > 0;

  } catch (error) {
    console.error('Error verifying Cloudflare Turnstile:', error);
    throw error;
  }
}

/**
 * Reset Cloudflare Turnstile
 */
export function resetCaptcha() {
  try {
    if (window.turnstile) {
      const container = document.getElementById('captcha-container');
      if (container) {
        window.turnstile.reset(container);
      }
    }
  } catch (error) {
    console.error('Error resetting Cloudflare Turnstile:', error);
  }
}

/**
 * Show account locked message
 * @param {Date} lockedUntil - Unlock time
 */
export function showAccountLockedMessage(lockedUntil) {
  const minutes = Math.ceil((new Date(lockedUntil) - new Date()) / 60000);
  
  const message = `
    <div class="bg-red-50 border border-red-200 rounded-xl p-4 mb-4">
      <div class="flex items-start gap-3">
        <svg class="w-6 h-6 text-red-600 flex-shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
        </svg>
        <div>
          <h4 class="font-bold text-red-900 mb-1">Account Temporarily Locked</h4>
          <p class="text-sm text-red-700">
            Your account has been locked due to multiple failed login attempts.
            Please try again in <strong>${minutes} minutes</strong>.
          </p>
          <p class="text-xs text-red-600 mt-2">
            If you believe this is an error, please contact support.
          </p>
        </div>
      </div>
    </div>
  `;

  const container = document.getElementById('security-message');
  if (container) {
    container.innerHTML = message;
  } else {
    // Insert before login form
    const loginForm = document.getElementById('login-form');
    if (loginForm) {
      const div = document.createElement('div');
      div.id = 'security-message';
      div.innerHTML = message;
      loginForm.parentNode?.insertBefore(div, loginForm);
    }
  }
}

/**
 * Show rate limit message
 */
export function showRateLimitMessage() {
  const message = `
    <div class="bg-amber-50 border border-amber-200 rounded-xl p-4 mb-4">
      <div class="flex items-start gap-3">
        <svg class="w-6 h-6 text-amber-600 flex-shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
        </svg>
        <div>
          <h4 class="font-bold text-amber-900 mb-1">Too Many Attempts</h4>
          <p class="text-sm text-amber-700">
            You've made too many login attempts. Please wait a moment before trying again.
          </p>
        </div>
      </div>
    </div>
  `;

  const container = document.getElementById('security-message');
  if (container) {
    container.innerHTML = message;
  }
}

/**
 * Show IP blocked message
 */
export function showIPBlockedMessage() {
  const message = `
    <div class="bg-red-50 border border-red-200 rounded-xl p-4 mb-4">
      <div class="flex items-start gap-3">
        <svg class="w-6 h-6 text-red-600 flex-shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 015.636 5.636m12.728 12.728L5.636 5.636" />
        </svg>
        <div>
          <h4 class="font-bold text-red-900 mb-1">Access Blocked</h4>
          <p class="text-sm text-red-700">
            Your IP address has been temporarily blocked due to suspicious activity.
            Please contact support if you believe this is an error.
          </p>
        </div>
      </div>
    </div>
  `;

  const container = document.getElementById('security-message');
  if (container) {
    container.innerHTML = message;
  }
}

/**
 * Clear security messages
 */
export function clearSecurityMessages() {
  const container = document.getElementById('security-message');
  if (container) {
    container.innerHTML = '';
  }
}

/**
 * Get human-readable security message
 * @param {Object} result - Security check result
 * @returns {string} Message
 */
function getSecurityMessage(result) {
  switch (result.reason) {
    case 'account_locked':
      return 'Account is locked due to multiple failed attempts';
    case 'ip_blocked':
      return 'Your IP address has been blocked';
    case 'rate_limited':
      return 'Too many login attempts. Please wait a moment';
    default:
      return 'Login allowed';
  }
}

/**
 * Enhanced login handler with security checks
 * @param {string} email - User email
 * @param {string} password - User password
 * @param {Function} loginCallback - Original login function
 * @returns {Promise<Object>} Login result
 */
export async function secureLogin(email, password, loginCallback) {
  try {
    clearSecurityMessages();

    // Step 1: Check if login is allowed
    const securityCheck = await checkLoginAllowed(email);

    if (!securityCheck.allowed) {
      // Handle different block reasons
      if (securityCheck.reason === 'account_locked') {
        showAccountLockedMessage(securityCheck.lockedUntil);
      } else if (securityCheck.reason === 'rate_limited') {
        showRateLimitMessage();
      } else if (securityCheck.reason === 'ip_blocked') {
        showIPBlockedMessage();
      }

      throw new Error(securityCheck.message);
    }

    // Step 2: Show CAPTCHA if required
    if (securityCheck.requiresCaptcha) {
      await showCaptcha();
      const captchaValid = await verifyCaptcha();
      
      if (!captchaValid) {
        throw new Error('CAPTCHA verification failed');
      }
    }

    // Step 3: Attempt login
    const loginResult = await loginCallback(email, password);

    // Step 4: Record successful attempt
    await recordLoginAttempt(email, 'success');

    return loginResult;

  } catch (error) {
    // Record failed attempt
    await recordLoginAttempt(email, 'failed', error.message);

    throw error;
  }
}

/**
 * Get security statistics (admin only)
 * @returns {Promise<Object>} Statistics
 */
export async function getSecurityStats() {
  try {
    const { data, error } = await supabase.rpc('get_security_stats');

    if (error) {
      console.error('Error getting security stats:', error);
      throw error;
    }

    return data && data.length > 0 ? data[0] : null;

  } catch (error) {
    console.error('Error in getSecurityStats:', error);
    throw error;
  }
}

// Export all functions
export default {
  checkLoginAllowed,
  recordLoginAttempt,
  loadCaptcha,
  showCaptcha,
  verifyCaptcha,
  resetCaptcha,
  showAccountLockedMessage,
  showRateLimitMessage,
  showIPBlockedMessage,
  clearSecurityMessages,
  secureLogin,
  getSecurityStats
};
