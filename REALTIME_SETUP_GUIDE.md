# 🚀 Real-Time Features Setup Guide

## Quick Start (3 Minutes)

### Option 1: Demo Mode (No Backend Required) ⚡

**Perfect for**: Testing, development, demonstrations

1. **Book an Appointment**:
   ```
   Open: pages/book-appointment.html
   Complete the 4-step wizard
   Click "View Queue Status (Live)"
   ```

2. **See Real-Time Updates**:
   - Queue status page opens automatically
   - Demo mode activates (purple control box appears)
   - Click "⏭️ Advance Queue" to simulate updates
   - Watch position decrease with animations

**That's it!** No database setup needed. Everything works locally.

---

### Option 2: Production Mode (With Supabase) 🔥

**Perfect for**: Production deployment, full functionality

#### Step 1: Supabase Project Setup (5 minutes)

1. **Go to** [Supabase Dashboard](https://app.supabase.com)

2. **Create New Project**:
   - Click "New Project"
   - Name: "MediQueue"
   - Database Password: (save this!)
   - Region: Choose closest to your users
   - Click "Create project"

3. **Wait for Setup** (2-3 minutes)
   - Project is provisioning
   - ☕ Grab coffee while it sets up

#### Step 2: Get API Credentials (1 minute)

1. **Navigate to**: Project Settings → API

2. **Copy These Values**:
   ```
   Project URL: https://xxxxx.supabase.co
   anon public key: eyJhbGc...
   ```

3. **Update Configuration**:
   ```javascript
   // File: js/config.js
   export const SUPABASE_URL = "https://xxxxx.supabase.co";
   export const SUPABASE_ANON_KEY = "eyJhbGc...";
   ```

#### Step 3: Run Database Migration (2 minutes)

1. **Open**: Supabase Dashboard → SQL Editor

2. **Create New Query**

3. **Copy & Paste**: Content from `supabase/realtime-schema.sql`

4. **Click**: "Run" button

5. **Verify Success**:
   ```
   ✅ Real-time schema setup complete!
   ✅ Tables created: queue_positions, notifications, messages, activity_logs
   ✅ Triggers created: update_queue_positions, initialize_queue
   ✅ RLS policies: Enabled and configured
   ✅ Realtime: Enabled for all tables
   ```

#### Step 4: Test Real-Time Features (2 minutes)

1. **Book Appointment**:
   - Navigate to booking page
   - Complete wizard
   - Appointment saves to Supabase

2. **View Queue Status**:
   - Click "View Queue Status (Live)"
   - See live connection indicator
   - No demo controls (using real backend)

3. **Simulate Doctor Action** (Optional):
   - Open Supabase → Table Editor → `queue_positions`
   - Change `position` from 5 to 4
   - See instant update in UI (no refresh!)

**Done!** You now have full real-time functionality. 🎉

---

## Detailed Configuration

### Environment Variables

```bash
# .env file (optional)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=eyJhbGc...
SUPABASE_SERVICE_KEY=eyJhbGc...  # Keep secret! Server-side only
```

### Database Schema Overview

```
Core Tables (Existing):
├── profiles            # Users (patients, doctors, admin)
├── departments         # Medical departments
├── doctors             # Doctor profiles
├── appointments        # Booking records

New Tables (Real-Time):
├── queue_positions     # Live queue tracking
├── notifications       # Push/SMS/email notifications
├── messages            # In-app chat
└── activity_logs       # Audit trail
```

### Real-Time Channels

```javascript
// Subscribe to multiple channels
const channel1 = supabase
  .channel('queue:patient-123')
  .on('postgres_changes', 
    { event: '*', schema: 'public', table: 'queue_positions', filter: 'appointment_id=eq.123' },
    (payload) => console.log('Queue updated:', payload)
  )
  .subscribe();

const channel2 = supabase
  .channel('notifications:user-456')
  .on('postgres_changes',
    { event: 'INSERT', schema: 'public', table: 'notifications', filter: 'user_id=eq.456' },
    (payload) => console.log('New notification:', payload)
  )
  .subscribe();
```

---

## Features Breakdown

### 1. Real-Time Queue Tracking ✅

**What it does**:
- Shows patient's current position in queue
- Updates instantly when position changes
- Calculates estimated wait time
- Sends notifications at key milestones

**How it works**:
```
Patient books → queue_positions table updated
                ↓
Doctor completes consultation → trigger runs
                ↓
All positions recalculated
                ↓
WebSocket broadcasts to affected patients
                ↓
UI updates instantly (no refresh!)
```

**User Experience**:
- Position 5: "5 patients ahead" (~75 min wait)
- Position 3: "Get ready soon" (~45 min wait) + Notification
- Position 2: "Almost your turn" (~30 min wait) + Notification
- Position 1: "Next in line!" (~15 min wait) + Notification
- Position 0: "🔔 Your turn!" + Sound + Browser notification

### 2. Check-In System ✅

**What it does**:
- Patients confirm arrival at hospital
- Updates appointment status
- Doctor sees who has arrived

**How it works**:
```javascript
// Patient clicks "Check In Now"
await realtimeQueue.checkIn();

// Updates database
UPDATE appointments 
SET check_in_time = NOW(), status = 'checked_in'
WHERE id = appointment_id;

// Doctor dashboard updates instantly
// Shows green indicator for checked-in patients
```

### 3. Browser Notifications ✅

**What it does**:
- Native OS notifications
- Works even when page is in background
- Requires user permission

**Triggers**:
- 30 minutes before appointment
- 15 minutes before
- 5 minutes before
- "Now serving" (position 0)
- Position changes (3, 2, 1)

**Example**:
```javascript
new Notification('Your Turn - MediQueue', {
  body: 'Please proceed to consultation room #3',
  icon: '/icons/icon-192x192.png',
  badge: '/icons/badge-72x72.png',
  vibrate: [200, 100, 200],
  requireInteraction: true,
  actions: [
    { action: 'view', title: 'View Queue' },
    { action: 'dismiss', title: 'OK' }
  ]
});
```

### 4. Toast Notifications ✅

**What it does**:
- In-app notifications
- Appears at top-right
- Auto-dismisses after 4 seconds
- Color-coded by type

**Types**:
- Success (green): "Position updated!"
- Error (red): "Connection failed"
- Warning (amber): "Get ready!"
- Info (blue): "Almost your turn"

### 5. Animated UI Updates ✅

**What it does**:
- Smooth transitions
- Pulse animations
- Scale effects
- Color changes

**Effects**:
- Position number scales up when changed
- Live indicator pulses continuously
- Cards lift on hover
- Buttons press down on click

---

## Advanced Configuration

### Custom Wait Time Calculation

```javascript
// Modify in js/utils/realtime.js
function calculateWaitTime(position, avgConsultationTime = 15) {
  // Custom logic here
  const baseTime = position * avgConsultationTime;
  const bufferTime = position * 2; // 2 min buffer per patient
  return baseTime + bufferTime;
}
```

### Custom Notification Triggers

```javascript
// Add new trigger in queue-status.js
if (position === 5) {
  toast.info('You have some time. Feel free to grab a coffee!', 10000);
}
```

### Multiple Language Support

```javascript
// Add to formatters.js
const messages = {
  en: {
    yourTurn: "It's your turn!",
    patientsAhead: (n) => `${n} patients ahead`
  },
  hi: {
    yourTurn: "आपकी बारी है!",
    patientsAhead: (n) => `${n} मरीज़ आगे हैं`
  }
};
```

---

## Monitoring & Debugging

### Enable Debug Mode

```javascript
// Add to top of realtime.js
const DEBUG = true;

if (DEBUG) {
  console.log('WebSocket status:', channel.state);
  console.log('Subscriptions:', supabase.getChannels());
}
```

### Check Connection Status

```javascript
// In browser console
supabase.getChannels().forEach(channel => {
  console.log(`Channel: ${channel.topic}`);
  console.log(`Status: ${channel.state}`);
  console.log(`Subscribers: ${channel.bindings.length}`);
});
```

### View Real-Time Logs

```
Supabase Dashboard → Logs → Realtime

Shows:
- Connection events
- Message broadcasts
- Error details
- Performance metrics
```

---

## Performance Optimization

### 1. Connection Pooling

```javascript
// Reuse channels instead of creating new ones
const channelCache = new Map();

function getChannel(topic) {
  if (!channelCache.has(topic)) {
    channelCache.set(topic, supabase.channel(topic));
  }
  return channelCache.get(topic);
}
```

### 2. Debounce Updates

```javascript
// Prevent too many UI updates
let updateTimer;
function debouncedUpdate(data) {
  clearTimeout(updateTimer);
  updateTimer = setTimeout(() => {
    updateUI(data);
  }, 200); // Wait 200ms before updating
}
```

### 3. Unsubscribe When Hidden

```javascript
// Save battery on mobile
document.addEventListener('visibilitychange', () => {
  if (document.hidden) {
    realtimeQueue.unsubscribe();
  } else {
    realtimeQueue.subscribe(appointmentId, callbacks);
  }
});
```

---

## Troubleshooting

### Issue: "Failed to connect to real-time updates"

**Causes**:
1. Supabase project not created
2. Realtime not enabled on tables
3. RLS policies blocking access
4. Invalid credentials

**Solutions**:
```sql
-- 1. Enable Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE queue_positions;

-- 2. Check RLS policies
SELECT * FROM pg_policies WHERE tablename = 'queue_positions';

-- 3. Test connection
SELECT * FROM queue_positions LIMIT 1; -- Should return data or empty
```

### Issue: "Position not updating"

**Debug Steps**:
1. Check if demo mode is active (purple box visible)
2. Open browser console for errors
3. Verify WebSocket connection: `supabase.getChannels()`
4. Check if position actually changed in database

### Issue: "Notifications not showing"

**Checklist**:
- [ ] Permission granted? (Check browser settings)
- [ ] HTTPS enabled? (Required for notifications)
- [ ] Service Worker registered? (Check DevTools → Application)
- [ ] Notification API supported? (Check: `'Notification' in window`)

---

## Security Best Practices

### 1. Row Level Security (RLS)

**Always enable RLS**:
```sql
ALTER TABLE queue_positions ENABLE ROW LEVEL SECURITY;

-- Patients see only their own position
CREATE POLICY "Patients see own position" ON queue_positions
  FOR SELECT USING (
    appointment_id IN (
      SELECT id FROM appointments WHERE patient_id = auth.uid()
    )
  );
```

### 2. API Key Safety

**DO**:
- ✅ Use `anon` key in frontend
- ✅ Use `service_role` key only in backend
- ✅ Store keys in environment variables
- ✅ Enable RLS on all tables

**DON'T**:
- ❌ Commit keys to Git
- ❌ Use `service_role` key in frontend
- ❌ Disable RLS in production
- ❌ Share keys publicly

### 3. Rate Limiting

```javascript
// Implement client-side rate limiting
const rateLimiter = {
  calls: 0,
  resetTime: Date.now() + 60000, // 1 minute
  limit: 60, // 60 calls per minute
  
  canMakeRequest() {
    if (Date.now() > this.resetTime) {
      this.calls = 0;
      this.resetTime = Date.now() + 60000;
    }
    return this.calls++ < this.limit;
  }
};
```

---

## Production Checklist

Before going live:

### Infrastructure
- [ ] Supabase project created
- [ ] Database migrated
- [ ] Realtime enabled
- [ ] RLS policies active
- [ ] Backups configured

### Code
- [ ] Environment variables set
- [ ] Demo mode disabled
- [ ] Error handling tested
- [ ] Logging configured
- [ ] Analytics integrated

### Testing
- [ ] Unit tests passing
- [ ] Integration tests passing
- [ ] Load testing completed
- [ ] Cross-browser tested
- [ ] Mobile tested

### Monitoring
- [ ] Sentry configured
- [ ] Uptime monitoring active
- [ ] Performance tracking
- [ ] Error alerts set up

### Documentation
- [ ] User guide written
- [ ] API docs updated
- [ ] Deployment guide ready
- [ ] Runbook prepared

---

## Support & Resources

### Documentation
- 📘 [Supabase Realtime Docs](https://supabase.com/docs/guides/realtime)
- 📗 [WebSocket API](https://developer.mozilla.org/en-US/docs/Web/API/WebSocket)
- 📕 [Notifications API](https://developer.mozilla.org/en-US/docs/Web/API/Notifications_API)

### Community
- 💬 [Supabase Discord](https://discord.supabase.com)
- 🐦 [Twitter: @supabase](https://twitter.com/supabase)
- 📧 Email: support@mediqueue.com

### Troubleshooting
- 🐛 [GitHub Issues](https://github.com/your-repo/issues)
- 📊 [Status Page](https://status.supabase.com)
- 🔧 [Debug Guide](./REALTIME_FEATURES.md)

---

**Last Updated**: July 12, 2026  
**Version**: 1.0.0  
**Next Review**: Weekly  

---

## 🎉 You're All Set!

Your real-time features are now configured and ready to use. Start with **Demo Mode** to test everything, then migrate to **Production Mode** when ready to deploy.

**Happy Building! 🚀**
