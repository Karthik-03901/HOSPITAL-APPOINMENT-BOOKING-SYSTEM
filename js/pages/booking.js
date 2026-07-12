/**
 * Appointment Booking System - Complete Wizard Flow
 * 4-Step Process: Department → Doctor → Date & Time → Confirmation
 */

import { 
  departments, 
  doctors, 
  getDepartmentById, 
  getDoctorById, 
  getDoctorsByDepartment, 
  getAvailableSlots 
} from '../data/mockData.js';
import { toast } from '../components/Toast.js';
import { formatDate, formatTime, formatCurrency, getInitials } from '../utils/formatters.js';

// State management
let currentStep = 1;
let selectedDepartment = null;
let selectedDoctor = null;
let selectedDate = null;
let selectedTime = null;
let bookingData = {};

// Initialize on page load
document.addEventListener('DOMContentLoaded', () => {
  initBookingSystem();
});

/**
 * Initialize the booking system
 */
function initBookingSystem() {
  setupDateInput();
  loadDepartments();
  
  // Make functions globally available for onclick handlers
  window.previousStep = previousStep;
  window.goToConfirmation = goToConfirmation;
  window.confirmBooking = confirmBooking;
  window.closeSuccessModal = closeSuccessModal;
}

/**
 * Setup date input with constraints
 */
function setupDateInput() {
  const dateInput = document.getElementById('appointment-date');
  if (!dateInput) return;
  
  // Set min date to tomorrow
  const tomorrow = new Date();
  tomorrow.setDate(tomorrow.getDate() + 1);
  dateInput.min = tomorrow.toISOString().split('T')[0];
  
  // Set max date to 30 days from now
  const maxDate = new Date();
  maxDate.setDate(maxDate.getDate() + 30);
  dateInput.max = maxDate.toISOString().split('T')[0];
  
  // Listen for date changes
  dateInput.addEventListener('change', handleDateChange);
}

/**
 * STEP 1: Load and display departments
 */
function loadDepartments() {
  const grid = document.getElementById('departments-grid');
  if (!grid) return;
  
  grid.innerHTML = departments.map(dept => `
    <div 
      class="card-glass p-6 cursor-pointer hover-lift group transition-all duration-300 ${!dept.availableToday ? 'opacity-60' : ''}"
      onclick="selectDepartment('${dept.id}')"
    >
      <div class="flex items-start justify-between mb-4">
        <div class="text-4xl">${dept.icon}</div>
        ${dept.availableToday 
          ? '<span class="status-pill bg-green-500/15 text-green-600"><span class="h-2 w-2 rounded-full bg-green-500"></span> Available</span>'
          : '<span class="status-pill bg-slate-500/15 text-slate-500">Unavailable</span>'
        }
      </div>
      
      <h3 class="font-display text-xl font-bold text-navy-900 mb-2 group-hover:text-teal-600 transition-colors">
        ${dept.name}
      </h3>
      <p class="text-sm text-slate-600 mb-4">${dept.description}</p>
      
      <div class="grid grid-cols-2 gap-3 text-xs">
        <div class="flex items-center gap-2 text-slate-600">
          <svg class="w-4 h-4 text-teal-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
          </svg>
          <span>${dept.totalDoctors} Doctors</span>
        </div>
        <div class="flex items-center gap-2 text-slate-600">
          <svg class="w-4 h-4 text-teal-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <span>~${dept.avgWaitTime} min</span>
        </div>
      </div>
      
      <div class="mt-4 pt-4 border-t border-slate-200">
        <div class="flex items-center justify-between">
          <span class="text-xs text-slate-500">Consultation Fee</span>
          <span class="font-mono font-bold text-teal-600">${formatCurrency(dept.consultationFee)}</span>
        </div>
      </div>
    </div>
  `).join('');
}

/**
 * Handle department selection
 */
window.selectDepartment = function(departmentId) {
  const dept = getDepartmentById(departmentId);
  
  if (!dept.availableToday) {
    toast.error('This department is currently unavailable. Please try again later.');
    return;
  }
  
  selectedDepartment = dept;
  loadDoctors(departmentId);
  navigateToStep(2);
};

/**
 * STEP 2: Load and display doctors for selected department
 */
function loadDoctors(departmentId) {
  const grid = document.getElementById('doctors-grid');
  const deptNameEl = document.getElementById('dept-name');
  
  if (!grid || !deptNameEl) return;
  
  const dept = getDepartmentById(departmentId);
  deptNameEl.textContent = dept.name;
  
  const deptDoctors = getDoctorsByDepartment(departmentId);
  
  if (deptDoctors.length === 0) {
    grid.innerHTML = `
      <div class="col-span-2 text-center py-12">
        <svg class="w-16 h-16 text-slate-300 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
        </svg>
        <p class="text-slate-600 font-medium">No doctors available in this department</p>
      </div>
    `;
    return;
  }
  
  grid.innerHTML = deptDoctors.map(doctor => {
    const initials = getInitials(doctor.name);
    const stars = '⭐'.repeat(Math.floor(doctor.rating));
    
    return `
      <div 
        class="card p-6 cursor-pointer hover-lift group transition-all duration-300"
        onclick="selectDoctor('${doctor.id}')"
      >
        <div class="flex items-start gap-4 mb-4">
          <div class="avatar avatar-lg bg-teal-100 text-teal-700 flex-shrink-0">
            ${initials}
          </div>
          <div class="flex-1 min-w-0">
            <h3 class="font-display text-lg font-bold text-navy-900 mb-1 group-hover:text-teal-600 transition-colors truncate">
              ${doctor.name}
            </h3>
            <p class="text-sm text-slate-600 mb-2">${doctor.specialization}</p>
            <p class="text-xs text-slate-500">${doctor.qualification}</p>
          </div>
        </div>
        
        <div class="space-y-3 mb-4">
          <div class="flex items-center justify-between text-sm">
            <span class="text-slate-600">Experience</span>
            <span class="font-semibold text-navy-900">${doctor.experience} years</span>
          </div>
          <div class="flex items-center justify-between text-sm">
            <span class="text-slate-600">Rating</span>
            <span class="font-semibold">
              ${stars} ${doctor.rating} <span class="text-slate-500 text-xs">(${doctor.totalReviews})</span>
            </span>
          </div>
          <div class="flex items-center justify-between text-sm">
            <span class="text-slate-600">Consultation</span>
            <span class="font-mono font-bold text-teal-600">${formatCurrency(doctor.consultationFee)}</span>
          </div>
        </div>
        
        <div class="pt-4 border-t border-slate-100">
          <div class="flex items-center gap-2 text-xs text-slate-600 mb-2">
            <svg class="w-4 h-4 text-teal-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5h12M9 3v2m1.048 9.5A18.022 18.022 0 016.412 9m6.088 9h7M11 21l5-10 5 10M12.751 5C11.783 10.77 8.07 15.61 3 18.129" />
            </svg>
            <span>Languages: ${doctor.languages.join(', ')}</span>
          </div>
          <div class="flex items-center gap-2 text-xs text-slate-600">
            <svg class="w-4 h-4 text-teal-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
            </svg>
            <span>Next available: ${formatDate(doctor.nextAvailable)}</span>
          </div>
        </div>
        
        <div class="mt-4">
          <p class="text-xs text-slate-600 line-clamp-2">${doctor.bio}</p>
        </div>
      </div>
    `;
  }).join('');
}

/**
 * Handle doctor selection
 */
window.selectDoctor = function(doctorId) {
  selectedDoctor = getDoctorById(doctorId);
  displayDoctorInfo();
  navigateToStep(3);
};

/**
 * STEP 3: Display selected doctor info in sidebar
 */
function displayDoctorInfo() {
  if (!selectedDoctor) return;
  
  const initials = getInitials(selectedDoctor.name);
  
  document.getElementById('doctor-avatar').textContent = initials;
  document.getElementById('doctor-name-display').textContent = selectedDoctor.name;
  document.getElementById('doctor-spec-display').textContent = selectedDoctor.specialization;
  document.getElementById('doctor-exp').textContent = `${selectedDoctor.experience} years`;
  document.getElementById('doctor-rating').textContent = `⭐ ${selectedDoctor.rating}`;
  document.getElementById('doctor-fee').textContent = formatCurrency(selectedDoctor.consultationFee);
}

/**
 * Handle date selection and load time slots
 */
function handleDateChange(e) {
  selectedDate = e.target.value;
  selectedTime = null; // Reset time selection
  
  if (selectedDate && selectedDoctor) {
    loadTimeSlots();
  }
  
  updateContinueButton();
}

/**
 * Load and display available time slots
 */
function loadTimeSlots() {
  const container = document.getElementById('time-slots-container');
  const noSlotsMsg = document.getElementById('no-slots-message');
  
  if (!container || !selectedDoctor || !selectedDate) return;
  
  const availableSlots = getAvailableSlots(selectedDoctor.id, selectedDate);
  
  if (availableSlots.length === 0) {
    container.classList.add('hidden');
    noSlotsMsg.classList.remove('hidden');
    return;
  }
  
  container.classList.remove('hidden');
  noSlotsMsg.classList.add('hidden');
  
  container.innerHTML = availableSlots.map(slot => `
    <button 
      class="time-slot" 
      data-time="${slot}"
      onclick="selectTimeSlot('${slot}')"
    >
      ${formatTime(slot)}
    </button>
  `).join('');
}

/**
 * Handle time slot selection
 */
window.selectTimeSlot = function(time) {
  selectedTime = time;
  
  // Update UI - remove previous selection
  document.querySelectorAll('.time-slot').forEach(slot => {
    slot.classList.remove('selected');
  });
  
  // Add selection to clicked slot
  event.target.classList.add('selected');
  
  updateContinueButton();
};

/**
 * Update continue button state
 */
function updateContinueButton() {
  const btn = document.getElementById('continue-to-confirm-btn');
  if (!btn) return;
  
  if (selectedDate && selectedTime) {
    btn.disabled = false;
    btn.classList.remove('opacity-50', 'cursor-not-allowed');
  } else {
    btn.disabled = true;
    btn.classList.add('opacity-50', 'cursor-not-allowed');
  }
}

/**
 * Navigate to confirmation step
 */
window.goToConfirmation = function() {
  if (!selectedDate || !selectedTime) {
    toast.warning('Please select both date and time slot');
    return;
  }
  
  populateConfirmationSummary();
  navigateToStep(4);
};

/**
 * STEP 4: Populate confirmation summary
 */
function populateConfirmationSummary() {
  const tokenNumber = generateTokenNumber();
  
  document.getElementById('summary-dept-doctor').textContent = 
    `${selectedDepartment.name} • ${selectedDoctor.name}`;
  document.getElementById('summary-token').textContent = tokenNumber;
  document.getElementById('summary-date').textContent = formatDate(selectedDate, 'long');
  document.getElementById('summary-time').textContent = formatTime(selectedTime);
  document.getElementById('summary-fee').textContent = formatCurrency(selectedDoctor.consultationFee);
  document.getElementById('summary-wait').textContent = `~${selectedDepartment.avgWaitTime} min`;
  
  // Store for final submission
  bookingData = {
    token: tokenNumber,
    department: selectedDepartment,
    doctor: selectedDoctor,
    date: selectedDate,
    time: selectedTime
  };
}

/**
 * Generate random token number
 */
function generateTokenNumber() {
  const prefix = String.fromCharCode(65 + Math.floor(Math.random() * 26)); // A-Z
  const number = Math.floor(Math.random() * 900) + 100; // 100-999
  return `${prefix}-${number}`;
}

/**
 * Confirm and submit booking
 */
window.confirmBooking = function() {
  const reasonInput = document.getElementById('reason');
  const medicalHistoryInput = document.getElementById('medical-history');
  
  // Validate required fields
  if (!reasonInput.value.trim()) {
    toast.error('Please provide a reason for your visit');
    reasonInput.focus();
    return;
  }
  
  // Add to booking data
  bookingData.reason = reasonInput.value.trim();
  bookingData.medicalHistory = medicalHistoryInput.value.trim();
  bookingData.status = 'pending';
  bookingData.createdAt = new Date().toISOString();
  
  // Show loading state
  const btn = document.getElementById('confirm-booking-btn');
  const originalText = btn.innerHTML;
  btn.disabled = true;
  btn.innerHTML = `
    <svg class="animate-spin h-5 w-5 mr-2" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
      <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
      <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
    </svg>
    Processing...
  `;
  
  // Simulate API call
  setTimeout(() => {
    // Store in localStorage (would be Supabase in production)
    saveBooking(bookingData);
    
    // Reset button
    btn.disabled = false;
    btn.innerHTML = originalText;
    
    // Show success modal
    showSuccessModal();
    
    toast.success('Appointment booked successfully! Check your email for confirmation.');
  }, 1500);
};

/**
 * Save booking to localStorage (mock database)
 */
function saveBooking(booking) {
  try {
    let bookings = JSON.parse(localStorage.getItem('appointments') || '[]');
    bookings.push(booking);
    localStorage.setItem('appointments', JSON.stringify(bookings));
    console.log('Booking saved:', booking);
  } catch (error) {
    console.error('Failed to save booking:', error);
  }
}

/**
 * Show success modal
 */
function showSuccessModal() {
  const modal = document.getElementById('success-modal');
  const modalContent = document.getElementById('success-modal-content');
  
  document.getElementById('final-token').textContent = bookingData.token;
  
  modal.classList.remove('opacity-0', 'pointer-events-none');
  setTimeout(() => {
    modalContent.classList.remove('scale-95');
    modalContent.classList.add('scale-100');
  }, 10);
}

/**
 * Close success modal
 */
window.closeSuccessModal = function() {
  const modal = document.getElementById('success-modal');
  const modalContent = document.getElementById('success-modal-content');
  
  modalContent.classList.remove('scale-100');
  modalContent.classList.add('scale-95');
  
  setTimeout(() => {
    modal.classList.add('opacity-0', 'pointer-events-none');
    
    // Reset form after modal closes
    setTimeout(() => {
      resetBookingFlow();
    }, 300);
  }, 300);
};

/**
 * Reset booking flow to start
 */
function resetBookingFlow() {
  currentStep = 1;
  selectedDepartment = null;
  selectedDoctor = null;
  selectedDate = null;
  selectedTime = null;
  bookingData = {};
  
  document.getElementById('appointment-date').value = '';
  document.getElementById('reason').value = '';
  document.getElementById('medical-history').value = '';
  
  navigateToStep(1);
  loadDepartments();
}

/**
 * Navigate to specific step (only if allowed)
 * Users can only navigate to completed steps or current step
 */
window.navigateToStepIfAllowed = function(targetStep) {
  // Can only navigate to completed steps or stay on current step
  if (targetStep < currentStep || targetStep === currentStep) {
    navigateToStep(targetStep);
  } else {
    // Show toast if trying to skip ahead
    toast.warning('Please complete the current step before proceeding');
  }
};

/**
 * Navigate to previous step
 */
window.previousStep = function() {
  if (currentStep > 1) {
    navigateToStep(currentStep - 1);
  }
};

/**
 * Navigate to specific step
 */
function navigateToStep(step) {
  currentStep = step;
  
  // Hide all steps
  for (let i = 1; i <= 4; i++) {
    const stepContent = document.getElementById(`step-${i}`);
    const stepIndicator = document.getElementById(`step-${i}-indicator`);
    
    if (stepContent) {
      stepContent.classList.add('hidden');
    }
    
    if (stepIndicator) {
      stepIndicator.classList.remove('active', 'completed');
    }
  }
  
  // Show current step
  const currentStepContent = document.getElementById(`step-${step}`);
  const currentStepIndicator = document.getElementById(`step-${step}-indicator`);
  
  if (currentStepContent) {
    currentStepContent.classList.remove('hidden');
  }
  
  if (currentStepIndicator) {
    currentStepIndicator.classList.add('active');
  }
  
  // Mark previous steps as completed
  for (let i = 1; i < step; i++) {
    const indicator = document.getElementById(`step-${i}-indicator`);
    if (indicator) {
      indicator.classList.add('completed');
    }
  }
  
  // Smooth scroll to top
  window.scrollTo({ top: 0, behavior: 'smooth' });
}
