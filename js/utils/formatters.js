/**
 * Formatting utilities for dates, times, currency, and display values
 */

/**
 * Format date to human-readable string
 * @param {Date|string} date 
 * @param {string} format - 'short' | 'long' | 'time' | 'datetime'
 */
export function formatDate(date, format = 'short') {
  if (!date) return '';
  
  const d = typeof date === 'string' ? new Date(date) : date;
  
  const options = {
    short: { month: 'short', day: 'numeric', year: 'numeric' },
    long: { weekday: 'long', month: 'long', day: 'numeric', year: 'numeric' },
    time: { hour: '2-digit', minute: '2-digit', hour12: true },
    datetime: { month: 'short', day: 'numeric', year: 'numeric', hour: '2-digit', minute: '2-digit', hour12: true }
  };
  
  return d.toLocaleDateString('en-US', options[format] || options.short);
}

/**
 * Format time to 12-hour format
 * @param {string} time - HH:MM:SS or HH:MM
 */
export function formatTime(time) {
  if (!time) return '';
  
  const [hours, minutes] = time.split(':');
  const h = parseInt(hours);
  const period = h >= 12 ? 'PM' : 'AM';
  const displayHour = h % 12 || 12;
  
  return `${displayHour}:${minutes} ${period}`;
}

/**
 * Calculate relative time (e.g., "2 hours ago", "in 15 minutes")
 */
export function relativeTime(date) {
  if (!date) return '';
  
  const d = typeof date === 'string' ? new Date(date) : date;
  const now = new Date();
  const diffMs = now - d;
  const diffMins = Math.floor(diffMs / 60000);
  const diffHours = Math.floor(diffMins / 60);
  const diffDays = Math.floor(diffHours / 24);
  
  if (diffMins < 1) return 'Just now';
  if (diffMins < 60) return `${diffMins} min${diffMins !== 1 ? 's' : ''} ago`;
  if (diffHours < 24) return `${diffHours} hour${diffHours !== 1 ? 's' : ''} ago`;
  if (diffDays < 7) return `${diffDays} day${diffDays !== 1 ? 's' : ''} ago`;
  
  return formatDate(d, 'short');
}

/**
 * Format currency (default Indian Rupees)
 */
export function formatCurrency(amount, currency = 'INR') {
  if (amount === null || amount === undefined) return '';
  
  const symbols = { INR: '₹', USD: '$', EUR: '€', GBP: '£' };
  const symbol = symbols[currency] || currency;
  
  return `${symbol}${parseFloat(amount).toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
}

/**
 * Format phone number
 */
export function formatPhone(phone) {
  if (!phone) return '';
  
  const cleaned = phone.replace(/\D/g, '');
  
  if (cleaned.length === 10) {
    return `+91 ${cleaned.slice(0, 5)} ${cleaned.slice(5)}`;
  }
  
  return phone;
}

/**
 * Generate initials from full name
 */
export function getInitials(name) {
  if (!name) return '?';
  
  return name
    .split(' ')
    .map(word => word[0])
    .join('')
    .toUpperCase()
    .slice(0, 2);
}

/**
 * Truncate text with ellipsis
 */
export function truncate(text, maxLength = 50) {
  if (!text || text.length <= maxLength) return text;
  return text.slice(0, maxLength - 3) + '...';
}

/**
 * Get status badge color classes
 */
export function getStatusColor(status) {
  const colors = {
    pending: 'bg-amber-500/15 text-amber-600',
    confirmed: 'bg-teal-500/15 text-teal-600',
    completed: 'bg-slate-500/15 text-slate-600',
    cancelled: 'bg-coral-500/15 text-coral-600',
    no_show: 'bg-slate-500/15 text-slate-500'
  };
  
  return colors[status] || colors.pending;
}

/**
 * Calculate ETA based on queue position and average consultation time
 */
export function calculateETA(patientsAhead, avgConsultationMins = 15) {
  const totalMins = patientsAhead * avgConsultationMins;
  const hours = Math.floor(totalMins / 60);
  const mins = totalMins % 60;
  
  if (hours === 0) return `${mins} mins`;
  return `${hours}h ${mins}m`;
}

/**
 * Format file size
 */
export function formatFileSize(bytes) {
  if (bytes === 0) return '0 Bytes';
  
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}
