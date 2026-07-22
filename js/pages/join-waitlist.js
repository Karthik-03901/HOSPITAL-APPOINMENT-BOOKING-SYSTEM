/**
 * Join Waitlist Page
 * Allows patients to join waitlist when slots are full
 */

import { supabase } from '../supabaseClient.js';
import { toast } from '../components/Toast.js';
import { doctors, getDoctorById } from '../data/mockData.js';

let currentWaitlistId = null;
window.currentWaitlistId = null; // For modal access

// Initialize on page load
document.addEventListener('DOMContentLoaded', () => {
  initWaitlistForm();
  setupDateInput();
  loadDoctors();
});

/**
 * Initialize waitlist form
 */
function initWaitlistForm() {
  const form = document.getElementById('waitlist-form');
  form.addEventListener('submit', handleWaitlistSubmit);
}

/**
 * Setup date input constraints
 */
function setupDateInput() {
  const dateInput = document.getElementById('preferred-date');
  
  // Set min date to tomorrow
  const tomorrow = new Date();
  tomorrow.setDate(tomorrow.getDate() + 1);
  dateInput.min = tomorrow.toISOString().split('T')[0];
  
  // Set max date to 30 days from now
  const maxDate = new Date();
  maxDate.setDate(maxDate.getDate() + 30);
  dateInput.max = maxDate.toISOString().split('T')[0];
}


/**
 * Load doctors into dropdown
 */
function loadDoctors() {
  const select = document.getElementById('doctor-select');
  
  select.innerHTML = '<option value="">Choose a doctor...</option>' + 
    doctors.map(doctor => `
      <option value="${doctor.id}" data-name="${doctor.name}">
        ${doctor.name} - ${doctor.specialization}
      </option>
    `).join('');
}

/**
 * Handle waitlist form submission
 */
async function handleWaitlistSubmit(e) {
  e.preventDefault();
  
  const submitBtn = document.getElementById('join-btn');
  const originalText = submitBtn.innerHTML;
  
  // Get form data
  const patientName = document.getElementById('patient-name').value.trim();
  const patientEmail = document.getElementById('patient-email').value.trim();
  const patientPhone = document.getElementById('patient-phone').value.trim();
  const doctorSelect = document.getElementById('doctor-select');
  const doctorId = doctorSelect.value;
  const doctorName = doctorSelect.selectedOptions[0].dataset.name;
  const preferredDate = document.getElementById('preferred-date').value;
  const timeRange = document.getElementById('time-range').value;
  const reason = document.getElementById('reason').value.trim();
  
  // Validation
  if (!doctorId) {
    toast.error('Please select a doctor');
    return;
  }
  
  // Show loading
  submitBtn.disabled = true;
  submitBtn.innerHTML = `
    <svg class="animate-spin h-5 w-5 mr-2" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
      <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
      <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
    </svg>
    Adding to Waitlist...
  `;
  
  try {
    // Get doctor details
    const doctor = getDoctorById(doctorId);
    
    // Call Supabase RPC function
    const { data, error } = await supabase.rpc('join_waitlist', {
      p_patient_name: patientName,
      p_patient_email: patientEmail,
      p_patient_phone: patientPhone,
      p_doctor_id: null, // We'll use doctorName for display
      p_doctor_name: doctorName,
      p_department_name: doctor.specialization,
      p_preferred_date: preferredDate,
      p_preferred_time_range: timeRange,
      p_reason: reason
    });
    
    if (error) {
      console.error('Waitlist error:', error);
      throw error;
    }
    
    console.log('Waitlist response:', data);
    
    if (!data.success) {
      throw new Error(data.error || 'Failed to join waitlist');
    }
    
    // Success!
    currentWaitlistId = data.waitlist_id;
    window.currentWaitlistId = data.waitlist_id;
    
    // Update modal
    document.getElementById('waitlist-position').textContent = `#${data.position}`;
    
    // Show success modal
    showSuccessModal();
    
    // Save to localStorage
    localStorage.setItem('currentWaitlistId', data.waitlist_id);
    localStorage.setItem('waitlistData', JSON.stringify({
      id: data.waitlist_id,
      patientName,
      patientEmail,
      doctorName,
      preferredDate,
      timeRange,
      position: data.position,
      joinedAt: new Date().toISOString()
    }));
    
    toast.success('Successfully joined waitlist!');
    
  } catch (error) {
    console.error('Failed to join waitlist:', error);
    toast.error(error.message || 'Failed to join waitlist. Please try again.');
    
    // Reset button
    submitBtn.disabled = false;
    submitBtn.innerHTML = originalText;
  }
}

/**
 * Show success modal
 */
function showSuccessModal() {
  const modal = document.getElementById('success-modal');
  const modalContent = document.getElementById('success-modal-content');
  
  modal.classList.remove('opacity-0', 'pointer-events-none');
  setTimeout(() => {
    modalContent.classList.remove('scale-95');
    modalContent.classList.add('scale-100');
  }, 10);
}

// Export for use in other modules
export { handleWaitlistSubmit };
