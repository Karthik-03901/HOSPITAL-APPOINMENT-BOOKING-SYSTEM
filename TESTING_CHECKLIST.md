# ✅ Testing Checklist - Homepage Implementation

## Pre-Testing Setup

### Step 1: Database Setup
- [ ] Open Supabase Dashboard
- [ ] Go to SQL Editor
- [ ] Run `supabase/messages-table.sql`
- [ ] Verify table created (check Tables section)
- [ ] Verify sample message inserted

### Step 2: Enable Realtime
- [ ] Go to Database → Replication
- [ ] Find `messages` table in list
- [ ] Toggle "Enable Realtime" to ON
- [ ] Wait for confirmation

### Step 3: Build CSS
- [ ] Open terminal in project root
- [ ] Run: `node build.js`
- [ ] Verify: "Build completed successfully!"
- [ ] Check: `css/output.css` file updated

---

## Feature Testing

### 1. Navigation (All Pages)

#### Test 1.1: Homepage Navigation
- [ ] Open `index.html`
- [ ] Verify navigation shows: Home, Profile, Dashboard, About, Contact
- [ ] Verify "Home" has blue underline (active state)
- [ ] Click each link
- [ ] Verify each page loads correctly
- [ ] Verify active state moves to clicked page

#### Test 1.2: Navigation Icons
- [ ] Verify each link has an icon:
  - [ ] 🏠 Home icon
  - [ ] 👤 Profile icon
  - [ ] 📊 Dashboard icon
  - [ ] ℹ️ About icon
  - [ ] ✉️ Contact icon

#### Test 1.3: Logo Link
- [ ] Click MediQueue logo
- [ ] Verify returns to homepage
- [ ] Test from all pages

---

### 2. Testimonials Carousel

#### Test 2.1: Automatic Scrolling
- [ ] Open `index.html`
- [ ] Scroll down to "Testimonials" section
- [ ] Wait 5 seconds
- [ ] Verify testimonials are scrolling left automatically
- [ ] Verify smooth animation (not jerky)

#### Test 2.2: Hover Pause
- [ ] Hover mouse over testimonials
- [ ] Verify scrolling PAUSES
- [ ] Move mouse away
- [ ] Verify scrolling RESUMES

#### Test 2.3: Content Check
- [ ] Verify 10 unique testimonials visible when scrolling
- [ ] Check testimonials show:
  - [ ] Dr. Rajesh Sharma
  - [ ] Priya Mehta
  - [ ] Sunil Kumar
  - [ ] Dr. Anjali Rao (NEW)
  - [ ] Amit Patel (NEW)
  - [ ] Dr. Meera Desai (NEW)
  - [ ] Rahul Singh (NEW)
  - [ ] Dr. Kavita Joshi (NEW)
  - [ ] Neha Verma (NEW)
  - [ ] Dr. Vikram Reddy (NEW)

#### Test 2.4: Card Design
- [ ] Verify each card shows:
  - [ ] 5-star rating
  - [ ] Testimonial text
  - [ ] Avatar with initials
  - [ ] Name
  - [ ] Role/title

#### Test 2.5: Infinite Loop
- [ ] Watch carousel for 2 full cycles (160 seconds)
- [ ] Verify no gaps/jumps in animation
- [ ] Verify seamless transition at loop point

---

### 3. Floating Message Box

#### Test 3.1: Button Visibility
- [ ] Open any page
- [ ] Look at bottom-right corner
- [ ] Verify blue circular button with chat icon
- [ ] Verify button is clickable

#### Test 3.2: Open/Close
- [ ] Click message box button
- [ ] Verify box slides up and opens
- [ ] Verify shows "Send us a message" header
- [ ] Click X (close button)
- [ ] Verify box closes
- [ ] Click button again
- [ ] Verify opens again

#### Test 3.3: Send Message
- [ ] Open message box
- [ ] Type "Hello, I need help" in input
- [ ] Click send button (arrow icon)
- [ ] Verify message appears in chat
- [ ] Verify input field clears
- [ ] Verify timestamp shows

#### Test 3.4: Auto-Reply
- [ ] After sending message
- [ ] Wait 2-3 seconds
- [ ] Verify auto-reply appears
- [ ] Verify reply has different styling (blue background)
- [ ] Verify reply timestamp shows

#### Test 3.5: Message Persistence
- [ ] Send a message
- [ ] Close message box
- [ ] Refresh page (F5)
- [ ] Open message box again
- [ ] Verify previous messages still visible

#### Test 3.6: Database Verification
- [ ] Open Supabase Dashboard
- [ ] Go to Table Editor → messages
- [ ] Verify your sent message is in table
- [ ] Check columns: content, sender, user_id, created_at

---

### 4. Profile Page

#### Test 4.1: Page Access (No Login)
- [ ] Log out if logged in
- [ ] Navigate to `pages/profile.html`
- [ ] Verify redirects to login page

#### Test 4.2: Page Access (With Login)
- [ ] Login with any account
- [ ] Navigate to `pages/profile.html`
- [ ] Verify page loads
- [ ] Verify no redirect

#### Test 4.3: User Info Display
- [ ] On profile page
- [ ] Verify shows:
  - [ ] Avatar with first letter of email
  - [ ] Email address
  - [ ] Member since date
  - [ ] Total appointments count
  - [ ] Upcoming appointments count

#### Test 4.4: Appointments List (No Appointments)
- [ ] If no appointments exist
- [ ] Verify shows "No appointments yet"
- [ ] Verify shows "Book Your First Appointment" button

#### Test 4.5: Appointments List (With Appointments)
- [ ] Book an appointment first
- [ ] Refresh profile page
- [ ] Verify appointment appears in list
- [ ] Verify shows:
  - [ ] Department name
  - [ ] Status badge
  - [ ] Date and time
  - [ ] Token number
  - [ ] "View Status" button

#### Test 4.6: Real-Time Updates
- [ ] Have profile page open
- [ ] In another tab, book a new appointment
- [ ] Switch back to profile page
- [ ] Verify new appointment appears WITHOUT page refresh
- [ ] Verify counts update automatically

#### Test 4.7: Logout
- [ ] Click "Sign Out" button
- [ ] Verify redirects to login page
- [ ] Verify session cleared

---

### 5. Dashboard Page

#### Test 5.1: Not Logged In
- [ ] Log out
- [ ] Navigate to `pages/dashboard.html`
- [ ] Verify shows loading spinner
- [ ] Verify redirects to login page

#### Test 5.2: Admin User
- [ ] Login with: `karthiksaravanavel18@gmail.com`
- [ ] Navigate to `pages/dashboard.html`
- [ ] Verify redirects to `dashboard-admin.html`
- [ ] Verify admin dashboard loads

#### Test 5.3: Doctor User
- [ ] Login with: `vel759894@gmail.com`
- [ ] Navigate to `pages/dashboard.html`
- [ ] Verify redirects to `dashboard-doctor.html`
- [ ] Verify doctor dashboard loads

#### Test 5.4: Other User (Patient)
- [ ] Login with any other email
- [ ] Navigate to `pages/dashboard.html`
- [ ] Verify redirects to `index.html` (home)
- [ ] Verify home page loads

#### Test 5.5: Loading State
- [ ] Clear browser cache
- [ ] Navigate to `pages/dashboard.html`
- [ ] Verify shows "Loading Dashboard..." message
- [ ] Verify shows spinner icon
- [ ] Verify message disappears after routing

---

### 6. Contact Page

#### Test 6.1: Page Load
- [ ] Navigate to `pages/contact.html`
- [ ] Verify page loads correctly
- [ ] Verify shows contact form
- [ ] Verify shows contact info cards

#### Test 6.2: Contact Info Display
- [ ] Verify shows:
  - [ ] Email card (support@mediqueue.com)
  - [ ] Phone card (+1 555-123-4567)
  - [ ] Office card (123 Healthcare Ave...)
  - [ ] "Need Immediate Help?" card

#### Test 6.3: Form Validation (Empty)
- [ ] Click "Send Message" with empty form
- [ ] Verify browser shows validation errors
- [ ] Verify form does not submit

#### Test 6.4: Form Validation (Partial)
- [ ] Fill only name
- [ ] Click "Send Message"
- [ ] Verify shows validation for missing fields

#### Test 6.5: Form Submission (Complete)
- [ ] Fill all fields:
  - [ ] Name: "Test User"
  - [ ] Email: "test@example.com"
  - [ ] Subject: "Testing"
  - [ ] Message: "This is a test message"
- [ ] Click "Send Message"
- [ ] Verify button shows "Sending..."
- [ ] Verify success message appears (green box)
- [ ] Verify form clears
- [ ] Verify button returns to "Send Message"

#### Test 6.6: Database Verification
- [ ] Open Supabase Dashboard
- [ ] Go to Table Editor → messages
- [ ] Verify contact form message saved
- [ ] Check sender = 'user'
- [ ] Check user_email matches form
- [ ] Check user_name matches form

#### Test 6.7: Message Box Integration
- [ ] On contact page
- [ ] Verify message box button visible (bottom-right)
- [ ] Click and test message box
- [ ] Verify works same as other pages

---

### 7. About Page

#### Test 7.1: Page Load
- [ ] Navigate to `pages/about.html`
- [ ] Verify page loads correctly
- [ ] Verify all sections visible

#### Test 7.2: Hero Section
- [ ] Verify shows:
  - [ ] "Revolutionizing Healthcare" title
  - [ ] Subtitle text
  - [ ] "One Queue at a Time" gradient text

#### Test 7.3: Mission Section
- [ ] Verify shows:
  - [ ] "Our Mission" heading
  - [ ] Mission statement text
  - [ ] Statistics grid with 4 stats:
    - [ ] 50K+ Patients Served
    - [ ] 500+ Healthcare Facilities
    - [ ] 98% Satisfaction Rate
    - [ ] 80% Time Saved

#### Test 7.4: Features Section
- [ ] Verify shows 3 feature cards:
  - [ ] Real-Time Tracking (⚡ icon)
  - [ ] Automated Workflows (✓ icon)
  - [ ] Smart Analytics (📊 icon)

#### Test 7.5: Technology Section
- [ ] Verify shows 4 tech badges:
  - [ ] ⚡ Real-Time (Supabase Realtime)
  - [ ] 🔒 Secure (Row-Level Security)
  - [ ] 📱 Responsive (Mobile-First Design)
  - [ ] 🚀 Fast (Edge Functions)

#### Test 7.6: CTA Section
- [ ] Verify shows:
  - [ ] "Ready to Transform..." heading
  - [ ] Two buttons:
    - [ ] "Try It Now" (links to book-appointment)
    - [ ] "Contact Sales" (links to contact)
- [ ] Click both buttons
- [ ] Verify correct pages load

#### Test 7.7: Message Box Integration
- [ ] Verify message box button visible
- [ ] Test message box functionality

---

## Responsive Testing

### Desktop (1920px)
- [ ] Open in full screen desktop
- [ ] Test all pages
- [ ] Verify navigation shows all links
- [ ] Verify testimonials show 3-4 cards at once
- [ ] Verify message box positioned correctly

### Laptop (1366px)
- [ ] Resize browser to 1366px width
- [ ] Test all pages
- [ ] Verify layout adjusts
- [ ] Verify all features work

### Tablet (768px)
- [ ] Resize browser to 768px width
- [ ] Test all pages
- [ ] Verify 2-column layout
- [ ] Verify navigation visible
- [ ] Verify forms are usable

### Mobile (375px)
- [ ] Resize browser to 375px width
- [ ] Test all pages
- [ ] Verify single column layout
- [ ] Verify hamburger menu shows
- [ ] Verify testimonials scroll
- [ ] Verify message box scales down
- [ ] Verify forms are usable

---

## Browser Testing

### Chrome
- [ ] Test on latest Chrome
- [ ] Verify all features work
- [ ] Check console for errors

### Firefox
- [ ] Test on latest Firefox
- [ ] Verify all features work
- [ ] Check console for errors

### Safari (if available)
- [ ] Test on latest Safari
- [ ] Verify all features work
- [ ] Check console for errors

### Edge
- [ ] Test on latest Edge
- [ ] Verify all features work
- [ ] Check console for errors

---

## Performance Testing

### Load Times
- [ ] Open Network tab in DevTools
- [ ] Refresh homepage
- [ ] Verify loads in < 3 seconds
- [ ] Check all assets load (CSS, JS, images)

### Animation Performance
- [ ] Open Performance tab in DevTools
- [ ] Record while testimonials scroll
- [ ] Verify maintains 60fps
- [ ] Check for frame drops

### Real-Time Performance
- [ ] Open profile page
- [ ] Book new appointment in another tab
- [ ] Verify update appears in < 1 second
- [ ] Check network tab for WebSocket connection

---

## Console Error Check

### Homepage
- [ ] Open browser console (F12)
- [ ] Refresh `index.html`
- [ ] Verify NO red errors
- [ ] Warnings are acceptable

### Profile Page
- [ ] Open console
- [ ] Navigate to profile page
- [ ] Verify NO red errors

### Dashboard Page
- [ ] Open console
- [ ] Navigate to dashboard page
- [ ] Verify NO red errors

### Contact Page
- [ ] Open console
- [ ] Navigate to contact page
- [ ] Verify NO red errors

### About Page
- [ ] Open console
- [ ] Navigate to about page
- [ ] Verify NO red errors

---

## Edge Cases

### Message Box - Rapid Messages
- [ ] Open message box
- [ ] Send 5 messages rapidly
- [ ] Verify all appear
- [ ] Verify all saved to database
- [ ] Verify auto-replies work

### Profile - No Session
- [ ] Clear cookies/storage
- [ ] Navigate to profile page
- [ ] Verify redirects to login

### Dashboard - Invalid Session
- [ ] Manually corrupt session in localStorage
- [ ] Navigate to dashboard
- [ ] Verify handles gracefully

### Testimonials - Slow Connection
- [ ] Throttle network to "Slow 3G"
- [ ] Refresh homepage
- [ ] Verify testimonials still work
- [ ] May load slower but should function

---

## Final Verification

### Code Quality
- [ ] No console errors on any page
- [ ] All links work
- [ ] All buttons work
- [ ] All forms work
- [ ] All animations smooth

### Data Integrity
- [ ] Messages saved to database
- [ ] Appointments show correctly
- [ ] Real-time updates work
- [ ] No data loss on refresh

### User Experience
- [ ] Navigation intuitive
- [ ] Pages load quickly
- [ ] Animations enhance (not distract)
- [ ] Forms easy to use
- [ ] Mobile experience good

### Accessibility
- [ ] Can tab through navigation
- [ ] Can use Enter to submit forms
- [ ] Text readable (good contrast)
- [ ] Icons have meaning

---

## Issue Tracking

### Found Issues:
1. __________________________________________________
   - Page: _________
   - Steps to reproduce: _________
   - Expected: _________
   - Actual: _________
   
2. __________________________________________________
   - Page: _________
   - Steps to reproduce: _________
   - Expected: _________
   - Actual: _________

3. __________________________________________________
   - Page: _________
   - Steps to reproduce: _________
   - Expected: _________
   - Actual: _________

---

## Sign-Off

### Tester Information
- Name: _________________________
- Date: _________________________
- Browser: _______________________
- OS: ___________________________

### Overall Status
- [ ] ✅ All tests passed
- [ ] ⚠️ Minor issues found (listed above)
- [ ] ❌ Major issues found (listed above)

### Comments:
_____________________________________________________
_____________________________________________________
_____________________________________________________
_____________________________________________________

---

## Quick Reference

### Test Priority
1. **Critical**: Navigation, Message Box, Database
2. **High**: Testimonials, Profile, Dashboard routing
3. **Medium**: Contact form, About page
4. **Low**: Animations, Performance

### Time Estimate
- Pre-setup: 5 minutes
- Feature testing: 30 minutes
- Responsive testing: 15 minutes
- Browser testing: 10 minutes
- Total: ~60 minutes

### Need Help?
- Check: `QUICK_START_GUIDE.md`
- Check: `README_HOMEPAGE_COMPLETE.md`
- Check: Browser console for errors
- Check: Supabase dashboard for database issues
