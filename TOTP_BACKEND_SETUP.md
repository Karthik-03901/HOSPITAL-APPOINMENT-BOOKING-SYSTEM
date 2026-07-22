# TOTP Backend API Setup Guide

## ✅ Implementation Complete!

The TOTP (Two-Factor Authentication) system is now fully implemented with a backend API approach.

## 🏗️ Architecture

```
Frontend (Browser)          Backend API (Node.js)         Database (Supabase)
     │                              │                             │
     ├─ totp-api-client.js         ├─ totp-server.js             ├─ user_2fa_settings
     ├─ totp-login.js         ────►│   (Express.js)          ────►├─ trusted_devices
     └─ totp-setup.html             │   Port: 3001                └─ totp_audit_log
                                    │
                                    ├─ otplib (npm)
                                    └─ qrcode (npm)
```

## 🚀 How to Start

### Option 1: Using NPM Script (Recommended)
```bash
npm run totp-server
```

### Option 2: Using Batch File
Double-click: `start-totp-server.bat`

### Option 3: Direct Node Command
```bash
node totp-server.js
```

## 📡 API Endpoints

The TOTP server runs on `http://localhost:3001` and provides these endpoints:

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/health` | Health check |
| POST | `/api/totp/generate` | Generate TOTP secret & QR code |
| POST | `/api/totp/verify` | Verify TOTP token |
| POST | `/api/totp/backup-codes` | Generate backup codes |
| POST | `/api/totp/verify-backup` | Verify backup code |
| GET | `/api/totp/status/:userId` | Check TOTP status |
| POST | `/api/totp/save` | Save TOTP settings |
| POST | `/api/totp/update-last-used` | Update last used timestamp |

## 🔧 Testing TOTP

### 1. Start Required Servers

```bash
# Terminal 1: Frontend Server
npx serve .

# Terminal 2: TOTP Backend
npm run totp-server
```

### 2. Login as Admin

- URL: `http://localhost:3000/pages/login.html`
- Email: `karthiksaravanavel18@gmail.com`
- Password: `123456`

### 3. TOTP Flow

1. **First Login**: Admin will be redirected to TOTP setup
2. **QR Code**: Scan with Google Authenticator / Authy
3. **Verify**: Enter 6-digit code
4. **Backup Codes**: Save the 10 backup codes
5. **Next Login**: Enter TOTP code or backup code
6. **Trusted Device**: Optional 30-day trust period

## 📱 TOTP Apps (Authenticator Apps)

- Google Authenticator (iOS/Android)
- Microsoft Authenticator (iOS/Android)
- Authy (iOS/Android/Desktop)
- 1Password (has built-in TOTP)

## 🔐 Security Features

✅ 30-second time window  
✅ 6-digit codes  
✅ ±1 time step tolerance (90 seconds)  
✅ 10 single-use backup codes  
✅ Device fingerprinting  
✅ Trusted device (30-day option)  
✅ 15-day inactivity re-auth  
✅ Rate limiting  
✅ Audit logging  

## 🗄️ Database Schema

Run this SQL in Supabase to set up tables:

```bash
supabase/totp-schema-clean.sql
```

Tables created:
- `user_2fa_settings` - TOTP configuration
- `trusted_devices` - Device trust management
- `totp_failed_attempts` - Rate limiting
- `totp_audit_log` - Security audit trail

## 📦 Dependencies

Already installed:
```json
{
  "otplib": "^13.4.1",
  "qrcode": "^1.5.4",
  "express": "^4.x",
  "cors": "^2.x",
  "body-parser": "^1.x"
}
```

## 🐛 Troubleshooting

### Error: "TOTP server not running"

**Solution**: Start the TOTP server
```bash
npm run totp-server
```

### Error: "Failed to generate TOTP"

**Causes**:
- TOTP server not running
- Port 3001 already in use
- CORS issues

**Solution**:
1. Check if server is running: `http://localhost:3001/health`
2. Kill process on port 3001: `netstat -ano | findstr :3001`
3. Restart TOTP server

### Admin Login Without TOTP

If TOTP server is not running, admin can still login (for development). The system shows a warning toast but allows access.

## 🔄 TOTP Re-auth Rules

| Scenario | Action |
|----------|--------|
| First login | Setup required |
| Normal login | Verify code |
| Trusted device | Skip for 30 days |
| 15-day inactive | Setup required again |
| Wrong code 5x | 15-minute lockout |

## 📝 Code Files

### Backend
- `totp-server.js` - Express API server
- `start-totp-server.bat` - Startup script

### Frontend
- `js/auth/totp-api-client.js` - API client
- `js/auth/totp-login.js` - Login modal
- `pages/totp-setup.html` - Setup wizard
- `js/pages/login.js` - Login integration

### Database
- `supabase/totp-schema-clean.sql` - Database schema

## ✨ Features

- ✅ QR code generation
- ✅ Manual secret entry fallback
- ✅ Backup codes
- ✅ Device trust management
- ✅ Inactivity detection
- ✅ Rate limiting
- ✅ Audit logging
- ✅ Security warnings

## 🎯 Next Steps

1. ✅ TOTP backend implemented
2. ✅ Frontend integration complete
3. ✅ Database schema created
4. ⏳ Test TOTP flow end-to-end
5. ⏳ Deploy to production

## 📚 Related Documentation

- `TOTP_IMPLEMENTATION_GUIDE.md` - Complete implementation details
- `TOTP_QUICK_TEST.md` - Quick testing steps
- `PRD_V3_ADVANCED.md` - Feature specifications

---

**Status**: ✅ Ready for testing

**Admin Credentials**:
- Email: `karthiksaravanavel18@gmail.com`
- Password: `123456`

**Test TOTP Now**:
1. Start TOTP server: `npm run totp-server`
2. Start web server: `npx serve .`
3. Login as admin
4. Follow setup wizard
