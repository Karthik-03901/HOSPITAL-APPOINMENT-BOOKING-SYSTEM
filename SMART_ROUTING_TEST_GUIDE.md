# 🧪 Smart Routing Testing Guide

## Prerequisites

Before testing, make sure:
- [ ] Browser developer tools are open (F12)
- [ ] Console tab is visible for debug logs
- [ ] You have cleared browser cache (Ctrl+Shift+Delete)
- [ ] You know the test credentials:
  - Admin: `karthiksaravanavel18@gmail.com` / `123456`
  - Doctor: `vel759894@gmail.com` / `123456`
  - Patient: Any email / Any password

---

## Test Suite 1: NOT LOGGED IN User

### Test 1.1: "Start Free Trial" Button (Not Logged In)
**Steps:**
1. Open `index.html` in browser
2. Make sure you are NOT logged in (clear session if needed)
3. Click "Start Free Trial" button in hero section

**Expected Result:**
- ✅ Should redirect to `pages/login.html` immediately
- ✅ No error messages
- ✅ Console log: "🔐 Checking login status..."

**Pass/Fail:** ___________

---

### Test 1.2: "Book Now" Button (Not Logged In)
**Steps:**
1. Open `index.html` in browser
2. Make sure you are NOT logged in
3. Click "Book Now" button in navigation bar

**Expected Result:**
- ✅ Should show notification: "Please login first to book an appointment"
- ✅ Should redirect to `pages/login.html` after 1 second
- ✅ Console log: "Intended destination: book-appointment"
- ✅ localStorage should contain: `intendedDestination: 'book-appointment'`

**Pass/Fail:** ___________

---

### Test 1.3: "Track Now" Button (Not Logged In)
**Steps:**
1. Open `index.html` in browser
2. Scroll down to "How It Works" section
3. Make sure you are NOT logged in
4. Click "Track Now" button in Step 3

**Expected Result:**
- ✅ Should show notification: "Please login first to track your appointment"
- ✅ Should redirect to `pages/login.html` after 1 second
- ✅ Console log: "Intended destination: track-live"
- ✅ localStorage should contain: `intendedDestination: 'track-live'`

**Pass/Fail:** ___________

---

## Test Suite 2: LOGGED IN User (No Appointments)

### Test 2.1: "Start Free Trial" Button (Logged In)
**Steps:**
1. Login with any email/password (e.g., `test@test.com` / `password`)
2. Navigate to `index.html` (home page)
3. Verify you see "Sign Out" or user profile in navbar
4. Click "Start Free Trial" button

**Expected Result:**
- ✅ Should redirect to `pages/book-appointment.html` immediately
- ✅ No error messages
- ✅ Console log: "User logged in, redirecting to booking"

**Pass/Fail:** ___________

---

### Test 2.2: "Book Now" Button (Logged In)
**Steps:**
1. Login with any email/password
2. Navigate to `index.html`
3. Click "Book Now" button in navbar

**Expected Result:**
- ✅ Should redirect to `pages/book-appointment.html` immediately
- ✅ No notification messages
- ✅ Console log: "User logged in, redirecting to booking"

**Pass/Fail:** ___________

---

### Test 2.3: "Track Now" Button (Logged In, No Appointments)
**Steps:**
1. Login with NEW email that has never booked (e.g., `newuser@test.com`)
2. Navigate to `index.html`
3. Scroll to "How It Works" section
4. Click "Track Now" button

**Expected Result:**
- ✅ Should show notification: "You don't have any appointments yet. Please book one first."
- ✅ Should redirect to `pages/book-appointment.html` after 1 second
- ✅ Console log: "User has no appointments"

**Pass/Fail:** ___________

---

## Test Suite 3: LOGGED IN User (Has Appointments)

### Test 3.1: "Track Now" Button (Has Appointments)
**Steps:**
1. Login with email that HAS booked appointments
2. Navigate to `index.html`
3. Scroll to "How It Works" section
4. Click "Track Now" button

**Expected Result:**
- ✅ Should redirect to `pages/queue-status.html?id={appointment_id}` immediately
- ✅ No notification messages
- ✅ Console log: "User has appointments, redirecting to queue status"
- ✅ URL should contain appointment ID parameter

**Pass/Fail:** ___________

---

## Test Suite 4: Intended Destination Redirect

### Test 4.1: Book Appointment → Login → Redirect Back
**Steps:**
1. Make sure you are NOT logged in
2. Open `index.html`
3. Click "Book Now" button
4. You should see notification and be on login page
5. Login with any credentials
6. Watch where you are redirected

**Expected Result:**
- ✅ After login, should redirect to `pages/book-appointment.html` (not homepage or dashboard)
- ✅ localStorage `intendedDestination` should be cleared
- ✅ Console log: "📍 Intended destination found: book-appointment"

**Pass/Fail:** ___________

---

### Test 4.2: Track Live → Login → Redirect Back
**Steps:**
1. Make sure you are NOT logged in
2. Open `index.html`
3. Scroll to "How It Works" and click "Track Now"
4. You should see notification and be on login page
5. Login with any credentials
6. Watch where you are redirected

**Expected Result:**
- ✅ After login, should redirect to `pages/queue-status.html` (not homepage or dashboard)
- ✅ localStorage `intendedDestination` should be cleared
- ✅ Console log: "📍 Intended destination found: track-live"

**Pass/Fail:** ___________

---

## Test Suite 5: Edge Cases

### Test 5.1: Double Click Prevention
**Steps:**
1. Open `index.html` (not logged in)
2. Rapidly double-click "Book Now" button

**Expected Result:**
- ✅ Should only show one notification
- ✅ Should only redirect once
- ✅ No duplicate console logs

**Pass/Fail:** ___________

---

### Test 5.2: Session Expiry
**Steps:**
1. Login and get session token
2. Manually delete session from localStorage/sessionStorage
3. Click any smart routing button

**Expected Result:**
- ✅ Should treat user as not logged in
- ✅ Should redirect to login page
- ✅ No JavaScript errors

**Pass/Fail:** ___________

---

### Test 5.3: Database Connection Error
**Steps:**
1. Login with valid credentials
2. Turn off internet connection
3. Click "Track Now" button

**Expected Result:**
- ✅ Should handle error gracefully
- ✅ Should show error message or fallback behavior
- ✅ Console log should show error details

**Pass/Fail:** ___________

---

## Debug Checklist

If tests are failing, check:

### JavaScript Console Errors
```javascript
// Open Console (F12) and look for:
- ❌ "Uncaught ReferenceError" → Module not loaded
- ❌ "Cannot read property of undefined" → Element not found
- ❌ "supabase is not defined" → supabaseClient.js not loaded
- ✅ "Smart routing initialized: {...}" → Successfully loaded
```

### Network Tab
```
Check if these files load successfully:
- smart-routing.js → Status 200
- supabaseClient.js → Status 200
- login.js → Status 200
```

### Local Storage
```javascript
// Check in Application tab → Local Storage
- Should have: mediqueue_session (if logged in)
- Should have: intendedDestination (temporarily, before login)
```

### Database Connection
```javascript
// Test Supabase connection
const { data: { session } } = await supabase.auth.getSession();
console.log('Session:', session);
```

---

## Console Debug Commands

### Check if user is logged in
```javascript
import { isUserLoggedIn } from './js/smart-routing.js';
const loggedIn = await isUserLoggedIn();
console.log('Logged in:', loggedIn);
```

### Check if user has appointments
```javascript
import { hasUserBookedAppointment } from './js/smart-routing.js';
const hasAppointment = await hasUserBookedAppointment();
console.log('Has appointment:', hasAppointment);
```

### Get user's latest appointment ID
```javascript
import { getLatestAppointmentId } from './js/smart-routing.js';
const id = await getLatestAppointmentId();
console.log('Latest appointment ID:', id);
```

### Check intended destination
```javascript
const intended = localStorage.getItem('intendedDestination');
console.log('Intended destination:', intended);
```

### Clear intended destination
```javascript
localStorage.removeItem('intendedDestination');
console.log('Intended destination cleared');
```

---

## Common Issues & Solutions

### Issue 1: Buttons not responding
**Solution:**
- Check browser console for errors
- Verify script tag is loaded: `<script type="module" src="./js/smart-routing.js"></script>`
- Verify button IDs exist in HTML
- Hard refresh: Ctrl+Shift+R

### Issue 2: Redirect not happening
**Solution:**
- Check console for error messages
- Verify Supabase connection
- Check if button event listener is attached
- Check if `window.location.href` is being called

### Issue 3: Notification not showing
**Solution:**
- Check if `window.toast` is available
- Fallback to `alert()` should work
- Import toast component: `import { toast } from './js/components/Toast.js'`

### Issue 4: Intended destination not working
**Solution:**
- Check localStorage has `intendedDestination` after clicking button
- Check login.js reads and clears `intendedDestination`
- Verify redirect URL is correct

### Issue 5: Database query errors
**Solution:**
- Verify Supabase credentials in `.env`
- Check appointments table exists
- Check RLS policies allow SELECT
- Verify patient_email column exists

---

## Test Results Summary

| Test Case | Description | Status | Notes |
|-----------|-------------|--------|-------|
| 1.1 | Start Free Trial (Not Logged In) | ⬜ | |
| 1.2 | Book Now (Not Logged In) | ⬜ | |
| 1.3 | Track Now (Not Logged In) | ⬜ | |
| 2.1 | Start Free Trial (Logged In) | ⬜ | |
| 2.2 | Book Now (Logged In) | ⬜ | |
| 2.3 | Track Now (No Appointments) | ⬜ | |
| 3.1 | Track Now (Has Appointments) | ⬜ | |
| 4.1 | Intended Destination (Book) | ⬜ | |
| 4.2 | Intended Destination (Track) | ⬜ | |
| 5.1 | Double Click Prevention | ⬜ | |
| 5.2 | Session Expiry | ⬜ | |
| 5.3 | Database Connection Error | ⬜ | |

**Legend:** ⬜ Not Tested | ✅ Pass | ❌ Fail

---

## Performance Testing

### Page Load Time
- [ ] smart-routing.js loads < 100ms
- [ ] Button initialization < 50ms
- [ ] No layout shift when buttons load

### Click Response Time
- [ ] Redirect happens < 500ms after click
- [ ] Notification appears < 100ms after click
- [ ] Database query completes < 1000ms

### Memory Usage
- [ ] No memory leaks after multiple clicks
- [ ] Event listeners properly attached
- [ ] No duplicate listeners

---

## Accessibility Testing

### Keyboard Navigation
- [ ] Tab key reaches all 3 buttons
- [ ] Enter key triggers button click
- [ ] Focus visible on buttons

### Screen Reader
- [ ] Button text is announced
- [ ] Notification messages are announced
- [ ] Link purpose is clear

### Mobile Testing
- [ ] All buttons tap-friendly (44x44px minimum)
- [ ] Notifications visible on mobile
- [ ] Redirects work on mobile

---

## Browser Compatibility

Test on:
- [ ] Chrome/Edge (latest)
- [ ] Firefox (latest)
- [ ] Safari (latest)
- [ ] Mobile Safari (iOS)
- [ ] Chrome Mobile (Android)

---

## Final Sign-off

**Tester Name:** _______________________  
**Date:** _______________________  
**Overall Status:** ⬜ Pass | ⬜ Fail | ⬜ Needs Review  
**Comments:**

_________________________________________________
_________________________________________________
_________________________________________________

---

**Ready to deploy?** ✅ Yes | ⬜ No

**If No, what needs to be fixed?**

_________________________________________________
_________________________________________________
