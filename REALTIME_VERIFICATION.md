# 🔍 Real-Time System Verification Guide

## Current Status

Your real-time queue management system is **READY TO TEST**! 

### ✅ What's Already Done

1. **Front-End Implementation**
   - ✅ Queue status page (`pages/queue-status.html`)
   - ✅ Real-time manager (`js/utils/realtime.js`)
   - ✅ Demo simulator for testing (`js/utils/demo-queue-simulator.js`)
   - ✅ Toast notifications
   - ✅ Browser notifications support
   - ✅ Check-in functionality
   - ✅ Live position tracking

2. **Supabase Configuration**
   - ✅ Credentials configured (`js/config.js`)
   - ✅ Supabase client initialized (`js/supabaseClient.js`)
   - ✅ SQL schema created (`supabase/realtime-schema-simple.sql`)

3. **UI Integration**
   - ✅ Booking flow redirects to queue status
   - ✅ Patient dashboard has "View Queue Status" button
   - ✅ Glassmorphic design applied

---

## 🚀 Quick Start Guide

### Option 1: Test with DEMO MODE (No Supabase Required)

You can test the entire system RIGHT NOW without setting up Supabase!

**Steps:**

1. **Open the application**
   ```
   Open index.html in your browser
   ```

2. **Book an appointment**
   - Click "Book Appointment"
   - Go through the booking wizard
   - Complete the booking

3. **View queue status**
   - After booking, you'll be redirected to queue status page
   - You should see:
     - 🟣 Purple "DEMO MODE" control box (bottom right)
     - Your queue position (starts at 5)
     - Estimated wait time
     - Token number and doctor details

4. **Test real-time updates**
   - Click "⏭️ Advance Queue" button
   - Watch the position decrease: 5 → 4 → 3 → 2 → 1 → 0
   - When position = 0, you'll see "🔔 It's your turn!"
   - Browser notification will appear (if you allow notifications)

**Expected Behavior in Demo Mode:**
- ✅ Live position updates
- ✅ Animated position changes
- ✅ ETA calculations
- ✅ Toast notifications
- ✅ Browser notifications (when position ≤ 3)
- ✅ Sound alert on your turn
- ✅ "Check In" button (simulated)

---

### Option 2: Test with PRODUCTION MODE (Supabase Required)

To test with real database and real-time WebSocket connections:

#### Step 1: Verify Supabase Credentials

**Check your configuration:**

```javascript
// File: js/config.js
export const SUPABASE_URL = "https://cgohfhvokszbolsafpxu.supabase.co";
export const SUPABASE_ANON_KEY = "sb_publishable_FPEWNr6wSyLh9zVfhNVBNw_StGygTEu";
```

**Are these correct?**
- [ ] URL matches your Supabase project
- [ ] ANON_KEY is correct

**Where to find these:**
1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Select your project: `cgohfhvokszbolsafpxu`
3. Go to **Settings** → **API**
4. Copy:
   - **Project URL** → `SUPABASE_URL`
   - **anon public** key → `SUPABASE_ANON_KEY`

#### Step 2: Run Database Schema

**You need to run ONE SQL file:**

1. Open Supabase Dashboard
2. Go to **SQL Editor**
3. Click **"New Query"**
4. Copy the entire contents of `supabase/realtime-schema-simple.sql`
5. Paste into the SQL editor
6. Make sure you're using the **postgres** role (top right dropdown)
7. Click **"Run"**

**Expected Output:**

```
✅ Real-time schema setup complete!
============================================
Tables created:
  - queue_positions
  - notifications

Realtime enabled on:
  - queue_positions
  - notifications
  - appointments

RLS policies: ✅ Configured
Triggers: ✅ Created
```

**If you see an error:**
- Read the error message carefully
- Check [SUPABASE_SETUP_TROUBLESHOOTING.md](./SUPABASE_SETUP_TROUBLESHOOTING.md)
- Most common issue: tables already exist (this is OK!)

#### Step 3: Verify Tables Were Created

Run this in SQL Editor:

```sql
-- Check if tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('queue_positions', 'notifications', 'appointments')
ORDER BY table_name;
```

**Expected Output:**
```
table_name
-----------------
appointments
notifications
queue_positions
```

#### Step 4: Verify Realtime is Enabled

Run this in SQL Editor:

```sql
-- Check Realtime publications
SELECT schemaname, tablename 
FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime'
AND tablename IN ('queue_positions', 'notifications', 'appointments');
```

**Expected Output:**
```
schemaname | tablename
-----------+------------------
public     | appointments
public     | notifications
public     | queue_positions
```

#### Step 5: Test Database Connection

**In browser console:**

```javascript
// Open your app in browser
// Press F12 to open Developer Tools
// Go to Console tab
// Run this code:

import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm';

const supabase = createClient(
  'https://cgohfhvokszbolsafpxu.supabase.co',
  'sb_publishable_FPEWNr6wSyLh9zVfhNVBNw_StGygTEu'
);

// Test connection
const { data, error } = await supabase
  .from('queue_positions')
  .select('*')
  .limit(1);

console.log('Connection test:', { data, error });
```

**Expected Output:**
```javascript
Connection test: {
  data: [],  // or array of records if you have data
  error: null
}
```

**If you see an error:**
- Check your credentials in `js/config.js`
- Make sure RLS policies are set up correctly
- Check network tab for failed requests

#### Step 6: Test Realtime WebSocket

**In browser console:**

```javascript
// Subscribe to changes
const channel = supabase
  .channel('test-channel')
  .on(
    'postgres_changes',
    {
      event: '*',
      schema: 'public',
      table: 'queue_positions'
    },
    (payload) => {
      console.log('🔴 REALTIME UPDATE:', payload);
    }
  )
  .subscribe((status) => {
    console.log('📡 Subscription status:', status);
  });

// Expected: "📡 Subscription status: SUBSCRIBED"
```

#### Step 7: Test Complete Flow

1. **Book an appointment**
   - Go through the booking wizard
   - Submit the appointment
   - You'll be redirected to queue status page

2. **Verify queue position created**
   - Run in SQL Editor:
   ```sql
   SELECT * FROM queue_positions ORDER BY created_at DESC LIMIT 1;
   ```
   - Should see your appointment's queue position

3. **Test real-time updates**
   - Keep queue status page open
   - In SQL Editor, update the position:
   ```sql
   UPDATE queue_positions 
   SET position = 3, updated_at = NOW()
   WHERE id = 'YOUR_QUEUE_POSITION_ID';
   ```
   - The page should update INSTANTLY without refresh!

4. **Test check-in**
   - Click "Check In Now" button
   - Should update `check_in_time` in database
   - Button should disappear

5. **Test appointment called**
   - In SQL Editor:
   ```sql
   UPDATE appointments 
   SET status = 'called'
   WHERE id = 'YOUR_APPOINTMENT_ID';
   ```
   - Should see "🔔 It's your turn!" on page
   - Browser notification should appear
   - Sound should play

---

## 🐛 Troubleshooting

### Issue: "No appointment found"

**Problem:** appointmentId not passed correctly

**Solution:**
1. Check URL has `?id=YOUR_APPOINTMENT_ID`
2. Or check localStorage:
   ```javascript
   localStorage.getItem('currentAppointmentId')
   ```

### Issue: "Running in DEMO mode"

**Problem:** Can't connect to Supabase, falling back to demo

**Reasons:**
- Supabase credentials incorrect
- Network error
- Database not set up

**Solution:**
1. Check browser console for errors
2. Verify credentials in `js/config.js`
3. Test connection (see Step 5 above)

### Issue: "Position not updating in real-time"

**Problem:** Realtime not enabled or RLS blocking

**Solutions:**

1. **Check Realtime is enabled:**
   ```sql
   SELECT * FROM pg_publication_tables 
   WHERE pubname = 'supabase_realtime';
   ```

2. **Check WebSocket connection:**
   - Open Developer Tools → Network tab
   - Filter by "WS" (WebSocket)
   - Should see active connection

3. **Temporarily disable RLS for testing:**
   ```sql
   ALTER TABLE queue_positions DISABLE ROW LEVEL SECURITY;
   -- Test if updates work now
   -- If yes, RLS is the issue
   -- Re-enable: ALTER TABLE queue_positions ENABLE ROW LEVEL SECURITY;
   ```

### Issue: "Check-in button not working"

**Problem:** Database update failing

**Solutions:**

1. **Check RLS policies:**
   ```sql
   -- Add policy for updates
   CREATE POLICY "appointments_update_own" ON appointments
     FOR UPDATE
     USING (patient_id = auth.uid());
   ```

2. **Check you're authenticated:**
   ```javascript
   // In browser console
   const { data: { user } } = await supabase.auth.getUser();
   console.log('Current user:', user);
   ```

### Issue: "Notifications not appearing"

**Problem:** Permission not granted

**Solution:**
1. Click the "🔔" icon in browser address bar
2. Allow notifications
3. Or browser settings → Privacy → Notifications → Allow

---

## 📊 System Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    USER INTERFACE                        │
│  (pages/queue-status.html + js/pages/queue-status.js)  │
└────────────────────┬────────────────────────────────────┘
                     │
                     ↓
┌─────────────────────────────────────────────────────────┐
│              REALTIME MANAGER                            │
│          (js/utils/realtime.js)                         │
│  • Subscribes to WebSocket channels                     │
│  • Handles position updates                             │
│  • Manages notifications                                │
│  • Check-in functionality                               │
└────────────────────┬────────────────────────────────────┘
                     │
                ┌────┴────┐
                │         │
                ↓         ↓
┌────────────────────┐  ┌──────────────────────┐
│   DEMO SIMULATOR   │  │   SUPABASE REALTIME  │
│  (for testing)     │  │   (production)       │
│  • Manual advance  │  │  • WebSocket         │
│  • Auto updates    │  │  • Postgres changes  │
└────────────────────┘  └──────────────────────┘
```

### Data Flow

1. **Booking → Queue Creation**
   ```
   User books appointment
   → Appointment created in database
   → Trigger creates queue_position
   → Redirect to queue status page
   ```

2. **Real-Time Updates**
   ```
   Doctor calls next patient
   → Appointment status = 'completed'
   → Trigger recalculates queue positions
   → WebSocket broadcasts to all clients
   → UI updates instantly
   ```

3. **Check-In Flow**
   ```
   User clicks "Check In"
   → Update appointment.check_in_time
   → Update appointment.status = 'checked_in'
   → UI hides check-in button
   ```

---

## 🎯 Next Steps

### Immediate Actions

1. **Test Demo Mode** (5 minutes)
   - Open app, book appointment, test queue updates
   - Verify UI, animations, notifications

2. **Set Up Supabase** (10 minutes)
   - Run SQL schema
   - Verify tables and Realtime
   - Test connection

3. **Test Production Mode** (10 minutes)
   - Book appointment with Supabase
   - Verify queue position created
   - Test real-time updates

### Future Enhancements

- [ ] Add doctor-side queue management dashboard
- [ ] SMS notifications (Twilio integration)
- [ ] Email notifications (SendGrid integration)
- [ ] Queue analytics and reporting
- [ ] Average wait time predictions (AI/ML)
- [ ] Multiple queue support (per department)
- [ ] Priority queue management
- [ ] Virtual waiting room (video call integration)

---

## 📚 Related Documentation

- [REALTIME_FEATURES.md](./REALTIME_FEATURES.md) - Feature overview
- [REALTIME_SETUP_GUIDE.md](./REALTIME_SETUP_GUIDE.md) - Detailed setup
- [SUPABASE_SETUP_TROUBLESHOOTING.md](./SUPABASE_SETUP_TROUBLESHOOTING.md) - Error solutions
- [PRD_V2_REALTIME.md](./PRD_V2_REALTIME.md) - Product requirements

---

## 💡 Tips

### Development
- Use Demo Mode for UI development (no backend needed)
- Use production mode for testing integrations
- Check browser console for real-time events

### Debugging
- Enable "Preserve log" in browser console
- Watch Network tab for WebSocket activity
- Use Supabase Dashboard → Logs → Realtime

### Performance
- WebSocket connection is persistent (stays open)
- Updates are instant (< 100ms latency)
- Scales to 1000s of concurrent users

### Security
- RLS policies protect user data
- Only authenticated users can check in
- Patients only see their own queue position
- Doctors see their entire queue

---

## ✅ Success Checklist

Before going to production:

- [ ] Demo mode works perfectly
- [ ] Supabase credentials configured
- [ ] SQL schema executed successfully
- [ ] Tables created (queue_positions, notifications)
- [ ] Realtime enabled on all tables
- [ ] RLS policies configured
- [ ] Triggers working (auto-create queue position)
- [ ] WebSocket connects successfully
- [ ] Position updates in real-time
- [ ] Check-in button works
- [ ] Browser notifications working
- [ ] Toast notifications working
- [ ] Sound alerts working
- [ ] UI animations smooth
- [ ] No console errors
- [ ] Tested on multiple browsers
- [ ] Tested on mobile devices

---

**Status:** ✅ READY TO TEST  
**Last Updated:** July 16, 2026  
**Version:** 1.0.0

**Need Help?** Check the troubleshooting guide or review the console logs for detailed error messages.
