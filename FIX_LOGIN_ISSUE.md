# 🔧 Fix Login Issue - Step by Step

## ⚠️ Problem:
Email `seranmani@gmail.com` is routing to admin dashboard instead of home page.

## 🎯 Root Cause:
**Old session data cached in browser localStorage/sessionStorage**

When you previously tested with different logic, a session was stored with admin role. The browser is using that old session instead of creating a new one.

## ✅ Solution - Clear All Sessions:

### Method 1: Use Clear Session Tool
1. Open: `CLEAR_SESSION.html` in your browser
2. Click "🗑️ Clear All Sessions"
3. Click "🔐 Go to Login Page"
4. Try login again

### Method 2: Browser Console (F12)
1. Open your site in browser
2. Press **F12** to open DevTools
3. Go to **Console** tab
4. Copy and paste this code:
```javascript
// Clear all sessions
localStorage.removeItem('mediqueue_session');
sessionStorage.removeItem('mediqueue_session');
localStorage.removeItem('mediqueue_demo_session');
localStorage.clear();
sessionStorage.clear();
console.log('✅ All sessions cleared!');

// Reload page
location.reload();
```
5. Press Enter
6. Try login again

### Method 3: Browser Settings
1. Press **Ctrl + Shift + Delete**
2. Select "Cookies and other site data"
3. Select "Cached images and files"
4. Click "Clear data"
5. Close and reopen browser
6. Try login again

## 🧪 Test After Clearing:

### Test 1: Admin Login ✅
```
Email: karthiksaravanavel18@gmail.com
Password: 123456
Expected: Routes to dashboard-admin.html
```

### Test 2: Doctor Login ✅
```
Email: vel759894@gmail.com
Password: 123456
Expected: Routes to dashboard-doctor.html
```

### Test 3: Regular User (THIS ONE WAS FAILING) ✅
```
Email: seranmani@gmail.com
Password: 123456
Expected: Routes to index.html (home page)
```

### Test 4: Any Other Email ✅
```
Email: user@test.com
Password: anything
Expected: Routes to index.html (home page)
```

## 📊 Console Logs to Verify:

**Open Browser Console (F12) while testing:**

### For seranmani@gmail.com (Should be patient):
```
🔐 Login attempt for: seranmani@gmail.com
🔑 Attempting authentication for: seranmani@gmail.com
✅ Regular user login (patient)  <-- THIS IS CORRECT!
✅ Authentication successful: { email: '...', role: 'patient', dashboard: '../index.html' }
🚀 Redirecting to: ../index.html  <-- SHOULD GO TO HOME PAGE
```

### If you see this (OLD SESSION):
```
📋 Existing session found: { email: 'seranmani@gmail.com', role: 'admin', ... }
```
This means old session is still cached! → Clear sessions and try again.

## 🔍 How to Check Current Session:

**In Browser Console (F12):**
```javascript
// Check localStorage
console.log('localStorage:', localStorage.getItem('mediqueue_session'));

// Check sessionStorage  
console.log('sessionStorage:', sessionStorage.getItem('mediqueue_session'));

// Check demo session
console.log('demoSession:', localStorage.getItem('mediqueue_demo_session'));
```

**Valid Patient Session Should Look Like:**
```json
{
  "email": "seranmani@gmail.com",
  "role": "patient",
  "name": "seranmani",
  "dashboard": "../index.html",
  "isSpecialUser": false,
  "loginTime": "2024-..."
}
```

**If You See role: "admin" or dashboard: "./dashboard-admin.html":**
→ That's the OLD session! Clear it!

## 🎯 Quick Fix Steps:

1. **Open:** `CLEAR_SESSION.html`
2. **Click:** "Clear All Sessions"
3. **Go to:** Login page
4. **Login with:** seranmani@gmail.com / 123456
5. **Check console:** Should see "Regular user login (patient)"
6. **Should redirect to:** index.html (home page)

## 💡 Why This Happens:

1. Login page checks for existing session on load
2. If session exists → Uses that session
3. If session has old data → Routes to wrong place
4. Solution → Clear old sessions first

## ✅ Verification Checklist:

After clearing sessions, verify:

- [ ] Admin email routes to admin dashboard
- [ ] Doctor email routes to doctor dashboard
- [ ] seranmani@gmail.com routes to HOME PAGE
- [ ] Any random email routes to HOME PAGE
- [ ] Console shows "Regular user login (patient)" for non-admin/doctor emails

## 🚨 Still Not Working?

1. Check browser console for errors
2. Verify code in `js/pages/login.js` matches:
   ```javascript
   const DEMO_USERS = {
     'karthiksaravanavel18@gmail.com': { ... },
     'vel759894@gmail.com': { ... }
   };
   ```
   Only these 2 emails should be in DEMO_USERS!

3. Check `authenticateUser()` function returns patient for other emails:
   ```javascript
   // All other users are treated as regular patients
   console.log('✅ Regular user login (patient)');
   return {
     email: normalizedEmail,
     role: 'patient',
     dashboard: '../index.html',
     isSpecialUser: false
   };
   ```

4. If still failing, share console logs

---

**Most likely fix: Just clear browser sessions! Use CLEAR_SESSION.html** 🎉
