/**
 * Waitlist Status Page - Real-Time Updates
 * Monitors waitlist position and slot offers
 */

import { supabase } from '../supabaseClient.js';
import { toast } from '../components/Toast.js';
import { formatDate, formatTime } from '../utils/formatters.js';

// Get waitlist ID from URL or localStorage
const urlParams = new URLSearchParams(window.location.search);
const waitlistId = urlParams.get('id') || localStorage.getItem('currentWaitlistId');

let waitlistData = null;
let countdownInterval = null;
let realtimeChannel = null;

// Initialize on page load
document.addEventListener('DOMContentLoaded', async () => {
  if (!waitlistId) {
    toast.error('No waitlist entry found');
    setTimeout(() => {
      window.location.href = './join-waitlist.html';
    }, 2000);
    return;
  }

  await loadWaitlistStatus();
  subscribeToRealTimeUpdates();
  startAutoRefresh();
});

/**
 * Load waitlist status from database
 */
async function loadWaitlistStatus() {
  try {
    const { data, error } = await supabase
      .rpc('get_waitlist_status', {
        p_waitlist_id: waitlistId
      });

    if (error) throw error;

    if (!data.success) {
      throw new Error(data.error || 'Waitlist entry not found');
    }

    waitlistData = data.waitlist;
    updateUI(waitlistData, data.position);

    // Hide loading, show appropriate state
    document.getElementById('loading-state').classList.add('hidden');
    
  } catch (error) {
    console.error('Failed to load waitlist status:', error);
    toast.error('Failed to load waitlist status');
    document.getElementById('loading-state').innerHTML = `
      <div class="text-center">
        <p class="text-red-600 mb-4">Failed to load waitlist status</p>
        <button onclick="window.location.reload()" class="btn-secondary">
          Try Again
        </button>
      </div>
    `;
  }
}


/**
 * Update UI based on waitlist status
 */
function updateUI(waitlist, position) {
  const status = waitlist.status;

  // Update details card
  updateDetailsCard(waitlist);

  // Show appropriate state
  if (status === 'waiting') {
    showWaitingState(position);
  } else if (status === 'offered') {
    showOfferedState(waitlist);
  } else if (status === 'expired') {
    showExpiredState();
  } else if (status === 'accepted') {
    showAcceptedState(waitlist);
  }
}

/**
 * Update details card
 */
function updateDetailsCard(waitlist) {
  document.getElementById('detail-patient').textContent = waitlist.patient_name;
  document.getElementById('detail-doctor').textContent = waitlist.doctor_name || 'Any';
  document.getElementById('detail-date').textContent = formatDate(waitlist.preferred_date);
  document.getElementById('detail-time').textContent = formatTimeRange(waitlist.preferred_time_range);
  document.getElementById('detail-joined').textContent = formatDate(waitlist.created_at, 'long');
  
  document.getElementById('details-card').classList.remove('hidden');
}

/**
 * Show waiting state
 */
function showWaitingState(position) {
  document.getElementById('waiting-state').classList.remove('hidden');
  document.getElementById('position-display').textContent = `#${position}`;
  
  // Position-specific messages
  const messages = {
    1: "You're next in line! 🎯",
    2: "Almost there! 2nd in line",
    3: "Getting close! 3rd in line"
  };
  
  if (messages[position]) {
    toast.info(messages[position], 3000);
  }
}

/**
 * Show offered state with countdown
 */
function showOfferedState(waitlist) {
  document.getElementById('offered-state').classList.remove('hidden');
  
  const expiresAt = new Date(waitlist.expires_at);
  const now = new Date();
  
  if (expiresAt <= now) {
    showExpiredState();
    return;
  }
  
  // Start countdown timer
  startCountdown(expiresAt);
  
  // Play notification sound
  playNotificationSound();
  
  // Browser notification
  if ('Notification' in window && Notification.permission === 'granted') {
    new Notification('🎉 Slot Available!', {
      body: 'A slot just opened up! Click to confirm.',
      icon: '/assets/logo.png',
      tag: 'waitlist-offer'
    });
  }
  
  toast.success('🎉 Slot available! Confirm now!', 10000);
}

/**
 * Show expired state
 */
function showExpiredState() {
  document.getElementById('expired-state').classList.remove('hidden');
  stopCountdown();
}

/**
 * Show accepted state
 */
function showAcceptedState(waitlist) {
  document.getElementById('accepted-state').classList.remove('hidden');
  
  // Setup redirect to appointment
  if (waitlist.offered_appointment_id) {
    document.getElementById('view-appointment-btn').onclick = () => {
      window.location.href = `./queue-status.html?id=${waitlist.offered_appointment_id}`;
    };
  }
}

/**
 * Start countdown timer
 */
function startCountdown(expiresAt) {
  const timerDisplay = document.getElementById('countdown-timer');
  
  countdownInterval = setInterval(() => {
    const now = new Date();
    const diff = expiresAt - now;
    
    if (diff <= 0) {
      clearInterval(countdownInterval);
      timerDisplay.textContent = '00:00';
      showExpiredState();
      return;
    }
    
    const minutes = Math.floor(diff / 60000);
    const seconds = Math.floor((diff % 60000) / 1000);
    timerDisplay.textContent = `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
    
    // Warning at 5 minutes
    if (diff <= 300000 && diff > 299000) {
      toast.warning('⏰ Only 5 minutes left to confirm!');
    }
    
    // Warning at 1 minute
    if (diff <= 60000 && diff > 59000) {
      toast.warning('⏰ Only 1 minute left!');
    }
  }, 1000);
}

/**
 * Stop countdown timer
 */
function stopCountdown() {
  if (countdownInterval) {
    clearInterval(countdownInterval);
    countdownInterval = null;
  }
}


/**
 * Subscribe to real-time updates from Supabase
 */
function subscribeToRealTimeUpdates() {
  console.log('📡 Subscribing to waitlist updates...');
  
  // Subscribe to waitlist table changes
  realtimeChannel = supabase
    .channel(`waitlist:${waitlistId}`)
    .on(
      'postgres_changes',
      {
        event: 'UPDATE',
        schema: 'public',
        table: 'waitlist',
        filter: `id=eq.${waitlistId}`
      },
      (payload) => {
        console.log('🔔 Waitlist update received:', payload);
        handleRealtimeUpdate(payload.new);
      }
    )
    .subscribe((status) => {
      if (status === 'SUBSCRIBED') {
        console.log('✅ Subscribed to real-time updates');
        toast.info('Connected to live updates', 2000);
      }
    });
}

/**
 * Handle real-time update
 */
function handleRealtimeUpdate(newData) {
  waitlistData = newData;
  
  // Reload full status to get position
  loadWaitlistStatus();
  
  // Show update notification
  if (newData.status === 'offered') {
    toast.success('🎉 Slot available! Check above!', 10000);
    playNotificationSound();
  } else if (newData.status === 'expired') {
    toast.warning('Offer expired - slot went to next person');
  } else if (newData.status === 'accepted') {
    toast.success('✅ Appointment confirmed!');
  }
}

/**
 * Confirm waitlist offer
 */
window.confirmWaitlistOffer = async function() {
  const confirmBtn = document.getElementById('confirm-btn');
  const originalText = confirmBtn.innerHTML;
  
  confirmBtn.disabled = true;
  confirmBtn.innerHTML = `
    <svg class="animate-spin h-5 w-5 mr-2" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
      <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
      <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
    </svg>
    Confirming...
  `;
  
  try {
    const { data, error} = await supabase.rpc('accept_waitlist_offer', {
      p_waitlist_id: waitlistId,
      p_patient_id: null // We'll use the patient info from waitlist
    });
    
    if (error) throw error;
    
    if (!data.success) {
      throw new Error(data.error || 'Failed to confirm');
    }
    
    toast.success('✅ Appointment confirmed!');
    
    // Update UI
    stopCountdown();
    document.getElementById('offered-state').classList.add('hidden');
    showAcceptedState({ ...waitlistData, offered_appointment_id: data.appointment_id });
    
    // Store appointment ID
    localStorage.setItem('currentAppointmentId', data.appointment_id);
    
    // Redirect after 2 seconds
    setTimeout(() => {
      window.location.href = `./queue-status.html?id=${data.appointment_id}`;
    }, 2000);
    
  } catch (error) {
    console.error('Failed to confirm offer:', error);
    toast.error(error.message || 'Failed to confirm. Please try again.');
    
    confirmBtn.disabled = false;
    confirmBtn.innerHTML = originalText;
  }
};

/**
 * Auto-refresh every 30 seconds
 */
function startAutoRefresh() {
  setInterval(() => {
    if (waitlistData && waitlistData.status === 'waiting') {
      loadWaitlistStatus();
    }
  }, 30000);
}

/**
 * Play notification sound
 */
function playNotificationSound() {
  try {
    const audio = new Audio('data:audio/wav;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACBhYqFbF1fdJivrJBhNjVgodDbq2EcBj+a2/LDciUFLIHO8tiJNwgZaLvt559NEAxQp+PwtmMcBjiR1/LMeSwFJHfH8N2QQAoUXrTp66hVFApGn+DyvmwhBSuBzvLZiTYIGWm98OScTgwOUKXi7q1hGwU7k9j0zHcrBxl6yvLbjDgKGGS35+qkUBELTKXh8rZqHQU3jtT0ynUrBCB5yPLaiTkIGGO15+moUhILS6Xi8rRqHAU4jdPzyXQrBSF4yPDZiTgIGGS15+mnUREKTKLe8bJmGwQ4jdT0ynQrBSB4x/HZiDgIGGOz5einTxEKTKLe8bFmGgQ5jdP0yXMrBSF4yPDZiTcIGGO14+mnThALTKLe8bFmGgU5jdT0yXMrBSB4yPDZiTcIGGO14+mnThAKTKPe8bFmGgU5jdT0yXMrBSF4yPDZiTcIGGO14+mnThAKTKPe8rFmGgU5jtT0yXMrBSB4yPDZiTcIGGO14+mnTRAKTKPe8rFmGgU5jtT0yXMrBSB4yPDZiTcIGGO14+mnTRAKTKPe8rFmGgU5jtT0yXMrBSB4yPDZiTcIGGO14+mnTRAKTKPe8rFmGgU5jtT0yXMrBSB4yPDZiTcIGGO14+mnTRAKTKPe8rFmGgU5jtT0yXMrBSB4yPDZiTcIGGO14+mnTRAKTKPe8rFmGgU5jtT0yXMrBSB4yPDZiTcIGGO14+mnTRAKTKPe8rFmGgU5jtT0yXMrBSB4yPDZiTcIGGO14+mnTRAKTKPe8rFmGgU5jtT0yXMrBSB4yPDZiTcIGGO14+mnTRAKTKPe8rFmGgU5jtT0yXMrBSB4yPDZiTcIGGO14+mnTRAKTKPe8rFmGgU5jtT0yXMrBSB4yPDZiTcIGGO14+mnTRAKTKPe8rFmGgU5jtT0yXMrBSB4yPDZiTcIGGO14+mnTRAK');
    audio.play().catch(e => console.log('Could not play sound'));
  } catch (e) {
    console.log('Could not play notification sound');
  }
}

/**
 * Format time range for display
 */
function formatTimeRange(range) {
  const ranges = {
    'any': 'Any Time',
    'morning': 'Morning (8 AM - 12 PM)',
    'afternoon': 'Afternoon (12 PM - 5 PM)',
    'evening': 'Evening (5 PM - 8 PM)'
  };
  return ranges[range] || range;
}

/**
 * Request notification permission
 */
if ('Notification' in window && Notification.permission === 'default') {
  Notification.requestPermission();
}

// Cleanup on page unload
window.addEventListener('beforeunload', () => {
  if (realtimeChannel) {
    supabase.removeChannel(realtimeChannel);
  }
  stopCountdown();
});
