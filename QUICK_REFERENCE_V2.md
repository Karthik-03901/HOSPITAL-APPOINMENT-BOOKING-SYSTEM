# MediQueue V2 - Quick Reference Guide

## 📁 Project Structure

```
hospital-management-system/
├── pages/
│   ├── index.html                    # Homepage (landing)
│   ├── book-appointment.html         # ✅ Booking wizard (4 steps)
│   ├── dashboard-patient.html        # ✅ Patient dashboard
│   ├── dashboard-doctor.html         # ✅ Doctor dashboard
│   ├── dashboard-admin.html          # ✅ Admin dashboard
│   ├── register.html                 # ✅ Registration page
│   └── (future)
│       ├── queue-status.html         # ⏳ Real-time queue tracking
│       ├── medical-records.html      # ⏳ Patient records hub
│       ├── video-call.html           # ⏳ Telemedicine room
│       └── pharmacy.html             # ⏳ Pharmacy module
│
├── js/
│   ├── pages/
│   │   └── booking.js                # ✅ Booking logic (500+ lines)
│   ├── components/
│   │   ├── Toast.js                  # ✅ Notifications
│   │   ├── Modal.js                  # ✅ Dialog system
│   │   └── (future)
│   │       ├── VideoCall.js          # ⏳ WebRTC wrapper
│   │       ├── QueueBoard.js         # ⏳ Real-time queue UI
│   │       └── ChatWidget.js         # ⏳ Messaging
│   ├── data/
│   │   └── mockData.js               # ✅ 8 depts, 10+ doctors
│   ├── utils/
│   │   ├── formatters.js             # ✅ Date, time, currency
│   │   └── validators.js             # ✅ Form validation
│   └── auth.js                       # ✅ Authentication
│
├── css/
│   ├── input.css                     # ✅ Tailwind source
│   └── output.css                    # ✅ Compiled CSS
│
├── supabase/
│   ├── schema.sql                    # ✅ Basic schema
│   └── schema-enhanced.sql           # ✅ V1 enhanced schema
│
└── docs/
    ├── PRD.md                        # ✅ Original PRD (V1)
    ├── PRD_V2_REALTIME.md            # ✅ New PRD (V2) - 10K words
    ├── PRD_V2_SUMMARY.md             # ✅ Executive summary
    ├── BOOKING_SYSTEM_GUIDE.md       # ✅ Complete booking guide
    ├── BOOKING_SYSTEM_TEST.md        # ✅ Testing checklist
    ├── UI_DESIGN_SYSTEM.md           # ✅ Design system
    ├── IMPLEMENTATION_GUIDE.md       # ✅ Dev guide
    └── CHANGELOG.md                  # ✅ Version history
```


---

## 🎯 Feature Status Matrix

| Feature | V1 Status | V2 Status | Priority |
|---------|-----------|-----------|----------|
| **Appointment Booking** | ✅ Complete | ✅ Enhanced | HIGH |
| **Department Selection** | ✅ Complete | ✅ 8 departments | HIGH |
| **Doctor Profiles** | ✅ Complete | ✅ 10+ doctors | HIGH |
| **Time Slot Selection** | ✅ Complete | ✅ Real-time | HIGH |
| **Token Generation** | ✅ Complete | ✅ Unique format | HIGH |
| **Real-Time Queue** | ❌ Not started | ⏳ Phase 1 | CRITICAL |
| **Push Notifications** | ❌ Not started | ⏳ Phase 1 | HIGH |
| **AI Symptom Checker** | ❌ Not started | ⏳ Phase 2 | MEDIUM |
| **Predictive Wait Time** | ❌ Not started | ⏳ Phase 2 | MEDIUM |
| **Video Consultation** | ❌ Not started | ⏳ Phase 2 | MEDIUM |
| **In-App Messaging** | ❌ Not started | ⏳ Phase 2 | MEDIUM |
| **Payment Gateway** | ❌ Not started | ⏳ Phase 2 | MEDIUM |
| **Pharmacy Module** | ❌ Not started | ⏳ Phase 3 | LOW |
| **Lab Integration** | ❌ Not started | ⏳ Phase 3 | LOW |
| **Mobile Apps (Native)** | ❌ Not started | ⏳ Phase 3 | LOW |
| **Multi-Hospital** | ❌ Not started | ⏳ Phase 4 | LOW |

**Legend**: ✅ Complete | ⏳ Planned | ❌ Not Started

---

## 🔧 Development Commands

### Setup
```bash
# Install dependencies
npm install

# Set up environment variables
cp .env.example .env
# Edit .env with your Supabase credentials
```

### Development
```bash
# Build CSS (watch mode)
npm run dev:css

# Build CSS (one-time)
npm run build:css

# Run tests
npm test

# Run linter
npm run lint
```

### Deployment
```bash
# Deploy to Vercel
vercel --prod

# Run Supabase migrations
supabase db push
```

---

## 📊 Key URLs

### Development
- **Local**: http://localhost:3000
- **Booking Page**: /pages/book-appointment.html
- **Patient Dashboard**: /pages/dashboard-patient.html
- **Doctor Dashboard**: /pages/dashboard-doctor.html
- **Admin Dashboard**: /pages/dashboard-admin.html

### Production (Future)
- **Main Site**: https://mediqueue.com
- **API**: https://api.mediqueue.com
- **WebSocket**: wss://ws.mediqueue.com
- **Admin Panel**: https://admin.mediqueue.com


---

## 🗄️ Database Quick Reference

### Core Tables (V1)
- `profiles` - User accounts (patients, doctors, admin)
- `departments` - Medical departments
- `doctors` - Doctor profiles
- `doctor_availability` - Schedule
- `appointments` - Booking records

### New Tables (V2 - Phase 1)
- `queue_positions` - Real-time queue tracking
- `notifications` - Push/SMS/email notifications
- `activity_logs` - Audit trail

### New Tables (V2 - Phase 2)
- `messages` - In-app chat
- `video_sessions` - Telemedicine records
- `symptom_analyses` - AI symptom checker
- `wait_time_predictions` - ML predictions
- `vitals_records` - Nurse-entered vitals
- `pharmacy_orders` - Prescription fulfillment
- `lab_orders` - Lab test management

### Key Relationships
```
profiles (1) ──> (*) appointments
departments (1) ──> (*) doctors
doctors (1) ──> (*) appointments
appointments (1) ──> (1) queue_positions
appointments (1) ──> (*) messages
appointments (1) ──> (0..1) video_sessions
```

---

## 🎨 Design System Quick Ref

### Colors
```css
/* Primary */
--teal-500: #0E9384
--navy-900: #0F2744

/* Status */
--success: #059669 (green)
--warning: #F59E0B (amber)
--error: #DC2626 (coral)
--info: #0EA5E9 (sky)

/* Neutrals */
--slate-50 to --slate-950
--paper: #F8FAFC
```

### Typography
```css
/* Font Families */
font-display: Space Grotesk (headers)
font-body: Inter (content)
font-mono: JetBrains Mono (data, tokens)

/* Sizes */
text-xs: 0.75rem (12px)
text-sm: 0.875rem (14px)
text-base: 1rem (16px)
text-lg: 1.125rem (18px)
text-xl: 1.25rem (20px)
text-2xl: 1.5rem (24px)
text-4xl: 2.25rem (36px)
```

### Components
```html
<!-- Buttons -->
<button class="btn-primary">Primary Action</button>
<button class="btn-secondary">Secondary</button>
<button class="btn-ghost">Ghost</button>

<!-- Cards -->
<div class="card">Standard Card</div>
<div class="card-glass">Glassmorphic Card</div>

<!-- Forms -->
<input class="field-input" />
<textarea class="field-textarea"></textarea>

<!-- Badges -->
<span class="badge">Default</span>
<span class="status-pill">Status</span>
```

---

## 📱 API Endpoints (Future)

### Authentication
```
POST   /auth/signup
POST   /auth/login
POST   /auth/logout
GET    /auth/me
```

### Appointments
```
GET    /appointments               # List all
GET    /appointments/:id           # Get one
POST   /appointments               # Create
PATCH  /appointments/:id           # Update
DELETE /appointments/:id           # Cancel
```

### Queue
```
GET    /queue/:appointmentId       # Get position
GET    /queue/doctor/:doctorId     # Doctor's queue
POST   /queue/check-in             # Check-in
```

### Real-Time (WebSocket)
```
subscribe    queue:{appointmentId}
subscribe    doctor:{doctorId}
subscribe    hospital:general
emit         queue:update
emit         appointment:called
```

---

## 🧪 Testing Quick Commands

### Manual Testing
1. Open `book-appointment.html`
2. Complete all 4 steps
3. Verify token generation
4. Check localStorage for saved booking

### Automated Testing
```bash
# Unit tests
npm run test:unit

# Integration tests
npm run test:integration

# E2E tests
npm run test:e2e

# All tests
npm test
```

### Test Accounts
```
# Patient
Email: patient@test.com
Password: Test123!

# Doctor
Email: doctor@test.com
Password: Test123!

# Admin
Email: admin@test.com
Password: Test123!
```

---

## 🚀 Deployment Checklist

### Pre-Deploy
- [ ] Run all tests
- [ ] Build CSS
- [ ] Check for console errors
- [ ] Test on mobile
- [ ] Update environment variables
- [ ] Review database migrations

### Deploy
- [ ] Push to GitHub
- [ ] Trigger Vercel deployment
- [ ] Run database migrations
- [ ] Verify production URLs
- [ ] Check error monitoring (Sentry)

### Post-Deploy
- [ ] Smoke test critical flows
- [ ] Monitor error rates
- [ ] Check performance metrics
- [ ] Announce to team

---

## 📞 Support & Resources

### Documentation
- [Complete PRD V2](./PRD_V2_REALTIME.md)
- [PRD Summary](./PRD_V2_SUMMARY.md)
- [Booking Guide](./BOOKING_SYSTEM_GUIDE.md)
- [Test Plan](./BOOKING_SYSTEM_TEST.md)

### External Resources
- [Tailwind CSS Docs](https://tailwindcss.com/docs)
- [Supabase Docs](https://supabase.com/docs)
- [Socket.io Docs](https://socket.io/docs/v4/)
- [WebRTC Guide](https://webrtc.org/getting-started/overview)

### Team Contacts
- Product: pm@mediqueue.com
- Tech: tech@mediqueue.com
- Support: support@mediqueue.com

---

**Last Updated**: July 12, 2026  
**Version**: 2.0.0  
**Status**: Active Development

