# ⚡ Quick Reference Card

## Essential Commands & Keys

---

## 🔑 Test Credentials

### User Accounts:
```
Admin:
  Email: karthiksaravanavel18@gmail.com
  Password: 123456
  
Doctor:
  Email: vel759894@gmail.com
  Password: 123456
  
Patient:
  Email: Any email
  Password: Any password
```

### API Keys:
```
Cloudflare Turnstile (Test):
  Site Key: 1x00000000000000000000AA

Razorpay (Test):
  Card: 4111 1111 1111 1111
  CVV: 123
  Expiry: 12/25
```

---

## 💻 Essential SQL Commands

### Security:

```sql
-- Unlock account
SELECT unlock_account('user@email.com', 'admin');

-- View locked accounts
SELECT * FROM account_locks WHERE is_locked = TRUE;

-- View recent attempts
SELECT email, status, attempted_at 
FROM login_attempts 
ORDER BY attempted_at DESC LIMIT 10;

-- View blocked IPs
SELECT * FROM ip_blacklist WHERE is_blocked = TRUE;

-- Security stats
SELECT * FROM get_security_stats();

-- Cleanup old data
SELECT cleanup_security_data();
```

---

### Payments:

```sql
-- View all payments
SELECT * FROM payments ORDER BY created_at DESC LIMIT 10;

-- Today's revenue
SELECT 
  COUNT(*) as payments,
  SUM(amount) as revenue
FROM payments
WHERE DATE(created_at) = CURRENT_DATE AND status = 'success';

-- Failed payments
SELECT * FROM payments WHERE status = 'failed';

-- Payment by order ID
SELECT * FROM get_payment_by_order_id('order_xxxxx');
```

---

### System Status:

```sql
-- Check all tables
SELECT tablename FROM pg_tables 
WHERE tablename IN ('login_attempts', 'account_locks', 'ip_blacklist', 
                    'security_audit_log', 'security_config', 'payments');

-- Check all functions
SELECT proname FROM pg_proc
WHERE proname IN ('check_login_allowed', 'record_login_attempt', 
                  'unlock_account', 'get_security_stats', 
                  'cleanup_security_data', 'create_payment',
                  'update_payment_status', 'get_payment_by_order_id');
```

---

## 🎯 Quick Tests

### Security Test:
```
1. Open login page
2. Enter wrong password 5 times
3. ✅ Account locks
4. ✅ Turnstile after 3 attempts
```

### Payment Test:
```
1. Book appointment
2. Card: 4111 1111 1111 1111
3. ✅ Payment succeeds
```

### Navigation Test:
```
1. Click "Start Free Trial" (not logged in)
2. ✅ Goes to login
3. Login and click again
4. ✅ Goes to book appointment
```

---

## 📁 Important Files

### JavaScript:
```
js/security.js           - Security module
js/razorpay.js          - Payment module
js/smart-routing.js     - Navigation module
js/pages/login.js       - Login with security
```

### SQL:
```
supabase/brute-force-protection.sql  - Security schema
supabase/payments-schema.sql         - Payment schema
```

### Config:
```
.env                    - Your API keys (DO NOT COMMIT)
.env.example            - Template
```

---

## 🛡️ Security Thresholds

```
Account Lockout: 5 failed attempts
Lockout Duration: 30 minutes
Rate Limit: 10 attempts per minute
Turnstile Trigger: 3 failed attempts
IP Ban: 20 failed attempts
IP Ban Duration: 60 minutes
Permanent Ban: 50 failed attempts
```

---

## 🔧 Configuration

### Update Turnstile Key:
```javascript
// File: js/security.js (line 6)
const TURNSTILE_SITE_KEY = 'YOUR_SITE_KEY_HERE';
```

### Update Razorpay Keys:
```env
# File: .env
RAZORPAY_KEY_ID=rzp_test_xxxxxxxxxxxxx
RAZORPAY_KEY_SECRET=xxxxxxxxxxxxxxxxxxxxx
```

---

## 🚨 Troubleshooting

### Error: "Function does not exist"
```
Solution: Re-run SQL schema in Supabase
```

### Turnstile not showing
```
Solution: Check site key in js/security.js
```

### Payment not working
```
Solution: Check .env has Razorpay keys
```

### Navigation broken
```
Solution: Check button IDs in index.html
```

---

## 📊 Monitoring Queries

### Daily Report:
```sql
SELECT 
  'Login Attempts' as metric, 
  COUNT(*) as value 
FROM login_attempts 
WHERE DATE(attempted_at) = CURRENT_DATE

UNION ALL

SELECT 
  'Failed Logins' as metric, 
  COUNT(*) as value 
FROM login_attempts 
WHERE DATE(attempted_at) = CURRENT_DATE AND status = 'failed'

UNION ALL

SELECT 
  'Locked Accounts' as metric, 
  COUNT(*) as value 
FROM account_locks 
WHERE is_locked = TRUE

UNION ALL

SELECT 
  'Payments' as metric, 
  COUNT(*) as value 
FROM payments 
WHERE DATE(created_at) = CURRENT_DATE

UNION ALL

SELECT 
  'Revenue' as metric, 
  COALESCE(SUM(amount), 0) as value 
FROM payments 
WHERE DATE(created_at) = CURRENT_DATE AND status = 'success';
```

---

## 🔗 Quick Links

**Setup:**
- START_HERE.md - 5-min quick start
- IMPLEMENTATION_ROADMAP.md - 30-min detailed setup
- VERIFY_SETUP.md - Verification checklist

**Security:**
- COMPLETE_SECURITY_SETUP.md - Complete overview
- BRUTE_FORCE_PROTECTION_GUIDE.md - Detailed guide
- CLOUDFLARE_TURNSTILE_SETUP.md - Turnstile setup

**Payments:**
- RAZORPAY_INTEGRATION_GUIDE.md - Complete guide
- RAZORPAY_QUICK_SETUP.md - Quick setup

**Navigation:**
- SMART_ROUTING_COMPLETE.md - Complete guide
- SMART_ROUTING_TEST_GUIDE.md - Test scenarios

**Master:**
- README_MASTER.md - Documentation index
- FINAL_STATUS_SUMMARY.md - Complete summary

---

## 🎯 Browser Console Tests

```javascript
// Check modules loaded
console.log('Security:', typeof checkLoginAllowed);
console.log('Payments:', typeof displayRazorpayCheckout);
console.log('Routing:', typeof handleBookAppointmentClick);

// Check Supabase
supabase.auth.getSession().then(({ data }) => {
  console.log('Logged in:', !!data.session);
});

// Check buttons
console.log('Buttons:', {
  create: !!document.getElementById('btn-create-account'),
  book: !!document.getElementById('btn-book-appointment'),
  track: !!document.getElementById('btn-track-live')
});
```

---

## 📦 File Structure

```
├── js/
│   ├── security.js          ✨ Security
│   ├── razorpay.js          ✨ Payments
│   └── smart-routing.js     ✨ Navigation
│
├── supabase/
│   ├── brute-force-protection.sql  ✨ Security DB
│   └── payments-schema.sql         ✨ Payment DB
│
├── pages/
│   ├── login.html
│   ├── book-appointment.html
│   └── [others]
│
├── index.html               🔄 Updated
├── .env                     🔄 Updated
└── Documentation/ (18 files)
```

---

## ⚡ Super Quick Setup

```bash
# Step 1: Database (Supabase SQL Editor)
# Run: supabase/brute-force-protection.sql
# Run: supabase/payments-schema.sql

# Step 2: Keys
# Turnstile: dash.cloudflare.com
# Razorpay: razorpay.com

# Step 3: Test
# Login wrong 5x → Locks ✅
# Payment test card → Works ✅
# Navigation → Smart routing ✅
```

**Total Time:** 30 minutes  
**Total Cost:** $0  
**Result:** Production ready 🚀

---

## 🎉 Success Checklist

- [ ] ✅ Database tables created (6 tables)
- [ ] ✅ RPC functions working (8 functions)
- [ ] ✅ Security protecting login
- [ ] ✅ Payments processing
- [ ] ✅ Navigation routing
- [ ] ✅ No console errors

**All checked?** YOU'RE READY! 🎊

---

## 💡 Pro Tips

1. Use test keys first
2. Check browser console
3. Verify with SQL queries
4. Test incrementally
5. Read documentation
6. Keep this card handy

---

## 📞 Support

**Cloudflare:** https://dash.cloudflare.com  
**Razorpay:** https://dashboard.razorpay.com  
**Supabase:** https://supabase.com/dashboard

---

**Version:** 2.0  
**Last Updated:** July 21, 2026  
**Print this card for quick reference!** 🖨️
