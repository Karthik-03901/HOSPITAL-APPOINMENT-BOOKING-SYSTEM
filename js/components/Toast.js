/**
 * Toast notification system
 * Usage: 
 *   import { showToast } from './components/Toast.js';
 *   showToast('Appointment booked successfully', 'success');
 */

let toastContainer = null;

/**
 * Initialize toast container
 */
function initToastContainer() {
  if (toastContainer) return;
  
  toastContainer = document.createElement('div');
  toastContainer.id = 'toast-container';
  toastContainer.className = 'fixed top-4 right-4 z-50 flex flex-col gap-3 max-w-md';
  document.body.appendChild(toastContainer);
}

/**
 * Show toast notification
 * @param {string} message - Notification message
 * @param {string} type - 'success' | 'error' | 'warning' | 'info'
 * @param {number} duration - Auto-dismiss duration in ms (0 = no auto-dismiss)
 */
export function showToast(message, type = 'info', duration = 4000) {
  initToastContainer();
  
  const toast = document.createElement('div');
  toast.className = `
    toast-item
    flex items-start gap-3 p-4 rounded-lg shadow-lg
    bg-white border-l-4 animate-slide-in
    ${getToastColors(type)}
  `;
  
  toast.innerHTML = `
    <div class="flex-shrink-0 mt-0.5">
      ${getToastIcon(type)}
    </div>
    <div class="flex-1 text-sm text-navy-900">
      ${message}
    </div>
    <button class="toast-close flex-shrink-0 text-slate-400 hover:text-navy-900 transition-colors">
      <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
      </svg>
    </button>
  `;
  
  // Close button handler
  const closeBtn = toast.querySelector('.toast-close');
  closeBtn.addEventListener('click', () => dismissToast(toast));
  
  toastContainer.appendChild(toast);
  
  // Auto-dismiss
  if (duration > 0) {
    setTimeout(() => dismissToast(toast), duration);
  }
  
  return toast;
}

/**
 * Dismiss a toast
 */
function dismissToast(toast) {
  toast.classList.add('animate-slide-out');
  setTimeout(() => {
    if (toast.parentNode) {
      toast.parentNode.removeChild(toast);
    }
  }, 300);
}

/**
 * Get toast colors based on type
 */
function getToastColors(type) {
  const colors = {
    success: 'border-green-500',
    error: 'border-coral-500',
    warning: 'border-amber-500',
    info: 'border-teal-500'
  };
  return colors[type] || colors.info;
}

/**
 * Get toast icon based on type
 */
function getToastIcon(type) {
  const icons = {
    success: `
      <svg class="w-5 h-5 text-green-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
      </svg>
    `,
    error: `
      <svg class="w-5 h-5 text-coral-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
      </svg>
    `,
    warning: `
      <svg class="w-5 h-5 text-amber-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
      </svg>
    `,
    info: `
      <svg class="w-5 h-5 text-teal-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
    `
  };
  return icons[type] || icons.info;
}

/**
 * Convenience methods
 */
export const toast = {
  success: (message, duration) => showToast(message, 'success', duration),
  error: (message, duration) => showToast(message, 'error', duration),
  warning: (message, duration) => showToast(message, 'warning', duration),
  info: (message, duration) => showToast(message, 'info', duration)
};
