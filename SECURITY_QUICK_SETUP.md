# 🚀 Security Quick Setup (10 Minutes)

## Step-by-Step Setup

### ✅ Step 1: Run Database Migration (3 minutes)

1. **Open Supabase Dashboard**
   - Go to: https://supabase.com
   - Login and select your project

2. **Open SQL Editor**
   - Click "SQL Editor" in left sidebar

3. **Run Migration**
   - Open file: `supabase/brute-force-protection.sql`
   - Copy ALL content
   - Paste in SQL Editor
   - Click "Run"
   - Wait for success message ✅

**Expected Output:**
```
✅ Brute force protection system created successfully!
📝 Security features enabled:
  - Login attempt tracking
  - Account lockout (5 failed attempts, 30min lock)
  - Rate limiting (10 attempts/min per IP)
  - IP blacklisting (20 failed attempts, 60min ban)
  - CAPTCHA trigger (after 3 failed attempts)
  - Comprehensive audit logging
```

---

### ✅ Step 2: Verify Database Tables (1 minute)

Run this in Supabase SQL Editor:

```sql
-- Check if tables exist
SELECT tablename FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('login_attempts', 'account_locks', 'ip_blacklist', 'security_audit_log', 'security_config');
```

**Should return 5 tables.**

---

### ✅ Step 3: Get reCAPTCHA Keys (Optional - 3 minutes)

1. **Go to Google reCAPTCHA:**
   - Visit: https://www.google.com/recaptcha/admin
   - Login with Google account

2. **Register Site:**
   - Label: "MediQueue Hospital"
   - reCAPTCHA type: Select "reCAPTCHA v2" → "I'm not a robot"
   - Domains: Add "localhost" (for testing) and your production domain
   - Click "Submit"

3. **Copy Keys:**
   - Site Key: Starts with `6L...`
   - Secret Key: Keep this secure!

4. **Update `js/security.js`:**
   ```javascript
   const CAPTCHA_SITE_KEY = 'YOUR_SITE_KEY_HERE';
   ```

**For Testing (skip step if you want):**
Use these test keys:
```
Site Key: 6LeIxAcTAAAAAJcZVRqyHh71UMIEGNQ_MXjiZKhI
Secret Key: 6LeIxAcTAAAAAGG-vFI1TnRWxMZNFuojJ4WifJWe
```

---

### ✅ Step 4: Test the System (3 minutes)

1. **Open Login Page:**
   - Navigate to: `pages/login.html`

2. **Test Failed Attempts:**
   - Enter any email: `test@test.com`
   - Enter wrong password: `wrongpassword`
   - Click "Sign In"
   - **Repeat 5 times**

3. **Verify Account Lockout:**
   - On 6th attempt, should see "Account Locked" message
   - Message should say "try again in 30 minutes"

4. **Verify in Database:**
   ```sql
   -- Check login attempts
   SELECT * FROM login_attempts ORDER BY attempted_at DESC LIMIT 5;
   
   -- Check if account locked
   SELECT * FROM account_locks WHERE email = 'test@test.com';
   ```

5. **Unlock Account (for testing):**
   ```sql
   SELECT unlock_account('test@test.com', 'admin');
   ```

---

## 🎯 Verification Checklist

- [ ] Database tables created
- [ ] `login_attempts` table exists
- [ ] `account_locks` table exists
- [ ] `ip_blacklist` table exists
- [ ] `security_audit_log` table exists
- [ ] `security_config` table exists
- [ ] RPC functions working
- [ ] reCAPTCHA configured (optional)
- [ ] Login page has security container
- [ ] Test lockout successful
- [ ] Can unlock account manually

---

## 🧪 Quick Tests

### Test 1: Account Lockout
```
Action: Try login 5 times with wrong password
Expected: Account locked message on 6th attempt
Status: ⬜ Pass | ⬜ Fail
```

### Test 2: Rate Limiting
```
Action: Try login 11 times within 1 minute
Expected: Rate limit message
Status: ⬜ Pass | ⬜ Fail
```

### Test 3: CAPTCHA
```
Action: Fail login 3 times
Expected: CAPTCHA appears on 4th attempt
Status: ⬜ Pass | ⬜ Fail
```

### Test 4: Security Logging
```sql
-- Check logs
SELECT * FROM security_audit_log ORDER BY created_at DESC LIMIT 10;
```
```
Expected: See all login attempts logged
Status: ⬜ Pass | ⬜ Fail
```

---

## 🔧 Configuration

### Default Settings:

| Setting | Value | What It Does |
|---------|-------|--------------|
| Max Failed Attempts | 5 | Lock account after 5 failures |
| Lockout Duration | 30 min | Keep locked for 30 minutes |
| Rate Limit | 10/min | Max 10 attempts per minute |
| IP Ban Threshold | 20 | Ban IP after 20 failures |
| IP Ban Duration | 60 min | Ban for 60 minutes |
| CAPTCHA Trigger | 3 | Show after 3 failures |

### Change Settings:

```sql
-- Make lockout stricter (3 attempts)
UPDATE security_config 
SET value = '3' 
WHERE key = 'max_failed_attempts';

-- Longer lockout (60 minutes)
UPDATE security_config 
SET value = '60' 
WHERE key = 'lockout_duration_minutes';
```

---

## 📊 Monitoring

### Check Security Stats:

```sql
SELECT * FROM get_security_stats();
```

Returns:
- Total attempts today
- Failed attempts today
- Currently locked accounts
- Currently blocked IPs
- Critical security events

### View Recent Failures:

```sql
SELECT 
  email, 
  ip_address, 
  attempted_at, 
  failure_reason
FROM login_attempts
WHERE status = 'failed'
  AND attempted_at > NOW() - INTERVAL '1 hour'
ORDER BY attempted_at DESC;
```

---

## 🐛 Troubleshooting

### Issue: "Function does not exist"
**Solution:** Re-run the SQL migration

### Issue: CAPTCHA not showing
**Solution:** 
1. Check internet connection
2. Verify site key in `js/security.js`
3. Check browser console for errors

### Issue: Account won't unlock
**Solution:**
```sql
-- Force unlock
SELECT unlock_account('email@example.com', 'admin');
```

### Issue: Can't login at all
**Solution:**
```sql
-- Clear all locks
DELETE FROM account_locks;
DELETE FROM ip_blacklist;
```

---

## 📞 Admin Commands

### Unlock Account:
```sql
SELECT unlock_account('user@example.com', 'admin');
```

### Unblock IP:
```sql
UPDATE ip_blacklist 
SET is_blocked = FALSE, unblocked_at = NOW()
WHERE ip_address = '1.2.3.4';
```

### View Locked Accounts:
```sql
SELECT email, locked_until, failed_attempts
FROM account_locks
WHERE is_locked = TRUE;
```

### Clear Old Data:
```sql
SELECT cleanup_security_data();
```

---

## ✅ Success Criteria

All items should be checked ✅:

- [x] Database migration successful
- [x] 5 tables created
- [x] Security functions working
- [x] Login attempts being tracked
- [x] Account lockout working
- [x] Can unlock manually
- [x] Logs being created
- [x] No database errors

---

## 🎉 You're Done!

If all checks pass, your system is protected against brute force attacks!

**Security Level:** 🛡️ HIGH  
**Setup Time:** ~10 minutes  
**Status:** ✅ PRODUCTION READY  

---

## 📚 Next Steps

1. ✅ Read full documentation: `BRUTE_FORCE_PROTECTION_GUIDE.md`
2. ✅ Set up monitoring dashboard
3. ✅ Configure email alerts
4. ✅ Train staff on security features
5. ✅ Test all scenarios thoroughly
6. ✅ Monitor logs regularly

---

**Your hospital management system is now secure!** 🔒✨
