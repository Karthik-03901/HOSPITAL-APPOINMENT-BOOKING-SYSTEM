/**
 * Smart Routing Logic for Homepage
 * Handles intelligent navigation based on user login and booking status
 */

import { supabase } from './supabaseClient.js';

/**
 * Check if user is logged in
 */
async function isUserLoggedIn() {
  try {
    const { data: { session }, error } = await supabase.auth.getSession();
    if (error) throw error;
    return session !== null;
  } catch (error) {
    console.error('Error checking login status:', error);
    return false;
  }
}

/**
 * Check if user has any appointments
 */
async function hasUserBookedAppointment() {
  try {
    const { data: { session } } = await supabase.auth.getSession();
    if (!session) return false;

    const userEmail = session.user.email;
    
    const { data, error } = await supabase
      .from('appointments')
      .select('id')
      .eq('patient_email', userEmail)
      .in('status', ['confirmed', 'scheduled'])
      .limit(1);

    if (error) throw error;
    
    return data && data.length > 0;
  } catch (error) {
    console.error('Error checking appointments:', error);
    return false;
  }
}

/**
 * Get latest appointment ID for user
 */
async function getLatestAppointmentId() {
  try {
    const { data: { session } } = await supabase.auth.getSession();
    if (!session) return null;

    const userEmail = session.user.email;
    
    const { data, error } = await supabase
      .from('appointments')
      .select('id')
      .eq('patient_email', userEmail)
      .in('status', ['confirmed', 'scheduled'])
      .order('created_at', { ascending: false })
      .limit(1);

    if (error) throw error;
    
    return data && data.length > 0 ? data[0].id : null;
  } catch (error) {
    console.error('Error getting appointment ID:', error);
    return null;
  }
}

/**
 * Show a notification message
 */
function showMessage(message, type = 'info') {
  // Try to use toast if available
  if (window.toast) {
    window.toast[type](message);
  } else {
    alert(message);
  }
}

/**
 * Handle "Create Account" / "Start Free Trial" button click
 * Logic: If logged in → Book Appointment, If not → Login
 */
async function handleCreateAccountClick(event) {
  event.preventDefault();
  
  const isLoggedIn = await isUserLoggedIn();
  
  if (isLoggedIn) {
    // User is logged in, route to book appointment
    window.location.href = './pages/book-appointment.html';
  } else {
    // User not logged in, route to login page
    window.location.href = './pages/login.html';
  }
}

/**
 * Handle "Book Appointment" / "Book Now" button click
 * Logic: If logged in → Book Appointment, If not → Show message then Login
 */
async function handleBookAppointmentClick(event) {
  event.preventDefault();
  
  const isLoggedIn = await isUserLoggedIn();
  
  if (isLoggedIn) {
    // User is logged in, route to booking page
    window.location.href = './pages/book-appointment.html';
  } else {
    // User not logged in, show message and route to login
    localStorage.setItem('intendedDestination', 'book-appointment');
    
    showMessage('Please login first to book an appointment', 'info');
    
    // Small delay to show message, then redirect
    setTimeout(() => {
      window.location.href = './pages/login.html';
    }, 1000);
  }
}

/**
 * Handle "Track Live" button click
 * Logic: If has appointment → Queue Status, If not → Book Appointment
 */
async function handleTrackLiveClick(event) {
  event.preventDefault();
  
  const isLoggedIn = await isUserLoggedIn();
  
  if (!isLoggedIn) {
    // Not logged in, redirect to login
    localStorage.setItem('intendedDestination', 'track-live');
    
    showMessage('Please login first to track your appointment', 'info');
    
    setTimeout(() => {
      window.location.href = './pages/login.html';
    }, 1000);
    return;
  }
  
  // User is logged in, check if they have appointments
  const hasAppointment = await hasUserBookedAppointment();
  
  if (hasAppointment) {
    // User has appointment, get the latest one and route to queue status
    const appointmentId = await getLatestAppointmentId();
    
    if (appointmentId) {
      window.location.href = `./pages/queue-status.html?id=${appointmentId}`;
    } else {
      // Fallback to generic queue status page
      window.location.href = './pages/queue-status.html';
    }
  } else {
    // User doesn't have appointment, route to booking page
    showMessage('You don\'t have any appointments yet. Please book one first.', 'info');
    
    setTimeout(() => {
      window.location.href = './pages/book-appointment.html';
    }, 1000);
  }
}

/**
 * Initialize smart routing on page load
 */
function initSmartRouting() {
  // 1. "Create Account" / "Start Free Trial" button in hero section
  const createAccountBtn = document.getElementById('btn-create-account');
  if (createAccountBtn) {
    createAccountBtn.addEventListener('click', handleCreateAccountClick);
  }
  
  // 2. "Book Appointment" / "Book Now" button in navbar
  const bookAppointmentBtn = document.getElementById('btn-book-appointment');
  if (bookAppointmentBtn) {
    bookAppointmentBtn.addEventListener('click', handleBookAppointmentClick);
  }
  
  // 3. "Track Live" button in How It Works section
  const trackLiveBtn = document.getElementById('btn-track-live');
  if (trackLiveBtn) {
    trackLiveBtn.addEventListener('click', handleTrackLiveClick);
  }
  
  console.log('Smart routing initialized:', {
    createAccount: !!createAccountBtn,
    bookAppointment: !!bookAppointmentBtn,
    trackLive: !!trackLiveBtn
  });
}

// Auto-initialize when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initSmartRouting);
} else {
  initSmartRouting();
}

// Export functions for manual use if needed
export {
  isUserLoggedIn,
  hasUserBookedAppointment,
  getLatestAppointmentId,
  handleCreateAccountClick,
  handleBookAppointmentClick,
  handleTrackLiveClick
};
