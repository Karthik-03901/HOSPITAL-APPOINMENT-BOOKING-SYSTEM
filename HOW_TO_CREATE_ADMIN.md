# 🔐 How to Create Admin Credentials

## 🚀 Quick Start (Demo Credentials)

**No setup needed!** The system has built-in demo users:

```
📧 Email: admin@mediqueue.com
🔑 Password: admin123
👤 Role: Admin
```

Just go to `pages/login.html` and log in!

---

## 📋 Three Methods to Create Admin Users

### Method 1: Use Demo Credentials (Easiest - Works Immediately)

**Steps:**
1. Open `pages/login.html` in browser
2. Enter:
   - Email: `admin@mediqueue.com`
   - Password: `admin123`
3. Click "Sign In"
4. You'll be routed to admin dashboard ✅

**Other demo users:**
- **Doctor:** doctor@mediqueue.com / doctor123
- **Patient:** patient@mediqueue.com / patient123

**How it works:**
- Demo users are hardcoded in `js/pages/login.js`
- No database setup required
- Perfect for testing and development

---

### Method 2: Create Admin in Database (Recommended)

**Steps:**

1. **Run the SQL script:**
   ```
   File: supabase/create-admin-users.sql
   Action: Run in Supabase SQL Editor
   ```

2. **This creates:**
   - Admin profile in `profiles` table
   - Sample doctors with fees
   - Sample departments
   - Demo credentials still work!

3. **Verify:**
   ```sql
   SELECT * FROM profiles WHERE role = 'admin';
   ```

4. **Login:**
   - Use demo credentials: admin@mediqueue.com / admin123
   - Works immediately!

---

### Method 3: Create Real Supabase Auth User (Production)

**For production with real authentication:**

#### Step 1: Create User in Supabase Dashboard

1. Go to **Supabase Dashboard**
2. Navigate to **Authentication** → **Users**
3. Click **"Add user"** → **"Create new user"**
4. Enter:
   - Email: `youradmin@example.com`
   - Password: `YourSecurePassword123!`
5. Click **"Create user"**

#### Step 2: Set Role to Admin

Run this in SQL Editor:

```sql
-- Update the user's role to admin
UPDATE profiles 
SET role = 'admin', full_name = 'Your Name'
WHERE email = 'youradmin@example.com';
```

#### Step 3: Login

1. Go to `pages/login.html`
2. Enter your email and password
3. System will authenticate via Supabase Auth
4. Route to admin dashboard ✅

---

## 🎯 How the Login System Works

### Demo Mode (Default)

```javascript
// Hardcoded in js/pages/login.js
const DEMO_USERS = {
  'admin@mediqueue.com': { 
    password: 'admin123', 
    role: 'admin' 
  },
  // ... other demo users
};
```

**Flow:**
1. User enters email/password
2. System checks DEMO_USERS first
3. If match found → Log in immediately
4. Route based on role

### Production Mode (Supabase Auth)

**Flow:**
1. User enters email/password
2. System tries demo users first
3. If not found → Try Supabase Auth
4. Query `profiles` table for role
5. Route based on role

---

## 🔧 Customizing Demo Credentials

Want to change demo credentials? Edit `js/pages/login.js`:

```javascript
const DEMO_USERS = {
  'myadmin@hospital.com': { 
    password: 'mypassword123', 
    role: 'admin',
    name: 'My Admin Name'
  },
  // Add more users...
};
```

---

## 🎭 All Available Roles

The system supports these roles:

| Role | Dashboard | Permissions |
|------|-----------|-------------|
| **admin** | `dashboard-admin.html` | Full system access, manage all |
| **doctor** | `dashboard-doctor.html` | View/manage own appointments |
| **patient** | `dashboard-patient.html` | View own appointments, book new |
| **nurse** | Custom | Assist doctors (if implemented) |
| **staff** | Custom | Front desk operations |

---

## 📊 Verify Admin Setup

### Check if Admin Exists

```sql
-- Check profiles table
SELECT email, role, full_name 
FROM profiles 
WHERE role = 'admin';
```

### Check if Demo Login Works

1. Open browser console (F12)
2. Go to `pages/login.html`
3. Enter demo credentials
4. Check console logs:
   ```
   ✅ User authenticated
   ✅ Role: admin
   ✅ Routing to: dashboard-admin.html
   ```

---

## 🔐 Security Notes

### Demo Credentials
- ⚠️ **Only for development/testing**
- ⚠️ Remove before production deployment
- ⚠️ Hardcoded passwords are insecure

### Production Setup
- ✅ Use Supabase Auth
- ✅ Strong passwords
- ✅ Email verification
- ✅ Two-factor authentication (optional)
- ✅ Remove demo users from code

---

## 🚀 Quick Test Checklist

After creating admin:

- [ ] Run `create-admin-users.sql`
- [ ] Open `pages/login.html`
- [ ] Try demo admin login
- [ ] Should route to `dashboard-admin.html`
- [ ] Check session stored in localStorage
- [ ] Try logout (if button exists)
- [ ] Try doctor login
- [ ] Try patient login

---

## 💡 Common Issues

### "Invalid credentials"
**Solution:** 
- Make sure you're using exact email/password
- Check for typos
- Demo users are case-sensitive

### "Not routing to admin dashboard"
**Solution:**
- Check browser console for errors
- Verify role in database: `SELECT * FROM profiles WHERE email = 'admin@mediqueue.com'`
- Clear browser cache and try again

### "Dashboard not found"
**Solution:**
- Check file exists: `pages/dashboard-admin.html`
- Check path in `login.js`: `./dashboard-admin.html`

---

## 🎉 Summary

**Easiest way:**
```
1. Open pages/login.html
2. Email: admin@mediqueue.com
3. Password: admin123
4. Done! ✅
```

**For production:**
```
1. Create user in Supabase Auth Dashboard
2. UPDATE profiles SET role = 'admin' WHERE email = 'your@email.com'
3. Login with real credentials
4. Done! ✅
```

---

**The demo credentials work immediately - no database setup required for testing!** 🚀
