# MediQueue V2 - Product Requirements Document (PRD)
## Advanced Hospital Management System with Real-Time Features

---

## 📋 Document Information

**Version**: 2.0  
**Last Updated**: July 12, 2026  
**Owner**: Product Team  
**Status**: Active Development  
**Previous Version**: [PRD.md](./PRD.md)

---

## 🎯 Executive Summary

### Vision
Transform MediQueue into an **AI-powered, real-time hospital management platform** that:
- Reduces patient wait times by **60%** (up from 40%)
- Provides **live operational intelligence** with predictive analytics
- Enables **seamless multi-stakeholder collaboration** in real-time
- Delivers **personalized patient experiences** through AI

### Key Differentiators (V2)
1. **Real-Time Everything**: Live queue updates, instant notifications, collaborative features
2. **AI-Powered Intelligence**: Predictive wait times, smart scheduling, symptom analysis
3. **Advanced Communication**: In-app chat, video calls, emergency broadcasting
4. **Predictive Analytics**: Forecasting, resource optimization, anomaly detection
5. **Mobile-First**: Progressive Web App (PWA) with offline capabilities

---

## 👥 Target Users (Expanded)

### Primary Users
1. **Patients** (Mass Market)
   - Tech-savvy millennials (25-40 years)
   - Elderly patients with caregiver assistance
   - Parents managing children's appointments

2. **Doctors** (Core Users)
   - General practitioners
   - Specialists (surgeons, cardiologists, etc.)
   - Resident doctors

3. **Nurses** (NEW)
   - Ward nurses
   - Triage nurses
   - Consultation room assistants


### Secondary Users
4. **Front Desk Staff** (High Volume)
   - Receptionists
   - Registration clerks
   - Token counter staff

5. **Admin** (Power Users)
   - Hospital administrators
   - Operations managers
   - Finance team

6. **Pharmacists** (NEW)
   - In-hospital pharmacy
   - External pharmacies (API integration)

7. **Lab Technicians** (NEW)
   - Lab result entry
   - Report generation

---

## 🚀 Core Features - V2 Enhancements

### 2.1 Patient Portal (Next-Gen)

#### A. Intelligent Appointment Booking
**Status**: 🔄 Enhanced from V1

**Features**:

- ✅ **Smart Multi-Step Wizard** (Current: 4 steps)
  - Step 1: Department Selection (8+ departments)
  - Step 2: Doctor Selection (with profiles, ratings, availability)
  - Step 3: Date & Time Slots (real-time availability)
  - Step 4: Confirmation (token generation, medical history)

- 🆕 **AI Symptom Checker** (NEW)
  - Chat-based symptom analysis
  - Recommends appropriate department
  - Suggests urgency level (emergency, urgent, routine)
  - Pre-fills reason for visit

- 🆕 **Smart Doctor Recommendations** (NEW)
  - Based on symptoms + patient history
  - Considers doctor ratings + availability
  - Shows estimated wait time for each doctor
  - "Best Match" badge on recommended doctors

- 🆕 **Flexible Scheduling Options** (NEW)
  - Same-day appointments (if slots available)
  - Next-available slot across all doctors
  - Recurring appointments (weekly/monthly)
  - Waitlist for fully booked dates

- 🆕 **Group Appointments** (NEW)
  - Book for family members (up to 5 people)
  - Synchronized time slots
  - Shared medical history access (with consent)


#### B. Real-Time Queue Tracking
**Status**: 🆕 NEW

**Features**:
- **Live Position Updates**
  - WebSocket connection for instant updates
  - Shows: "You are #3 in queue" (updates every 30 sec)
  - Animated position changes

- **Predictive Wait Time**
  - ML-based ETA calculation
  - Factors: avg consultation time, current queue, doctor pace
  - Accuracy target: 92%
  - Updates dynamically as queue moves

- **Smart Notifications**
  - 30-min warning: "Get ready to leave"
  - 15-min alert: "Time to head to hospital"
  - 5-min alert: "Almost your turn"
  - "Now Serving" push notification
  - Configurable notification preferences

- **Virtual Queue Management**
  - Check-in remotely (30 min before slot)
  - "I'm running late" button (reschedule to end of queue)
  - GPS-based arrival detection
  - Auto-cancel if no-show after 15 min

- **Queue Visualization**
  - Timeline view showing all patients ahead
  - Doctor's current status (consulting, break, delayed)
  - Interactive queue board (pull-to-refresh)


#### C. Digital Medical Records Hub
**Status**: 🆕 NEW

**Features**:
- **Complete Health Timeline**
  - Chronological view of all consultations
  - Prescriptions with medication history
  - Lab reports with trend graphs
  - Vaccination records
  - Allergies & chronic conditions

- **Document Management**
  - Upload: Drag-drop, camera capture, scan QR
  - OCR: Extract text from images (prescriptions, reports)
  - Organization: Folders by date/doctor/type
  - Sharing: Generate secure links (time-limited access)
  - Download as PDF bundle

- **Health Insights Dashboard**
  - BMI tracker with history graph
  - Blood pressure trends
  - Upcoming medication reminders
  - Health score (gamification)

- **Family Health Management**
  - Manage records for dependents (kids, elderly parents)
  - Shared access with family members
  - Emergency contact integration


#### D. Telemedicine & Communication
**Status**: 🆕 NEW

**Features**:
- **Video Consultation**
  - WebRTC-based video calls (no app download)
  - Screen sharing for reports
  - Recording (with consent)
  - Post-call summary

- **In-App Messaging**
  - Chat with doctor (async)
  - Send images/documents
  - Quick replies from doctor
  - Message read receipts

- **Prescription Renewal**
  - Request renewal for chronic medications
  - Doctor approves with one click
  - Auto-notify pharmacy

- **Second Opinion**
  - Request review from another specialist
  - Share records securely
  - Compare diagnoses

#### E. Payment & Billing
**Status**: 🆕 NEW

**Features**:
- **Multiple Payment Methods**
  - Credit/debit cards (Stripe)
  - UPI (Razorpay)
  - Wallets (Paytm, PhonePe)
  - Insurance claims

- **Smart Invoicing**
  - Itemized bills
  - Download PDF invoice
  - Email receipts
  - GST compliance

- **Payment Plans**
  - Split payment options
  - EMI for high-value treatments
  - Advance deposit for surgeries


---

### 2.2 Doctor Dashboard (AI-Powered)

#### A. Smart Queue Management
**Status**: 🔄 Enhanced from V1

**Features**:
- **Today's Schedule**
  - Patient cards with key info
  - Color-coded by status (waiting, consulting, completed)
  - Drag-to-reorder for emergencies
  - Batch actions (skip all, mark multiple complete)

- **Patient Pre-Screening**
  - AI summary of symptoms before consultation
  - Highlighted allergies & chronic conditions
  - Suggested tests based on symptoms
  - Previous diagnosis quick view

- **One-Click Actions**
  - "Call Next Patient" (sends push notification)
  - "Start Consultation" (starts timer)
  - "Mark Emergency" (moves to top)
  - "Refer to Specialist" (creates new appointment)

- **Real-Time Collaboration**
  - Nurse can add vitals during waiting
  - Lab results auto-append when ready
  - Pharmacy gets prescription instantly
  - Multiple users can view (not edit) simultaneously


#### B. Clinical Workspace (Enhanced)
**Status**: 🔄 Enhanced from V1

**Features**:
- **Intelligent Note-Taking**
  - Voice-to-text with medical terminology
  - Auto-suggest diagnoses (ICD-10 codes)
  - Templates for common cases
  - Copy from previous consultation

- **Smart Prescription Writer**
  - Drug database with dosage suggestions
  - Drug interaction warnings
  - Allergy checks (automatic)
  - Favorite combinations (save & reuse)
  - Digital signature with timestamp

- **Diagnostic Tools Integration**
  - Order lab tests directly
  - Request imaging (X-ray, MRI, CT)
  - Track test status in real-time
  - Results appear in patient record automatically

- **Decision Support System**
  - Differential diagnosis suggestions
  - Treatment protocol guidelines
  - Drug alternatives (generic options)
  - Clinical pathways


#### C. Performance Analytics (Personal)
**Status**: 🆕 NEW

**Features**:
- **Daily Metrics**
  - Patients seen today vs target
  - Average consultation time
  - Queue wait time (patient perspective)
  - Patient satisfaction score (today)

- **Weekly Insights**
  - Peak hour analysis
  - Most common diagnoses
  - Prescription patterns
  - No-show rate

- **Monthly Reports**
  - Total revenue generated
  - Patient retention rate
  - Comparison with peers (anonymized)
  - Areas for improvement

- **Gamification**
  - Badges: "Speed Demon" (fast consultations), "Patient Favorite" (high ratings)
  - Leaderboard (optional, private)
  - Achievements unlock

---

### 2.3 Admin Command Center (Enterprise-Grade)

#### A. Real-Time Hospital Overview
**Status**: 🔄 Enhanced from V1

**Features**:
- **Live Dashboard**
  - Total patients in hospital (map view)
  - Department occupancy (heatmap)
  - Queue lengths (bar chart)
  - Revenue ticker (real-time)
  - Alerts panel (bottlenecks, emergencies)

- **Resource Monitor**
  - Doctor availability (green/red indicators)
  - Room occupancy (consultation, OT, ICU)
  - Equipment status
  - Staff on duty


#### B. Predictive Analytics Engine
**Status**: 🆕 NEW

**Features**:
- **Demand Forecasting**
  - Predict patient volume (next week, month)
  - Seasonal trends (flu season, etc.)
  - Department-wise predictions
  - Resource planning recommendations

- **Anomaly Detection**
  - Unusual wait times alert
  - Sudden spike in appointments (outbreak?)
  - Staff absence patterns
  - Revenue anomalies

- **Optimization Suggestions**
  - "Add 2 more slots for Dr. Sharma on Mondays"
  - "Consider hiring part-time doctor for Saturdays"
  - "Peak hours: 10AM-12PM, schedule more staff"

- **What-If Scenarios**
  - Simulate: "What if we add a new cardiologist?"
  - Impact analysis: revenue, wait times, patient satisfaction

#### C. Advanced Reporting
**Status**: 🔄 Enhanced from V1

**Features**:
- **Custom Report Builder**
  - Drag-drop metrics (appointments, revenue, ratings)
  - Filter by date, department, doctor, patient demographics
  - Visualizations: Line, bar, pie, heatmap, scatter
  - Save templates for recurring reports

- **Scheduled Reports**
  - Auto-generate weekly/monthly reports
  - Email to stakeholders
  - PDF or Excel format

- **Benchmarking**
  - Compare with industry standards
  - Historical trends (YoY, MoM)
  - Departmental comparisons


#### D. Staff & Resource Management
**Status**: 🆕 NEW

**Features**:
- **Doctor Schedule Management**
  - Bulk availability editor (calendar view)
  - Leave management (apply, approve, reject)
  - Substitute doctor assignment
  - Shift rotation planning

- **Staff Onboarding**
  - Digital onboarding workflows
  - Document upload & verification
  - Training module assignments
  - Progress tracking

- **Performance Management**
  - Set KPIs for doctors/nurses
  - Track monthly targets
  - Performance reviews
  - Feedback collection

- **Compliance & Auditing**
  - Activity logs (who accessed what)
  - HIPAA/GDPR compliance checks
  - Data export for audits
  - Policy enforcement

---

### 2.4 Front Desk Module (Optimized)

#### A. Quick Check-In System
**Status**: 🔄 Enhanced from V1

**Features**:
- **Multi-Modal Patient Search**
  - Phone number
  - Token number
  - QR code scan (from patient app)
  - Name search with fuzzy matching
  - Biometric (fingerprint) - optional

- **Instant Registration**
  - Pre-filled forms from online booking
  - Camera capture for ID documents
  - Print token slip (thermal printer support)
  - SMS confirmation sent

- **Walk-In Management**
  - Quick slot finder (next available across doctors)
  - Emergency case flagging
  - Insurance verification
  - Co-payment collection


#### B. TV Display Mode
**Status**: 🆕 NEW

**Features**:
- **Full-Screen Queue Board**
  - Large token numbers (readable from 10m)
  - Current + next 5 patients
  - Doctor name + room number
  - Color-coded status
  - Auto-refresh every 10 seconds

- **Announcement System**
  - Display custom messages
  - Emergency alerts
  - Hospital news/promotions

- **Multi-Language Support**
  - English, Hindi, regional languages
  - Auto-rotate every 30 seconds

---

### 2.5 Nurse Dashboard (NEW)

#### A. Patient Vitals Entry
**Status**: 🆕 NEW

**Features**:
- **Quick Vitals Form**
  - BP, temp, pulse, SpO2, weight, height
  - BMI auto-calculation
  - History comparison (highlight abnormal)
  - Photo capture (wounds, rashes)

- **Triage System**
  - Assign priority level (low, medium, high, critical)
  - Auto-notify doctor for critical cases
  - Color-coded patient cards

#### B. Medication Administration
**Status**: 🆕 NEW

**Features**:
- **Medication Tracker**
  - List of prescribed meds
  - Check-off when administered
  - Time tracking (late alerts)
  - Allergy warnings

---

### 2.6 Pharmacy Integration (NEW)

#### A. Prescription Management
**Status**: 🆕 NEW

**Features**:
- **Auto-Receive Prescriptions**
  - Instant notification when doctor prescribes
  - Queue for preparation
  - Mark drugs as out-of-stock
  - Suggest alternatives to doctor

- **Inventory Management**
  - Real-time stock levels
  - Auto-reorder alerts
  - Expiry tracking
  - Batch number recording


---

## 🎨 UI/UX Enhancements (V2)

### 3.1 Design System Evolution

#### Color Palette (Expanded)
- **Primary**: Teal (#0E9384) - Healthcare trust
- **Secondary**: Navy (#0F2744 - #20507D) - Professionalism
- **Accent**: Blue (#3B82F6) - Information
- **Success**: Emerald (#059669) - Positive actions
- **Warning**: Amber (#F59E0B) - Cautions
- **Error**: Coral (#DC2626) - Errors
- **Info**: Sky (#0EA5E9) - Informational
- **Neutrals**: Slate (50-950) + Paper (#F8FAFC)

#### Typography System
- **Display**: Space Grotesk (Headers, 600-700 weight)
- **Body**: Inter (Content, 400-600 weight) - Changed from IBM Plex Sans for better readability
- **Data/Code**: JetBrains Mono (Numbers, tokens, 500-600 weight)

#### Component Library (50+ Components)
1. **Buttons**: Primary, secondary, ghost, danger, icon, loading
2. **Forms**: Input, select, textarea, checkbox, radio, toggle, datepicker
3. **Cards**: Default, glass, elevated, interactive, skeleton
4. **Tables**: Sortable, paginated, filterable, responsive
5. **Modals**: Centered, drawer, bottom-sheet, full-screen
6. **Notifications**: Toast, banner, inline, snackbar
7. **Navigation**: Navbar, sidebar, tabs, breadcrumbs, stepper
8. **Data Display**: Timeline, progress, badge, chip, avatar
9. **Feedback**: Loading spinner, skeleton, empty state, error state
10. **Charts**: Line, bar, pie, donut, heatmap, scatter


### 3.2 Micro-Interactions & Animations

**Principles**: Meaningful, fast (< 300ms), purposeful

**Examples**:
- Button press: Scale down (0.95) + shadow reduce
- Card hover: Lift (translateY -4px) + shadow increase
- Loading: Skeleton screens → fade-in real content
- Success: Checkmark animation (draw SVG path)
- Error: Shake animation (translateX -10px to +10px)
- Queue update: Smooth slide-up animation
- Notification: Slide-in from top-right + bounce

### 3.3 Responsive Design (Mobile-First)

#### Breakpoints
- **Mobile**: 320px - 640px (1 column)
- **Tablet**: 641px - 1024px (2 columns)
- **Desktop**: 1025px - 1440px (3 columns)
- **Large**: 1441px+ (4 columns, wider cards)

#### Mobile Optimizations
- Bottom navigation bar (easier thumb reach)
- Swipe gestures (delete, archive)
- Pull-to-refresh on lists
- Infinite scroll (no pagination)
- Touch-friendly targets (min 44px × 44px)
- Reduced font sizes (save space)
- Collapsible sections (accordions)

### 3.4 Accessibility (WCAG 2.1 AAA)

**Enhancements**:
- Screen reader: Full ARIA labels on all interactive elements
- Keyboard nav: Tab order, skip links, focus trap in modals
- Color contrast: Minimum 7:1 (AAA standard)
- Focus indicators: 3px teal outline with 2px offset
- Error messages: Descriptive, near field, icon + text
- Form labels: Always visible, not placeholder-only
- Alt text: All images, icons have descriptive text
- Captions: Video consultations have real-time captions


---

## 🏗️ Technical Architecture (V2)

### 4.1 Frontend Stack (Modern)

```
MediQueue Frontend
├── Core
│   ├── HTML5 (Semantic, SEO-optimized)
│   ├── Tailwind CSS 3.4+ (Utility-first, custom design system)
│   └── Vanilla JavaScript ES2023+ (Modular, tree-shakeable)
│
├── Real-Time
│   ├── Socket.io Client (WebSocket for live updates)
│   ├── Service Worker (Push notifications, offline support)
│   └── IndexedDB (Local data caching)
│
├── Components (/js/components/)
│   ├── Toast.js (4 types: success, error, warning, info)
│   ├── Modal.js (Centered, drawer, bottom-sheet)
│   ├── DataTable.js (Sort, filter, paginate, export)
│   ├── Chart.js (Wrapper for Chart.js library)
│   ├── QueueBoard.js (Real-time queue display)
│   ├── VideoCall.js (WebRTC wrapper)
│   ├── ChatWidget.js (Messaging interface)
│   └── FileUpload.js (Drag-drop, preview, progress)
│
├── Utils (/js/utils/)
│   ├── formatters.js (Date, time, currency, phone)
│   ├── validators.js (Form validation, sanitization)
│   ├── api.js (Fetch wrapper, error handling)
│   ├── realtime.js (Socket.io handlers)
│   ├── storage.js (LocalStorage, IndexedDB helpers)
│   └── notifications.js (Push, in-app notifications)
│
├── State Management (/js/state/)
│   ├── store.js (Simple Pub-Sub event system)
│   ├── queue.js (Queue state management)
│   └── auth.js (User session management)
│
└── External Libraries
    ├── Chart.js 4.0 (Data visualizations)
    ├── Day.js 1.11 (Date manipulation, lightweight)
    ├── Socket.io Client 4.5 (WebSocket)
    ├── Simple-peer (WebRTC for video calls)
    └── Tesseract.js (OCR for document scanning)
```


### 4.2 Backend Architecture (Supabase + Edge Functions)

```
Backend Services
├── Supabase Core
│   ├── PostgreSQL 15 (Database with RLS)
│   ├── Realtime (Postgres Changes → WebSocket)
│   ├── Storage (S3-compatible, documents & images)
│   ├── Auth (Email, OAuth, MFA)
│   └── PostgREST (Auto-generated REST API)
│
├── Edge Functions (Deno Deploy)
│   ├── /generate-prescription (PDF generation)
│   ├── /send-notification (SMS, email, push)
│   ├── /process-payment (Payment gateway webhook)
│   ├── /ai-symptom-checker (OpenAI API proxy)
│   ├── /predict-wait-time (ML model inference)
│   ├── /generate-report (Complex analytics)
│   └── /ocr-document (Tesseract OCR processing)
│
├── External Integrations
│   ├── OpenAI GPT-4 (Symptom analysis, note summarization)
│   ├── Twilio (SMS notifications)
│   ├── SendGrid (Email notifications)
│   ├── Stripe (Payment processing)
│   ├── Razorpay (UPI, wallets)
│   └── Firebase Cloud Messaging (Push notifications)
│
└── Monitoring & Analytics
    ├── Sentry (Error tracking)
    ├── PostHog (Product analytics)
    ├── Supabase Logs (Query performance)
    └── Grafana (Infrastructure monitoring)
```

### 4.3 Real-Time Architecture

**WebSocket Flow**:
```
1. Client connects → Socket.io handshake
2. Client subscribes to channels:
   - queue:{appointmentId} (personal queue updates)
   - doctor:{doctorId} (doctor's queue)
   - hospital:general (announcements)
3. Server listens to Postgres NOTIFY
4. On DB change → Server broadcasts to subscribed clients
5. Client receives → Updates UI (React-like state management)
```

**Scaling Strategy**:
- Socket.io with Redis adapter (horizontal scaling)
- Load balancer distributes WebSocket connections
- Sticky sessions for same-user connections
- Fallback to long-polling if WebSocket unavailable


### 4.4 Database Schema (V2 - Enhanced)

#### New Tables (V2)

```sql
-- Real-time queue tracking
CREATE TABLE queue_positions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  appointment_id UUID REFERENCES appointments(id) ON DELETE CASCADE,
  doctor_id UUID REFERENCES doctors(id),
  position INT NOT NULL,
  estimated_time TIMESTAMPTZ,
  actual_call_time TIMESTAMPTZ,
  status TEXT DEFAULT 'waiting', -- waiting, called, consulting, completed
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- In-app messaging
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  sender_id UUID REFERENCES profiles(id),
  receiver_id UUID REFERENCES profiles(id),
  appointment_id UUID REFERENCES appointments(id),
  message TEXT NOT NULL,
  attachments TEXT[], -- URLs
  read BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Video consultation sessions
CREATE TABLE video_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  appointment_id UUID REFERENCES appointments(id),
  room_id TEXT UNIQUE,
  started_at TIMESTAMPTZ,
  ended_at TIMESTAMPTZ,
  duration_minutes INT,
  recording_url TEXT,
  participants JSONB, -- [{user_id, joined_at, left_at}]
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- AI symptom analysis
CREATE TABLE symptom_analyses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id UUID REFERENCES profiles(id),
  symptoms JSONB, -- [{symptom, severity, duration}]
  ai_analysis JSONB, -- {suggested_departments, urgency, recommendations}
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Wait time predictions
CREATE TABLE wait_time_predictions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  doctor_id UUID REFERENCES doctors(id),
  date DATE,
  hour INT, -- 0-23
  predicted_wait_minutes INT,
  actual_wait_minutes INT,
  accuracy_score NUMERIC(3,2),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```


```sql
-- Nurse vitals records
CREATE TABLE vitals_records (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  appointment_id UUID REFERENCES appointments(id),
  recorded_by UUID REFERENCES profiles(id), -- nurse
  blood_pressure_systolic INT,
  blood_pressure_diastolic INT,
  heart_rate INT,
  temperature NUMERIC(4,1),
  oxygen_saturation INT,
  weight NUMERIC(5,2),
  height NUMERIC(5,2),
  bmi NUMERIC(4,2),
  notes TEXT,
  recorded_at TIMESTAMPTZ DEFAULT NOW()
);

-- Pharmacy prescriptions
CREATE TABLE pharmacy_orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  prescription_id UUID REFERENCES prescriptions(id),
  pharmacy_id UUID, -- External pharmacy or in-hospital
  status TEXT DEFAULT 'pending', -- pending, preparing, ready, dispensed
  prepared_by UUID REFERENCES profiles(id),
  dispensed_at TIMESTAMPTZ,
  payment_status TEXT DEFAULT 'unpaid',
  payment_amount NUMERIC(10,2),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Lab test orders
CREATE TABLE lab_orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  appointment_id UUID REFERENCES appointments(id),
  ordered_by UUID REFERENCES doctors(id),
  test_type TEXT, -- blood_test, urine_test, xray, mri, ct_scan
  test_name TEXT,
  priority TEXT DEFAULT 'routine', -- routine, urgent, stat
  status TEXT DEFAULT 'ordered', -- ordered, sample_collected, processing, completed
  result_url TEXT, -- Supabase Storage URL
  result_data JSONB, -- Structured test results
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Patient feedback & reviews (Enhanced)
CREATE TABLE patient_feedback (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id UUID REFERENCES profiles(id),
  appointment_id UUID REFERENCES appointments(id),
  doctor_id UUID REFERENCES doctors(id),
  overall_rating SMALLINT CHECK (overall_rating BETWEEN 1 AND 5),
  wait_time_rating SMALLINT,
  doctor_rating SMALLINT,
  facility_rating SMALLINT,
  comment TEXT,
  tags TEXT[], -- ['punctual', 'friendly', 'thorough']
  would_recommend BOOLEAN,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```


```sql
-- Real-time notifications (Enhanced)
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id),
  type TEXT NOT NULL, -- queue_update, appointment_reminder, message, prescription_ready
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data JSONB, -- Extra metadata
  channels TEXT[], -- ['push', 'sms', 'email', 'in_app']
  read BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMPTZ,
  sent_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  INDEX idx_user_unread (user_id, read) WHERE read = FALSE
);

-- System announcements
CREATE TABLE announcements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT DEFAULT 'info', -- info, warning, emergency
  target_audience TEXT[], -- ['patients', 'doctors', 'staff', 'all']
  start_time TIMESTAMPTZ DEFAULT NOW(),
  end_time TIMESTAMPTZ,
  active BOOLEAN DEFAULT TRUE,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Appointment reminders (Scheduled)
CREATE TABLE appointment_reminders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  appointment_id UUID REFERENCES appointments(id) ON DELETE CASCADE,
  reminder_type TEXT, -- 24_hours, 2_hours, 30_minutes, 15_minutes
  scheduled_time TIMESTAMPTZ,
  sent BOOLEAN DEFAULT FALSE,
  sent_at TIMESTAMPTZ,
  channel TEXT, -- sms, email, push
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### Database Functions & Triggers (V2)

```sql
-- Auto-update queue positions when appointment status changes
CREATE OR REPLACE FUNCTION update_queue_positions()
RETURNS TRIGGER AS $$
BEGIN
  -- Recalculate positions for all waiting appointments
  WITH ranked AS (
    SELECT id, ROW_NUMBER() OVER (
      PARTITION BY doctor_id, DATE(appointment_date) 
      ORDER BY appointment_time
    ) as new_position
    FROM appointments
    WHERE status IN ('pending', 'confirmed') 
    AND doctor_id = NEW.doctor_id
    AND DATE(appointment_date) = DATE(NEW.appointment_date)
  )
  UPDATE queue_positions qp
  SET position = r.new_position,
      estimated_time = NEW.appointment_date + (r.new_position * INTERVAL '15 minutes')
  FROM ranked r
  WHERE qp.appointment_id = r.id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```


```sql
-- Predict wait time based on historical data
CREATE OR REPLACE FUNCTION predict_wait_time(
  p_doctor_id UUID,
  p_date DATE,
  p_hour INT
) RETURNS INT AS $$
DECLARE
  avg_wait INT;
BEGIN
  SELECT AVG(actual_wait_minutes)::INT INTO avg_wait
  FROM wait_time_predictions
  WHERE doctor_id = p_doctor_id
    AND EXTRACT(HOUR FROM date) = p_hour
    AND date >= p_date - INTERVAL '30 days'
  LIMIT 10;
  
  RETURN COALESCE(avg_wait, 15); -- Default 15 minutes
END;
$$ LANGUAGE plpgsql;

-- Send notification trigger
CREATE OR REPLACE FUNCTION send_notification_trigger()
RETURNS TRIGGER AS $$
BEGIN
  -- Call Edge Function to send notification
  PERFORM http_post(
    'https://your-project.supabase.co/functions/v1/send-notification',
    jsonb_build_object(
      'user_id', NEW.user_id,
      'type', NEW.type,
      'title', NEW.title,
      'body', NEW.body,
      'channels', NEW.channels
    )
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_notification_insert
  AFTER INSERT ON notifications
  FOR EACH ROW
  EXECUTE FUNCTION send_notification_trigger();
```

### 4.5 Security (Enterprise-Grade)

**Authentication**:
- Email + Password with bcrypt hashing
- OAuth providers (Google, Apple, Microsoft)
- **Multi-Factor Authentication (TOTP - RFC 6238)**
  - Time-based One-Time Password using authenticator apps
  - 6-digit codes rotating every 30 seconds
  - Backup codes for account recovery
  - Device fingerprinting for trusted devices
  - Rate limiting: Max 5 attempts per 15 minutes
  - Full audit trail of 2FA events
  - HIPAA/PCI DSS compliant
- SMS-based OTP (fallback option)
- Biometric login (WebAuthn) for mobile devices
- Session management (JWT with refresh tokens)

**TOTP Implementation Highlights**:
- **Setup**: QR code generation for authenticator apps (Google Authenticator, Authy, Microsoft Authenticator)
- **Storage**: Encrypted secrets using AES-256 with per-user salt
- **Validation**: Server-side verification via Supabase Edge Functions
- **Recovery**: 10 single-use backup codes, email verification flow
- **Compliance**: Meets HIPAA requirements for PHI access control

**Authorization (RLS)**:
```sql
-- Example: Patients can only see their own appointments
CREATE POLICY patient_appointments ON appointments
  FOR SELECT
  USING (patient_id = auth.uid());

-- Doctors can see appointments assigned to them
CREATE POLICY doctor_appointments ON appointments
  FOR ALL
  USING (doctor_id IN (
    SELECT id FROM doctors WHERE user_id = auth.uid()
  ));
```

**Data Protection**:
- Encryption at rest (AES-256)
- TLS 1.3 for all connections
- PII masking in logs
- GDPR right-to-erasure support
- Data retention policies

---

## 📊 Performance Targets (V2)

| Metric | V1 Target | V2 Target | How to Achieve |
|--------|-----------|-----------|----------------|
| First Contentful Paint | < 1.2s | < 0.9s | Code splitting, lazy loading |
| Time to Interactive | < 2.5s | < 1.8s | Reduce JS bundle, defer non-critical |
| Largest Contentful Paint | - | < 2.0s | Image optimization, CDN |
| API Response Time (P95) | < 300ms | < 200ms | Query optimization, caching |
| WebSocket Latency | - | < 300ms | Edge deployment, Redis |
| Lighthouse Score | > 90 | > 95 | All optimizations |
| Bundle Size | - | < 150KB (gzipped) | Tree-shaking, minification |
| Real-time Update Delay | < 500ms | < 200ms | Optimistic UI updates |

---

## 🎯 Success Metrics (KPIs) - V2

### Product Adoption
| Metric | 3 Months | 6 Months | 12 Months |
|--------|----------|----------|-----------|
| Total Registered Users | 2,000 | 5,000 | 15,000 |
| Daily Active Users (DAU) | 500 | 1,200 | 4,000 |
| Monthly Active Users (MAU) | 1,500 | 3,500 | 12,000 |
| DAU/MAU Ratio | 33% | 34% | 33% |

### Engagement
| Metric | Target |
|--------|--------|
| Appointments booked online | 85% (up from 70%) |
| Avg sessions per user/month | 4 |
| Avg session duration | 5 minutes |
| Feature adoption (video call) | 30% of consultations |

### Operational Efficiency
| Metric | Current | Target | Improvement |
|--------|---------|--------|-------------|
| Average wait time | 45 min | 18 min | 60% reduction |
| Doctor idle time | 15% | 5% | 10% improvement |
| No-show rate | 20% | 8% | 12% reduction |
| Patient satisfaction | 3.8/5 | 4.6/5 | 21% increase |

### Business Metrics
| Metric | Monthly Target |
|--------|---------------|
| Revenue per user | ₹500 |
| Appointment completion rate | 92% |
| Upsell rate (telemedicine) | 15% |
| Customer acquisition cost | < ₹100 |
| Lifetime value (LTV) | > ₹5,000 |


---

## 🗺️ Development Roadmap

### Phase 1: Foundation + Real-Time (Weeks 1-4)
**Status**: 🟢 In Progress

**Objectives**:
- Complete booking system with real-time features
- Queue management with live updates
- Enhanced doctor dashboard
- Admin analytics v1

**Deliverables**:
- [x] Smart appointment booking (4-step wizard)
- [x] Department & doctor mock data (8 depts, 10+ doctors)
- [x] Time slot availability system
- [x] Token generation
- [x] Glassmorphic UI with animations
- [ ] Real-time queue tracking (WebSocket integration)
- [ ] Push notifications setup
- [ ] Basic analytics dashboard

**Technical Debt**:
- Migrate from localStorage to Supabase
- Implement RLS policies
- Set up Edge Functions

---

### Phase 2: Intelligence + Communication (Weeks 5-8)
**Status**: 🟡 Planned

**Objectives**:
- AI-powered features
- Telemedicine integration
- Advanced analytics
- Payment gateway

**Deliverables**:
- [ ] AI symptom checker (OpenAI integration)
- [ ] Smart doctor recommendations
- [ ] Predictive wait time algorithm
- [ ] Video consultation (WebRTC)
- [ ] In-app messaging
- [ ] Payment gateway (Stripe/Razorpay)
- [ ] Email/SMS notifications (Twilio)
- [ ] Advanced reporting with exports

**Dependencies**:
- OpenAI API access
- Payment gateway merchant account
- Twilio/SendGrid accounts


---

### Phase 3: Mobile + Integrations (Weeks 9-14)
**Status**: 🔴 Future

**Objectives**:
- Native mobile experience
- Third-party integrations
- Pharmacy & lab modules
- Billing system

**Deliverables**:
- [ ] Progressive Web App (PWA) with offline mode
- [ ] React Native mobile app (iOS + Android)
- [ ] Pharmacy integration
- [ ] Lab test ordering & results
- [ ] Billing & invoicing module
- [ ] Insurance claim integration
- [ ] Wearable device sync (Apple Health, Google Fit)

**Team Requirements**:
- 2 React Native developers
- 1 Integration specialist
- 1 QA engineer

---

### Phase 4: Scale + Enterprise (Weeks 15-20)
**Status**: 🔴 Future

**Objectives**:
- Multi-hospital support
- White-label platform
- Enterprise features
- Compliance certifications

**Deliverables**:
- [ ] Multi-tenancy architecture
- [ ] White-label customization
- [ ] Partner API with documentation
- [ ] Advanced security (SOC 2, HIPAA)
- [ ] Role-based access control (RBAC) v2
- [ ] Hospital network management
- [ ] Franchise management module

---

## 🚫 Out of Scope (V2)

**Explicitly NOT included**:
- ❌ Hospital inventory management (beds, equipment)
- ❌ Surgical scheduling
- ❌ Blood bank management
- ❌ Ambulance tracking
- ❌ Mortuary management
- ❌ Accounting & payroll
- ❌ HR management
- ❌ Food service management

These may be considered for V3 or as separate modules.


---

## 🔧 Technical Implementation Details

### 5.1 Real-Time Queue System

#### Architecture
```javascript
// Client-side (booking.js)
import { io } from 'socket.io-client';

class QueueManager {
  constructor(appointmentId) {
    this.socket = io('wss://your-server.com');
    this.appointmentId = appointmentId;
    this.init();
  }
  
  init() {
    // Subscribe to personal queue updates
    this.socket.emit('subscribe', `queue:${this.appointmentId}`);
    
    // Listen for position updates
    this.socket.on('queue:update', (data) => {
      this.updateUI(data);
      this.showNotification(data);
    });
    
    // Handle connection issues
    this.socket.on('disconnect', () => {
      this.showOfflineMessage();
    });
  }
  
  updateUI(data) {
    document.getElementById('queue-position').textContent = data.position;
    document.getElementById('eta').textContent = this.formatETA(data.estimatedTime);
    this.updateProgressBar(data.position, data.totalPatients);
  }
  
  showNotification(data) {
    if (data.position <= 3) {
      new Notification('Your turn is approaching!', {
        body: `You are #${data.position} in queue. ETA: ${data.estimatedTime}`,
        icon: '/logo.png',
        badge: '/badge.png'
      });
    }
  }
}
```

#### Server-side (Edge Function)
```javascript
// Supabase Edge Function: queue-manager
import { createClient } from '@supabase/supabase-js';
import { Server } from 'socket.io';

const io = new Server({
  cors: { origin: '*' }
});

// Listen to Postgres changes
const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

supabase
  .channel('appointments')
  .on('postgres_changes', 
    { event: 'UPDATE', schema: 'public', table: 'appointments' },
    async (payload) => {
      // Recalculate queue positions
      const queue = await getUpdatedQueue(payload.new.doctor_id);
      
      // Broadcast to affected patients
      queue.forEach(appointment => {
        io.to(`queue:${appointment.id}`).emit('queue:update', {
          position: appointment.position,
          estimatedTime: appointment.estimated_time,
          totalPatients: queue.length
        });
      });
    }
  )
  .subscribe();
```


### 5.2 AI Symptom Checker

#### Implementation
```javascript
// ai-symptom-checker.js
class SymptomChecker {
  constructor() {
    this.symptoms = [];
  }
  
  async analyzeSymptoms(symptoms) {
    // Call Edge Function that proxies to OpenAI
    const response = await fetch('/functions/v1/ai-symptom-checker', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ symptoms })
    });
    
    const analysis = await response.json();
    return {
      suggestedDepartments: analysis.departments, // ['Cardiology', 'General Medicine']
      urgencyLevel: analysis.urgency, // 'routine', 'urgent', 'emergency'
      reasoning: analysis.reasoning,
      disclaimer: 'This is not a medical diagnosis. Please consult a doctor.'
    };
  }
  
  renderRecommendations(analysis) {
    const container = document.getElementById('recommendations');
    
    container.innerHTML = `
      <div class="card p-6 mb-6 border-l-4 border-${this.getUrgencyColor(analysis.urgencyLevel)}">
        <div class="flex items-start gap-4">
          <div class="text-4xl">${this.getUrgencyIcon(analysis.urgencyLevel)}</div>
          <div class="flex-1">
            <h3 class="font-display text-xl font-bold mb-2">
              ${this.getUrgencyTitle(analysis.urgencyLevel)}
            </h3>
            <p class="text-slate-600 mb-4">${analysis.reasoning}</p>
            
            <div class="space-y-2">
              <p class="font-semibold text-navy-900">Recommended Departments:</p>
              <div class="flex flex-wrap gap-2">
                ${analysis.suggestedDepartments.map(dept => `
                  <button 
                    class="badge badge-lg bg-teal-100 text-teal-700 hover:bg-teal-200 cursor-pointer"
                    onclick="selectDepartment('${dept}')"
                  >
                    ${dept}
                  </button>
                `).join('')}
              </div>
            </div>
          </div>
        </div>
        <div class="mt-4 p-3 bg-amber-50 rounded-lg text-sm text-amber-800">
          ⚠️ ${analysis.disclaimer}
        </div>
      </div>
    `;
  }
  
  getUrgencyColor(level) {
    const colors = {
      routine: 'green-500',
      urgent: 'amber-500',
      emergency: 'coral-500'
    };
    return colors[level] || 'slate-500';
  }
}
```


### 5.3 Predictive Wait Time Algorithm

#### Machine Learning Model
```python
# Edge Function: predict-wait-time.py
import numpy as np
from sklearn.ensemble import RandomForestRegressor
import joblib

# Model trained on historical data
# Features: doctor_id, day_of_week, hour, current_queue_length, avg_consultation_time
model = joblib.load('wait_time_model.pkl')

def predict_wait_time(doctor_id, date, time, current_queue):
    features = extract_features(doctor_id, date, time, current_queue)
    predicted_minutes = model.predict([features])[0]
    
    # Adjust for real-time factors
    adjusted = adjust_for_realtime(predicted_minutes, current_queue)
    
    return {
        'predicted_wait_minutes': int(adjusted),
        'confidence': 0.92,  # Model confidence score
        'factors': {
            'queue_length': current_queue,
            'doctor_pace': get_doctor_pace(doctor_id),
            'time_of_day': time
        }
    }

def extract_features(doctor_id, date, time, queue):
    return [
        doctor_id_to_numeric(doctor_id),
        date.weekday(),  # 0=Monday, 6=Sunday
        time.hour,
        len(queue),
        get_avg_consultation_time(doctor_id),
        is_holiday(date),
        get_current_delay(doctor_id)
    ]
```

#### Client-side Display
```javascript
// Display predicted wait time
async function showWaitTimePrediction(doctorId, selectedDate, selectedTime) {
  const response = await fetch('/functions/v1/predict-wait-time', {
    method: 'POST',
    body: JSON.stringify({ doctorId, date: selectedDate, time: selectedTime })
  });
  
  const prediction = await response.json();
  
  document.getElementById('wait-time-info').innerHTML = `
    <div class="flex items-center gap-3 p-4 bg-blue-50 rounded-lg">
      <svg class="w-6 h-6 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
          d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
      <div>
        <p class="font-semibold text-navy-900">Estimated Wait Time</p>
        <p class="text-2xl font-bold text-teal-600">${prediction.predicted_wait_minutes} minutes</p>
        <p class="text-xs text-slate-600">${prediction.confidence * 100}% prediction accuracy</p>
      </div>
    </div>
  `;
}
```


### 5.4 Push Notifications System

#### Service Worker Setup
```javascript
// service-worker.js
self.addEventListener('push', event => {
  const data = event.data.json();
  
  const options = {
    body: data.body,
    icon: '/icons/icon-192x192.png',
    badge: '/icons/badge-72x72.png',
    vibrate: [200, 100, 200],
    tag: data.tag || 'notification',
    requireInteraction: data.urgent || false,
    actions: [
      { action: 'view', title: 'View', icon: '/icons/view.png' },
      { action: 'dismiss', title: 'Dismiss', icon: '/icons/dismiss.png' }
    ],
    data: {
      url: data.url || '/',
      appointmentId: data.appointmentId
    }
  };
  
  event.waitUntil(
    self.registration.showNotification(data.title, options)
  );
});

self.addEventListener('notificationclick', event => {
  event.notification.close();
  
  if (event.action === 'view') {
    event.waitUntil(
      clients.openWindow(event.notification.data.url)
    );
  }
});
```

#### Notification Manager
```javascript
// notifications.js
class NotificationManager {
  async requestPermission() {
    if ('Notification' in window && 'serviceWorker' in navigator) {
      const permission = await Notification.requestPermission();
      
      if (permission === 'granted') {
        await this.subscribeToPush();
      }
      
      return permission;
    }
    return 'denied';
  }
  
  async subscribeToPush() {
    const registration = await navigator.serviceWorker.ready;
    
    const subscription = await registration.pushManager.subscribe({
      userVisibleOnly: true,
      applicationServerKey: this.urlBase64ToUint8Array(VAPID_PUBLIC_KEY)
    });
    
    // Send subscription to server
    await fetch('/api/push-subscribe', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(subscription)
    });
  }
  
  async sendNotification(userId, notification) {
    // Server-side: Send via FCM or native Push API
    await fetch('/functions/v1/send-notification', {
      method: 'POST',
      body: JSON.stringify({
        userId,
        title: notification.title,
        body: notification.body,
        urgent: notification.urgent,
        url: notification.url
      })
    });
  }
}
```


### 5.5 Video Consultation (WebRTC)

#### Video Call Component
```javascript
// VideoCall.js
import SimplePeer from 'simple-peer';

class VideoCallManager {
  constructor(roomId, isInitiator) {
    this.roomId = roomId;
    this.isInitiator = isInitiator;
    this.peer = null;
    this.localStream = null;
    this.remoteStream = null;
  }
  
  async startCall() {
    // Get user media
    this.localStream = await navigator.mediaDevices.getUserMedia({
      video: { width: 1280, height: 720 },
      audio: true
    });
    
    // Display local video
    document.getElementById('local-video').srcObject = this.localStream;
    
    // Initialize peer connection
    this.peer = new SimplePeer({
      initiator: this.isInitiator,
      stream: this.localStream,
      trickle: false
    });
    
    // Handle signaling
    this.peer.on('signal', data => {
      // Send signal to other peer via Socket.io
      this.socket.emit('webrtc-signal', {
        roomId: this.roomId,
        signal: data
      });
    });
    
    // Handle remote stream
    this.peer.on('stream', stream => {
      this.remoteStream = stream;
      document.getElementById('remote-video').srcObject = stream;
    });
    
    // Listen for remote signal
    this.socket.on('webrtc-signal', data => {
      this.peer.signal(data.signal);
    });
  }
  
  endCall() {
    this.peer?.destroy();
    this.localStream?.getTracks().forEach(track => track.stop());
    this.remoteStream?.getTracks().forEach(track => track.stop());
    
    // Update session end time in database
    this.updateSessionEndTime();
  }
  
  toggleVideo() {
    const videoTrack = this.localStream.getVideoTracks()[0];
    videoTrack.enabled = !videoTrack.enabled;
    return videoTrack.enabled;
  }
  
  toggleAudio() {
    const audioTrack = this.localStream.getAudioTracks()[0];
    audioTrack.enabled = !audioTrack.enabled;
    return audioTrack.enabled;
  }
}
```


---

## 📱 Mobile & Progressive Web App

### 6.1 PWA Features

#### Manifest.json
```json
{
  "name": "MediQueue - Hospital Management",
  "short_name": "MediQueue",
  "description": "Smart hospital management with real-time queue tracking",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#F8FAFC",
  "theme_color": "#0E9384",
  "orientation": "portrait",
  "icons": [
    {
      "src": "/icons/icon-72x72.png",
      "sizes": "72x72",
      "type": "image/png"
    },
    {
      "src": "/icons/icon-192x192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "any maskable"
    },
    {
      "src": "/icons/icon-512x512.png",
      "sizes": "512x512",
      "type": "image/png"
    }
  ],
  "shortcuts": [
    {
      "name": "Book Appointment",
      "url": "/pages/book-appointment.html",
      "icons": [{ "src": "/icons/book.png", "sizes": "96x96" }]
    },
    {
      "name": "My Queue",
      "url": "/pages/queue-status.html",
      "icons": [{ "src": "/icons/queue.png", "sizes": "96x96" }]
    }
  ]
}
```

#### Offline Support
```javascript
// service-worker.js - Caching Strategy
const CACHE_VERSION = 'v2.0.0';
const CACHE_ASSETS = [
  '/',
  '/css/output.css',
  '/js/app.js',
  '/pages/dashboard-patient.html',
  '/icons/icon-192x192.png'
];

// Install event - cache assets
self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_VERSION).then(cache => {
      return cache.addAll(CACHE_ASSETS);
    })
  );
});

// Fetch event - Network first, fallback to cache
self.addEventListener('fetch', event => {
  event.respondWith(
    fetch(event.request)
      .then(response => {
        // Clone and cache successful responses
        const responseClone = response.clone();
        caches.open(CACHE_VERSION).then(cache => {
          cache.put(event.request, responseClone);
        });
        return response;
      })
      .catch(() => {
        // Network failed, try cache
        return caches.match(event.request);
      })
  );
});
```


### 6.2 Mobile-Specific Features

#### Bottom Navigation
```javascript
// mobile-nav.js
function initMobileNav() {
  const nav = document.getElementById('mobile-nav');
  
  nav.innerHTML = `
    <nav class="fixed bottom-0 left-0 right-0 bg-white border-t border-slate-200 z-50 md:hidden">
      <div class="flex items-center justify-around h-16">
        <a href="/pages/dashboard-patient.html" class="nav-item ${isActive('dashboard') ? 'active' : ''}">
          <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
              d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
          </svg>
          <span class="text-xs mt-1">Home</span>
        </a>
        
        <a href="/pages/book-appointment.html" class="nav-item ${isActive('book') ? 'active' : ''}">
          <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
              d="M12 4v16m8-8H4" />
          </svg>
          <span class="text-xs mt-1">Book</span>
        </a>
        
        <a href="/pages/queue-status.html" class="nav-item ${isActive('queue') ? 'active' : ''}">
          <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
              d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <span class="text-xs mt-1">Queue</span>
        </a>
        
        <a href="/pages/medical-records.html" class="nav-item ${isActive('records') ? 'active' : ''}">
          <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
              d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
          </svg>
          <span class="text-xs mt-1">Records</span>
        </a>
        
        <a href="/pages/profile.html" class="nav-item ${isActive('profile') ? 'active' : ''}">
          <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
              d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
          </svg>
          <span class="text-xs mt-1">Profile</span>
        </a>
      </div>
    </nav>
  `;
}
```

#### Gesture Support
```javascript
// gesture-handler.js
class GestureHandler {
  constructor(element) {
    this.element = element;
    this.startX = 0;
    this.startY = 0;
    this.threshold = 100; // pixels
    
    this.init();
  }
  
  init() {
    this.element.addEventListener('touchstart', e => {
      this.startX = e.touches[0].clientX;
      this.startY = e.touches[0].clientY;
    });
    
    this.element.addEventListener('touchend', e => {
      const endX = e.changedTouches[0].clientX;
      const endY = e.changedTouches[0].clientY;
      
      const deltaX = endX - this.startX;
      const deltaY = endY - this.startY;
      
      if (Math.abs(deltaX) > this.threshold && Math.abs(deltaY) < 50) {
        if (deltaX > 0) {
          this.onSwipeRight();
        } else {
          this.onSwipeLeft();
        }
      }
      
      if (deltaY < -this.threshold) {
        this.onSwipeUp();
      } else if (deltaY > this.threshold) {
        this.onSwipeDown();
      }
    });
  }
  
  onSwipeRight() { /* Navigate back */ }
  onSwipeLeft() { /* Navigate forward */ }
  onSwipeUp() { /* Show more details */ }
  onSwipeDown() { /* Refresh */ }
}
```


---

## 🧪 Testing Strategy

### 7.1 Testing Pyramid

```
                     🔺 Manual Testing (10%)
                   /     \
                  /  E2E  \  (20%)
                 /---------\
                / Integration\ (30%)
               /-------------\
              /  Unit Tests   \ (40%)
             /-----------------\
```

### 7.2 Unit Testing
**Framework**: Jest + Testing Library

**Coverage Target**: 80%+

```javascript
// Example: formatters.test.js
import { formatCurrency, formatTime, formatDate } from '../utils/formatters';

describe('formatCurrency', () => {
  test('formats Indian rupees correctly', () => {
    expect(formatCurrency(500)).toBe('₹500.00');
    expect(formatCurrency(1250.5)).toBe('₹1,250.50');
  });
  
  test('handles zero and negative values', () => {
    expect(formatCurrency(0)).toBe('₹0.00');
    expect(formatCurrency(-100)).toBe('₹-100.00');
  });
});

describe('formatTime', () => {
  test('converts 24h to 12h format', () => {
    expect(formatTime('09:00')).toBe('09:00 AM');
    expect(formatTime('14:30')).toBe('02:30 PM');
    expect(formatTime('00:00')).toBe('12:00 AM');
  });
});
```

### 7.3 Integration Testing
**Framework**: Cypress

```javascript
// Example: booking-flow.spec.js
describe('Appointment Booking Flow', () => {
  beforeEach(() => {
    cy.visit('/pages/book-appointment.html');
    cy.login('patient@example.com', 'password');
  });
  
  it('should complete full booking flow', () => {
    // Step 1: Select department
    cy.contains('Cardiology').click();
    cy.url().should('include', 'step=2');
    
    // Step 2: Select doctor
    cy.contains('Dr. Anjali Rao').click();
    cy.url().should('include', 'step=3');
    
    // Step 3: Select date and time
    cy.get('#appointment-date').type('2026-07-20');
    cy.contains('09:00 AM').click();
    cy.contains('Continue to Confirmation').click();
    
    // Step 4: Fill form and confirm
    cy.get('#reason').type('Regular checkup for chest pain');
    cy.contains('Confirm Booking').click();
    
    // Verify success
    cy.contains('Booking Confirmed!').should('be.visible');
    cy.get('#final-token').should('match', /^[A-Z]-\d{3}$/);
  });
  
  it('should show error for unavailable slots', () => {
    cy.selectDepartment('Neurology');
    cy.contains('This department is currently unavailable').should('be.visible');
  });
});
```


### 7.4 E2E Testing
**Tools**: Playwright (cross-browser)

```javascript
// e2e/real-time-queue.spec.js
import { test, expect } from '@playwright/test';

test('real-time queue updates', async ({ browser }) => {
  // Open two contexts: patient and doctor
  const patientContext = await browser.newContext();
  const doctorContext = await browser.newContext();
  
  const patientPage = await patientContext.newPage();
  const doctorPage = await doctorContext.newPage();
  
  // Patient books appointment
  await patientPage.goto('/pages/book-appointment.html');
  await patientPage.fill('#reason', 'Test consultation');
  await patientPage.click('button:has-text("Confirm Booking")');
  
  const token = await patientPage.locator('#final-token').textContent();
  
  // Patient sees queue position
  await patientPage.goto('/pages/queue-status.html');
  await expect(patientPage.locator('#queue-position')).toContainText('3');
  
  // Doctor completes a consultation
  await doctorPage.goto('/pages/dashboard-doctor.html');
  await doctorPage.click('button:has-text("Complete")');
  
  // Patient's position updates in real-time
  await expect(patientPage.locator('#queue-position')).toContainText('2', {
    timeout: 5000
  });
});
```

### 7.5 Performance Testing
**Tools**: Lighthouse CI, WebPageTest

**Metrics to Track**:
- Page load time (< 2s)
- First Contentful Paint (< 1s)
- Time to Interactive (< 2s)
- WebSocket connection time (< 500ms)
- API response time (< 300ms P95)

### 7.6 Security Testing
**Tools**: OWASP ZAP, Snyk

**Checks**:
- SQL injection prevention
- XSS vulnerability scanning
- CSRF token validation
- RLS policy effectiveness
- Dependency vulnerability scanning

---

## 📊 Analytics & Monitoring

### 8.1 Product Analytics
**Tool**: PostHog (self-hosted)

**Events to Track**:
```javascript
// User actions
posthog.capture('appointment_booked', {
  department: 'Cardiology',
  doctor_id: 'doc-1',
  slot_time: '09:00',
  booking_time_seconds: 45
});

posthog.capture('queue_position_viewed', {
  position: 3,
  estimated_wait: 25
});

posthog.capture('notification_received', {
  type: 'queue_update',
  position: 2
});
```

**Funnels to Monitor**:
1. Booking Funnel: Landing → Department → Doctor → Date → Confirmation
2. Engagement Funnel: Login → View Queue → Check Records → Book Again
3. Conversion Funnel: Visitor → Signup → First Booking → Repeat Booking


### 8.2 Error Tracking
**Tool**: Sentry

```javascript
// Initialize Sentry
import * as Sentry from '@sentry/browser';

Sentry.init({
  dsn: 'https://your-dsn@sentry.io/project',
  environment: 'production',
  release: 'mediqueue@2.0.0',
  integrations: [
    new Sentry.BrowserTracing(),
    new Sentry.Replay()
  ],
  tracesSampleRate: 0.2,
  replaysSessionSampleRate: 0.1,
  replaysOnErrorSampleRate: 1.0
});

// Capture custom errors
try {
  await bookAppointment(data);
} catch (error) {
  Sentry.captureException(error, {
    tags: {
      feature: 'booking',
      department: data.departmentId
    },
    user: {
      id: currentUser.id,
      email: currentUser.email
    }
  });
}
```

### 8.3 Infrastructure Monitoring
**Tool**: Grafana + Prometheus

**Dashboards**:
1. **Application Health**
   - Request rate (req/s)
   - Error rate (%)
   - P50, P95, P99 latencies
   - Active WebSocket connections

2. **Database Performance**
   - Query execution time
   - Connection pool usage
   - Cache hit rate
   - Slow query alerts

3. **Business Metrics**
   - Appointments per hour
   - Revenue per day
   - Active users
   - Queue wait times

---

## 🚀 Deployment Strategy

### 9.1 Hosting Architecture
```
┌─────────────────────────────────────────────┐
│           Cloudflare CDN (Edge)             │
│  - Static assets (CSS, JS, images)         │
│  - DDoS protection                          │
│  - SSL/TLS termination                      │
└──────────────┬──────────────────────────────┘
               │
┌──────────────▼──────────────────────────────┐
│         Vercel (Frontend)                   │
│  - HTML pages                               │
│  - Next.js (optional future migration)     │
│  - Edge Functions (geo-distributed)        │
└──────────────┬──────────────────────────────┘
               │
┌──────────────▼──────────────────────────────┐
│       Supabase (Backend + Database)         │
│  - PostgreSQL 15                            │
│  - Realtime WebSocket server                │
│  - Storage (S3-compatible)                  │
│  - Edge Functions (Deno)                    │
└──────────────┬──────────────────────────────┘
               │
┌──────────────▼──────────────────────────────┐
│         External Services                   │
│  - OpenAI API (AI features)                 │
│  - Twilio (SMS)                             │
│  - SendGrid (Email)                         │
│  - Stripe/Razorpay (Payments)               │
└─────────────────────────────────────────────┘
```


### 9.2 CI/CD Pipeline
**Tool**: GitHub Actions

```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run unit tests
        run: npm run test:unit
      
      - name: Run linting
        run: npm run lint
      
      - name: Build CSS
        run: npm run build:css
      
      - name: Run Lighthouse CI
        run: npm run lighthouse:ci

  deploy:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Deploy to Vercel
        uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.ORG_ID }}
          vercel-project-id: ${{ secrets.PROJECT_ID }}
          vercel-args: '--prod'
      
      - name: Run E2E tests
        run: npm run test:e2e
      
      - name: Notify deployment
        uses: 8398a7/action-slack@v3
        with:
          status: ${{ job.status }}
          text: 'Deployment to production completed'
          webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

### 9.3 Environment Management
```bash
# .env.production
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
OPENAI_API_KEY=sk-proj-...
STRIPE_PUBLIC_KEY=pk_live_...
TWILIO_ACCOUNT_SID=AC...
SENTRY_DSN=https://...@sentry.io/...
POSTHOG_API_KEY=phc_...
```

### 9.4 Rollback Strategy
1. **Instant Rollback**: Vercel allows one-click rollback to previous deployment
2. **Database Migrations**: Use Supabase migrations with versioning
3. **Feature Flags**: Use PostHog feature flags to disable broken features
4. **Blue-Green Deployment**: Deploy to staging, test, then switch traffic

---

## 📋 Launch Checklist

### Pre-Launch (2 weeks before)
- [ ] All Phase 1 features complete and tested
- [ ] Security audit passed
- [ ] Performance benchmarks met
- [ ] Load testing completed (1000 concurrent users)
- [ ] Backup and recovery procedures documented
- [ ] Support team trained
- [ ] Marketing materials prepared
- [ ] Legal terms & privacy policy reviewed

### Launch Week
- [ ] Beta testing with 50 users
- [ ] Monitor error rates closely
- [ ] Customer support on standby
- [ ] Social media announcement ready
- [ ] Press release prepared

### Post-Launch (First month)
- [ ] Daily monitoring of KPIs
- [ ] Weekly user feedback review
- [ ] Bug triage and fixes
- [ ] Performance optimization
- [ ] User onboarding improvements


---

## ❓ Open Questions & Decisions Needed

### Technical Decisions
1. **Real-Time Infrastructure**
   - Q: Should we use Supabase Realtime or build custom WebSocket server?
   - A: Start with Supabase Realtime, scale to custom if needed
   - Owner: Tech Lead
   - Deadline: Phase 1

2. **AI Model Hosting**
   - Q: Self-host ML models or use OpenAI API?
   - A: OpenAI API for Phase 1 (faster), evaluate self-hosting in Phase 2
   - Owner: ML Engineer
   - Deadline: Phase 2

3. **Video Infrastructure**
   - Q: Use Twilio Video or self-hosted WebRTC?
   - A: TBD - Cost analysis needed
   - Owner: Product Manager
   - Deadline: Phase 2

### Business Decisions
4. **Pricing Model**
   - Q: Charge patients per booking or subscription?
   - Options:
     - A) Free for patients, charge hospitals (B2B)
     - B) Freemium: Free basic, paid for telemedicine
     - C) Per-booking fee (₹20-50)
   - Owner: CEO
   - Deadline: Before launch

5. **Payment Gateway**
   - Q: Stripe vs Razorpay vs both?
   - A: Both - Razorpay for Indian market, Stripe for international
   - Owner: Finance Team
   - Deadline: Phase 2

6. **Data Residency**
   - Q: Where to host data for GDPR/HIPAA compliance?
   - A: EU region for European hospitals, Mumbai for Indian hospitals
   - Owner: Legal + Tech Lead
   - Deadline: Before enterprise sales

### Product Decisions
7. **Multi-Language Support**
   - Q: Launch with English only or add Hindi/regional languages?
   - A: English for Phase 1, add Hindi in Phase 1.5
   - Owner: Product Manager
   - Deadline: Phase 1

8. **Doctor Ratings**
   - Q: Public ratings or private feedback only?
   - A: Public ratings with moderation (prevent abuse)
   - Owner: Product Manager
   - Deadline: Phase 1

---

## 🔒 Compliance & Legal

### HIPAA Compliance (US Healthcare)
- [ ] Encryption at rest and in transit
- [ ] Access controls and audit logs
- [ ] Business Associate Agreements (BAA)
- [ ] Regular risk assessments
- [ ] Breach notification procedures

### GDPR Compliance (European Union)
- [ ] User consent for data collection
- [ ] Right to access data
- [ ] Right to erasure ("Right to be forgotten")
- [ ] Data portability
- [ ] Privacy policy clearly displayed

### Indian Healthcare Standards
- [ ] Digital Information Security in Healthcare Act (DISHA)
- [ ] Telemedicine Practice Guidelines (India, 2020)
- [ ] Electronic Health Records Standards

### Terms & Policies
- [ ] Terms of Service
- [ ] Privacy Policy
- [ ] Cookie Policy
- [ ] Acceptable Use Policy
- [ ] Doctor Code of Conduct


---

## 📚 Documentation Requirements

### User Documentation
1. **Patient Guide**
   - How to book an appointment
   - How to track your queue position
   - How to access medical records
   - How to use telemedicine features

2. **Doctor Guide**
   - Dashboard overview
   - Managing daily queue
   - Writing prescriptions
   - Using voice-to-text notes

3. **Admin Guide**
   - Setting up departments and doctors
   - Generating reports
   - Managing staff
   - System configuration

### Developer Documentation
1. **API Documentation**
   - Supabase REST API endpoints
   - Authentication & authorization
   - Rate limits
   - Error codes

2. **Integration Guide**
   - WebSocket events
   - Webhook setup
   - Third-party API integrations

3. **Deployment Guide**
   - Environment setup
   - CI/CD configuration
   - Database migrations
   - Rollback procedures

---

## 🎓 Training & Onboarding

### Hospital Staff Training
**Duration**: 2 days

**Day 1 - Front Desk & Nurses**
- System overview (1 hour)
- Patient check-in process (2 hours)
- Using the queue board (1 hour)
- Recording vitals (2 hours)
- Q&A session (1 hour)

**Day 2 - Doctors & Admin**
- Doctor dashboard walkthrough (2 hours)
- Managing appointments (1 hour)
- Writing prescriptions (1 hour)
- Admin analytics & reports (2 hours)
- Troubleshooting (1 hour)

### Patient Onboarding
**In-App Tutorial**: Interactive 3-step guide
1. Welcome screen with benefits
2. How to book an appointment (animated)
3. How to track your queue (with demo)

**Video Tutorials**: 2-3 minute videos
- Booking your first appointment
- Understanding your queue position
- Accessing your medical records

---

## 🤝 Stakeholder Communication

### Weekly Updates
**To**: CEO, CTO, Investors
**Format**: Email summary
**Content**:
- Progress this week
- Blockers & risks
- Metrics update
- Next week's plan

### Monthly Reviews
**To**: All stakeholders
**Format**: Slide deck + demo
**Content**:
- Feature releases
- User growth metrics
- Financial performance
- Roadmap updates
- User feedback highlights

---

## 🎉 Success Celebration Milestones

1. **First 100 Users**: Team lunch 🍕
2. **First 1000 Bookings**: Feature on company blog
3. **Zero Critical Bugs (1 week)**: Bonus day off
4. **4.5+ Star Rating**: Team outing
5. **Break-even Month**: Company party 🎊
6. **Enterprise Customer Signed**: Stock options bonus

---

## 📞 Support & Escalation

### Support Tiers
1. **Tier 1 - Chatbot**: Common questions, 24/7
2. **Tier 2 - Support Team**: Email/chat, 9 AM - 9 PM
3. **Tier 3 - Engineering**: Critical bugs, on-call

### SLA (Service Level Agreement)
- **Critical (system down)**: < 1 hour response
- **High (feature broken)**: < 4 hours response
- **Medium (bug)**: < 24 hours response
- **Low (enhancement)**: < 72 hours response

### Emergency Contacts
- **On-call Engineer**: +91-XXXX-XXXX
- **Product Manager**: pm@mediqueue.com
- **CEO**: ceo@mediqueue.com


---

## 🔮 Future Vision (Beyond V2)

### Year 1 Goals
- 50 hospitals onboarded
- 100,000 patients using the platform
- 500,000 appointments booked
- ₹5 crore annual recurring revenue

### Year 2-3 Vision
- **Geographic Expansion**: Launch in 3 countries
- **AI Doctor Assistant**: Real-time clinical decision support
- **Chronic Disease Management**: Long-term patient tracking
- **Health Insurance Integration**: Direct claims processing
- **Marketplace**: Third-party services (ambulance, home nursing)

### Long-Term Vision (5+ years)
- **Healthcare Super App**: One-stop solution for all healthcare needs
- **Predictive Health Monitoring**: Wearable integration + AI predictions
- **Genetic Health Reports**: Personalized medicine recommendations
- **Global Health Network**: Connect patients to doctors worldwide

---

## 📖 Glossary

| Term | Definition |
|------|------------|
| **Token** | Unique identifier given to patients (e.g., A-234) |
| **Queue Position** | Patient's current place in line |
| **ETA** | Estimated Time of Arrival/Appointment |
| **RLS** | Row-Level Security (Postgres feature) |
| **WebSocket** | Protocol for real-time bidirectional communication |
| **PWA** | Progressive Web App (installable web app) |
| **WebRTC** | Web Real-Time Communication (for video calls) |
| **Edge Function** | Serverless function running at edge locations |
| **HIPAA** | Health Insurance Portability and Accountability Act (US) |
| **GDPR** | General Data Protection Regulation (EU) |
| **OCR** | Optical Character Recognition (text from images) |
| **MFA** | Multi-Factor Authentication |
| **DAU** | Daily Active Users |
| **MAU** | Monthly Active Users |

---

## 📝 Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 2.0 | July 12, 2026 | Complete V2 PRD with real-time features | Product Team |
| 1.5 | July 11, 2026 | Added Phase 1 completion notes | Product Manager |
| 1.0 | July 1, 2026 | Initial PRD for V1 features | Product Team |

---

## ✅ Approval & Sign-Off

| Role | Name | Signature | Date |
|------|------|-----------|------|
| **Product Manager** | _________ | _________ | _________ |
| **Tech Lead** | _________ | _________ | _________ |
| **CTO** | _________ | _________ | _________ |
| **CEO** | _________ | _________ | _________ |

---

## 📎 Related Documents

1. [Original PRD V1](./PRD.md)
2. [Booking System Guide](./BOOKING_SYSTEM_GUIDE.md)
3. [UI Design System](./UI_DESIGN_SYSTEM.md)
4. [Database Schema](./supabase/schema-enhanced.sql)
5. [Implementation Guide](./IMPLEMENTATION_GUIDE.md)
6. [Project Summary](./PROJECT_SUMMARY.md)
7. [API Documentation](./docs/API.md) (TBD)
8. [Security Audit Report](./docs/SECURITY.md) (TBD)

---

**🎯 Next Steps**:
1. Review and approve this PRD
2. Break down Phase 1 into sprint tasks
3. Set up development environment
4. Begin implementation of real-time queue system
5. Weekly sync meetings to track progress

---

**End of Document**

*This is a living document. Please update as requirements evolve.*

**Last Modified**: July 12, 2026  
**Document Owner**: Product Team  
**Contact**: product@mediqueue.com

