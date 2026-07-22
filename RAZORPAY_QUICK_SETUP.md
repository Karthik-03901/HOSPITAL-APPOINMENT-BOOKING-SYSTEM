# 🚀 Razorpay Quick Setup Guide (5 Minutes)

## Step-by-Step Setup

### Step 1: Get Razorpay Keys (2 minutes)

1. **Go to Razorpay:**
   - Visit: https://razorpay.com
   - Click "Sign Up" (if new) or "Login"

2. **Get Test API Keys:**
   - After login, go to Settings → API Keys
   - Click "Generate Test Key"
   - Copy both:
     - Key ID (starts with `rzp_test_`)
     - Key Secret (keep secret!)

---

### Step 2: Add Keys to `.env` File (1 minute)

Open `.env` file and update:

```env
RAZORPAY_KEY_ID=rzp_test_YOUR_KEY_ID_HERE
RAZORPAY_KEY_SECRET=YOUR_KEY_SECRET_HERE
```

**Example:**
```env
RAZORPAY_KEY_ID=rzp_test_1234567890abcd
RAZORPAY_KEY_SECRET=abcdef1234567890abcdef
```

**⚠️ Important:**
- Replace `YOUR_KEY_ID_HERE` with your actual key
- Replace `YOUR_KEY_SECRET_HERE` with your actual secret
- Don't share these keys publicly!

---

### Step 3: Run Database Migration (2 minutes)

1. **Open Supabase Dashboard:**
   - Go to: https://supabase.com
   - Login and select your project

2. **Go to SQL Editor:**
   - Click on "SQL Editor" in left sidebar

3. **Run Migration:**
   - Open file: `supabase/payments-schema.sql`
   - Copy ALL content
   - Paste in SQL Editor
   - Click "Run"
   - Wait for success message ✅

**Verify:**
```sql
-- Run this to check if table was created
SELECT * FROM payments LIMIT 1;
```

---

### Step 4: Test Payment Flow (Optional)

1. **Open booking page:**
   - Navigate to: `pages/book-appointment.html`

2. **Complete booking:**
   - Select department
   - Choose doctor
   - Pick date & time
   - Click "Confirm Booking"

3. **Use test card:**
   ```
   Card Number: 4111 1111 1111 1111
   CVV: 123
   Expiry: 12/25 (any future date)
   ```

4. **Verify success:**
   - Payment should complete
   - Appointment should be confirmed
   - Check `payments` table in Supabase

---

## ✅ Verification Checklist

- [ ] Razorpay account created
- [ ] Test API keys obtained
- [ ] Keys added to `.env` file
- [ ] Database migration completed
- [ ] `payments` table exists in Supabase
- [ ] Test payment successful

---

## 🧪 Quick Test Commands

### Check if keys are loaded:
```javascript
// In browser console
console.log('Key ID:', import.meta.env.VITE_RAZORPAY_KEY_ID);
// Should show: rzp_test_xxxxx
```

### Check database:
```sql
-- In Supabase SQL Editor
SELECT COUNT(*) FROM payments;
-- Should return 0 (if no payments yet)
```

### Test Razorpay script:
```javascript
// In browser console (on booking page)
console.log('Razorpay loaded:', !!window.Razorpay);
// Should show: true
```

---

## 🐛 Common Issues

### Issue: "Key ID not found"
**Solution:** Check `.env` file has correct format:
```env
RAZORPAY_KEY_ID=rzp_test_xxxxx
```
(No quotes, no spaces around `=`)

### Issue: "Table payments does not exist"
**Solution:** Re-run database migration SQL

### Issue: "Payment modal not opening"
**Solution:** Check browser console for errors, ensure Razorpay script loaded

---

## 📞 Need Help?

- **Full Documentation:** Read `RAZORPAY_INTEGRATION_GUIDE.md`
- **Razorpay Docs:** https://razorpay.com/docs
- **Test Cards:** https://razorpay.com/docs/payments/payments/test-card-upi-details/

---

## 🎉 You're Done!

If all checkboxes are ticked, you're ready to accept payments!

**Next Steps:**
1. Test with different payment methods
2. Check payment records in Supabase
3. When ready for production, get Live API keys
4. Update `.env` with live keys

---

## 🔄 Quick Reference

### Test Card Details:
```
Card: 4111 1111 1111 1111
CVV: Any 3 digits
Expiry: Any future date
```

### Test UPI:
```
UPI ID: success@razorpay
```

### Database Check:
```sql
-- View all payments
SELECT * FROM payments ORDER BY created_at DESC;

-- View successful payments
SELECT * FROM payments WHERE status = 'success';
```

---

**Total Setup Time:** ~5 minutes  
**Difficulty:** Easy  
**Status:** ✅ Ready to go!
