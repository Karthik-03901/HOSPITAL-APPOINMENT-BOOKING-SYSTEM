-- ============================================================
-- INTELLIGENT HEALTHCARE PORTAL — SUPABASE SCHEMA
-- Run this in the Supabase SQL editor (Project > SQL Editor > New query)
-- ============================================================

-- Extension needed for gen_random_uuid()
create extension if not exists "pgcrypto";

-- ------------------------------------------------------------
-- 1. PROFILES  (extends auth.users — one row per signed-up user)
-- ------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  role text not null default 'patient' check (role in ('patient', 'doctor', 'admin')),
  phone text,
  avatar_url text,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

drop policy if exists "Profiles are viewable by the owner" on public.profiles;
create policy "Profiles are viewable by the owner"
  on public.profiles for select
  using (auth.uid() = id);

drop policy if exists "Users can insert their own profile" on public.profiles;
create policy "Users can insert their own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

drop policy if exists "Users can update their own profile" on public.profiles;
create policy "Users can update their own profile"
  on public.profiles for update
  using (auth.uid() = id);

-- Auto-create a profile row whenever a new auth user signs up
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, full_name, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', 'New User'),
    coalesce(new.raw_user_meta_data->>'role', 'patient')
  );
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ------------------------------------------------------------
-- 2. DOCTORS  (public directory — spec-sheet style records)
-- ------------------------------------------------------------
create table if not exists public.doctors (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid references public.profiles(id) on delete set null,
  full_name text not null,
  specialty text not null,
  license_no text not null unique,
  years_experience int not null default 0,
  consultation_fee numeric(10,2) not null default 0,
  clinic_location text not null,
  rating numeric(2,1) default 4.5,
  status text not null default 'offline' check (status in ('available', 'busy', 'offline')),
  avatar_url text,
  created_at timestamptz not null default now()
);

alter table public.doctors enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'doctors_license_no_key'
  ) then
    alter table public.doctors add constraint doctors_license_no_key unique (license_no);
  end if;
end $$;

drop policy if exists "Doctors directory is publicly readable" on public.doctors;
create policy "Doctors directory is publicly readable"
  on public.doctors for select
  using (true);

drop policy if exists "Doctors can update their own record" on public.doctors;
create policy "Doctors can update their own record"
  on public.doctors for update
  using (auth.uid() = profile_id);

-- ------------------------------------------------------------
-- 3. AVAILABILITY SLOTS  (real-time bookable slots)
-- ------------------------------------------------------------
create table if not exists public.slots (
  id uuid primary key default gen_random_uuid(),
  doctor_id uuid not null references public.doctors(id) on delete cascade,
  slot_date date not null,
  start_time time not null,
  end_time time not null,
  is_booked boolean not null default false,
  created_at timestamptz not null default now(),
  unique (doctor_id, slot_date, start_time)
);

alter table public.slots enable row level security;

drop policy if exists "Slots are publicly readable" on public.slots;
create policy "Slots are publicly readable"
  on public.slots for select
  using (true);

drop policy if exists "Doctors manage their own slots" on public.slots;
create policy "Doctors manage their own slots"
  on public.slots for all
  using (
    doctor_id in (select id from public.doctors where profile_id = auth.uid())
  );

-- ------------------------------------------------------------
-- 4. APPOINTMENTS  (booking records / "work orders")
-- ------------------------------------------------------------
create table if not exists public.appointments (
  id uuid primary key default gen_random_uuid(),
  ticket_code text not null unique default upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8)),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  doctor_id uuid not null references public.doctors(id) on delete cascade,
  slot_id uuid not null references public.slots(id) on delete cascade,
  reason text,
  status text not null default 'confirmed' check (status in ('confirmed', 'completed', 'cancelled')),
  patient_name text,
  patient_age int,
  previous_checkup boolean not null default false,
  prescription_notes text,
  consultation_type text not null default 'General' check (consultation_type in ('General', 'Specialist', 'Follow-up', 'Emergency')),
  consultation_mode text not null default 'In-Clinic' check (consultation_mode in ('In-Clinic', 'Video-Consult')),
  govt_id_type text not null check (govt_id_type in ('Aadhaar', 'Passport', 'Driving License', 'Voter ID')),
  govt_id_number text not null,
  emergency_contact_name text not null,
  emergency_contact_phone text not null,
  medical_history text,
  consent_signed boolean not null default false check (consent_signed = true),
  created_at timestamptz not null default now()
);

-- Ensure existing appointments table has the new columns
alter table public.appointments
  add column if not exists patient_name text,
  add column if not exists patient_age int,
  add column if not exists previous_checkup boolean not null default false,
  add column if not exists prescription_notes text,
  add column if not exists consultation_type text not null default 'General',
  add column if not exists consultation_mode text not null default 'In-Clinic',
  add column if not exists govt_id_type text,
  add column if not exists govt_id_number text,
  add column if not exists emergency_contact_name text,
  add column if not exists emergency_contact_phone text,
  add column if not exists medical_history text,
  add column if not exists consent_signed boolean not null default true;

-- Ensure check constraints exist on altered table
do $$
begin
  -- Sanitize any existing rows to satisfy consent check prior to adding constraint
  update public.appointments set consent_signed = true where consent_signed = false or consent_signed is null;

  if not exists (select 1 from pg_constraint where conname = 'appointments_consultation_type_check') then
    alter table public.appointments add constraint appointments_consultation_type_check check (consultation_type in ('General', 'Specialist', 'Follow-up', 'Emergency'));
  end if;
  if not exists (select 1 from pg_constraint where conname = 'appointments_consultation_mode_check') then
    alter table public.appointments add constraint appointments_consultation_mode_check check (consultation_mode in ('In-Clinic', 'Video-Consult'));
  end if;
  if not exists (select 1 from pg_constraint where conname = 'appointments_govt_id_type_check') then
    alter table public.appointments add constraint appointments_govt_id_type_check check (govt_id_type in ('Aadhaar', 'Passport', 'Driving License', 'Voter ID'));
  end if;
  if not exists (select 1 from pg_constraint where conname = 'appointments_consent_signed_check') then
    alter table public.appointments add constraint appointments_consent_signed_check check (consent_signed = true);
  end if;
end $$;

-- Enforce slot availability check BEFORE booking
create or replace function public.check_slot_availability()
returns trigger as $$
declare
  v_is_booked boolean;
  v_slot_date date;
begin
  select liveslot.is_booked, liveslot.slot_date into v_is_booked, v_slot_date from public.slots liveslot where liveslot.id = new.slot_id;
  if v_is_booked then
    raise exception 'SECURITY VIOLATION: Slot is already booked.' using errcode = 'LOCKED';
  end if;
  if v_slot_date < current_date then
    raise exception 'SECURITY VIOLATION: Cannot book a slot in the past.';
  end if;
  return new;
end;
$$ language plpgsql;

drop trigger if exists before_appointment_inserted on public.appointments;
create trigger before_appointment_inserted
  before insert on public.appointments
  for each row execute procedure public.check_slot_availability();

-- Unique index to prevent double bookings under concurrent transactions
create unique index if not exists unique_active_slot_booking on public.appointments (slot_id) where (status <> 'cancelled');



alter table public.appointments enable row level security;

drop policy if exists "Patients view their own appointments" on public.appointments;
create policy "Patients view their own appointments"
  on public.appointments for select
  using (
    auth.uid() = patient_id
    or doctor_id in (select id from public.doctors where profile_id = auth.uid())
  );

drop policy if exists "Patients create their own appointments" on public.appointments;
create policy "Patients create their own appointments"
  on public.appointments for insert
  with check (auth.uid() = patient_id);

drop policy if exists "Patients cancel their own appointments" on public.appointments;
create policy "Patients cancel their own appointments"
  on public.appointments for update
  using (auth.uid() = patient_id);

-- Mark slot as booked whenever an appointment is created
create or replace function public.handle_new_appointment()
returns trigger as $$
begin
  update public.slots set is_booked = true where id = new.slot_id;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_appointment_created on public.appointments;
create trigger on_appointment_created
  after insert on public.appointments
  for each row execute procedure public.handle_new_appointment();

-- Free the slot back up if an appointment is cancelled
create or replace function public.handle_appointment_cancelled()
returns trigger as $$
begin
  if new.status = 'cancelled' and old.status <> 'cancelled' then
    update public.slots set is_booked = false where id = new.slot_id;
  end if;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_appointment_cancelled on public.appointments;
create trigger on_appointment_cancelled
  after update on public.appointments
  for each row execute procedure public.handle_appointment_cancelled();

-- ------------------------------------------------------------
-- 5. REALTIME — enable live updates for the status board
-- ------------------------------------------------------------
do $$
begin
  if not exists (
    select 1 from pg_publication_tables 
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'doctors'
  ) then
    alter publication supabase_realtime add table public.doctors;
  end if;

  if not exists (
    select 1 from pg_publication_tables 
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'slots'
  ) then
    alter publication supabase_realtime add table public.slots;
  end if;

  if not exists (
    select 1 from pg_publication_tables 
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'appointments'
  ) then
    alter publication supabase_realtime add table public.appointments;
  end if;
end $$;

-- ------------------------------------------------------------
-- 6. SEED DATA (sample doctors, for local dev)
-- ------------------------------------------------------------
insert into public.doctors (full_name, specialty, license_no, years_experience, consultation_fee, clinic_location, rating, status)
values
  ('Dr. Anita Rao', 'Cardiology', 'MCI-88213', 14, 800.00, 'Block A, Room 204', 4.8, 'available'),
  ('Dr. Suresh Iyer', 'Orthopedics', 'MCI-77120', 9, 600.00, 'Block B, Room 110', 4.6, 'busy'),
  ('Dr. Meera Nair', 'Dermatology', 'MCI-90344', 6, 500.00, 'Block A, Room 118', 4.7, 'available'),
  ('Dr. Karthik Menon', 'General Medicine', 'MCI-65029', 20, 400.00, 'Block C, Room 302', 4.9, 'offline')
on conflict (license_no) do nothing;

-- ------------------------------------------------------------
-- 7. SEED SLOTS (sample slots for the seeded doctors)
-- ------------------------------------------------------------
do $$
declare
  doc_id uuid;
begin
  -- Loop through all existing doctors and insert slot dates for today, tomorrow, and the day after
  for doc_id in select id from public.doctors loop
    insert into public.slots (doctor_id, slot_date, start_time, end_time, is_booked)
    values
      (doc_id, current_date, '09:00:00', '10:00:00', false),
      (doc_id, current_date, '14:00:00', '15:00:00', false),
      (doc_id, current_date + 1, '10:00:00', '11:00:00', false),
      (doc_id, current_date + 1, '16:00:00', '17:00:00', false)
    on conflict (doctor_id, slot_date, start_time) do nothing;
  end loop;
end $$;

