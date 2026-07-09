# MediGrid — Intelligent Healthcare Portal

Real-time doctor appointment booking. Frontend: HTML + Tailwind (CDN) with an
industrial/clinical-console design. Backend: Supabase (Postgres + Auth + Realtime).

## Project structure

```
healthcare-portal/
├── public/
│   ├── index.html          landing page
│   ├── login.html          Supabase email/password login
│   ├── signup.html         Supabase sign-up (patients)
│   ├── dashboard.html      live doctor status board + booking
│   ├── css/
│   │   └── styles.css      design tokens, corner-bracket motif, hazard-strip
│   └── js/
│       ├── supabaseClient.js   Supabase client init (put your keys here)
│       ├── auth.js             signup/login/logout handlers
│       └── dashboard.js        board rendering, booking flow, realtime sub
└── supabase/
    └── schema.sql          full DB schema, RLS policies, triggers, seed data
```

## Setup

1. **Create a Supabase project** at supabase.com.
2. **Run the schema.** Open Project → SQL Editor → paste the contents of
   `supabase/schema.sql` → Run. This creates:
   - `profiles` (auto-created on signup via trigger)
   - `doctors` (public directory, seeded with 4 sample doctors)
   - `slots` (bookable time slots per doctor)
   - `appointments` (bookings, auto-generates a `ticket_code`)
   - Row Level Security policies so patients only see their own bookings,
     and doctors only manage their own records.
   - Realtime is enabled on `doctors`, `slots`, `appointments` so the status
     board updates live without a page refresh.
3. **Add your API keys.** Open `public/js/supabaseClient.js` and replace:
   ```js
   const SUPABASE_URL = "https://YOUR-PROJECT-REF.supabase.co";
   const SUPABASE_ANON_KEY = "YOUR-PUBLIC-ANON-KEY";
   ```
   Both values are in Supabase Dashboard → Project Settings → API.
4. **Add some slots** (schema seeds doctors but not slots — insert a few via
   Table Editor, e.g. doctor_id, slot_date, start_time, end_time), or build
   an admin/doctor-facing slot creator as a next step.
5. **Serve the `public/` folder** with any static server, e.g.:
   ```bash
   npx serve public
   ```
   (Supabase auth requires http/https, not `file://`.)

## What's already wired up

- **Auth**: sign up, log in, log out, session-gated dashboard redirect.
- **Live status board**: doctor cards read from `doctors`, re-render on any
  Postgres change via a Realtime channel subscription.
- **Booking flow**: side panel lists open slots for a doctor → confirms →
  inserts into `appointments` → trigger flips the slot to booked → ticket
  modal shows the generated ticket code.
- **My appointments**: patient's own bookings with status labels.

## Suggested next steps

- Doctor-facing view (a `role = 'doctor'` dashboard to manage their own
  slots and see their queue).
- Admin view for verifying doctors and license numbers.
- Email/SMS reminders (Supabase Edge Functions + a cron trigger).
- Search/filter on the status board (specialty, fee range, rating).
- Replace the Tailwind CDN script with a build step (Tailwind CLI/PostCSS)
  before shipping to production, since the CDN build is dev-only.
