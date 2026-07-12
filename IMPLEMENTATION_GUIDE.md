# MediQueue Implementation Guide

> **Step-by-step guide** to transform the basic scaffold into a production-ready hospital management system.

---

## 📋 Table of Contents

1. [Current Status](#current-status)
2. [Phase 1: Enhanced UI Components](#phase-1-enhanced-ui-components)
3. [Phase 2: Booking Flow](#phase-2-booking-flow)
4. [Phase 3: Real-time Queue](#phase-3-real-time-queue)
5. [Phase 4: Doctor Dashboard](#phase-4-doctor-dashboard)
6. [Phase 5: Admin Dashboard](#phase-5-admin-dashboard)
7. [Phase 6: Testing & Deployment](#phase-6-testing--deployment)

---

## Current Status

### ✅ Completed
- [x] Base schema with RLS policies
- [x] Authentication system (sign up, sign in, sign out)
- [x] Role-based routing (patient, doctor, admin)
- [x] Enhanced UI design system
- [x] Component library (Toast, Modal, formatters, validators)
- [x] Enhanced database schema with production features
- [x] Responsive landing page with animations
- [x] Product Requirements Document (PRD)

### 🔄 In Progress
- [ ] Complete booking flow
- [ ] Real-time queue tracking
- [ ] Doctor dashboard functionality
- [ ] Admin dashboard analytics

### ⏳ Pending
- [ ] Mobile optimization
- [ ] Advanced analytics
- [ ] Payment integration
- [ ] Notification system (SMS/Email)

---

## Phase 1: Enhanced UI Components

### Step 1.1: Create Loading Component
**File**: `js/components/Loading.js`

```javascript
export class Loading {
  static show(container, text = 'Loading...') {
    const loader = document.createElement('div');
    loader.className = 'flex flex-col items-center justify-center py-12';
    loader.innerHTML = `
      <div class="spinner w-12 h-12 mb-4"></div>
      <p class="text-sm text-slate-600">${text}</p>
    `;
    container.innerHTML = '';
    container.appendChild(loader);
  }
  
  static hide(container) {
    container.innerHTML = '';
  }
}
```

### Step 1.2: Create Empty State Component
**File**: `js/components/EmptyState.js`

```javascript
export function renderEmptyState(options = {}) {
  const {
    icon = 'inbox',
    title = 'No data found',
    description = 'Get started by creating your first item.',
    actionText = null,
    onAction = null
  } = options;
  
  return `
    <div class="empty-state">
      <svg class="empty-state-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        ${getIconPath(icon)}
      </svg>
      <h3 class="empty-state-title">${title}</h3>
      <p class="empty-state-description">${description}</p>
      ${actionText ? `<button class="btn-primary mt-4" onclick="${onAction}">${actionText}</button>` : ''}
    </div>
  `;
}
```

### Step 1.3: Create Data Table Component
**File**: `js/components/DataTable.js`

```javascript
export class DataTable {
  constructor(options) {
    this.container = options.container;
    this.columns = options.columns; // [{ key, label, render }]
    this.data = options.data || [];
    this.sortable = options.sortable !== false;
    this.sortColumn = null;
    this.sortDirection = 'asc';
  }
  
  render() {
    if (this.data.length === 0) {
      this.container.innerHTML = renderEmptyState({
        title: 'No data available',
        description: 'There are no records to display.'
      });
      return;
    }
    
    const html = `
      <table class="data-table">
        <thead>
          <tr>
            ${this.columns.map(col => `
              <th class="${this.sortable ? 'cursor-pointer hover:bg-slate-100' : ''}"
                  data-column="${col.key}">
                <div class="flex items-center gap-2">
                  ${col.label}
                  ${this.sortable ? this.getSortIcon(col.key) : ''}
                </div>
              </th>
            `).join('')}
          </tr>
        </thead>
        <tbody>
          ${this.data.map(row => `
            <tr>
              ${this.columns.map(col => `
                <td>${col.render ? col.render(row[col.key], row) : row[col.key]}</td>
              `).join('')}
            </tr>
          `).join('')}
        </tbody>
      </table>
    `;
    
    this.container.innerHTML = html;
    
    // Add sort listeners
    if (this.sortable) {
      this.container.querySelectorAll('th[data-column]').forEach(th => {
        th.addEventListener('click', () => this.sort(th.dataset.column));
      });
    }
  }
  
  sort(column) {
    if (this.sortColumn === column) {
      this.sortDirection = this.sortDirection === 'asc' ? 'desc' : 'asc';
    } else {
      this.sortColumn = column;
      this.sortDirection = 'asc';
    }
    
    this.data.sort((a, b) => {
      const aVal = a[column];
      const bVal = b[column];
      const multiplier = this.sortDirection === 'asc' ? 1 : -1;
      return aVal > bVal ? multiplier : -multiplier;
    });
    
    this.render();
  }
  
  getSortIcon(column) {
    if (this.sortColumn !== column) return '↕';
    return this.sortDirection === 'asc' ? '↑' : '↓';
  }
  
  updateData(newData) {
    this.data = newData;
    this.render();
  }
}
```

---

## Phase 2: Booking Flow

### Step 2.1: Department Selection
**File**: `js/pages/booking-step1.js`

```javascript
import { supabase } from '../supabaseClient.js';
import { Loading } from '../components/Loading.js';
import { toast } from '../components/Toast.js';

export async function renderDepartmentSelection(container) {
  Loading.show(container, 'Loading departments...');
  
  try {
    const { data: departments, error } = await supabase
      .from('departments')
      .select('*')
      .order('name');
    
    if (error) throw error;
    
    container.innerHTML = `
      <div class="max-w-4xl mx-auto">
        <h2 class="font-display text-2xl font-semibold text-navy-900 mb-6">
          Select Department
        </h2>
        
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          ${departments.map(dept => `
            <button class="dept-card card-hover p-6 text-left" data-dept-id="${dept.id}">
              <div class="flex items-start gap-4">
                <div class="flex-shrink-0 w-12 h-12 rounded-lg bg-teal-100 flex items-center justify-center">
                  <svg class="w-6 h-6 text-teal-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
                  </svg>
                </div>
                <div class="flex-1">
                  <h3 class="font-display font-semibold text-navy-900 mb-1">
                    ${dept.name}
                  </h3>
                  <p class="text-sm text-slate-600">
                    ${dept.description || 'View available doctors'}
                  </p>
                </div>
              </div>
            </button>
          `).join('')}
        </div>
      </div>
    `;
    
    // Add click handlers
    container.querySelectorAll('.dept-card').forEach(card => {
      card.addEventListener('click', () => {
        const deptId = card.dataset.deptId;
        const deptName = departments.find(d => d.id === deptId).name;
        
        // Store selection and move to next step
        sessionStorage.setItem('booking_department_id', deptId);
        sessionStorage.setItem('booking_department_name', deptName);
        
        // Navigate to step 2 (doctor selection)
        window.location.href = '#step2';
      });
    });
    
  } catch (err) {
    console.error('Error loading departments:', err);
    toast.error('Failed to load departments. Please try again.');
  }
}
```

### Step 2.2: Doctor Selection
**File**: `js/pages/booking-step2.js`

Similar structure - fetch doctors from selected department, display with:
- Photo/avatar
- Name, qualification
- Experience, rating
- Next available slot
- "Book Now" button

### Step 2.3: Date & Time Selection
**File**: `js/pages/booking-step3.js`

- Calendar component with available dates
- Time slots for selected date (from `doctor_availability`)
- Check existing appointments to disable booked slots
- Calculate and show token number preview

### Step 2.4: Confirmation
**File**: `js/pages/booking-step4.js`

- Summary of all selections
- Reason for visit (textarea)
- Upload documents (optional)
- Payment status (if enabled)
- Confirm button → creates appointment

---

## Phase 3: Real-time Queue

### Step 3.1: Queue Status Component
**File**: `js/components/QueueTracker.js`

```javascript
import { supabase } from '../supabaseClient.js';
import { calculateETA } from '../utils/formatters.js';

export class QueueTracker {
  constructor(appointmentId, container) {
    this.appointmentId = appointmentId;
    this.container = container;
    this.subscription = null;
  }
  
  async init() {
    // Load initial state
    await this.loadQueueStatus();
    
    // Subscribe to real-time updates
    this.subscription = supabase
      .channel(`queue:${this.appointmentId}`)
      .on('postgres_changes', {
        event: '*',
        schema: 'public',
        table: 'queue_status',
        filter: `appointment_id=eq.${this.appointmentId}`
      }, (payload) => {
        this.handleUpdate(payload.new);
      })
      .subscribe();
  }
  
  async loadQueueStatus() {
    const { data, error } = await supabase
      .from('queue_status')
      .select(`
        *,
        appointment:appointments(
          token_number,
          appointment_date,
          appointment_time
        )
      `)
      .eq('appointment_id', this.appointmentId)
      .single();
    
    if (!error && data) {
      this.render(data);
    }
  }
  
  handleUpdate(newData) {
    this.render(newData);
    
    // Show notification if position changed
    if (newData.current_position <= 3) {
      toast.info(`You're ${newData.current_position} in queue!`);
    }
  }
  
  render(data) {
    const eta = calculateETA(data.current_position);
    
    this.container.innerHTML = `
      <div class="card p-6">
        <div class="flex items-center justify-between mb-4">
          <h3 class="font-display font-semibold text-navy-900">Queue Position</h3>
          <span class="status-pill ${this.getStatusColor(data.status)}">
            ${data.status}
          </span>
        </div>
        
        <div class="text-center py-6">
          <div class="text-6xl font-mono font-bold text-teal-600 mb-2">
            ${data.current_position}
          </div>
          <p class="text-slate-600">patients ahead of you</p>
        </div>
        
        <div class="divider"></div>
        
        <div class="grid grid-cols-2 gap-4 text-sm">
          <div>
            <p class="text-slate-500">Estimated wait</p>
            <p class="font-medium text-navy-900">${eta}</p>
          </div>
          <div>
            <p class="text-slate-500">Token number</p>
            <p class="font-mono font-medium text-navy-900">
              ${data.appointment.token_number}
            </p>
          </div>
        </div>
      </div>
    `;
  }
  
  getStatusColor(status) {
    const colors = {
      waiting: 'bg-amber-100 text-amber-700',
      in_consultation: 'bg-teal-100 text-teal-700',
      completed: 'bg-slate-100 text-slate-700'
    };
    return colors[status] || colors.waiting;
  }
  
  destroy() {
    if (this.subscription) {
      supabase.removeChannel(this.subscription);
    }
  }
}
```

### Step 3.2: WebSocket Integration
Add real-time subscription to appointments table:

```javascript
// In patient dashboard
const subscription = supabase
  .channel('appointments')
  .on('postgres_changes', {
    event: 'UPDATE',
    schema: 'public',
    table: 'appointments',
    filter: `patient_id=eq.${userId}`
  }, (payload) => {
    // Update UI when appointment status changes
    refreshAppointmentsList();
  })
  .subscribe();
```

---

## Phase 4: Doctor Dashboard

### Step 4.1: Today's Queue
**File**: `js/pages/doctor-dashboard.js`

```javascript
import { supabase } from '../supabaseClient.js';
import { formatTime, formatDate } from '../utils/formatters.js';

export async function renderDoctorQueue(doctorId) {
  const { data, error } = await supabase
    .rpc('get_doctor_queue', {
      doc_id: doctorId,
      appt_date: new Date().toISOString().split('T')[0]
    });
  
  if (error) {
    console.error('Error loading queue:', error);
    return;
  }
  
  const container = document.getElementById('queue-container');
  
  container.innerHTML = `
    <div class="space-y-3">
      ${data.map((patient, index) => `
        <div class="card p-4 hover:shadow-md transition-shadow">
          <div class="flex items-start gap-4">
            <div class="flex-shrink-0">
              <div class="avatar avatar-lg bg-teal-100 text-teal-700">
                ${patient.patient_name.charAt(0)}
              </div>
            </div>
            
            <div class="flex-1">
              <div class="flex items-start justify-between">
                <div>
                  <h4 class="font-medium text-navy-900">${patient.patient_name}</h4>
                  <p class="text-sm text-slate-600">${patient.patient_phone}</p>
                </div>
                <div class="text-right">
                  <span class="font-mono text-lg font-semibold text-navy-900">
                    #${patient.token_number}
                  </span>
                  <p class="text-xs text-slate-500">${formatTime(patient.appointment_time)}</p>
                </div>
              </div>
              
              <div class="flex items-center gap-2 mt-3">
                <button class="btn-primary btn-sm" onclick="startConsultation('${patient.appointment_id}')">
                  Start Consultation
                </button>
                <button class="btn-ghost btn-sm" onclick="viewHistory('${patient.appointment_id}')">
                  View History
                </button>
              </div>
            </div>
          </div>
        </div>
      `).join('')}
    </div>
  `;
}
```

### Step 4.2: Consultation Interface
Create modal or side panel with:
- Patient info and vitals
- Medical history
- Prescription form
- Save & Complete button

---

## Phase 5: Admin Dashboard

### Step 5.1: Analytics Dashboard
**File**: `js/pages/admin-analytics.js`

```javascript
// Fetch and display:
// - Today's appointments count
// - Revenue (if payment enabled)
// - Department-wise patient distribution
// - Peak hours chart
// - Doctor performance metrics

export async function renderAnalytics() {
  const stats = await fetchDashboardStats();
  
  document.getElementById('analytics-container').innerHTML = `
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
      ${renderStatCard('Total Appointments', stats.totalAppointments, '+12%', 'positive')}
      ${renderStatCard('Today\'s Patients', stats.todayPatients, '+5%', 'positive')}
      ${renderStatCard('Active Doctors', stats.activeDoctors, '', '')}
      ${renderStatCard('Avg Wait Time', stats.avgWaitTime + ' min', '-8%', 'positive')}
    </div>
    
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <div class="card">
        <div class="card-header">
          <h3 class="font-display font-semibold text-navy-900">Appointments This Week</h3>
        </div>
        <div class="card-body">
          <canvas id="appointments-chart"></canvas>
        </div>
      </div>
      
      <div class="card">
        <div class="card-header">
          <h3 class="font-display font-semibold text-navy-900">Department Distribution</h3>
        </div>
        <div class="card-body">
          <canvas id="departments-chart"></canvas>
        </div>
      </div>
    </div>
  `;
  
  // Initialize charts using Chart.js
  renderCharts(stats);
}
```

### Step 5.2: Staff Management
CRUD operations for:
- Doctors (create, edit, delete, toggle availability)
- Departments (create, edit, delete)
- Availability schedules (weekly calendar editor)

---

## Phase 6: Testing & Deployment

### Step 6.1: Testing Checklist
- [ ] Authentication flows (sign up, sign in, sign out, password reset)
- [ ] Booking flow (all steps, validation, error handling)
- [ ] Real-time updates (queue position, notifications)
- [ ] Role-based access (patient can't access doctor dashboard)
- [ ] Mobile responsiveness (test on iPhone, Android)
- [ ] Performance (Lighthouse scores)
- [ ] Security (RLS policies, input validation)

### Step 6.2: Deployment

#### Option 1: Vercel
```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
vercel --prod
```

#### Option 2: Netlify
```bash
# Install Netlify CLI
npm i -g netlify-cli

# Deploy
netlify deploy --prod --dir=.
```

#### Option 3: GitHub Pages
1. Push to GitHub
2. Go to Settings → Pages
3. Select branch and `/` folder
4. Save

### Step 6.3: Environment Variables
Make sure to set environment variables in your hosting provider:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

---

## 🚀 Next Steps

1. **Complete booking flow** (Steps 2.1-2.4)
2. **Implement real-time queue** (Step 3.1-3.2)
3. **Build doctor dashboard** (Step 4.1-4.2)
4. **Create admin analytics** (Step 5.1-5.2)
5. **Test thoroughly** (Step 6.1)
6. **Deploy to production** (Step 6.2-6.3)

---

## 📚 Resources

- [Supabase Docs](https://supabase.com/docs)
- [Tailwind CSS Docs](https://tailwindcss.com/docs)
- [Chart.js Docs](https://www.chartjs.org/docs/)
- [MDN Web Docs](https://developer.mozilla.org/)

---

**Happy coding! 🎉**
