/**
 * Login Page with Role-Based Routing, Brute Force Protection, and TOTP
 * Routes users to appropriate dashboard based on role
 * Includes security measures and two-factor authentication for admins
 */

import { supabase } from '../supabaseClient.js';
import { toast } from '../components/Toast.js';
import { secureLogin, clearSecurityMessages } from '../security.js';
import { totpManager } from '../auth/totp-api-client.js';
import { totpLogin } from '../auth/totp-login.js';

// Demo users (for development - remove in production)
const DEMO_USERS = {
  // Admin user
  'karthiksaravanavel18@gmail.com': { 
    password: '123456', 
    role: 'admin', 
    name: 'Admin User',
    dashboard: './dashboard-admin.html'
  },
  // Doctor user
  'vel759894@gmail.com': { 
    password: '123456', 
    role: 'doctor', 
    name: 'Dr. Vel',
    dashboard: './dashboard-doctor.html'
  }
};

// Initialize
document.addEventListener('DOMContentLoaded', () => {
  // Check if already logged in
  checkExistingSession();
  
  // Handle form submission
  document.getElementById('login-form').addEventListener('submit', handleLogin);
  
  // Setup password toggle
  setupPasswordToggle();
});

/**
 * Check for existing session
 */
async function checkExistingSession() {
  const session = localStorage.getItem('mediqueue_session') || sessionStorage.getItem('mediqueue_session');
  if (session) {
    try {
      const user = JSON.parse(session);
      console.log('📋 Existing session found:', user);
      
      // Redirect to saved dashboard
      if (user.dashboard) {
        window.location.href = user.dashboard;
      } else {
        // Fallback for old sessions
        window.location.href = '../index.html';
      }
    } catch (e) {
      console.error('Error parsing session:', e);
      localStorage.removeItem('mediqueue_session');
      sessionStorage.removeItem('mediqueue_session');
    }
  }
}

/**
 * Setup password toggle functionality
 */
function setupPasswordToggle() {
  const passwordInput = document.getElementById('password');
  const toggleButton = document.getElementById('toggle-password');
  const eyeIcon = document.getElementById('eye-icon');
  const eyeSlashIcon = document.getElementById('eye-slash-icon');
  
  if (!toggleButton || !passwordInput) return;
  
  toggleButton.addEventListener('click', () => {
    // Toggle password visibility
    const isPassword = passwordInput.type === 'password';
    passwordInput.type = isPassword ? 'text' : 'password';
    
    // Toggle icons
    eyeIcon.classList.toggle('hidden');
    eyeSlashIcon.classList.toggle('hidden');
    
    // Update aria-label
    toggleButton.setAttribute(
      'aria-label', 
      isPassword ? 'Hide password' : 'Show password'
    );
  });
}

/**
 * Handle login form submission with security checks
 */
async function handleLogin(e) {
  e.preventDefault();
  
  const email = document.getElementById('email').value.trim();
  const password = document.getElementById('password').value;
  const remember = document.getElementById('remember').checked;
  
  const btn = document.getElementById('login-btn');
  const originalText = btn.innerHTML;
  
  // Validate inputs
  if (!email || !password) {
    toast.error('Please enter both email and password');
    return;
  }
  
  // Show loading state
  btn.disabled = true;
  btn.innerHTML = `
    <svg class="animate-spin h-5 w-5 mr-2 inline" fill="none" viewBox="0 0 24 24">
      <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
      <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
    </svg>
    Signing in...
  `;
  
  try {
    console.log('🔐 Login attempt for:', email);
    
    // Use secure login with brute force protection
    const user = await secureLogin(email, password, authenticateUser);
    
    if (!user) {
      // Authentication failed (only for special users with wrong password)
      throw new Error('Invalid email or password');
    }
    
    console.log('✅ Authentication successful:', { 
      email: user.email, 
      role: user.role,
      dashboard: user.dashboard 
    });
    
    // Store session
    const sessionData = {
      email: user.email,
      role: user.role,
      name: user.name,
      id: user.id || generateUserId(email),
      dashboard: user.dashboard,
      isSpecialUser: user.isSpecialUser,
      loginTime: new Date().toISOString()
    };
    
    if (remember) {
      localStorage.setItem('mediqueue_session', JSON.stringify(sessionData));
    } else {
      sessionStorage.setItem('mediqueue_session', JSON.stringify(sessionData));
    }
    
    // Show success message
    let welcomeMessage = 'Welcome!';
    if (user.role === 'admin') {
      welcomeMessage = `Welcome back, Admin!`;
    } else if (user.role === 'doctor') {
      welcomeMessage = `Welcome back, Dr. ${user.name}!`;
    } else {
      welcomeMessage = `Welcome, ${user.name}!`;
    }
    
    toast.success(welcomeMessage);
    
    // Check for intended destination (from smart routing)
    const intendedDestination = localStorage.getItem('intendedDestination');
    let redirectUrl = user.dashboard;
    
    if (intendedDestination) {
      // User was trying to access something before login
      console.log('📍 Intended destination found:', intendedDestination);
      
      if (intendedDestination === 'book-appointment') {
        redirectUrl = './book-appointment.html';
      } else if (intendedDestination === 'track-live') {
        redirectUrl = './queue-status.html';
      }
      
      // Clear the intended destination
      localStorage.removeItem('intendedDestination');
    }
    
    // Redirect to appropriate page
    console.log('🚀 Redirecting to:', redirectUrl);
    setTimeout(() => {
      window.location.href = redirectUrl;
    }, 1000);
    
  } catch (error) {
    console.error('❌ Login error:', error);
    
    // Show error message
    toast.error(error.message || 'Login failed. Please try again.');
    
    // Reset button
    btn.disabled = false;
    btn.innerHTML = originalText;
  }
}

/**
 * Authenticate user (Demo + Supabase + TOTP for Admins)
 * Returns user object with role and dashboard URL
 */
async function authenticateUser(email, password) {
  const normalizedEmail = email.toLowerCase().trim();
  
  console.log('🔑 Attempting authentication for:', normalizedEmail);
  
  // Check if this is a special admin or doctor user
  if (DEMO_USERS[normalizedEmail]) {
    const demoUser = DEMO_USERS[normalizedEmail];
    if (demoUser.password === password) {
      console.log('✅ Special user authenticated:', { 
        email: normalizedEmail, 
        role: demoUser.role,
        dashboard: demoUser.dashboard 
      });
      
      const user = {
        email: normalizedEmail,
        role: demoUser.role,
        name: demoUser.name,
        dashboard: demoUser.dashboard,
        isSpecialUser: true,
        id: generateUserId(normalizedEmail)
      };
      
      // TOTP Check for Admin Users
      if (demoUser.role === 'admin') {
        console.log('🔐 Admin detected - checking TOTP status...');
        
        try {
          const totpStatus = await totpManager.checkTOTPStatus(user.id);
          console.log('TOTP Status:', totpStatus);
          
          if (totpStatus.required) {
            if (totpStatus.reason === 'not_setup' || totpStatus.reason === 'inactive_15_days') {
              // First time setup or inactive - redirect to setup
              console.log('📱 TOTP setup required:', totpStatus.reason);
              toast.info('Please set up Two-Factor Authentication');
              
              // Store user data temporarily
              sessionStorage.setItem('totp_setup_user', JSON.stringify(user));
              
              setTimeout(() => {
                window.location.href = './totp-setup.html';
              }, 1500);
              
              return null; // Block login until TOTP setup
            } else {
              // TOTP enabled - show verification modal
              console.log('🔑 TOTP verification required');
              
              return new Promise((resolve) => {
                totpLogin.show(user.id, user.email, () => {
                  console.log('✅ TOTP verified successfully');
                  resolve(user);
                });
              });
            }
          } else {
            // Trusted device - skip TOTP
            console.log('✅ Trusted device - TOTP skipped');
            return user;
          }
        } catch (error) {
          console.error('TOTP check error:', error);
          toast.error('TOTP server not running. Start it with: npm run totp-server');
          // Allow login anyway for development
          return user;
        }
      }
      
      return user;
    } else {
      console.log('❌ Wrong password for special user');
      return null;
    }
  }
  
  // All other users are treated as regular patients
  // They can use ANY email/password combination
  console.log('✅ Regular user login (patient)');
  return {
    email: normalizedEmail,
    role: 'patient',
    name: email.split('@')[0], // Use part before @ as name
    dashboard: '../index.html', // Home page with booking
    isSpecialUser: false
  };
}

/**
 * Generate user ID from email (for demo)
 * Creates a UUID v4 based on email hash
 */
function generateUserId(email) {
  // Create a deterministic UUID from email
  // For demo purposes - in production, use actual database UUIDs
  const hash = email.split('').reduce((acc, char) => {
    return ((acc << 5) - acc) + char.charCodeAt(0);
  }, 0);
  
  // Generate a UUID v4 format from hash
  const hex = Math.abs(hash).toString(16).padStart(32, '0');
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-4${hex.slice(13, 16)}-${hex.slice(16, 20)}-${hex.slice(20, 32)}`;
}

/**
 * Logout function (exported for other pages)
 */
export async function logout() {
  // Clear session
  localStorage.removeItem('mediqueue_session');
  sessionStorage.removeItem('mediqueue_session');
  
  // Sign out from Supabase
  await supabase.auth.signOut();
  
  // Redirect to home
  window.location.href = '../index.html';
}

// Make logout available globally
window.logout = logout;
