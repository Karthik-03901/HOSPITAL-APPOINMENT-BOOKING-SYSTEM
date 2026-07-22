# 🚀 TOTP Quick Test Guide

## ✅ Setup Complete!

Your TOTP system is now integrated. Here's how to test it:

---

## 🧪 Test Steps:

### 1. **First Admin Login (TOTP Setup)**

```
1. Go to: http://localhost:3000/pages/login.html
2. Enter admin credentials:
   Email: karthiksaravanavel18@gmail.com
   Password: 123456
3. Click Login
```

**Expected Result:**
- ✅ Password authentication succeeds
- ✅ Detects admin user
- ✅ Checks TOTP status (not setup)
- ✅ Shows message: "Please set up Two-Factor Authentication"
- ✅ Redirects to `/pages/totp-setup.html`

---

### 2. **Complete TOTP Setup**

```
1. On setup page, click "Start Setup"
2. QR code appears
3. Open Google Authenticator / Authy on your phone
4. Scan the QR code
5. Enter the 6-digit code from your app
6. Click "Verify & Complete Setup"
7. Download/print backup codes
8. Check "I have saved my backup codes"
9. Click "Finish & Go to Dashboard"
```

**Expected Result:**
- ✅ QR code scans successfully
- ✅ TOTP code verifies
- ✅ 10 backup codes generated
- ✅ Redirects to admin dashboard

---

### 3. **Second Admin Login (TOTP Verification)**

```
1. Logout from admin dashboard
2. Go back to login page
3. Enter admin credentials again:
   Email: karthiksaravanavel18@gmail.com
   Password: 123456
4. Click Login
```

**Expected Result:**
- ✅ Password authentication succeeds
- ✅ TOTP modal appears (popup)
- ✅ Shows "Enter the 6-digit code from your authenticator app"
- ✅ Countdown timer shows (30 seconds)

```
5. Open authenticator app
6. Find "MediQueue" entry
7. Enter the 6-digit code
8. (Optional) Check "Trust this device for 30 days"
9. Click "Verify & Login"
```

**Expected Result:**
- ✅ TOTP verifies successfully
- ✅ Modal closes
- ✅ Redirects to admin dashboard

---

### 4. **Trusted Device Test**

If you checked "Trust this device":

```
1. Logout again
2. Login with admin credentials
```

**Expected Result:**
- ✅ Password authentication succeeds
- ✅ TOTP modal does NOT appear
- ✅ Directly goes to admin dashboard (trusted for 30 days)

---

### 5. **Backup Code Test**

```
1. Logout
2. Login with admin credentials
3. TOTP modal appears
4. Click "Lost your device? Use backup code"
5. Enter one of your backup codes (8 characters)
6. Click "Verify Backup Code"
```

**Expected Result:**
- ✅ Backup code verifies
- ✅ Message shows: "Backup code accepted! X codes remaining"
- ✅ Redirects to admin dashboard
- ✅ That backup code cannot be used again

---

### 6. **15-Day Inactivity Test**

To simulate 15 days of inactivity:

```sql
-- Run in Supabase SQL Editor:
UPDATE user_2fa_settings 
SET last_used_at = NOW() - INTERVAL '16 days'
WHERE user_id = 'user_a2FydGhpa3NhcmF2YW5hdmVsMTh';
```

Then login:

**Expected Result:**
- ✅ Forces TOTP re-setup
- ✅ Redirects to setup page
- ✅ Must complete setup again

---

### 7. **Rate Limiting Test**

```
1. Login with admin credentials
2. Enter WRONG TOTP code (123456)
3. Repeat 5 times
```

**Expected Result:**
- ✅ After 5 wrong attempts:
- ✅ Account locked for 15 minutes
- ✅ Shows: "Account locked. Try again in X minutes"

---

## 🔍 Console Logs to Watch:

Open browser console (F12) and you'll see:

```
🔑 Attempting authentication for: karthiksaravanavel18@gmail.com
✅ Special user authenticated: { email: ..., role: 'admin' }
🔐 Admin detected - checking TOTP status...
TOTP Status: { required: true, reason: 'not_setup' }
📱 TOTP setup required: not_setup
```

Or after setup:

```
🔐 Admin detected - checking TOTP status...
TOTP Status: { required: true, reason: 'totp_enabled' }
🔑 TOTP verification required
✅ TOTP verified successfully
```

---

## 📱 Authenticator Apps:

Download one of these (if you don't have one):

- **Google Authenticator** (iOS/Android)
- **Authy** (iOS/Android/Desktop) - Recommended!
- **Microsoft Authenticator** (iOS/Android)
- **1Password** (if you have subscription)

---

## 🐛 Troubleshooting:

### Issue: "Cannot find module '../auth/totp.js'"
**Fix:** The TOTP files are created. Make sure your server is running and files exist:
- `js/auth/totp.js`
- `js/auth/totp-login.js`

### Issue: TOTP modal doesn't appear
**Fix:** Check browser console for errors. Make sure:
1. Database functions are created (run the SQL)
2. Supabase client is configured correctly
3. Import paths are correct

### Issue: QR code doesn't load
**Fix:**
- Check internet connection (needs CDN for qrcode library)
- Check console for errors
- Make sure secret is generated

### Issue: "Invalid code" every time
**Fix:**
- Check your phone's time is synchronized
- Make sure you're scanning the right QR code
- Try codes from different time windows (wait 30 seconds)

---

## ✅ Success Checklist:

- [ ] Admin login shows TOTP setup page
- [ ] QR code generates and displays
- [ ] Authenticator app scans successfully
- [ ] Verification code works
- [ ] Backup codes download
- [ ] Second login shows TOTP modal
- [ ] TOTP verification works
- [ ] Trusted device feature works
- [ ] Backup codes work
- [ ] Rate limiting works (5 attempts)

---

## 🎉 Next Steps:

Once TOTP is working:

1. **Test with real users** in your team
2. **Document the process** for end users
3. **Add recovery flow** (email verification for lost devices)
4. **Monitor audit logs** in Supabase
5. **Set up alerts** for suspicious activity

---

**Need help?** Check the full guide: `TOTP_IMPLEMENTATION_GUIDE.md`

**Last Updated:** July 22, 2026
