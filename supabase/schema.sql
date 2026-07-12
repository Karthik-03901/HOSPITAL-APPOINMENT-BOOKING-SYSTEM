-- =====================================================================
-- Hospital Appointment Booking System — Supabase schema
-- Run this in the Supabase SQL editor (or via `supabase db push`).
-- =====================================================================

-- ---------- Extensions ----------
create extension if not exists "uuid-ossp";

-- ---------- Enums ----------
create type user_role as enum ('patient', 'doctor', 'admin');
create type appointment_status as enum ('pending', 'confirmed', 'completed', 'cancelled', 'no_show');

-- ---------- Profiles ----------
-- One row per auth.users entry, storing role + display info.
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  role user_role not null default 'patient',
  phone text,
  created_at timestamptz not null default now()
);

-- ---------- Departments ----------
create table departments (
  id uuid primary key default uuid_generate_v4(),
  name text not null unique,
  description text,
  created_at timestamptz not null default now()
);

-- ---------- Doctors ----------
-- Extends a profile (role = 'doctor') with clinical details.
create table doctors (
  id uuid primary key default uuid_generate_v4(),
  profile_id uuid not null references profiles(id) on delete cascade,
  department_id uuid not null references departments(id) on delete restrict,
  specialization text,
  consultation_fee numeric(10,2) default 0,
  slot_duration_minutes int not null default 15,
  created_at timestamptz not null default now(),
  unique (profile_id)
);

-- ---------- Doctor weekly availability ----------
create table doctor_availability (
  id uuid primary key default uuid_generate_v4(),
  doctor_id uuid not null references doctors(id) on delete cascade,
  day_of_week smallint not null check (day_of_week between 0 and 6), -- 0 = Sunday
  start_time time not null,
  end_time time not null
);

-- ---------- Appointments ----------
-- token_number is the human-facing queue number shown to the patient,
-- scoped per doctor per day (see trigger below).
create table appointments (
  id uuid primary key default uuid_generate_v4(),
  token_number int not null,
  patient_id uuid not null references profiles(id) on delete cascade,
  doctor_id uuid not null references doctors(id) on delete cascade,
  department_id uuid not null references departments(id) on delete restrict,
  appointment_date date not null,
  appointment_time time not null,
  status appointment_status not null default 'pending',
  reason text,
  created_at timestamptz not null default now()
);

create index idx_appointments_doctor_date on appointments (doctor_id, appointment_date);
create index idx_appointments_patient on appointments (patient_id);

-- Auto-generate a per-doctor, per-day token number on insert.
create or replace function set_token_number()
returns trigger as $$
begin
  select coalesce(max(token_number), 0) + 1
  into new.token_number
  from appointments
  where doctor_id = new.doctor_id
    and appointment_date = new.appointment_date;
  return new;
end;
$$ language plpgsql;

create trigger trg_set_token_number
before insert on appointments
for each row execute function set_token_number();

-- =====================================================================
-- Row Level Security
-- =====================================================================
alter table profiles enable row level security;
alter table departments enable row level security;
alter table doctors enable row level security;
alter table doctor_availability enable row level security;
alter table appointments enable row level security;

-- ---------- Admin Helper Function ----------
-- Helper function to check if the current user is an admin.
-- Defined with security definer to bypass RLS recursion on profiles.
create or replace function public.is_admin()
begin
  return exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
end;
$$ language plpgsql security definer set search_path = public;

-- Profiles: users can read/update their own profile; admins read all.
create policy "profiles_select_own_or_admin"
  on profiles for select
  using (
    auth.uid() = id
    or public.is_admin()
  );

create policy "profiles_update_own"
  on profiles for update
  using (auth.uid() = id);

create policy "profiles_insert_self"
  on profiles for insert
  with check (auth.uid() = id);

-- Departments & doctor availability: public read (needed for booking flow).
create policy "departments_public_read" on departments for select using (true);
create policy "doctors_public_read" on doctors for select using (true);
create policy "availability_public_read" on doctor_availability for select using (true);

-- Only admins manage departments/doctors.
create policy "departments_admin_write"
  on departments for all
  using (public.is_admin());

create policy "doctors_admin_write"
  on doctors for all
  using (public.is_admin());

-- Appointments: patients see their own; doctors see theirs; admins see all.
create policy "appointments_select"
  on appointments for select
  using (
    patient_id = auth.uid()
    or exists (select 1 from doctors d where d.id = doctor_id and d.profile_id = auth.uid())
    or public.is_admin()
  );

create policy "appointments_insert_patient"
  on appointments for insert
  with check (patient_id = auth.uid());

create policy "appointments_update"
  on appointments for update
  using (
    patient_id = auth.uid()
    or exists (select 1 from doctors d where d.id = doctor_id and d.profile_id = auth.uid())
    or public.is_admin()
  );

-- ---------- Auth Profile Trigger ----------
-- Auto-create a profile row when a new user signs up.
-- Reads full_name, phone, and role from user_metadata.
create or replace function public.handle_new_user()
returns trigger as $$
declare
  default_role user_role := 'patient'::user_role;
  user_role_text text;
  assigned_role user_role;
begin
  -- Defensively extract role
  if new.raw_user_meta_data is not null then
    user_role_text := new.raw_user_meta_data->>'role';
  end if;
  
  if user_role_text is not null and user_role_text in ('patient', 'doctor', 'admin') then
    assigned_role := user_role_text::user_role;
  else
    assigned_role := default_role;
  end if;

  insert into public.profiles (id, full_name, role, phone)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    assigned_role,
    new.raw_user_meta_data->>'phone'
  );
  return new;
end;
$$ language plpgsql security definer set search_path = public;

create or replace trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
