# 🔧 Supabase Setup Troubleshooting Guide

## Common SQL Errors & Solutions

### Error: "column user_id does not exist"

**Problem**: The script references columns that don't exist in your current schema.

**Solution**: Use the simplified schema instead.

```bash
# Use this file instead:
supabase/realtime-schema-simple.sql
```

This version:
- ✅ Creates missing tables automatically
- ✅ Skips tables that already exist
- ✅ Checks for columns before referencing them
- ✅ Works with any existing schema

---

### Error: "relation does not exist"

**Problem**: Trying to reference a table that hasn't been created yet.

**Solution**: Run the simplified schema which creates tables in the correct order:

1. Core tables (profiles, departments, doctors, appointments)
2. Real-time tables (queue_positions, notifications)
3. Triggers and functions
4. RLS policies

---

### Error: "permission denied for publication"

**Problem**: You're using the wrong database role.

**Solution**: Make sure you're running the SQL as the **postgres** role:

1. Open Supabase Dashboard
2. Go to SQL Editor
3. Select "postgres" from the role dropdown (top right)
4. Run the script

---

## Step-by-Step Setup (Fresh Start)

### Step 1: Check Your Current Schema

```sql
-- Run this to see what tables you have
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;
```

**Expected Output**:
```
table_name
-----------
(list of your current tables)
```

### Step 2: Check for Existing Tables

```sql
-- Check if appointments table exists
SELECT EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_schema = 'public' 
  AND table_name = 'appointments'
);
```

**If returns `true`**: You have the appointments table ✅  
**If returns `false`**: Need to create it first ❌

### Step 3: Run the Simplified Schema

**Option A: If you have NO tables yet**

```sql
-- Copy and paste the ENTIRE content of:
-- supabase/realtime-schema-simple.sql

-- This will create everything from scratch
```

**Option B: If you have SOME tables already**

Run only the sections you need:

```sql
-- 1. Check which tables exist first
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public';

-- 2. Skip tables you already have
-- 3. Run only the CREATE TABLE statements for missing tables
-- 4. Then run the Realtime and RLS sections
```

---

## Minimal Setup (Just Real-Time Features)

If you just want to add real-time features to your existing schema:

```sql
-- ========================================
-- MINIMAL REAL-TIME SETUP
-- ========================================

-- 1. Create queue_positions table
CREATE TABLE IF NOT EXISTS queue_positions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  appointment_id UUID, -- Remove REFERENCES if appointments table doesn't exist yet
  doctor_id UUID,
  position INT NOT NULL,
  estimated_time TIMESTAMPTZ,
  status TEXT DEFAULT 'waiting',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Enable Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE queue_positions;

-- 3. Enable RLS
ALTER TABLE queue_positions ENABLE ROW LEVEL SECURITY;

-- 4. Add basic policy (allow all for testing)
CREATE POLICY "queue_positions_public" ON queue_positions
  FOR ALL
  USING (true);

-- Test it!
SELECT * FROM queue_positions;
```

---

## Verification Steps

### 1. Verify Tables Were Created

```sql
-- Check queue_positions table
SELECT EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_schema = 'public' 
  AND table_name = 'queue_positions'
) as queue_table_exists;
```

**Expected**: `true`

### 2. Verify Realtime is Enabled

```sql
-- Check Realtime publications
SELECT * FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime';
```

**Expected**: Should see `queue_positions` in the list

### 3. Verify RLS is Enabled

```sql
-- Check RLS status
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename = 'queue_positions';
```

**Expected**: `rowsecurity` should be `true`

### 4. Test Insert

```sql
-- Try inserting a test record
INSERT INTO queue_positions (position, status)
VALUES (1, 'waiting');

-- Verify it was created
SELECT * FROM queue_positions;
```

**Expected**: Should see the record

---

## Quick Fix: Start From Scratch

If nothing is working, here's the nuclear option:

### Step 1: Drop All Tables (⚠️ WARNING: Deletes all data!)

```sql
-- ONLY DO THIS IF YOU WANT TO START FRESH
-- THIS WILL DELETE ALL YOUR DATA!

DROP TABLE IF EXISTS queue_positions CASCADE;
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS appointments CASCADE;
DROP TABLE IF EXISTS doctors CASCADE;
DROP TABLE IF EXISTS departments CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;
```

### Step 2: Run Simplified Schema

```sql
-- Now copy/paste the entire content of:
-- supabase/realtime-schema-simple.sql

-- This will create everything fresh
```

---

## Test Real-Time Connection

After setup, test the connection:

```javascript
// Open browser console on your app
// Run this code:

import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm';

const supabase = createClient(
  'YOUR_SUPABASE_URL',
  'YOUR_ANON_KEY'
);

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
      console.log('Change received!', payload);
    }
  )
  .subscribe((status) => {
    console.log('Subscription status:', status);
  });

// Should see: "Subscription status: SUBSCRIBED"
```

---

## Common Issues After Setup

### Issue 1: "Not receiving real-time updates"

**Checks**:

1. **Is Realtime enabled?**
```sql
SELECT * FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime' 
AND schemaname = 'public';
```

2. **Is RLS blocking you?**
```sql
-- Temporarily disable RLS for testing
ALTER TABLE queue_positions DISABLE ROW LEVEL SECURITY;

-- Test updates
-- If it works, RLS was the issue

-- Re-enable RLS
ALTER TABLE queue_positions ENABLE ROW LEVEL SECURITY;
```

3. **Check browser console**
```javascript
// Should see WebSocket connection
// Look for: ws://... or wss://...
```

### Issue 2: "RLS policy blocking access"

**Quick Fix** (for development only):

```sql
-- Allow all access (NOT FOR PRODUCTION!)
DROP POLICY IF EXISTS "queue_positions_public" ON queue_positions;
CREATE POLICY "queue_positions_public" ON queue_positions
  FOR ALL
  USING (true);
```

**Proper Fix** (for production):

```sql
-- Drop the public policy
DROP POLICY IF EXISTS "queue_positions_public" ON queue_positions;

-- Create proper policies
CREATE POLICY "queue_positions_select" ON queue_positions
  FOR SELECT
  USING (true); -- Everyone can view

CREATE POLICY "queue_positions_insert_auth" ON queue_positions
  FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL); -- Only authenticated users can insert
```

### Issue 3: "Triggers not firing"

**Check if triggers exist**:

```sql
SELECT trigger_name, event_manipulation, event_object_table 
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND event_object_table IN ('appointments', 'queue_positions');
```

**Re-create triggers**:

```sql
-- Drop existing
DROP TRIGGER IF EXISTS trigger_update_queue_positions ON appointments;
DROP TRIGGER IF EXISTS trigger_initialize_queue ON appointments;

-- Run the CREATE TRIGGER statements from the schema file again
```

---

## Getting Help

### Debug Logs

**Enable query logging**:

1. Supabase Dashboard
2. Settings → Database
3. Enable "Log all queries"
4. Watch logs while testing

### Check Realtime Logs

1. Supabase Dashboard
2. Logs → Realtime
3. Look for connection events
4. Check for errors

### Community Support

- 💬 [Supabase Discord](https://discord.supabase.com)
- 📧 Email: support@mediqueue.com
- 🐛 [GitHub Issues](https://github.com/your-repo/issues)

---

## Success Checklist

Before moving forward, verify:

- [ ] ✅ Tables created (queue_positions, notifications)
- [ ] ✅ Realtime enabled (ALTER PUBLICATION)
- [ ] ✅ RLS enabled and policies created
- [ ] ✅ Triggers created (update_queue_positions, initialize_queue)
- [ ] ✅ Can insert test data
- [ ] ✅ Can query data
- [ ] ✅ WebSocket connects (check browser console)
- [ ] ✅ Real-time updates work (test in app)

---

## Next Steps

Once everything is working:

1. **Test the booking flow**
   - Book an appointment
   - Should create queue_position automatically
   - Check queue status page

2. **Test real-time updates**
   - Open queue status page
   - Update position in Supabase dashboard
   - Should see instant UI update

3. **Test notifications**
   - Grant notification permission in browser
   - Change position to 3, 2, 1, 0
   - Should see browser notifications

4. **Go to production**
   - Review RLS policies (tighten security)
   - Add indexes for performance
   - Set up monitoring
   - Deploy!

---

**Last Updated**: July 12, 2026  
**Version**: 1.0.0

**Questions?** Check the main setup guide: [REALTIME_SETUP_GUIDE.md](./REALTIME_SETUP_GUIDE.md)
