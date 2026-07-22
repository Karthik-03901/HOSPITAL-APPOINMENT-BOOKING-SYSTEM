# 🔄 Smart Routing Flowchart

## Complete User Journey Map

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           HOMEPAGE (index.html)                         │
│                                                                         │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐    │
│  │ Button #1        │  │ Button #2        │  │ Button #3        │    │
│  │ Start Free Trial │  │ Book Now         │  │ Track Now        │    │
│  └────────┬─────────┘  └────────┬─────────┘  └────────┬─────────┘    │
└───────────┼──────────────────────┼──────────────────────┼──────────────┘
            │                      │                      │
            ▼                      ▼                      ▼
```

---

## Button #1: "Start Free Trial" Flow

```
                    User Clicks "Start Free Trial"
                                │
                                ▼
                    ┌───────────────────────┐
                    │ Check Login Status    │
                    └───────────┬───────────┘
                                │
                    ┌───────────┴───────────┐
                    │                       │
            ┌───────▼────────┐      ┌──────▼─────────┐
            │ NOT Logged In  │      │ Logged In      │
            └───────┬────────┘      └──────┬─────────┘
                    │                       │
                    ▼                       ▼
        ┌─────────────────────┐  ┌─────────────────────┐
        │ pages/login.html    │  │ pages/book-         │
        │                     │  │ appointment.html    │
        └─────────────────────┘  └─────────────────────┘
```

---

## Button #2: "Book Now" Flow

```
                        User Clicks "Book Now"
                                │
                                ▼
                    ┌───────────────────────┐
                    │ Check Login Status    │
                    └───────────┬───────────┘
                                │
                    ┌───────────┴───────────┐
                    │                       │
            ┌───────▼────────┐      ┌──────▼─────────┐
            │ NOT Logged In  │      │ Logged In      │
            └───────┬────────┘      └──────┬─────────┘
                    │                       │
                    ▼                       │
        ┌─────────────────────┐            │
        │ Show Notification:  │            │
        │ "Please login first"│            │
        └─────────┬───────────┘            │
                  │                        │
                  ▼                        │
        ┌─────────────────────┐            │
        │ Save to localStorage│            │
        │ intendedDestination:│            │
        │ 'book-appointment'  │            │
        └─────────┬───────────┘            │
                  │                        │
                  ▼                        │
        ┌─────────────────────┐            │
        │ Wait 1 second       │            │
        └─────────┬───────────┘            │
                  │                        │
                  ▼                        ▼
        ┌─────────────────────┐  ┌─────────────────────┐
        │ pages/login.html    │  │ pages/book-         │
        │                     │  │ appointment.html    │
        └─────────┬───────────┘  └─────────────────────┘
                  │
                  ▼
        ┌─────────────────────┐
        │ User Logs In        │
        └─────────┬───────────┘
                  │
                  ▼
        ┌─────────────────────┐
        │ Check intended      │
        │ destination         │
        └─────────┬───────────┘
                  │
                  ▼
        ┌─────────────────────┐
        │ pages/book-         │
        │ appointment.html    │
        │ (NOT default dash!) │
        └─────────────────────┘
```

---

## Button #3: "Track Now" Flow (Most Complex)

```
                        User Clicks "Track Now"
                                │
                                ▼
                    ┌───────────────────────┐
                    │ Check Login Status    │
                    └───────────┬───────────┘
                                │
                    ┌───────────┴───────────┐
                    │                       │
            ┌───────▼────────┐      ┌──────▼─────────┐
            │ NOT Logged In  │      │ Logged In      │
            └───────┬────────┘      └──────┬─────────┘
                    │                       │
                    ▼                       ▼
        ┌─────────────────────┐  ┌─────────────────────┐
        │ Show Notification:  │  │ Query Database:     │
        │ "Please login first"│  │ Check Appointments  │
        └─────────┬───────────┘  └─────────┬───────────┘
                  │                         │
                  ▼                         │
        ┌─────────────────────┐            │
        │ Save to localStorage│   ┌────────┴────────┐
        │ intendedDestination:│   │                 │
        │ 'track-live'        │   │                 │
        └─────────┬───────────┘   │                 │
                  │           ┌───▼────┐      ┌─────▼────┐
                  ▼           │ Has    │      │ No       │
        ┌─────────────────┐   │ Appts  │      │ Appts    │
        │ Wait 1 second   │   └───┬────┘      └─────┬────┘
        └─────────┬───────┘       │                 │
                  │                │                 │
                  ▼                ▼                 ▼
        ┌─────────────────┐   ┌────────┐   ┌─────────────┐
        │ pages/login.html│   │ Get    │   │ Show Notif: │
        │                 │   │ Latest │   │ "Book first"│
        └─────────┬───────┘   │ ID     │   └──────┬──────┘
                  │            └───┬────┘          │
                  ▼                │               ▼
        ┌─────────────────┐        │      ┌─────────────┐
        │ User Logs In    │        │      │ Wait 1 sec  │
        └─────────┬───────┘        │      └──────┬──────┘
                  │                │              │
                  ▼                ▼              ▼
        ┌─────────────────┐   ┌────────────┐   ┌──────────┐
        │ Check intended  │   │ pages/     │   │ pages/   │
        │ destination     │   │ queue-     │   │ book-    │
        └─────────┬───────┘   │ status.html│   │ appoint- │
                  │            │ ?id=123    │   │ ment.html│
                  ▼            └────────────┘   └──────────┘
        ┌─────────────────┐
        │ pages/queue-    │
        │ status.html     │
        └─────────────────┘
```

---

## State Diagram

```
┌──────────────────────────────────────────────────────────────────┐
│                         USER STATES                              │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────────┐                                            │
│  │  Anonymous User │ (Not Logged In)                            │
│  └────────┬────────┘                                            │
│           │                                                      │
│           │ Login                                                │
│           ▼                                                      │
│  ┌─────────────────┐                                            │
│  │ Logged In User  │ (Has Session)                              │
│  │ No Appointments │                                            │
│  └────────┬────────┘                                            │
│           │                                                      │
│           │ Books Appointment                                    │
│           ▼                                                      │
│  ┌─────────────────┐                                            │
│  │ Logged In User  │ (Has Session + Appointments)               │
│  │ Has Appointments│                                            │
│  └─────────────────┘                                            │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## Button Behavior Matrix

| User State | Button #1 | Button #2 | Button #3 |
|------------|-----------|-----------|-----------|
| **Anonymous** | → Login | → Message + Login | → Message + Login |
| **Logged In (No Appts)** | → Book | → Book | → Message + Book |
| **Logged In (Has Appts)** | → Book | → Book | → Queue Status |

---

## Database Query Flow

```
                    User Clicks Button #3
                            │
                            ▼
                ┌────────────────────────┐
                │ Check Supabase Session │
                └───────────┬────────────┘
                            │
                    Session Found? 
                            │
                            ▼ YES
                ┌────────────────────────┐
                │ Query Database:        │
                │ SELECT id              │
                │ FROM appointments      │
                │ WHERE patient_email = ?│
                │ AND status IN (        │
                │   'confirmed',         │
                │   'scheduled'          │
                │ )                      │
                │ ORDER BY created_at    │
                │ DESC LIMIT 1           │
                └───────────┬────────────┘
                            │
                    Data Returned?
                            │
                ┌───────────┴───────────┐
                │                       │
            ▼ YES                   ▼ NO
    ┌────────────────┐      ┌─────────────────┐
    │ Appointments   │      │ No Appointments │
    │ Found          │      │ Found           │
    └───────┬────────┘      └────────┬────────┘
            │                        │
            ▼                        ▼
    ┌────────────────┐      ┌─────────────────┐
    │ Redirect to    │      │ Redirect to     │
    │ queue-status   │      │ book-appointment│
    │ with ID        │      │                 │
    └────────────────┘      └─────────────────┘
```

---

## localStorage Flow

```
User Not Logged In → Clicks Button #2 or #3
        │
        ▼
┌──────────────────────────────┐
│ localStorage.setItem(        │
│   'intendedDestination',     │
│   'book-appointment'         │  ← or 'track-live'
│ )                            │
└──────────────┬───────────────┘
               │
               ▼
    Redirect to login.html
               │
               ▼
        User Logs In
               │
               ▼
┌──────────────────────────────┐
│ const intended =             │
│   localStorage.getItem(      │
│     'intendedDestination'    │
│   )                          │
└──────────────┬───────────────┘
               │
       Found? Yes/No
               │
        ┌──────┴──────┐
        │             │
    ▼ YES         ▼ NO
┌──────────┐  ┌──────────────┐
│ Redirect │  │ Redirect to  │
│ to       │  │ default      │
│ intended │  │ dashboard    │
└────┬─────┘  └──────────────┘
     │
     ▼
┌──────────────────────────────┐
│ localStorage.removeItem(     │
│   'intendedDestination'      │
│ )                            │
└──────────────────────────────┘
```

---

## Event Listener Flow

```
┌──────────────────────────────────────────────────────────────┐
│                  index.html Loads                            │
└────────────────────────────┬─────────────────────────────────┘
                             │
                             ▼
                ┌────────────────────────┐
                │ DOM Ready Event        │
                └────────────┬───────────┘
                             │
                             ▼
                ┌────────────────────────┐
                │ smart-routing.js       │
                │ initSmartRouting()     │
                └────────────┬───────────┘
                             │
                             ▼
        ┌────────────────────┼────────────────────┐
        │                    │                    │
        ▼                    ▼                    ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│ Find Button  │    │ Find Button  │    │ Find Button  │
│ #1 by ID     │    │ #2 by ID     │    │ #3 by ID     │
└──────┬───────┘    └──────┬───────┘    └──────┬───────┘
       │                   │                    │
       ▼                   ▼                    ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│ Attach       │    │ Attach       │    │ Attach       │
│ click event  │    │ click event  │    │ click event  │
│ handler      │    │ handler      │    │ handler      │
└──────────────┘    └──────────────┘    └──────────────┘
       │                   │                    │
       └───────────────────┴────────────────────┘
                           │
                           ▼
                ┌────────────────────────┐
                │ Console Log:           │
                │ "Smart routing         │
                │  initialized"          │
                └────────────────────────┘
```

---

## Error Handling Flow

```
                    User Action
                        │
                        ▼
                ┌───────────────┐
                │ Try Operation │
                └───────┬───────┘
                        │
                Success/Error?
                        │
        ┌───────────────┴───────────────┐
        │                               │
    ▼ ERROR                        ▼ SUCCESS
┌────────────────┐            ┌────────────────┐
│ Catch Error    │            │ Execute Action │
└───────┬────────┘            └────────────────┘
        │
        ▼
┌────────────────┐
│ Log to Console │
└───────┬────────┘
        │
        ▼
┌────────────────┐
│ Show User      │
│ Message        │
│ (Toast/Alert)  │
└───────┬────────┘
        │
        ▼
┌────────────────┐
│ Fallback       │
│ Behavior       │
│ (e.g., login)  │
└────────────────┘
```

---

## Timing Diagram

```
Time (ms) │ Event
──────────┼─────────────────────────────────────────────────
0         │ User clicks button
          │
10-50     │ JavaScript executes
          │ ├─ Check login status
          │ └─ Query database (if needed)
          │
100-500   │ Database query returns
          │ └─ Process results
          │
600       │ Show notification (if needed)
          │
1000      │ Wait period (for notification)
          │
1100      │ Redirect to next page
          │
1200-1500 │ New page loads
```

---

## Integration Points

```
┌────────────────────────────────────────────────────────────────┐
│                      Smart Routing System                      │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐   │
│  │              │    │              │    │              │   │
│  │  Supabase    │◄───┤   Smart      │───►│  Toast/      │   │
│  │  Auth        │    │   Routing    │    │  Alert       │   │
│  │              │    │   Module     │    │              │   │
│  └──────────────┘    └──────┬───────┘    └──────────────┘   │
│                             │                                 │
│                             ▼                                 │
│                     ┌──────────────┐                          │
│                     │              │                          │
│                     │  Database    │                          │
│                     │  (Appts)     │                          │
│                     │              │                          │
│                     └──────┬───────┘                          │
│                            │                                  │
│                            ▼                                  │
│                     ┌──────────────┐                          │
│                     │              │                          │
│                     │ localStorage │                          │
│                     │              │                          │
│                     └──────────────┘                          │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

---

## Component Dependencies

```
index.html
    │
    ├─► smart-routing.js (module)
    │       │
    │       ├─► supabaseClient.js
    │       │       │
    │       │       └─► Supabase SDK
    │       │
    │       └─► Toast Component (optional)
    │
    ├─► login.js (module)
    │       │
    │       └─► reads intendedDestination
    │
    └─► Other scripts
            ├─► testimonials.js
            ├─► message-box.js
            └─► navbar-scroll.js
```

---

## Legend

```
│  = Flow line (vertical)
─  = Flow line (horizontal)
┌┐ = Box/Container (top corners)
└┘ = Box/Container (bottom corners)
├┤ = Branch point (sides)
┬┴ = Branch point (top/bottom)
▼  = Flow direction (down)
►  = Flow direction (right)
?  = Decision point
```

---

**This flowchart shows the complete user journey through all possible states!** 🎯
