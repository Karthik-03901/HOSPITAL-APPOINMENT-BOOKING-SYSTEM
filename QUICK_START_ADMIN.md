# 🚀 Quick Start - Admin Dashboard

## Step 1: Run SQL Schema (3 minutes)

1. Open **Supabase Dashboard** → SQL Editor
2. Open file: `supabase/admin-doctor-schema-fixed.sql`
3. Copy ALL content and paste into SQL Editor
4. Click **RUN** button
5. Wait for success message: **"✅ Admin & Doctor Schema Created!"**

## Step 2: Login as Admin (1 minute)

1. Open your application
2. Go to login page: `pages/login.html`
3. Enter credentials:
   ```
   Email: karthiksaravanavel18@gmail.com
   Password: admin123
   ```
4. Click **Sign In**
5. You'll be automatically redirected to admin dashboard

## Step 3: Test Real-Time Updates (2 minutes)

### Test 1: View Dashboard
- ✅ You should see 8 statistics cards
- ✅ Appointments table at the bottom
- ✅ All data loads automatically

### Test 2: Real-Time Update
1. **Keep admin dashboard open** in Tab 1
2. **Open booking page** in Tab 2: `pages/book-appointment.html`
3. **Book a new appointment** in Tab 2
4. **Watch Tab 1** - dashboard updates automatically! 🎉
   - Statistics increase
   - New appointment appears in table
   - Toast notification shows

## 🎯 What You Get

### Real-Time Statistics (Auto-Updates Every 30s)
- 📊 Total Appointments
- 📅 Today's Appointments  
- ⏳ Pending Appointments
- 💰 Total Revenue
- 👥 Total Patients
- 👨‍⚕️ Total Doctors
- ✅ Active Doctors
- 💵 Pending Revenue

### Live Appointments Table
- ✅ Real-time updates (no refresh needed!)
- 🔍 Search by token, reason, status
- 🎯 Filters: All, Today, Pending, Completed, Cancelled
- 🎨 Color-coded status badges
- 💳 Payment status indicators
- 🔢 Queue position display
- ⚡ Quick actions: View, Confirm, Cancel

### Real-Time Features
- 🔄 WebSocket subscriptions
- 📢 Toast notifications
- ⚡ Instant updates
- 🚫 No page refresh needed

## 🎨 Using the Dashboard

### Filters
Click any filter button:
- **All** - Show everything
- **Today** - Today's appointments only
- **Pending** - Awaiting confirmation
- **Completed** - Finished appointments
- **Cancelled** - Cancelled appointments

### Search
Type in search box to find:
- Token numbers (e.g., "A-123")
- Reason text (e.g., "checkup")
- Status (e.g., "pending")

### Actions on Appointments
- **👁️ View** - See full details (coming soon)
- **✅ Confirm** - Confirm pending appointment
- **❌ Cancel** - Cancel appointment with reason

### Refresh Button
Click refresh icon in top-right to manually update all data

## 🎉 That's It!

Your admin dashboard is now live with real-time functionality!

### What Happens Automatically:
- ✅ New appointments appear instantly
- ✅ Status changes update live
- ✅ Queue positions update in real-time
- ✅ Statistics refresh every 30 seconds
- ✅ Toast notifications for all events

### No More:
- ❌ Page refreshes
- ❌ Manual polling
- ❌ Delayed updates
- ❌ Stale data

## 🔐 All Demo Accounts

### Admin
```
Email: karthiksaravanavel18@gmail.com
Password: admin123
Dashboard: pages/dashboard-admin.html
```

### Doctor
```
Email: idselect@gmail.com
Password: doctor123
Dashboard: pages/dashboard-doctor.html (basic)
```

### Patient
```
Email: patient@mediqueue.com
Password: patient123
Access: Booking and patient dashboard
```

## 🐛 Issues?

### Dashboard Shows 0 Stats
→ Create test appointments via booking page

### Real-Time Not Working
→ Check Supabase project settings - ensure Real-time is enabled

### SQL Errors
→ Make sure you used `admin-doctor-schema-fixed.sql` (not the old one)

### Login Doesn't Work
→ Use exact email/password above (copy-paste recommended)

## 📚 Full Documentation

See `ADMIN_DASHBOARD_IMPLEMENTATION.md` for:
- Complete feature list
- Technical implementation details
- Troubleshooting guide
- Next steps and enhancements

---

**Need Help?** Check browser console (F12) for error messages.
