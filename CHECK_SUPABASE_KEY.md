# ⚠️ Supabase Key Issue Detected

## The Problem

Your Supabase anon key looks incorrect:
```
sb_publishable_FPEWNr6wSyLh9zVfhNVBNw_StGygTEu
```

**Supabase anon keys should start with `eyJ...` and be much longer (200+ characters).**

The key you have (`sb_publishable_...`) looks like it might be from a different service or an incorrect copy.

---

## ✅ How to Get the Correct Key

### Step 1: Go to Supabase Dashboard
```
https://app.supabase.com
```

### Step 2: Select Your Project
```
Click on: cgohfhvokszbolsafpxu
```

### Step 3: Go to Settings → API
```
Left sidebar → ⚙️ Settings → API
```

### Step 4: Copy the Correct Keys

You'll see two keys:

**Project URL:**
```
https://cgohfhvokszbolsafpxu.supabase.co
```
✅ This one looks correct!

**anon public key:**
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJl...
```
❌ **This is what you need!** (starts with `eyJ`, very long)

**NOT the "service_role" key** - that's for backend only!

---

## 🔧 Fix It Now

### Option 1: Update in Supabase Dashboard

1. Go to Supabase Dashboard
2. Settings → API
3. Copy the **anon public** key (starts with `eyJ...`)
4. Update these files:

**File 1:** `js/config.js`
```javascript
export const SUPABASE_URL = "https://cgohfhvokszbolsafpxu.supabase.co";
export const SUPABASE_ANON_KEY = "eyJ...YOUR_ACTUAL_KEY_HERE...";
```

**File 2:** `.env`
```
SUPABASE_URL=https://cgohfhvokszbolsafpxu.supabase.co
SUPABASE_ANON_KEY=eyJ...YOUR_ACTUAL_KEY_HERE...
```

---

## 🎯 What This Will Fix

With the correct key:
- ✅ Booking from the app will work
- ✅ Queue status page will load
- ✅ Real-time updates will work
- ✅ Check-in button will work

---

## 🧪 After Updating

1. **Update the key** in `js/config.js`
2. **Hard refresh** browser: `Ctrl + Shift + R`
3. **Try booking again**
4. **Should work perfectly!** ✅

---

## 📸 What the Correct Key Looks Like

**❌ WRONG (what you have):**
```
sb_publishable_FPEWNr6wSyLh9zVfhNVBNw_StGygTEu
```

**✅ CORRECT (what you need):**
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNnb2hmaHZva3N6Ym9sc2FmcHh1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE2ODc...
```
(much longer, starts with `eyJ`)

---

## 🔍 Why SQL Worked But App Didn't

- **SQL Editor** uses your authenticated session (works with any key)
- **Browser app** needs the correct anon key for client-side access
- That's why SQL test succeeded but booking failed!

---

**Go get the correct anon key from Supabase Dashboard → Settings → API, update `js/config.js`, and try again!** 🚀
