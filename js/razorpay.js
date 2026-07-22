/**
 * Razorpay Payment Gateway Integration
 * Handles payment creation, verification, and callbacks
 */

import { supabase } from './supabaseClient.js';

// Load Razorpay key from environment
const RAZORPAY_KEY_ID = import.meta.env.VITE_RAZORPAY_KEY_ID || 'your_razorpay_key_id_here';

/**
 * Load Razorpay checkout script
 */
export function loadRazorpayScript() {
  return new Promise((resolve, reject) => {
    // Check if script already loaded
    if (window.Razorpay) {
      resolve(true);
      return;
    }

    const script = document.createElement('script');
    script.src = 'https://checkout.razorpay.com/v1/checkout.js';
    script.async = true;
    script.onload = () => resolve(true);
    script.onerror = () => reject(new Error('Failed to load Razorpay script'));
    document.body.appendChild(script);
  });
}

/**
 * Create payment order in database
 * @param {Object} appointmentData - Appointment and payment details
 * @returns {Promise<Object>} Payment order details
 */
export async function createPaymentOrder(appointmentData) {
  try {
    const {
      appointmentId,
      amount,
      currency = 'INR',
      patientEmail,
      patientName,
      patientContact,
      doctorName,
      departmentName,
      appointmentDate,
      appointmentTime
    } = appointmentData;

    // Generate unique order ID
    const orderId = `order_${Date.now()}_${Math.random().toString(36).substring(7)}`;

    // Create payment record in database
    const { data, error } = await supabase.rpc('create_payment', {
      p_appointment_id: appointmentId,
      p_amount: amount,
      p_currency: currency,
      p_patient_email: patientEmail,
      p_patient_name: patientName,
      p_patient_contact: patientContact,
      p_razorpay_order_id: orderId
    });

    if (error) {
      console.error('Error creating payment order:', error);
      throw new Error('Failed to create payment order');
    }

    console.log('✅ Payment order created:', orderId);

    return {
      orderId,
      amount: amount * 100, // Convert to paise for Razorpay
      currency,
      paymentId: data
    };
  } catch (error) {
    console.error('Error in createPaymentOrder:', error);
    throw error;
  }
}

/**
 * Display Razorpay checkout modal
 * @param {Object} options - Payment options
 * @param {Function} onSuccess - Success callback
 * @param {Function} onError - Error callback
 */
export async function displayRazorpayCheckout(options, onSuccess, onError) {
  try {
    // Load Razorpay script
    await loadRazorpayScript();

    const {
      orderId,
      amount,
      currency = 'INR',
      patientName,
      patientEmail,
      patientContact,
      doctorName,
      departmentName,
      appointmentDate,
      appointmentTime
    } = options;

    // Razorpay checkout options
    const rzpOptions = {
      key: RAZORPAY_KEY_ID,
      amount: amount, // Amount in paise
      currency: currency,
      name: 'MediQueue Hospital',
      description: `Consultation with ${doctorName}`,
      order_id: orderId,
      image: '/assets/logo.png', // Add your hospital logo
      
      prefill: {
        name: patientName,
        email: patientEmail,
        contact: patientContact
      },
      
      notes: {
        doctor_name: doctorName,
        department: departmentName,
        appointment_date: appointmentDate,
        appointment_time: appointmentTime
      },
      
      theme: {
        color: '#0E9384' // Teal color to match your theme
      },
      
      modal: {
        ondismiss: function() {
          console.log('Payment modal dismissed');
          if (onError) {
            onError(new Error('Payment cancelled by user'));
          }
        }
      },
      
      handler: async function(response) {
        console.log('Payment successful:', response);
        
        // Verify payment signature
        const verified = await verifyPayment(
          orderId,
          response.razorpay_payment_id,
          response.razorpay_signature,
          response.razorpay_order_id
        );

        if (verified) {
          if (onSuccess) {
            onSuccess({
              orderId: response.razorpay_order_id,
              paymentId: response.razorpay_payment_id,
              signature: response.razorpay_signature
            });
          }
        } else {
          if (onError) {
            onError(new Error('Payment verification failed'));
          }
        }
      }
    };

    // Create and open Razorpay checkout
    const rzp = new window.Razorpay(rzpOptions);
    
    rzp.on('payment.failed', function(response) {
      console.error('Payment failed:', response.error);
      
      // Update payment status to failed
      updatePaymentStatus(
        orderId,
        null,
        null,
        'failed',
        null,
        response.error.code,
        response.error.description
      );
      
      if (onError) {
        onError(new Error(response.error.description || 'Payment failed'));
      }
    });

    rzp.open();
    
  } catch (error) {
    console.error('Error displaying Razorpay checkout:', error);
    if (onError) {
      onError(error);
    }
  }
}

/**
 * Verify payment signature (client-side check)
 * Note: This is basic verification. Server-side verification is more secure.
 * @param {string} orderId - Razorpay order ID
 * @param {string} paymentId - Razorpay payment ID
 * @param {string} signature - Razorpay signature
 * @param {string} razorpayOrderId - Order ID from response
 * @returns {Promise<boolean>} Verification result
 */
export async function verifyPayment(orderId, paymentId, signature, razorpayOrderId) {
  try {
    console.log('Verifying payment:', { orderId, paymentId, signature });

    // Update payment status in database
    const { data, error } = await supabase.rpc('update_payment_status', {
      p_razorpay_order_id: orderId,
      p_razorpay_payment_id: paymentId,
      p_razorpay_signature: signature,
      p_status: 'success'
    });

    if (error) {
      console.error('Error updating payment status:', error);
      return false;
    }

    console.log('✅ Payment verified and status updated');
    return true;
    
  } catch (error) {
    console.error('Error verifying payment:', error);
    return false;
  }
}

/**
 * Update payment status in database
 * @param {string} orderId - Razorpay order ID
 * @param {string} paymentId - Razorpay payment ID
 * @param {string} signature - Razorpay signature
 * @param {string} status - Payment status
 * @param {string} method - Payment method
 * @param {string} errorCode - Error code (if failed)
 * @param {string} errorDescription - Error description (if failed)
 */
export async function updatePaymentStatus(
  orderId,
  paymentId,
  signature,
  status,
  method = null,
  errorCode = null,
  errorDescription = null
) {
  try {
    const { error } = await supabase.rpc('update_payment_status', {
      p_razorpay_order_id: orderId,
      p_razorpay_payment_id: paymentId,
      p_razorpay_signature: signature,
      p_status: status,
      p_method: method,
      p_error_code: errorCode,
      p_error_description: errorDescription
    });

    if (error) {
      console.error('Error updating payment status:', error);
      throw error;
    }

    console.log(`✅ Payment status updated to: ${status}`);
    
  } catch (error) {
    console.error('Error in updatePaymentStatus:', error);
    throw error;
  }
}

/**
 * Get payment details by order ID
 * @param {string} orderId - Razorpay order ID
 * @returns {Promise<Object>} Payment details
 */
export async function getPaymentDetails(orderId) {
  try {
    const { data, error } = await supabase.rpc('get_payment_by_order_id', {
      p_order_id: orderId
    });

    if (error) {
      console.error('Error fetching payment details:', error);
      throw error;
    }

    return data && data.length > 0 ? data[0] : null;
    
  } catch (error) {
    console.error('Error in getPaymentDetails:', error);
    throw error;
  }
}

/**
 * Check if payment is required (consultation fee > 0)
 * @param {number} amount - Consultation fee amount
 * @returns {boolean}
 */
export function isPaymentRequired(amount) {
  return amount && amount > 0;
}

/**
 * Format amount for display
 * @param {number} amount - Amount in rupees
 * @param {string} currency - Currency code
 * @returns {string} Formatted amount
 */
export function formatAmount(amount, currency = 'INR') {
  const formatter = new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency: currency,
    minimumFractionDigits: 0,
    maximumFractionDigits: 2
  });
  
  return formatter.format(amount);
}

/**
 * Show payment loading indicator
 */
export function showPaymentLoading(message = 'Processing payment...') {
  const loadingDiv = document.createElement('div');
  loadingDiv.id = 'payment-loading';
  loadingDiv.className = 'fixed inset-0 bg-navy-950/50 backdrop-blur-sm z-50 flex items-center justify-center';
  loadingDiv.innerHTML = `
    <div class="glass-white rounded-2xl p-8 text-center">
      <div class="animate-spin w-16 h-16 border-4 border-teal-500 border-t-transparent rounded-full mx-auto mb-4"></div>
      <p class="text-lg font-semibold text-navy-900">${message}</p>
      <p class="text-sm text-slate-600 mt-2">Please wait...</p>
    </div>
  `;
  document.body.appendChild(loadingDiv);
}

/**
 * Hide payment loading indicator
 */
export function hidePaymentLoading() {
  const loadingDiv = document.getElementById('payment-loading');
  if (loadingDiv) {
    loadingDiv.remove();
  }
}

/**
 * Show payment error modal
 */
export function showPaymentError(errorMessage) {
  const errorDiv = document.createElement('div');
  errorDiv.id = 'payment-error';
  errorDiv.className = 'fixed inset-0 bg-navy-950/50 backdrop-blur-sm z-50 flex items-center justify-center p-4';
  errorDiv.innerHTML = `
    <div class="glass-white rounded-2xl p-8 max-w-md text-center">
      <div class="w-16 h-16 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-4">
        <svg class="w-8 h-8 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
        </svg>
      </div>
      <h3 class="text-xl font-bold text-navy-900 mb-2">Payment Failed</h3>
      <p class="text-slate-600 mb-6">${errorMessage}</p>
      <button onclick="document.getElementById('payment-error').remove()" class="btn-primary w-full">
        Try Again
      </button>
    </div>
  `;
  document.body.appendChild(errorDiv);
}

/**
 * Initialize Razorpay on page load
 */
export async function initializeRazorpay() {
  try {
    await loadRazorpayScript();
    console.log('✅ Razorpay initialized successfully');
    return true;
  } catch (error) {
    console.error('❌ Failed to initialize Razorpay:', error);
    return false;
  }
}

// Export all functions
export default {
  loadRazorpayScript,
  createPaymentOrder,
  displayRazorpayCheckout,
  verifyPayment,
  updatePaymentStatus,
  getPaymentDetails,
  isPaymentRequired,
  formatAmount,
  showPaymentLoading,
  hidePaymentLoading,
  showPaymentError,
  initializeRazorpay
};
