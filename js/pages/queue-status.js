/**
 * Queue Status Page - Real-Time Queue Tracking
 * Shows live position updates for patients
 */

import { realtimeQueue } from '../utils/realtime-queue.js';
import { supabase } from '../supabaseClient.js';
import { toast } from '../components/Toast.js';

// Get appointment ID from URL or localStorage
const urlParams = new URLSearchParams(window.location.search);
const appointmentId = urlParams.get('id') || localStorage.getItem('currentAppointmentId');

// State
let appointmentData = null;
let isCheckedIn = false;
let refreshInterval = null;

// Initialize on page load
document.addEventListener('DOMContentLoaded', async () => {
  await initQueueStatus();
  setupNavbarScroll();
  await requestNotificationPermission();
});

/**
 * Initialize queue status page
 */
async function initQueueStatus() {
  if (!appointmentId) {
    toast.error('No appointment found. Please book an appointment first.');
    setTimeout(() => {
      window.location.href = './book-appointment.html';
    }, 2000);
    return;
  }

  try {
    await loadAppointmentDetails();
    
    const subscribed = await realtimeQueue.subscribe(appointmentId, {
      onPositionChange: handlePositionUpdate,
      onQueueUpdate: handleQueueUpdate,
      onAppointmentCalled: handleAppointmentCalled,
      onError: handleRealtimeError
    });

    if (subscribed) {
      console.log('✅ Real-time updates enabled');
    }
  } catch (error) {
    console.error('Error initializing:', error);
    toast.error('Failed to load queue status');
  }
}

/**
 * Load appointment details
 */
async function loadAppointmentDetails() {
  try {
    document.getElementById('position-display').textContent = '...';

    const { data, error } = await supabase
      .rpc('get_appointment_status', {
        p_appointment_id: appointmentId
      });

    if (error) throw error;

    if (!data || !data.success) {
      throw new Error(data?.error || 'Appointment not found');
    }

    const appointment = data.appointment;
    const queue = data.queue;

    appointmentData = appointment;
    isCheckedIn = !!appointment.check_in_time;

    // Update UI
    document.getElementById('token-display').textContent = appointment.token_number || 'N/A';
    document.getElementById('doctor-display').textContent = appointment.doctor_name || 'General';
    document.getElementById('department-display').textContent = appointment.department_name || 'General';
    document.getElementById('time-display').textContent = formatTime(appointment.appointment_time);

    // Initial position
    if (queue && queue.position !== null) {
      handlePositionUpdate({
        position: queue.position,
        estimatedTime: queue.estimated_time,
        status: queue.status,
        event: 'INITIAL'
      });
    }

    // Hide check-in if already checked in
    if (isCheckedIn) {
      document.getElementById('checkin-section').classList.add('hidden');
    }

  } catch (error) {
    console.error('Error loading appointment:', error);
    toast.error(error.message || 'Failed to load');
    throw error;
  }
}

/**
 * Handle position updates
 */
function handlePositionUpdate(data) {
  const { position, estimatedTime, status } = data;
  
  const positionDisplay = document.getElementById('position-display');
  const positionText = document.getElementById('position-text');

  positionDisplay.classList.remove('animate-bounce', 'animate-pulse');


  if (position === 0 || status === 'called') {
    positionDisplay.textContent = '🔔';
    positionDisplay.classList.add('animate-bounce');
    positionText.textContent = "It's your turn!";
    positionText.className = 'text-green-600 font-bold';
    showCalledModal();
  } else if (position === 1) {
    positionDisplay.textContent = '1';
    positionDisplay.classList.add('animate-pulse');
    positionText.textContent = 'Next in line!';
    positionText.className = 'text-amber-600 font-semibold';
  } else if (position === 2) {
    positionDisplay.textContent = '2';
    positionText.textContent = 'Almost your turn!';
  } else {
    positionDisplay.textContent = position;
    positionText.textContent = `${position} patients ahead`;
  }

  // Update ETA
  if (estimatedTime) {
    document.getElementById('eta-display').textContent = calculateETA(estimatedTime);
  } else {
    document.getElementById('eta-display').textContent = `~${position * 15} min`;
  }
}

/**
 * Handle queue updates
 */
function handleQueueUpdate(data) {
  console.log('Queue updated:', data);
  if (data.status === 'completed') {
    toast.success('Consultation completed!');
    setTimeout(() => window.location.href = './dashboard.html', 3000);
  }
}

/**
 * Handle appointment called
 */
function handleAppointmentCalled(data) {
  console.log('Appointment called:', data);
  showCalledModal();
}

/**
 * Show called modal
 */
function showCalledModal() {
  const modal = document.createElement('div');
  modal.id = 'called-modal';
  modal.className = 'fixed inset-0 bg-green-900/90 backdrop-blur z-50 flex items-center justify-center';
  modal.innerHTML = `
    <div class="bg-white rounded-3xl p-12 text-center max-w-md shadow-2xl">
      <div class="w-24 h-24 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-6">
        <svg class="w-12 h-12 text-green-600 animate-bounce" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 13l4 4L19 7" />
        </svg>
      </div>
      <h2 class="text-4xl font-bold text-navy-900 mb-4">It's Your Turn!</h2>
      <p class="text-xl text-slate-600 mb-8">Please proceed to consultation</p>
      <button onclick="document.getElementById('called-modal').remove()" class="btn-primary text-lg px-8 py-4">
        Got It
      </button>
    </div>
  `;
  document.body.appendChild(modal);
  playSound();
}

/**
 * Handle errors
 */
function handleRealtimeError(error) {
  console.error('Realtime error:', error);
  toast.error('Connection lost. Reconnecting...');
}

/**
 * Check in
 */
window.checkIn = async function() {
  const btn = document.getElementById('checkin-btn');
  btn.disabled = true;
  btn.innerHTML = '<span class="animate-spin">⏳</span> Checking In...';
  
  try {
    const { data, error } = await supabase
      .rpc('check_in_appointment', { p_appointment_id: appointmentId });
    
    if (error) throw error;
    if (!data?.success) throw new Error(data?.error || 'Check-in failed');
    
    toast.success('✅ Checked in!');
    document.getElementById('checkin-section').classList.add('hidden');
    isCheckedIn = true;
  } catch (error) {
    console.error(error);
    toast.error(error.message || 'Check-in failed');
    btn.disabled = false;
    btn.innerHTML = 'Check In Now';
  }
};

/**
 * Utilities
 */
function calculateETA(estimatedTime) {
  const diff = Math.round((new Date(estimatedTime) - new Date()) / 60000);
  if (diff < 0) return 'Any moment';
  if (diff === 0) return 'Now';
  if (diff < 60) return `${diff} min`;
  return `${Math.floor(diff / 60)}h ${diff % 60}m`;
}

function formatTime(time) {
  if (!time) return 'N/A';
  const [h, m] = time.split(':');
  const hour = parseInt(h);
  const ampm = hour >= 12 ? 'PM' : 'AM';
  const hour12 = hour % 12 || 12;
  return `${hour12}:${m} ${ampm}`;
}

async function requestNotificationPermission() {
  if ('Notification' in window && Notification.permission === 'default') {
    await Notification.requestPermission();
  }
}

function playSound() {
  try {
    const audio = new Audio('data:audio/wav;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACBhYqFbF1fdJivrJBhNjVgodDbq2EcBj+a2/LDciUFLIHO8tiJNwgZaLvt559NEAxQp+PwtmMcBjiR1/LMeSwFJHfH8N2QQAoUXrTp66hVFA==');
    audio.volume = 0.5;
    audio.play().catch(() => {});
  } catch {}
}

function setupNavbarScroll() {
  const navbar = document.getElementById('navbar');
  let lastY = window.scrollY;
  window.addEventListener('scroll', () => {
    if (window.scrollY > 100) {
      navbar.style.transform = window.scrollY > lastY ? 'translateY(-100%)' : 'translateY(0)';
    } else {
      navbar.style.transform = 'translateY(0)';
    }
    lastY = window.scrollY;
  }, { passive: true });
}

// Cleanup
window.addEventListener('beforeunload', () => {
  realtimeQueue.unsubscribe();
  if (refreshInterval) clearInterval(refreshInterval);
});
