# MediQueue - Product Requirements Document (PRD)
## Hospital Management System - Production Version

---

## 1. Executive Summary

**Vision**: Transform MediQueue into an enterprise-grade hospital management platform that revolutionizes patient care coordination, reduces wait times by 40%, and provides real-time operational insights.

**Target Users**:
- **Patients** (Primary): Book appointments, track queue position in real-time, access medical records
- **Doctors** (Core): Manage daily schedules, view patient history, update consultation notes
- **Admins** (Power Users): Hospital-wide analytics, staff management, resource optimization
- **Front Desk Staff** (New): Patient check-in, walk-in management, queue coordination

---

## 2. Core Features - Production Level

### 2.1 Patient Portal (Enhanced)
- ✅ **Smart Appointment Booking**
  - Multi-step wizard with department → doctor → slot selection
  - Real-time slot availability with live queue preview
  - AI-powered doctor recommendations based on symptoms
  - Medical history pre-fill for returning patients
  
- ✅ **Live Queue Tracking**
  - Real-time position updates via WebSocket
  - ETA calculations with 90% accuracy
  - Push notifications (15min, 5min, "Now Serving")
  - QR code token for in-hospital kiosks

- ✅ **Medical Records**
  - View past consultations and prescriptions
  - Download reports (PDF with encryption)
  - Upload medical documents (drag-drop, OCR support)
  - Share records with doctors securely

- ✅ **Telemedicine Integration**
  - Video consultation for follow-ups
  - Chat with doctor (async messaging)
  - Prescription renewal requests

### 2.2 Doctor Dashboard (Professional)
- ✅ **Smart Queue Management**
  - Today's schedule with patient cards
  - Drag-to-reorder for urgent cases
  - One-click "Next Patient" / "Skip" / "Complete"
  - Patient pre-arrival notifications

- ✅ **Clinical Workspace**
  - Patient history timeline (last 5 visits)
  - Quick-prescription templates (favorites)
  - Voice-to-text notes (using Web Speech API)
  - E-prescription generation with digital signature

- ✅ **Analytics Dashboard**
  - Average consultation time
  - Patient satisfaction scores
  - Weekly schedule optimization suggestions

### 2.3 Admin Command Center (Enterprise)
- ✅ **Real-Time Hospital Overview**
  - Live department occupancy heatmap
  - Queue lengths across all doctors
  - Today's appointment vs walk-in ratio
  - Alert system for bottlenecks

- ✅ **Resource Management**
  - Doctor availability bulk editing (calendar view)
  - Department & room assignment
  - Staff onboarding workflows
  - Equipment tracking integration points

- ✅ **Advanced Analytics**
  - Revenue reports (daily, weekly, monthly)
  - Patient demographics & trends
  - Peak hour analysis with forecasting
  - Export to Excel/CSV with filters

- ✅ **System Configuration**
  - Working hours & holidays
  - Notification templates (email, SMS, push)
  - Payment gateway integration settings
  - Emergency mode toggle

### 2.4 Front Desk Module (New)
- ✅ **Quick Check-In**
  - Search patient by phone/token/QR
  - Mark patient as arrived
  - Print physical token slip
  - Register walk-ins instantly

- ✅ **Queue Monitor**
  - TV display mode (full-screen queue board)
  - Call patient to consultation room
  - Reassign to different doctor

---

## 3. UI/UX Enhancement Specifications

### 3.1 Design System
**Visual Language**: Clinical Precision meets Modern SaaS
- **Color System**: 
  - Primary: Teal (#0E9384) - Trust, Healthcare
  - Navy (#081826 - #20507D) - Professionalism
  - Success: Green (#059669)
  - Warning: Amber (#F59E0B)
  - Error: Coral (#D64545)
  - Neutrals: Slate scale + Paper (#F6F8F7)

- **Typography**:
  - Display: Space Grotesk (headings, 600-700)
  - Body: IBM Plex Sans (paragraphs, 400-600)
  - Data/Tokens: IBM Plex Mono (numbers, codes)

- **Components**:
  - Glassmorphic cards with subtle shadows
  - Micro-interactions (button states, hover effects)
  - Skeleton loaders for async data
  - Toast notifications (success, error, info)
  - Modal system (centered, drawer variants)

### 3.2 Responsive Breakpoints
- Mobile: 320px - 767px (Priority 1)
- Tablet: 768px - 1023px
- Desktop: 1024px - 1440px
- Large: 1441px+

### 3.3 Accessibility (WCAG 2.1 AA)
- Keyboard navigation (Tab, Arrow keys)
- Screen reader labels (aria-*)
- Color contrast ≥4.5:1
- Focus indicators (2px teal outline)

---

## 4. Technical Architecture

### 4.1 Frontend Stack (Enhanced)
```
├── HTML5 (Semantic structure)
├── Tailwind CSS 3.4+ (Utility-first)
├── Vanilla JavaScript ES2022+ (Modular)
│   ├── Components/
│   │   ├── Toast.js (Notification system)
│   │   ├── Modal.js (Dialog handler)
│   │   ├── DataTable.js (Sortable, paginated tables)
│   │   ├── Chart.js (Analytics visualizations)
│   │   └── QueueBoard.js (Real-time queue UI)
│   ├── Utils/
│   │   ├── formatters.js (Date, currency, time)
│   │   ├── validators.js (Form validation)
│   │   └── api.js (Fetch wrappers)
│   └── State/
│       └── store.js (Simple event-driven state)
└── External:
    ├── Chart.js (for analytics)
    ├── Day.js (date manipulation)
    └── Socket.io (real-time updates)
```

### 4.2 Backend (Supabase)
- **Realtime**: Postgres Changes → WebSocket → UI updates
- **Storage**: Patient documents, prescriptions (S3-compatible)
- **Edge Functions**: PDF generation, notifications, webhooks
- **Database**: Enhanced schema (see section 5)

### 4.3 Security
- **Authentication**: Supabase Auth with MFA support
- **Authorization**: RLS policies (role-based + resource-based)
- **Data**: AES-256 encryption at rest, TLS 1.3 in transit
- **Audit**: Activity logs table (who did what, when)

---

## 5. Enhanced Database Schema

### New Tables
```sql
-- Medical records
CREATE TABLE medical_records (
  id UUID PRIMARY KEY,
  patient_id UUID REFERENCES profiles(id),
  doctor_id UUID REFERENCES doctors(id),
  appointment_id UUID REFERENCES appointments(id),
  diagnosis TEXT,
  prescription JSONB,
  notes TEXT,
  attachments TEXT[], -- Supabase Storage URLs
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Prescriptions
CREATE TABLE prescriptions (
  id UUID PRIMARY KEY,
  medical_record_id UUID REFERENCES medical_records(id),
  medications JSONB, -- [{ name, dosage, frequency, duration }]
  special_instructions TEXT,
  issued_at TIMESTAMPTZ DEFAULT NOW(),
  valid_until DATE
);

-- Notifications
CREATE TABLE notifications (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES profiles(id),
  type TEXT, -- 'appointment_reminder', 'queue_update', 'prescription_ready'
  title TEXT,
  message TEXT,
  read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Activity logs
CREATE TABLE activity_logs (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES profiles(id),
  action TEXT, -- 'appointment_created', 'record_updated', 'login'
  entity_type TEXT,
  entity_id UUID,
  metadata JSONB,
  ip_address INET,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Hospital settings
CREATE TABLE hospital_settings (
  key TEXT PRIMARY KEY,
  value JSONB,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Reviews & ratings
CREATE TABLE reviews (
  id UUID PRIMARY KEY,
  patient_id UUID REFERENCES profiles(id),
  doctor_id UUID REFERENCES doctors(id),
  appointment_id UUID REFERENCES appointments(id),
  rating SMALLINT CHECK (rating BETWEEN 1 AND 5),
  comment TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Enhanced Existing Tables
```sql
-- Add to appointments
ALTER TABLE appointments 
  ADD COLUMN check_in_time TIMESTAMPTZ,
  ADD COLUMN consultation_start_time TIMESTAMPTZ,
  ADD COLUMN consultation_end_time TIMESTAMPTZ,
  ADD COLUMN notes TEXT,
  ADD COLUMN payment_status TEXT DEFAULT 'pending',
  ADD COLUMN payment_amount NUMERIC(10,2);

-- Add to profiles
ALTER TABLE profiles
  ADD COLUMN date_of_birth DATE,
  ADD COLUMN gender TEXT,
  ADD COLUMN blood_group TEXT,
  ADD COLUMN address TEXT,
  ADD COLUMN emergency_contact TEXT,
  ADD COLUMN avatar_url TEXT;

-- Add to doctors
ALTER TABLE doctors
  ADD COLUMN bio TEXT,
  ADD COLUMN qualification TEXT,
  ADD COLUMN experience_years INT,
  ADD COLUMN rating NUMERIC(3,2),
  ADD COLUMN total_reviews INT DEFAULT 0,
  ADD COLUMN is_available BOOLEAN DEFAULT TRUE;
```

---

## 6. Key User Flows

### 6.1 Patient - Book Appointment (7 steps)
1. Dashboard → "Book Appointment" CTA
2. Select Department (cards with icons)
3. Choose Doctor (photos, ratings, next available slot)
4. Pick Date (calendar with availability indicators)
5. Select Time Slot (green = available, grey = booked)
6. Enter Reason + Upload Documents (optional)
7. Confirm & Pay → Token Generated

### 6.2 Doctor - Daily Workflow
1. Login → Dashboard shows Today's Queue (15 patients)
2. Click "Start Day" → First patient card highlights
3. View patient history (sidebar slides in)
4. Click "Start Consultation" → Timer starts
5. Add notes (voice-to-text) → Save to record
6. Generate prescription → Send to patient
7. Click "Complete" → Next patient auto-loads

### 6.3 Admin - Generate Monthly Report
1. Dashboard → Analytics Tab
2. Select Date Range (picker with presets)
3. Choose Metrics (checkboxes: revenue, appointments, ratings)
4. Click "Generate Report" → Progress indicator
5. View charts (bar, line, pie)
6. Export → Downloads Excel with raw data

---

## 7. Performance Targets

| Metric | Target | Measurement |
|--------|--------|-------------|
| First Contentful Paint | < 1.2s | Lighthouse |
| Time to Interactive | < 2.5s | Lighthouse |
| API Response Time | < 300ms | Server logs |
| Real-time Update Latency | < 500ms | WebSocket |
| Lighthouse Score | > 90 | All categories |

---

## 8. Success Metrics (KPIs)

### Product Metrics
- **Adoption**: 500+ daily active users (DAU) within 3 months
- **Engagement**: 70% of patients book via app (vs phone)
- **Retention**: 80% monthly active users (MAU)

### Operational Metrics
- **Efficiency**: 40% reduction in average wait time
- **Accuracy**: 95% queue time prediction accuracy
- **Satisfaction**: 4.5+ star rating from patients

---

## 9. Roadmap Phases

### Phase 1: Foundation (Current → +2 weeks)
- ✅ Enhanced UI components library
- ✅ Complete booking flow
- ✅ Real-time queue updates
- ✅ Doctor dashboard completion
- ✅ Admin analytics v1

### Phase 2: Intelligence (+3-5 weeks)
- AI symptom checker (OpenAI API integration)
- Smart slot suggestions (ML-based)
- Automated appointment reminders
- Advanced reporting

### Phase 3: Ecosystem (+6-10 weeks)
- Mobile app (React Native)
- Payment gateway (Stripe/Razorpay)
- SMS/Email gateway (Twilio/SendGrid)
- Third-party lab integration

### Phase 4: Scale (+11-15 weeks)
- Multi-hospital support
- White-label capability
- API for partners
- Advanced security (SOC 2 compliance)

---

## 10. Out of Scope (V1)
- ❌ Video consultation (Phase 3)
- ❌ Mobile native apps (Phase 3)
- ❌ Billing & invoicing (Phase 2)
- ❌ Inventory management
- ❌ Lab test integration (Phase 3)
- ❌ Insurance claim processing

---

## 11. Open Questions
1. **Payment**: Integrate payment gateway in V1 or defer to Phase 3?
2. **Notifications**: SMS costs - use email + push only for V1?
3. **Languages**: English only or add Hindi/regional languages?
4. **Compliance**: HIPAA/GDPR requirements for international markets?

---

**Document Version**: 1.0  
**Last Updated**: July 11, 2026  
**Owner**: Product Team  
**Status**: Approved for Development
