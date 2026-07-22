# 💳 Razorpay Payment Gateway Integration Guide

## Overview

This guide explains how to integrate Razorpay payment gateway into the MediQueue hospital management system for collecting consultation fees during appointment booking.

---

## 🎯 Features

✅ **Secure Payment Processing** - PCI DSS compliant  
✅ **Multiple Payment Methods** - Cards, UPI, Netbanking, Wallets  
✅ **Real-time Payment Verification** - Instant confirmation  
✅ **Payment Status Tracking** - Complete audit trail  
✅ **Refund Support** - Handle cancellations  
✅ **Mobile-Friendly** - Works on all devices  
✅ **Test Mode** - Sandbox for development  

---

## 📋 Prerequisites

### 1. Razorpay Account Setup

1. **Create Account:**
   - Go to [https://razorpay.com](https://razorpay.com)
   - Sign up for a free account
   - Complete KYC verification (for live mode)

2. **Get API Keys:**
   - Login to Razorpay Dashboard
   - Go to Settings → API Keys
   - Generate Test Keys for development
   - Note down:
     - Key ID (starts with `rzp_test_`)
     - Key Secret (keep this secure!)

3. **Test Credentials:**
   ```
   Test Key ID: rzp_test_xxxxxxxxxxxxx
   Test Key Secret: xxxxxxxxxxxxxxxxxxxxx
   
   Test Cards:
   Card Number: 4111 1111 1111 1111
   CVV: Any 3 digits
   Expiry: Any future date
   ```

---

## 🔧 Installation Steps

### Step 1: Add Razorpay Keys to `.env`

Open `.env` file and add your Razorpay keys:

```env
# Razorpay Payment Gateway
# Test Mode Keys (for development)
RAZORPAY_KEY_ID=rzp_test_xxxxxxxxxxxxx
RAZORPAY_KEY_SECRET=xxxxxxxxxxxxxxxxxxxxx

# Live Mode Keys (for production - add later)
# RAZORPAY_KEY_ID=rzp_live_xxxxxxxxxxxxx
# RAZORPAY_KEY_SECRET=xxxxxxxxxxxxxxxxxxxxx
```

**⚠️ Important:**
- **NEVER** commit `.env` file to Git
- Keep Key Secret confidential
- Use Test keys in development
- Switch to Live keys only in production

---

### Step 2: Run Database Migration

Execute the SQL schema in Supabase SQL Editor:

1. Open Supabase Dashboard
2. Go to SQL Editor
3. Copy content from `supabase/payments-schema.sql`
4. Click "Run"
5. Verify success message

**What this creates:**
- `payments` table - Stores all payment records
- `payment_status` column in `appointments` table
- RPC functions for payment operations
- Indexes for performance
- RLS policies for security

---

### Step 3: Update Environment Variables

If using Vite or other build tools, create `.env.local`:

```env
VITE_RAZORPAY_KEY_ID=rzp_test_xxxxxxxxxxxxx
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your_anon_key
```

---

## 📁 File Structure

```
hospital-management-system/
│
├── .env                          # Environment variables (API keys)
├── .env.example                  # Template for .env
│
├── js/
│   ├── razorpay.js               # NEW - Payment gateway module
│   └── pages/
│       └── booking.js            # Updated - Includes payment flow
│
├── supabase/
│   └── payments-schema.sql       # NEW - Database schema
│
└── pages/
    └── book-appointment.html     # Updated - Payment UI
```

---

## 🔄 Payment Flow

### Complete User Journey:

```
1. User selects doctor and time slot
   ↓
2. User fills appointment details
   ↓
3. User clicks "Confirm Booking"
   ↓
4. System creates payment order
   ↓
5. Razorpay checkout modal opens
   ↓
6. User selects payment method
   ↓
7. User completes payment
   ↓
8. Razorpay sends callback
   ↓
9. System verifies payment
   ↓
10. Appointment confirmed
    ↓
11. User sees success message with token
```

---

## 💻 Code Implementation

### 1. Import Razorpay Module

In your booking page JavaScript:

```javascript
import {
  createPaymentOrder,
  displayRazorpayCheckout,
  isPaymentRequired,
  formatAmount,
  showPaymentLoading,
  hidePaymentLoading,
  showPaymentError
} from '../razorpay.js';
```

---

### 2. Create Payment Order

Before showing Razorpay checkout:

```javascript
async function initiatePayment(appointmentData) {
  try {
    // Show loading
    showPaymentLoading('Creating payment order...');
    
    // Create payment order
    const paymentOrder = await createPaymentOrder({
      appointmentId: appointmentData.appointmentId,
      amount: appointmentData.consultationFee, // In rupees
      currency: 'INR',
      patientEmail: appointmentData.patientEmail,
      patientName: appointmentData.patientName,
      patientContact: appointmentData.patientContact,
      doctorName: appointmentData.doctorName,
      departmentName: appointmentData.departmentName,
      appointmentDate: appointmentData.appointmentDate,
      appointmentTime: appointmentData.appointmentTime
    });
    
    hidePaymentLoading();
    
    // Show Razorpay checkout
    await showRazorpayCheckout(paymentOrder, appointmentData);
    
  } catch (error) {
    hidePaymentLoading();
    showPaymentError(error.message);
  }
}
```

---

### 3. Display Razorpay Checkout

```javascript
async function showRazorpayCheckout(paymentOrder, appointmentData) {
  await displayRazorpayCheckout(
    {
      orderId: paymentOrder.orderId,
      amount: paymentOrder.amount, // Amount in paise
      currency: paymentOrder.currency,
      patientName: appointmentData.patientName,
      patientEmail: appointmentData.patientEmail,
      patientContact: appointmentData.patientContact,
      doctorName: appointmentData.doctorName,
      departmentName: appointmentData.departmentName,
      appointmentDate: appointmentData.appointmentDate,
      appointmentTime: appointmentData.appointmentTime
    },
    // Success callback
    async (paymentResponse) => {
      console.log('✅ Payment successful:', paymentResponse);
      
      // Show success message
      showSuccessModal(appointmentData);
    },
    // Error callback
    (error) => {
      console.error('❌ Payment failed:', error);
      showPaymentError(error.message);
    }
  );
}
```

---

### 4. Check If Payment Required

Before booking:

```javascript
const consultationFee = doctor.consultationFee; // e.g., 500

if (isPaymentRequired(consultationFee)) {
  // Show payment gateway
  await initiatePayment(appointmentData);
} else {
  // Free consultation - book directly
  await bookAppointmentDirectly(appointmentData);
}
```

---

### 5. Format Amount for Display

```javascript
import { formatAmount } from '../razorpay.js';

const fee = 500; // Rupees
const formattedFee = formatAmount(fee, 'INR');
// Output: "₹500"

console.log(`Consultation Fee: ${formattedFee}`);
```

---

## 🗃️ Database Schema

### Payments Table

```sql
CREATE TABLE payments (
  id UUID PRIMARY KEY,
  appointment_id UUID REFERENCES appointments(id),
  
  -- Payment details
  amount DECIMAL(10, 2) NOT NULL,
  currency VARCHAR(3) DEFAULT 'INR',
  status VARCHAR(50) DEFAULT 'pending',
  
  -- Razorpay IDs
  razorpay_order_id VARCHAR(255) UNIQUE,
  razorpay_payment_id VARCHAR(255) UNIQUE,
  razorpay_signature VARCHAR(500),
  
  -- User info
  patient_email TEXT NOT NULL,
  patient_name TEXT,
  patient_contact VARCHAR(20),
  
  -- Payment method
  method VARCHAR(50),
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  paid_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Metadata & errors
  metadata JSONB DEFAULT '{}'::JSONB,
  error_code VARCHAR(100),
  error_description TEXT
);
```

---

### RPC Functions

#### 1. Create Payment

```sql
SELECT create_payment(
  p_appointment_id := 'uuid-here',
  p_amount := 500.00,
  p_currency := 'INR',
  p_patient_email := 'patient@example.com',
  p_patient_name := 'John Doe',
  p_patient_contact := '9876543210',
  p_razorpay_order_id := 'order_xxxxx'
);
```

#### 2. Update Payment Status

```sql
SELECT update_payment_status(
  p_razorpay_order_id := 'order_xxxxx',
  p_razorpay_payment_id := 'pay_xxxxx',
  p_razorpay_signature := 'signature_xxxxx',
  p_status := 'success'
);
```

#### 3. Get Payment Details

```sql
SELECT * FROM get_payment_by_order_id('order_xxxxx');
```

---

## 🎨 UI Integration

### Payment Button

Add to confirmation step in `book-appointment.html`:

```html
<button onclick="confirmBooking()" id="confirm-booking-btn" class="btn-primary">
  <svg class="w-6 h-6 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z" />
  </svg>
  Pay ₹<span id="payment-amount">500</span> & Confirm
</button>
```

### Payment Status Badge

```html
<div class="flex items-center gap-2">
  <span class="status-pill bg-green-500/20 text-green-300">
    <span class="h-2 w-2 rounded-full bg-green-400"></span> Paid
  </span>
  <span class="text-sm text-slate-600">₹500</span>
</div>
```

---

## 🧪 Testing

### Test Mode

**Test Cards:**

| Card Number | Type | Behavior |
|-------------|------|----------|
| 4111 1111 1111 1111 | Visa | Success |
| 5555 5555 5555 4444 | Mastercard | Success |
| 4000 0000 0000 0002 | Visa | Declined |
| 4000 0000 0000 0341 | Visa | Auth Required |

**Test UPI ID:** `success@razorpay`

**Test Netbanking:**
- Select any bank
- Use "Success" in credentials for success
- Use "Failure" for failure

---

### Test Scenarios

#### 1. Successful Payment
```javascript
// Expected flow:
1. User clicks "Confirm Booking"
2. Payment order created in database
3. Razorpay modal opens
4. User completes payment
5. Payment verified
6. Appointment confirmed
7. Success modal shown
```

#### 2. Failed Payment
```javascript
// Expected flow:
1. User clicks "Confirm Booking"
2. Payment order created
3. Razorpay modal opens
4. Payment fails
5. Error recorded in database
6. Error modal shown
7. User can retry
```

#### 3. Cancelled Payment
```javascript
// Expected flow:
1. User clicks "Confirm Booking"
2. Payment order created
3. Razorpay modal opens
4. User closes modal
5. Payment status remains "pending"
6. User can retry later
```

---

## 🔒 Security Best Practices

### 1. API Key Security

```javascript
// ✅ GOOD - Use environment variables
const RAZORPAY_KEY_ID = import.meta.env.VITE_RAZORPAY_KEY_ID;

// ❌ BAD - Hardcoding keys
const RAZORPAY_KEY_ID = 'rzp_test_xxxxx'; // DON'T DO THIS!
```

### 2. Payment Verification

```javascript
// Always verify payment on server-side
// Client-side verification is just a first check
const verified = await verifyPayment(orderId, paymentId, signature);

if (verified) {
  // Proceed with booking confirmation
} else {
  // Show error and don't confirm booking
}
```

### 3. Amount Validation

```javascript
// Validate amount before creating order
if (amount <= 0 || amount > 100000) {
  throw new Error('Invalid amount');
}

// Convert to paise for Razorpay
const amountInPaise = Math.round(amount * 100);
```

### 4. Database Security

- ✅ Use RLS policies
- ✅ Validate user permissions
- ✅ Sanitize inputs
- ✅ Use parameterized queries

---

## 📊 Payment Status States

| Status | Description | Next Action |
|--------|-------------|-------------|
| `pending` | Payment initiated | Awaiting completion |
| `success` | Payment successful | Confirm appointment |
| `failed` | Payment failed | Allow retry |
| `refunded` | Payment refunded | Cancel appointment |

---

## 🔄 Refund Process

### Initiate Refund (via Razorpay Dashboard)

1. Login to Razorpay Dashboard
2. Go to Transactions → Payments
3. Find the payment
4. Click "Refund"
5. Enter amount and reason
6. Confirm refund

### Programmatic Refund (Future Enhancement)

```javascript
// This requires server-side implementation
async function refundPayment(paymentId, amount, reason) {
  // Call your backend API
  // Backend calls Razorpay Refund API
  // Update payment status in database
}
```

---

## 🚀 Going Live

### Checklist Before Production

- [ ] Complete Razorpay KYC verification
- [ ] Get Live API keys from Razorpay
- [ ] Update `.env` with live keys
- [ ] Test with real payments (small amounts)
- [ ] Set up webhooks for payment notifications
- [ ] Configure refund policy
- [ ] Add terms and conditions
- [ ] Enable SSL certificate
- [ ] Test on multiple devices
- [ ] Monitor first few transactions closely

### Switch to Live Mode

```env
# In .env file
# Comment out test keys
# RAZORPAY_KEY_ID=rzp_test_xxxxx
# RAZORPAY_KEY_SECRET=xxxxx

# Add live keys
RAZORPAY_KEY_ID=rzp_live_xxxxx
RAZORPAY_KEY_SECRET=xxxxx
```

---

## 📈 Monitoring & Analytics

### Check Payment Statistics

```sql
-- Total payments today
SELECT COUNT(*), SUM(amount) 
FROM payments 
WHERE DATE(created_at) = CURRENT_DATE;

-- Success rate
SELECT 
  status,
  COUNT(*) as count,
  ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM payments), 2) as percentage
FROM payments
GROUP BY status;

-- Payment methods used
SELECT 
  method,
  COUNT(*) as count
FROM payments
WHERE status = 'success'
GROUP BY method
ORDER BY count DESC;
```

---

## 🐛 Troubleshooting

### Issue 1: Razorpay script not loading

**Solution:**
```javascript
// Check internet connection
// Verify script URL
// Check browser console for errors
await loadRazorpayScript();
```

### Issue 2: Payment modal not opening

**Solution:**
```javascript
// Verify Razorpay key is correct
// Check browser popup blocker
// Ensure script is loaded before calling
console.log('Razorpay available:', !!window.Razorpay);
```

### Issue 3: Payment verification failing

**Solution:**
```sql
-- Check if payment record exists
SELECT * FROM payments WHERE razorpay_order_id = 'order_xxxxx';

-- Check appointment payment status
SELECT id, payment_status, payment_id FROM appointments WHERE id = 'uuid';
```

### Issue 4: Amount mismatch

**Solution:**
```javascript
// Always use Math.round for paise conversion
const amountInPaise = Math.round(amountInRupees * 100);

// Don't use floating point directly
// ❌ const amountInPaise = amountInRupees * 100;
```

---

## 📞 Support

### Razorpay Support
- Dashboard: https://dashboard.razorpay.com
- Documentation: https://razorpay.com/docs
- Support Email: support@razorpay.com
- Phone: +91-80-71176001

### Code Issues
- Check browser console for errors
- Verify database schema is created
- Test with Razorpay test cards
- Review this documentation

---

## 📚 Additional Resources

- [Razorpay Documentation](https://razorpay.com/docs/payments/)
- [Checkout.js Reference](https://razorpay.com/docs/payments/payment-gateway/web-integration/)
- [Test Cards](https://razorpay.com/docs/payments/payments/test-card-upi-details/)
- [Webhooks](https://razorpay.com/docs/webhooks/)
- [Refunds API](https://razorpay.com/docs/api/refunds/)

---

## ✅ Summary

**What we implemented:**
1. ✅ Razorpay SDK integration
2. ✅ Payment order creation
3. ✅ Checkout modal display
4. ✅ Payment verification
5. ✅ Database schema for payments
6. ✅ RPC functions for operations
7. ✅ Error handling
8. ✅ UI components

**Next steps:**
1. Add Razorpay keys to `.env`
2. Run database migration
3. Test with test cards
4. Integrate into booking flow
5. Test all scenarios
6. Go live with proper keys

---

**Status:** ✅ READY TO INTEGRATE

**Estimated Time:** 2-3 hours to complete integration and testing
