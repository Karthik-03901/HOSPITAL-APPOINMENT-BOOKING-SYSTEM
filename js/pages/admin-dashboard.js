/**
 * Admin Dashboard with Real-Time Functionality
 * Features:
 * - Real-time statistics
 * - Live appointments table with filters
 * - Doctor management
 * - System settings
 * - Activity monitoring
 */

import { supabase } from '../supabaseClient.js';
import { getCurrentProfile, signOut } from '../auth.js';
import { toast } from '../components/Toast.js';
import { formatDate, formatTime, formatCurrency } from '../utils/formatters.js';

// State management
let currentProfile = null;
let dashboardStats = {};
let appointments = [];
let realtimeSubscription = null;
let statsInterval = null;

// Filters
let currentFilter = 'all'; // all, today, pending, completed, cancelled
let searchQuery = '';

// Initialize on page load
document.addEventListener('DOMContentLoaded', async () => {
  await initAdminDashboard();
});

/**
 * Initialize the admin dashboard
 */
async function initAdminDashboard() {
  try {
    // Get current profile
    currentProfile = await getCurrentProfile();
    
    if (!currentProfile) {
      console.warn('❌ No profile found, redirecting to login');
      window.location.href = '../pages/login.html';
      return;
    }
    
    console.log('🔐 Admin Dashboard Access Check:', {
      email: currentProfile.email,
      role: currentProfile.role
    });
    
    // SIMPLE CHECK: Must be admin email
    const ADMIN_EMAIL = 'karthiksaravanavel18@gmail.com';
    const userEmail = (currentProfile.email || '').toLowerCase().trim();
    
    if (userEmail !== ADMIN_EMAIL) {
      console.error('❌ Access Denied - Not admin email:', userEmail);
      
      toast.error('Access denied. Admin privileges required.');
      
      // Force logout and redirect
      localStorage.removeItem('mediqueue_session');
      sessionStorage.removeItem('mediqueue_session');
      
      setTimeout(() => {
        window.location.href = '../index.html';
      }, 2000);
      return;
    }
    
    console.log('✅ Admin access granted');
    
    // Display admin info
    displayAdminInfo();
    
    // Setup logout
    setupLogout();
    
    // Load dashboard data
    await loadDashboardStats();
    await loadAppointments();
    
    // Setup real-time subscriptions
    setupRealtimeSubscriptions();
    
    // Setup refresh interval for stats (every 30 seconds)
    statsInterval = setInterval(loadDashboardStats, 30000);
    
    // Setup event listeners
    setupEventListeners();
    
    toast.success('Admin dashboard loaded successfully');
    
  } catch (error) {
    console.error('Failed to initialize admin dashboard:', error);
    toast.error('Failed to load dashboard');
  }
}

/**
 * Display admin information in header
 */
function displayAdminInfo() {
  const adminNameEl = document.getElementById('admin-name');
  const adminRoleEl = document.getElementById('admin-role');
  
  if (adminNameEl) {
    adminNameEl.textContent = currentProfile.full_name || currentProfile.email;
  }
  
  if (adminRoleEl) {
    adminRoleEl.textContent = 'Administrator';
  }
}

/**
 * Setup logout button
 */
function setupLogout() {
  const logoutBtn = document.getElementById('logout-btn');
  if (logoutBtn) {
    logoutBtn.addEventListener('click', async () => {
      await signOut();
      window.location.href = '../index.html';
    });
  }
}

/**
 * Load dashboard statistics
 */
async function loadDashboardStats() {
  try {
    const { data, error } = await supabase.rpc('admin_get_dashboard_stats');
    
    if (error) {
      console.error('Failed to load stats:', error);
      // Use fallback stats
      dashboardStats = {
        total_appointments: 0,
        today_appointments: 0,
        pending_appointments: 0,
        completed_appointments: 0,
        total_patients: 0,
        total_doctors: 0,
        active_doctors: 0,
        total_revenue: 0,
        pending_revenue: 0
      };
    } else {
      dashboardStats = data;
    }
    
    displayDashboardStats();
    
  } catch (error) {
    console.error('Error loading dashboard stats:', error);
  }
}

/**
 * Display dashboard statistics
 */
function displayDashboardStats() {
  // Total Appointments
  const totalApptEl = document.getElementById('stat-total-appointments');
  if (totalApptEl) {
    totalApptEl.textContent = dashboardStats.total_appointments || 0;
  }
  
  // Today's Appointments
  const todayApptEl = document.getElementById('stat-today-appointments');
  if (todayApptEl) {
    todayApptEl.textContent = dashboardStats.today_appointments || 0;
  }
  
  // Pending Appointments
  const pendingApptEl = document.getElementById('stat-pending-appointments');
  if (pendingApptEl) {
    pendingApptEl.textContent = dashboardStats.pending_appointments || 0;
  }
  
  // Total Revenue
  const revenueEl = document.getElementById('stat-total-revenue');
  if (revenueEl) {
    revenueEl.textContent = formatCurrency(dashboardStats.total_revenue || 0);
  }
  
  // Total Patients
  const patientsEl = document.getElementById('stat-total-patients');
  if (patientsEl) {
    patientsEl.textContent = dashboardStats.total_patients || 0;
  }
  
  // Total Doctors
  const doctorsEl = document.getElementById('stat-total-doctors');
  if (doctorsEl) {
    doctorsEl.textContent = dashboardStats.total_doctors || 0;
  }
  
  // Active Doctors
  const activeDoctorsEl = document.getElementById('stat-active-doctors');
  if (activeDoctorsEl) {
    activeDoctorsEl.textContent = dashboardStats.active_doctors || 0;
  }
  
  // Pending Revenue
  const pendingRevenueEl = document.getElementById('stat-pending-revenue');
  if (pendingRevenueEl) {
    pendingRevenueEl.textContent = formatCurrency(dashboardStats.pending_revenue || 0);
  }
}

/**
 * Load all appointments
 */
async function loadAppointments() {
  try {
    // Try using RPC function first
    const { data: rpcData, error: rpcError } = await supabase.rpc('admin_get_all_appointments');
    
    if (!rpcError && rpcData) {
      appointments = rpcData;
    } else {
      // Fallback to direct query
      const { data, error } = await supabase
        .from('appointments')
        .select(`
          id,
          token_number,
          appointment_date,
          appointment_time,
          status,
          reason,
          consultation_fee,
          payment_status,
          created_at
        `)
        .order('created_at', { ascending: false })
        .limit(100);
      
      if (error) {
        console.error('Failed to load appointments:', error);
        appointments = [];
      } else {
        appointments = data || [];
        
        // Load queue positions separately
        const appointmentIds = appointments.map(a => a.id);
        if (appointmentIds.length > 0) {
          const { data: queueData } = await supabase
            .from('queue_positions')
            .select('appointment_id, position')
            .in('appointment_id', appointmentIds);
          
          if (queueData) {
            // Merge queue positions
            appointments = appointments.map(appt => {
              const queue = queueData.find(q => q.appointment_id === appt.id);
              return {
                ...appt,
                queue_position: queue ? queue.position : null
              };
            });
          }
        }
      }
    }
    
    displayAppointments();
    
  } catch (error) {
    console.error('Error loading appointments:', error);
    appointments = [];
    displayAppointments();
  }
}

/**
 * Display appointments table
 */
function displayAppointments() {
  const tableBody = document.getElementById('appointments-table-body');
  const emptyState = document.getElementById('appointments-empty-state');
  
  if (!tableBody) return;
  
  // Filter appointments
  let filteredAppointments = filterAppointments();
  
  // Apply search
  if (searchQuery.trim()) {
    const query = searchQuery.toLowerCase();
    filteredAppointments = filteredAppointments.filter(appt => 
      (appt.token_number && appt.token_number.toLowerCase().includes(query)) ||
      (appt.reason && appt.reason.toLowerCase().includes(query)) ||
      (appt.status && appt.status.toLowerCase().includes(query))
    );
  }
  
  // Show/hide empty state
  if (filteredAppointments.length === 0) {
    if (emptyState) emptyState.classList.remove('hidden');
    tableBody.innerHTML = '';
    return;
  }
  
  if (emptyState) emptyState.classList.add('hidden');
  
  // Render appointments
  tableBody.innerHTML = filteredAppointments.map(appt => {
    const statusColor = getStatusColor(appt.status);
    const paymentColor = getPaymentStatusColor(appt.payment_status);
    
    return `
      <tr class="border-b border-slate-100 hover:bg-slate-50 transition-colors">
        <td class="px-6 py-4">
          <div class="font-mono font-bold text-navy-900">${appt.token_number || 'N/A'}</div>
          <div class="text-xs text-slate-500 mt-1">${formatDate(appt.created_at)}</div>
        </td>
        <td class="px-6 py-4">
          <div class="font-medium text-navy-900">${formatDate(appt.appointment_date)}</div>
          <div class="text-sm text-slate-600">${formatTime(appt.appointment_time)}</div>
        </td>
        <td class="px-6 py-4">
          <span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium ${statusColor}">
            <span class="h-1.5 w-1.5 rounded-full bg-current"></span>
            ${appt.status || 'pending'}
          </span>
        </td>
        <td class="px-6 py-4">
          <div class="text-sm text-slate-700 max-w-xs truncate">${appt.reason || 'General consultation'}</div>
        </td>
        <td class="px-6 py-4">
          <div class="font-mono font-bold text-navy-900">${appt.consultation_fee ? formatCurrency(appt.consultation_fee) : '-'}</div>
          <span class="inline-flex items-center gap-1 px-2 py-0.5 rounded text-xs font-medium ${paymentColor} mt-1">
            ${appt.payment_status || 'pending'}
          </span>
        </td>
        <td class="px-6 py-4 text-center">
          <div class="inline-flex items-center justify-center w-8 h-8 rounded-full bg-teal-100 text-teal-700 font-bold text-sm">
            ${appt.queue_position || '-'}
          </div>
        </td>
        <td class="px-6 py-4 text-right">
          <div class="flex items-center justify-end gap-2">
            <button 
              onclick="viewAppointmentDetails('${appt.id}')"
              class="p-2 text-slate-600 hover:text-teal-600 hover:bg-teal-50 rounded-lg transition-colors"
              title="View Details"
            >
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
              </svg>
            </button>
            ${appt.status === 'pending' ? `
              <button 
                onclick="updateAppointmentStatus('${appt.id}', 'confirmed')"
                class="p-2 text-green-600 hover:bg-green-50 rounded-lg transition-colors"
                title="Confirm"
              >
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                </svg>
              </button>
              <button 
                onclick="cancelAppointment('${appt.id}')"
                class="p-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                title="Cancel"
              >
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            ` : ''}
          </div>
        </td>
      </tr>
    `;
  }).join('');
  
  // Update count
  const countEl = document.getElementById('appointments-count');
  if (countEl) {
    countEl.textContent = filteredAppointments.length;
  }
}

/**
 * Filter appointments based on current filter
 */
function filterAppointments() {
  switch (currentFilter) {
    case 'today':
      const today = new Date().toISOString().split('T')[0];
      return appointments.filter(appt => appt.appointment_date === today);
    case 'pending':
      return appointments.filter(appt => appt.status === 'pending');
    case 'completed':
      return appointments.filter(appt => appt.status === 'completed');
    case 'cancelled':
      return appointments.filter(appt => appt.status === 'cancelled');
    case 'all':
    default:
      return appointments;
  }
}

/**
 * Get status badge color
 */
function getStatusColor(status) {
  switch (status) {
    case 'pending':
      return 'bg-yellow-100 text-yellow-700';
    case 'confirmed':
      return 'bg-blue-100 text-blue-700';
    case 'checked_in':
      return 'bg-purple-100 text-purple-700';
    case 'in_progress':
      return 'bg-indigo-100 text-indigo-700';
    case 'completed':
      return 'bg-green-100 text-green-700';
    case 'cancelled':
      return 'bg-red-100 text-red-700';
    case 'no_show':
      return 'bg-slate-100 text-slate-700';
    default:
      return 'bg-slate-100 text-slate-700';
  }
}

/**
 * Get payment status badge color
 */
function getPaymentStatusColor(status) {
  switch (status) {
    case 'paid':
      return 'bg-green-100 text-green-700';
    case 'pending':
      return 'bg-yellow-100 text-yellow-700';
    case 'refunded':
      return 'bg-red-100 text-red-700';
    default:
      return 'bg-slate-100 text-slate-700';
  }
}

/**
 * Setup real-time subscriptions
 */
function setupRealtimeSubscriptions() {
  // Subscribe to appointments table changes
  realtimeSubscription = supabase
    .channel('admin-dashboard')
    .on(
      'postgres_changes',
      { event: '*', schema: 'public', table: 'appointments' },
      (payload) => {
        console.log('Real-time update:', payload);
        handleRealtimeUpdate(payload);
      }
    )
    .on(
      'postgres_changes',
      { event: '*', schema: 'public', table: 'queue_positions' },
      (payload) => {
        console.log('Queue update:', payload);
        handleQueueUpdate(payload);
      }
    )
    .subscribe((status) => {
      console.log('Real-time subscription status:', status);
      if (status === 'SUBSCRIBED') {
        toast.success('Real-time updates enabled', { duration: 2000 });
      }
    });
}

/**
 * Handle real-time appointment updates
 */
function handleRealtimeUpdate(payload) {
  const { eventType, new: newRecord, old: oldRecord } = payload;
  
  switch (eventType) {
    case 'INSERT':
      appointments.unshift(newRecord);
      toast.success('New appointment created', { duration: 3000 });
      break;
    case 'UPDATE':
      const updateIndex = appointments.findIndex(a => a.id === newRecord.id);
      if (updateIndex !== -1) {
        appointments[updateIndex] = { ...appointments[updateIndex], ...newRecord };
        toast.info('Appointment updated', { duration: 2000 });
      }
      break;
    case 'DELETE':
      appointments = appointments.filter(a => a.id !== oldRecord.id);
      toast.info('Appointment deleted', { duration: 2000 });
      break;
  }
  
  // Refresh display
  displayAppointments();
  loadDashboardStats();
}

/**
 * Handle queue position updates
 */
function handleQueueUpdate(payload) {
  const { eventType, new: newRecord } = payload;
  
  if (eventType === 'INSERT' || eventType === 'UPDATE') {
    const apptIndex = appointments.findIndex(a => a.id === newRecord.appointment_id);
    if (apptIndex !== -1) {
      appointments[apptIndex].queue_position = newRecord.position;
      displayAppointments();
    }
  }
}

/**
 * Setup event listeners
 */
function setupEventListeners() {
  // Filter buttons
  document.querySelectorAll('[data-filter]').forEach(btn => {
    btn.addEventListener('click', (e) => {
      const filter = e.currentTarget.dataset.filter;
      setFilter(filter);
    });
  });
  
  // Search input
  const searchInput = document.getElementById('appointments-search');
  if (searchInput) {
    searchInput.addEventListener('input', (e) => {
      searchQuery = e.target.value;
      displayAppointments();
    });
  }
  
  // Refresh button
  const refreshBtn = document.getElementById('refresh-btn');
  if (refreshBtn) {
    refreshBtn.addEventListener('click', async () => {
      toast.info('Refreshing data...');
      await loadDashboardStats();
      await loadAppointments();
      toast.success('Data refreshed');
    });
  }
}

/**
 * Set active filter
 */
function setFilter(filter) {
  currentFilter = filter;
  
  // Update button states
  document.querySelectorAll('[data-filter]').forEach(btn => {
    if (btn.dataset.filter === filter) {
      btn.classList.add('bg-teal-600', 'text-white');
      btn.classList.remove('bg-white', 'text-slate-700');
    } else {
      btn.classList.remove('bg-teal-600', 'text-white');
      btn.classList.add('bg-white', 'text-slate-700');
    }
  });
  
  displayAppointments();
}

/**
 * View appointment details (global function)
 */
window.viewAppointmentDetails = function(appointmentId) {
  const appt = appointments.find(a => a.id === appointmentId);
  if (!appt) return;
  
  toast.info(`Viewing appointment ${appt.token_number}`);
  // TODO: Open modal with full details
};

/**
 * Update appointment status (global function)
 */
window.updateAppointmentStatus = async function(appointmentId, newStatus) {
  try {
    const { error } = await supabase
      .from('appointments')
      .update({ status: newStatus, updated_at: new Date().toISOString() })
      .eq('id', appointmentId);
    
    if (error) throw error;
    
    toast.success(`Appointment ${newStatus}`);
    await loadAppointments();
    
  } catch (error) {
    console.error('Failed to update appointment:', error);
    toast.error('Failed to update appointment');
  }
};

/**
 * Cancel appointment (global function)
 */
window.cancelAppointment = async function(appointmentId) {
  if (!confirm('Are you sure you want to cancel this appointment?')) {
    return;
  }
  
  try {
    const { error } = await supabase
      .from('appointments')
      .update({ 
        status: 'cancelled',
        cancelled_by: 'admin',
        cancellation_reason: 'Cancelled by administrator',
        updated_at: new Date().toISOString() 
      })
      .eq('id', appointmentId);
    
    if (error) throw error;
    
    toast.success('Appointment cancelled');
    await loadAppointments();
    
  } catch (error) {
    console.error('Failed to cancel appointment:', error);
    toast.error('Failed to cancel appointment');
  }
};

/**
 * Cleanup on page unload
 */
window.addEventListener('beforeunload', () => {
  if (realtimeSubscription) {
    supabase.removeChannel(realtimeSubscription);
  }
  if (statsInterval) {
    clearInterval(statsInterval);
  }
});
