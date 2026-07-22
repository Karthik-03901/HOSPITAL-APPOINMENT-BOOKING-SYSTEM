# ✅ Razorpay Payment Implementation Checklist

## Pre-Implementation (Before Coding)

### 1. Razorpay Account Setup
- [ ] Created Razorpay account at https://razorpay.com
- [ ] Verified email address
- [ ] Logged into Razorpay dashboard
- [ ] Generated Test API keys
- [ ] Copied Key ID (rzp_test_xxxxx)
- [ ] Copied Key Secret (keep secure!)
- [ ] Noted both keys in safe place

### 2. Environment Setup
- [ ] Located `.env` file in project root
- [ ] Opened `.env` file in editor
- [ ] Added `RAZORPAY_KEY_ID=rzp_test_xxxxx`
- [ ] Added `RAZORPAY_KEY_SECRET=xxxxx`
- [ ] Saved `.env` file
- [ ] Verified `.env` is in `.gitignore`
- [ ] **Did NOT** commit `.env` to Git

### 3. Database Setup
- [ ] Opened Supabase Dashboard
- [ ] Logged into project
- [ ] Navigated to SQL Editor
- [ ] Opened `supabase/payments-schema.sql`
- [ ] Copied entire SQL content
- [ ] Pasted into Supabase SQL Editor
- [ ] Clicked "Run" button
- [ ] Saw success message ✅
- [ ] Verified `payments` table exists
- [ ] Checked RPC functions created

---

## Implementation (Coding)

### 4. Update Booking Page
- [ ] Opened `pages/book-appointment.html`
- [ ] Added Razorpay script tag to `<head>`:
  ```html
  <script src="https://checkout.razorpay.com/v1/checkout.js"></script>
  ```
- [ ] Updated confirmation button text to show amount
- [ ] Added payment status indicator

### 5. Update Booking JavaScript
- [ ] Opened `js/pages/booking.js`
- [ ] Added import for razorpay module:
  ```javascript
  import { 
    createPaymentOrder,
    displayRazorpayCheckout,
    isPaymentRequired 
  } from '../razorpay.js';
  ```
- [ ] Modified `confirmBooking()` function
- [ ] Added payment flow before appointment creation
- [ ] Handled payment success callback
- [ ] Handled payment error callback
- [ ] Added loading indicators

### 6. Environment Variables (if using build tool)
- [ ] Created `.env.local` file (if using Vite)
- [ ] Added `VITE_RAZORPAY_KEY_ID=rzp_test_xxxxx`
- [ ] Added `VITE_SUPABASE_URL=...`
- [ ] Added `VITE_SUPABASE_ANON_KEY=...`
- [ ] Restarted dev server

---

## Testing (Critical!)

### 7. Basic Integration Test
- [ ] Opened booking page in browser
- [ ] Opened browser console (F12)
- [ ] Checked for Razorpay script loaded
- [ ] Verified no JavaScript errors
- [ ] Confirmed environment variables loaded

### 8. Payment Flow Test
- [ ] Selected department → doctor → date/time
- [ ] Clicked "Confirm Booking" button
- [ ] Payment modal opened successfully
- [ ] Used test card: 4111 1111 1111 1111
- [ ] CVV: 123, Expiry: 12/25
- [ ] Completed test payment
- [ ] Saw success message
- [ ] Appointment created in database
- [ ] Payment record created in database

### 9. Database Verification
- [ ] Opened Supabase Dashboard
- [ ] Navigated to Table Editor
- [ ] Checked `payments` table:
  ```sql
  SELECT * FROM payments ORDER BY created_at DESC LIMIT 1;
  ```
- [ ] Verified payment details correct:
  - [ ] Order ID exists
  - [ ] Payment ID exists
  - [ ] Status = 'success'
  - [ ] Amount correct
  - [ ] Patient email correct
- [ ] Checked `appointments` table:
  ```sql
  SELECT id, payment_status, payment_id FROM appointments 
  WHERE id = 'your-appointment-id';
  ```
- [ ] Verified:
  - [ ] payment_status = 'success'
  - [ ] payment_id links to payment record

### 10. Error Handling Test
- [ ] Started new booking
- [ ] Opened payment modal
- [ ] Clicked outside modal (cancel)
- [ ] Verified error message shown
- [ ] Verified can retry payment
- [ ] Used declining test card: 4000 0000 0000 0002
- [ ] Verified payment failed gracefully
- [ ] Error message displayed
- [ ] Payment status = 'failed' in database

### 11. Different Payment Methods
- [ ] Tested with Credit Card ✅
- [ ] Tested with Debit Card ✅
- [ ] Tested with UPI (success@razorpay) ✅
- [ ] Tested with Netbanking ✅
- [ ] All methods working correctly

### 12. Mobile Testing
- [ ] Opened on mobile device / emulator
- [ ] Completed booking flow
- [ ] Payment modal responsive
- [ ] Touch-friendly buttons
- [ ] No layout issues
- [ ] Payment successful on mobile

---

## Security Review

### 13. Security Checklist
- [ ] `.env` file in `.gitignore`
- [ ] No API keys hardcoded in JavaScript
- [ ] Using environment variables correctly
- [ ] RLS policies enabled on `payments` table
- [ ] Payment verification implemented
- [ ] No sensitive data in console logs (production)
- [ ] SSL/HTTPS enabled (production only)
- [ ] Test keys used (not live keys yet)

---

## Documentation

### 14. Documentation Review
- [ ] Read `RAZORPAY_QUICK_SETUP.md`
- [ ] Read `RAZORPAY_INTEGRATION_GUIDE.md`
- [ ] Understood payment flow
- [ ] Know how to troubleshoot issues
- [ ] Bookmarked Razorpay documentation

---

## Pre-Production

### 15. Final Checks Before Going Live
- [ ] All tests passing ✅
- [ ] No console errors
- [ ] Payment flow smooth
- [ ] Database records accurate
- [ ] Error handling works
- [ ] Mobile responsive
- [ ] Documentation complete
- [ ] Team trained on system

### 16. Razorpay KYC (Required for Live)
- [ ] Submitted KYC documents to Razorpay
- [ ] KYC approved by Razorpay
- [ ] Account activated for live transactions
- [ ] Generated Live API keys
- [ ] Noted live keys securely

### 17. Production Deployment
- [ ] Updated `.env` with live keys:
  ```env
  RAZORPAY_KEY_ID=rzp_live_xxxxx
  RAZORPAY_KEY_SECRET=xxxxx
  ```
- [ ] Restarted production server
- [ ] Tested with small real payment (₹1-10)
- [ ] Verified payment in Razorpay dashboard
- [ ] Verified in database
- [ ] Confirmed refund process works
- [ ] Set up payment notifications
- [ ] Configured webhooks (optional)
- [ ] Added terms & conditions
- [ ] Added refund policy

---

## Post-Launch

### 18. Monitoring (First Week)
- [ ] Check payments dashboard daily
- [ ] Monitor success rate
- [ ] Review failed payments
- [ ] Check user feedback
- [ ] Fix any issues immediately
- [ ] Track revenue metrics

### 19. Performance Monitoring
- [ ] Payment completion rate > 90%
- [ ] Average payment time < 2 minutes
- [ ] Zero security incidents
- [ ] User satisfaction positive
- [ ] No critical bugs

---

## Advanced Features (Optional)

### 20. Future Enhancements
- [ ] Set up Razorpay webhooks
- [ ] Implement automatic refunds
- [ ] Add payment receipt emails
- [ ] Create payment analytics dashboard
- [ ] Add subscription support
- [ ] Implement payment reminders
- [ ] Add invoice generation
- [ ] Support international payments

---

## Troubleshooting Reference

### If Payment Modal Doesn't Open:
1. Check Razorpay script loaded
2. Verify Key ID in .env
3. Check browser console errors
4. Disable popup blocker
5. Try different browser

### If Payment Verification Fails:
1. Check Supabase connection
2. Verify RPC functions exist
3. Check payment_status column exists
4. Review error in console
5. Check database logs

### If Amount Mismatch:
1. Verify amount in rupees (not paise)
2. Check conversion: amount * 100
3. Use Math.round() for conversion
4. Verify in Razorpay dashboard

---

## Sign-Off

### Developer Sign-Off
- [ ] All checkboxes completed
- [ ] System tested thoroughly
- [ ] Documentation reviewed
- [ ] Code committed (excluding .env)
- [ ] Ready for review

**Developer Name:** _____________________  
**Date:** _____________________  
**Signature:** _____________________

---

### QA Sign-Off
- [ ] All test cases passed
- [ ] No critical bugs
- [ ] Performance acceptable
- [ ] Security verified
- [ ] Ready for production

**QA Name:** _____________________  
**Date:** _____________________  
**Signature:** _____________________

---

### Project Manager Sign-Off
- [ ] Requirements met
- [ ] Documentation complete
- [ ] Budget within limits
- [ ] Timeline met
- [ ] Approved for deployment

**PM Name:** _____________________  
**Date:** _____________________  
**Signature:** _____________________

---

## Success Criteria

### Minimum Requirements:
- ✅ Payment gateway integrated
- ✅ Test payments working
- ✅ Database records accurate
- ✅ Error handling implemented
- ✅ Mobile responsive
- ✅ Secure implementation
- ✅ Documentation complete

### Deployment Ready:
- ✅ All tests passed
- ✅ Live keys configured
- ✅ KYC approved
- ✅ Production tested
- ✅ Team trained
- ✅ Monitoring set up
- ✅ Support ready

---

## Status

**Current Status:** ⬜ Not Started | ⬜ In Progress | ⬜ Testing | ⬜ Complete

**Blocker Issues:** None / [Describe if any]

**Estimated Completion:** _____________________

**Actual Completion:** _____________________

---

## Notes

_Add any additional notes, issues, or observations here:_

________________________________________________________
________________________________________________________
________________________________________________________

---

**Remember:**
- Test thoroughly before going live
- Always use test keys in development
- Keep API secrets secure
- Monitor payments closely after launch
- Have rollback plan ready

**Good luck! 🚀**
