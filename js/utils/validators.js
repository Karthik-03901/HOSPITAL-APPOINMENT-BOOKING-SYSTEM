/**
 * Form validation utilities
 */

/**
 * Validate email format
 */
export function validateEmail(email) {
  const regex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return regex.test(email);
}

/**
 * Validate password strength
 * Returns { valid: boolean, message: string }
 */
export function validatePassword(password) {
  if (password.length < 8) {
    return { valid: false, message: 'Password must be at least 8 characters' };
  }
  
  if (!/[A-Z]/.test(password)) {
    return { valid: false, message: 'Password must contain an uppercase letter' };
  }
  
  if (!/[a-z]/.test(password)) {
    return { valid: false, message: 'Password must contain a lowercase letter' };
  }
  
  if (!/[0-9]/.test(password)) {
    return { valid: false, message: 'Password must contain a number' };
  }
  
  return { valid: true, message: 'Password is strong' };
}

/**
 * Validate Indian phone number (10 digits)
 */
export function validatePhone(phone) {
  const cleaned = phone.replace(/\D/g, '');
  return cleaned.length === 10 && /^[6-9]\d{9}$/.test(cleaned);
}

/**
 * Validate date is in future
 */
export function validateFutureDate(date) {
  const d = typeof date === 'string' ? new Date(date) : date;
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  return d >= today;
}

/**
 * Validate time format (HH:MM)
 */
export function validateTime(time) {
  return /^([01]\d|2[0-3]):([0-5]\d)$/.test(time);
}

/**
 * Validate required field
 */
export function validateRequired(value) {
  if (typeof value === 'string') {
    return value.trim().length > 0;
  }
  return value !== null && value !== undefined;
}

/**
 * Validate age (must be >= 18)
 */
export function validateAge(dateOfBirth) {
  const dob = new Date(dateOfBirth);
  const today = new Date();
  const age = today.getFullYear() - dob.getFullYear();
  const monthDiff = today.getMonth() - dob.getMonth();
  
  if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < dob.getDate())) {
    return age - 1 >= 18;
  }
  
  return age >= 18;
}

/**
 * Sanitize HTML to prevent XSS
 */
export function sanitizeHTML(str) {
  const temp = document.createElement('div');
  temp.textContent = str;
  return temp.innerHTML;
}

/**
 * Generic form validator
 * @param {Object} data - Form data object
 * @param {Object} rules - Validation rules
 * @returns {Object} - { valid: boolean, errors: { field: message } }
 */
export function validateForm(data, rules) {
  const errors = {};
  
  for (const [field, validators] of Object.entries(rules)) {
    const value = data[field];
    
    for (const validator of validators) {
      const result = validator(value);
      
      if (!result.valid) {
        errors[field] = result.message;
        break;
      }
    }
  }
  
  return {
    valid: Object.keys(errors).length === 0,
    errors
  };
}

/**
 * Helper to create validator functions
 */
export const Validators = {
  required: (message = 'This field is required') => (value) => ({
    valid: validateRequired(value),
    message
  }),
  
  email: (message = 'Invalid email format') => (value) => ({
    valid: !value || validateEmail(value),
    message
  }),
  
  phone: (message = 'Invalid phone number') => (value) => ({
    valid: !value || validatePhone(value),
    message
  }),
  
  minLength: (length, message) => (value) => ({
    valid: !value || value.length >= length,
    message: message || `Must be at least ${length} characters`
  }),
  
  maxLength: (length, message) => (value) => ({
    valid: !value || value.length <= length,
    message: message || `Must be at most ${length} characters`
  }),
  
  pattern: (regex, message = 'Invalid format') => (value) => ({
    valid: !value || regex.test(value),
    message
  })
};
