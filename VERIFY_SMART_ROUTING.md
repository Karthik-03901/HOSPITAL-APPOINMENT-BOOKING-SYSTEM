# ✅ Smart Routing Verification Checklist

## 🎯 Quick Verification (5 minutes)

Before starting comprehensive testing, verify the basic setup:

---

## Step 1: File Verification

### Check Files Exist:
- [ ] `js/smart-routing.js` exists
- [ ] `index.html` has been updated
- [ ] `js/pages/login.js` has been updated

### Quick File Check:
```bash
# In your terminal, run:
dir js\smart-routing.js
# Should show the file exists

# Or in PowerShell:
Test-Path "js\smart-routing.js"
# Should return: True
```

---

## Step 2: Browser Test

### Open in Browser:
1. [ ] Open `index.html` in browser (double-click or use Live Server)
2. [ ] Press F12 to open Developer Tools
3. [ ] Go to Console tab

### Expected Console Output:
```javascript
Smart routing initialized: { 
  createAccount: true, 
  bookAppointment: true, 
  trackLive: true 
}
```

**If you see this ✅ → Basic setup is working!**

**If you DON'T see this ❌ → Check:**
- Script tag is in `index.html`
- No JavaScript errors in console
- File path is correct

---

## Step 3: Visual Verification

### Find the 3 Buttons:

#### Button #1: "Start Free Trial"
- [ ] Located in hero section (top of page)
- [ ] Has teal background
- [ ] Text reads "Start Free Trial"
- [ ] Has right arrow icon →
- [ ] Hovering shows visual feedback

#### Button #2: "Book Now"
- [ ] Located in navigation bar (top right)
- [ ] Has teal background
- [ ] Text reads "Book Now"
- [ ] Visible on desktop (may be hidden on mobile menu)
- [ ] Hovering shows visual feedback

#### Button #3: "Track Now"
- [ ] Located in "How It Works" section
- [ ] Under Step 3: "Track Live"
- [ ] Has transparent background with teal border
- [ ] Has eye icon 👁️
- [ ] Text reads "Track Now"
- [ ] Hovering shows visual feedback

**If you can see all 3 buttons ✅ → Visual setup is correct!**

---

## Step 4: Click Test (Not Logged In)

### Test Button #1:
1. [ ] Make sure you're NOT logged in (clear session if needed)
2. [ ] Click "Start Free Trial"
3. [ ] Should redirect to `pages/login.html`

**Pass?** ⬜ Yes | ⬜ No

### Test Button #2:
1. [ ] Go back to homepage
2. [ ] Click "Book Now" in navbar
3. [ ] Should show notification: "Please login first..."
4. [ ] Should redirect to `pages/login.html` after 1 second

**Pass?** ⬜ Yes | ⬜ No

### Test Button #3:
1. [ ] Go back to homepage
2. [ ] Scroll to "How It Works" section
3. [ ] Click "Track Now"
4. [ ] Should show notification: "Please login first..."
5. [ ] Should redirect to `pages/login.html` after 1 second

**Pass?** ⬜ Yes | ⬜ No

---

## Step 5: Click Test (Logged In)

### Login First:
1. [ ] On login page, enter any email/password (e.g., `test@test.com` / `password`)
2. [ ] Click "Sign In"
3. [ ] Should redirect somewhere (homepage or book appointment)

### Test Button #1:
1. [ ] Go to homepage (index.html)
2. [ ] Click "Start Free Trial"
3. [ ] Should redirect to `pages/book-appointment.html`

**Pass?** ⬜ Yes | ⬜ No

### Test Button #2:
1. [ ] Go back to homepage
2. [ ] Click "Book Now" in navbar
3. [ ] Should redirect to `pages/book-appointment.html` immediately

**Pass?** ⬜ Yes | ⬜ No

### Test Button #3 (No Appointments):
1. [ ] Go back to homepage
2. [ ] Scroll to "How It Works"
3. [ ] Click "Track Now"
4. [ ] Should show notification: "You don't have any appointments yet..."
5. [ ] Should redirect to `pages/book-appointment.html` after 1 second

**Pass?** ⬜ Yes | ⬜ No

---

## Step 6: Intended Destination Test

### Test "Book Now" → Login → Redirect:
1. [ ] Logout (clear session)
2. [ ] Go to homepage
3. [ ] Click "Book Now"
4. [ ] On login page, login with any credentials
5. [ ] Should redirect to `pages/book-appointment.html` (NOT homepage)

**Pass?** ⬜ Yes | ⬜ No

### Test "Track Now" → Login → Redirect:
1. [ ] Logout
2. [ ] Go to homepage
3. [ ] Scroll to "How It Works" and click "Track Now"
4. [ ] On login page, login with any credentials
5. [ ] Should redirect to `pages/queue-status.html` (NOT homepage)

**Pass?** ⬜ Yes | ⬜ No

---

## Step 7: Console Verification

### Check Console Logs:

Open browser console and look for these logs when clicking buttons:

#### Expected Logs:
```javascript
// On page load
"Smart routing initialized: {...}"

// When clicking button (not logged in)
"Error checking login status:" // OR session info

// When clicking button (logged in)
"User logged in, redirecting..."

// When clicking Track Now (logged in)
"Error checking appointments:" // OR appointment data

// On login page after redirect
"📍 Intended destination found: book-appointment" // OR track-live
```

**Logs look good?** ⬜ Yes | ⬜ No

---

## Step 8: Network Tab Check

### Check Network Requests:

1. [ ] Open Developer Tools → Network tab
2. [ ] Reload homepage
3. [ ] Look for these files:

```
Name                    Status  Type
smart-routing.js        200     script
supabaseClient.js       200     script
login.js               200     script
testimonials.js        200     script
message-box.js         200     script
navbar-scroll.js       200     script
```

**All files loaded?** ⬜ Yes | ⬜ No

**If any 404 errors:** Check file paths in script tags

---

## Step 9: LocalStorage Check

### Verify Intended Destination Storage:

1. [ ] Logout
2. [ ] Open Developer Tools → Application tab → Local Storage
3. [ ] Click "Book Now" button
4. [ ] Check Local Storage for key: `intendedDestination`
5. [ ] Value should be: `"book-appointment"`

**LocalStorage working?** ⬜ Yes | ⬜ No

---

## Step 10: Mobile Responsiveness

### Test on Mobile (or Responsive Mode):

1. [ ] Press F12 → Click device toolbar icon (or Ctrl+Shift+M)
2. [ ] Select mobile device (e.g., iPhone 12)
3. [ ] Check all 3 buttons are visible and clickable
4. [ ] Button #2 may be in mobile menu
5. [ ] All buttons should be touch-friendly

**Mobile works?** ⬜ Yes | ⬜ No

---

## 🎯 Overall Status

### Quick Summary:

| Test | Status |
|------|--------|
| Files exist | ⬜ |
| Console shows init | ⬜ |
| All 3 buttons visible | ⬜ |
| Button #1 works (not logged in) | ⬜ |
| Button #2 works (not logged in) | ⬜ |
| Button #3 works (not logged in) | ⬜ |
| Button #1 works (logged in) | ⬜ |
| Button #2 works (logged in) | ⬜ |
| Button #3 works (logged in) | ⬜ |
| Intended destination works | ⬜ |
| Console logs correct | ⬜ |
| Network files load | ⬜ |
| LocalStorage works | ⬜ |
| Mobile responsive | ⬜ |

**Legend:** ✅ Pass | ❌ Fail | ⬜ Not tested

---

## 🐛 Common Issues

### Issue: Console shows "Smart routing initialized: all false"
**Cause:** Button IDs not found in HTML  
**Fix:** Verify button IDs in `index.html`:
- `id="btn-create-account"`
- `id="btn-book-appointment"`
- `id="btn-track-live"`

### Issue: "supabase is not defined" error
**Cause:** supabaseClient.js not loaded  
**Fix:** Check script tag order in HTML, supabaseClient should load before smart-routing

### Issue: Notifications not showing
**Cause:** Toast component not available  
**Fix:** Should fallback to `alert()`, check if alerts appear

### Issue: Redirect not happening
**Cause:** JavaScript error blocking execution  
**Fix:** Check console for errors, fix them first

### Issue: Database query fails
**Cause:** Supabase credentials or table structure  
**Fix:** 
1. Check `.env` file has correct Supabase URL and key
2. Verify `appointments` table exists in Supabase
3. Check RLS policies allow SELECT

---

## 🔍 Detailed Debug Steps

### If Button #1 Fails:

```javascript
// In console, run:
const btn = document.getElementById('btn-create-account');
console.log('Button #1:', btn);
// Should show: <a id="btn-create-account" ...>

// Test click handler manually:
import { handleCreateAccountClick } from './js/smart-routing.js';
const event = new Event('click');
await handleCreateAccountClick(event);
```

### If Button #2 Fails:

```javascript
// In console, run:
const btn = document.getElementById('btn-book-appointment');
console.log('Button #2:', btn);
// Should show: <a id="btn-book-appointment" ...>

// Test click handler manually:
import { handleBookAppointmentClick } from './js/smart-routing.js';
const event = new Event('click');
await handleBookAppointmentClick(event);
```

### If Button #3 Fails:

```javascript
// In console, run:
const btn = document.getElementById('btn-track-live');
console.log('Button #3:', btn);
// Should show: <a id="btn-track-live" ...>

// Test click handler manually:
import { handleTrackLiveClick } from './js/smart-routing.js';
const event = new Event('click');
await handleTrackLiveClick(event);
```

### If Login Check Fails:

```javascript
// In console, run:
import { isUserLoggedIn } from './js/smart-routing.js';
const loggedIn = await isUserLoggedIn();
console.log('Logged in:', loggedIn);
// Should be true or false
```

### If Appointment Check Fails:

```javascript
// In console, run:
import { hasUserBookedAppointment } from './js/smart-routing.js';
const hasAppt = await hasUserBookedAppointment();
console.log('Has appointment:', hasAppt);
// Should be true or false
```

---

## ✅ Success Criteria

All items should be checked ✅ for system to be considered working:

- [x] All files exist
- [x] No console errors
- [x] All 3 buttons visible
- [x] All buttons clickable
- [x] Correct redirects for not logged in state
- [x] Correct redirects for logged in state
- [x] Notifications show before redirect
- [x] Intended destination saves and restores
- [x] Mobile responsive
- [x] No JavaScript errors

---

## 📞 Next Steps

### If Everything Works ✅:
1. ✅ System is ready to use!
2. ✅ Run full test suite: `SMART_ROUTING_TEST_GUIDE.md`
3. ✅ Deploy to production
4. ✅ Monitor for issues

### If Something Fails ❌:
1. ❌ Note which test failed
2. ❌ Check console for errors
3. ❌ Review relevant documentation
4. ❌ Try debug steps above
5. ❌ Ask for help with specific error message

---

## 📊 Test Results

**Date Tested:** _____________________  
**Tested By:** _____________________  
**Browser:** _____________________  
**Overall Status:** ⬜ Pass | ⬜ Fail  

**Notes:**
_________________________________________________
_________________________________________________
_________________________________________________

---

**Ready for production?** ⬜ Yes | ⬜ No (explain why)

_________________________________________________
_________________________________________________

---

## 🎉 Congratulations!

If all checks pass, your smart routing system is working perfectly! 🚀

**Next:** Read `SMART_ROUTING_COMPLETE.md` for advanced features and customization options.
