-- =====================================================================
-- Hospital Management System — Enhanced Production Schema
-- Run this AFTER the base schema.sql to add production features
-- =====================================================================

-- ---------- Medical Records ----------
create table if not exists medical_records (
  id uuid primary key default uuid_generate_v4(),
  patient_id uuid not null references profiles(id) on delete cascade,
  doctor_id uuid not null references doctors(id) on delete restrict,
  appointment_id uuid references appointments(id) on delete set null,
  diagnosis text not null,
  symptoms text,
  prescription jsonb, -- { medications: [...], instructions: "..." }
  notes text,
  attachments text[], -- Supabase Storage URLs
  vitals jsonb, -- { bp: "120/80", temp: "98.6", pulse: "72", weight: "70" }
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_medical_records_patient on medical_records (patient_id, created_at desc);
create index idx_medical_records_doctor on medical_records (doctor_id, created_at desc);

-- ---------- Prescriptions (detailed) ----------
create table if not exists prescriptions (
  id uuid primary key default uuid_generate_v4(),
  medical_record_id uuid not null references medical_records(id) on delete cascade,
  patient_id uuid not null references profiles(id) on delete cascade,
  doctor_id uuid not null references doctors(id) on delete restrict,
  medications jsonb not null, -- [{ name, dosage, frequency, duration, instructions }]
  special_instructions text,
  issued_at timestamptz not null default now(),
  valid_until date,
  is_active boolean default true
);

create index idx_prescriptions_patient on prescriptions (patient_id, issued_at desc);

-- ---------- Notifications ----------
create type notification_type as enum (
  'appointment_reminder',
  'appointment_confirmed',
  'appointment_cancelled',
  'queue_update',
  'prescription_ready',
  'test_result_ready',
  'payment_reminder'
);

create table if not exists notifications (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references profiles(id) on delete cascade,
  type notification_type not null,
  title text not null,
  message text not null,
  action_url text,
  read boolean not null default false,
  metadata jsonb,
  created_at timestamptz not null default now()
);

create index idx_notifications_user on notifications (user_id, created_at desc);
create index idx_notifications_unread on notifications (user_id, read) where read = false;

-- ---------- Activity Logs (audit trail) ----------
create table if not exists activity_logs (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references profiles(id) on delete set null,
  action text not null, -- 'appointment_created', 'record_updated', 'login'
  entity_type text, -- 'appointment', 'medical_record', etc.
  entity_id uuid,
  metadata jsonb,
  ip_address inet,
  user_agent text,
  created_at timestamptz not null default now()
);

create index idx_activity_logs_user on activity_logs (user_id, created_at desc);
create index idx_activity_logs_entity on activity_logs (entity_type, entity_id);
create index idx_activity_logs_action on activity_logs (action, created_at desc);

-- ---------- Hospital Settings ----------
create table if not exists hospital_settings (
  key text primary key,
  value jsonb not null,
  description text,
  updated_by uuid references profiles(id),
  updated_at timestamptz not null default now()
);

-- Insert default settings
insert into hospital_settings (key, value, description) values
  ('hospital_name', '"MediQueue Hospital"', 'Hospital name displayed in the system'),
  ('working_hours', '{"start": "09:00", "end": "18:00"}', 'Default hospital working hours'),
  ('slot_duration', '15', 'Default appointment slot duration in minutes'),
  ('avg_consultation_time', '15', 'Average consultation time for ETA calculations'),
  ('max_advance_booking_days', '30', 'Maximum days in advance for booking'),
  ('emergency_mode', 'false', 'Emergency mode toggle'),
  ('notifications_enabled', 'true', 'Enable/disable notifications'),
  ('payment_required', 'false', 'Require payment before confirmation')
on conflict (key) do nothing;

-- ---------- Reviews & Ratings ----------
create table if not exists reviews (
  id uuid primary key default uuid_generate_v4(),
  patient_id uuid not null references profiles(id) on delete cascade,
  doctor_id uuid not null references doctors(id) on delete cascade,
  appointment_id uuid not null references appointments(id) on delete cascade,
  rating smallint not null check (rating between 1 and 5),
  comment text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (patient_id, appointment_id)
);

create index idx_reviews_doctor on reviews (doctor_id, created_at desc);
create index idx_reviews_rating on reviews (doctor_id, rating);

-- Trigger to update doctor rating after review
create or replace function update_doctor_rating()
returns trigger as $$
begin
  update doctors
  set 
    rating = (
      select round(avg(rating)::numeric, 2)
      from reviews
      where doctor_id = new.doctor_id
    ),
    total_reviews = (
      select count(*)
      from reviews
      where doctor_id = new.doctor_id
    )
  where id = new.doctor_id;
  
  return new;
end;
$$ language plpgsql;

create trigger trg_update_doctor_rating
after insert or update on reviews
for each row execute function update_doctor_rating();

-- ---------- Enhanced Appointments Table ----------
alter table appointments add column if not exists check_in_time timestamptz;
alter table appointments add column if not exists consultation_start_time timestamptz;
alter table appointments add column if not exists consultation_end_time timestamptz;
alter table appointments add column if not exists notes text;
alter table appointments add column if not exists payment_status text default 'pending';
alter table appointments add column if not exists payment_amount numeric(10,2);
alter table appointments add column if not exists payment_method text;
alter table appointments add column if not exists payment_transaction_id text;
alter table appointments add column if not exists updated_at timestamptz default now();

-- Index for payment tracking
create index if not exists idx_appointments_payment on appointments (payment_status, appointment_date);

-- ---------- Enhanced Profiles Table ----------
alter table profiles add column if not exists date_of_birth date;
alter table profiles add column if not exists gender text;
alter table profiles add column if not exists blood_group text;
alter table profiles add column if not exists address text;
alter table profiles add column if not exists emergency_contact text;
alter table profiles add column if not exists avatar_url text;
alter table profiles add column if not exists updated_at timestamptz default now();

-- ---------- Enhanced Doctors Table ----------
alter table doctors add column if not exists bio text;
alter table doctors add column if not exists qualification text;
alter table doctors add column if not exists experience_years int;
alter table doctors add column if not exists rating numeric(3,2) default 0.0;
alter table doctors add column if not exists total_reviews int default 0;
alter table doctors add column if not exists is_available boolean default true;
alter table doctors add column if not exists updated_at timestamptz default now();

-- ---------- Document Storage ----------
create table if not exists documents (
  id uuid primary key default uuid_generate_v4(),
  patient_id uuid not null references profiles(id) on delete cascade,
  medical_record_id uuid references medical_records(id) on delete cascade,
  file_name text not null,
  file_type text not null,
  file_size bigint,
  storage_path text not null, -- Supabase Storage path
  uploaded_by uuid references profiles(id),
  description text,
  created_at timestamptz not null default now()
);

create index idx_documents_patient on documents (patient_id, created_at desc);
create index idx_documents_record on documents (medical_record_id);

-- ---------- Queue Management ----------
create table if not exists queue_status (
  id uuid primary key default uuid_generate_v4(),
  appointment_id uuid not null references appointments(id) on delete cascade unique,
  current_position int not null,
  estimated_wait_minutes int,
  status text not null default 'waiting', -- 'waiting', 'in_consultation', 'completed'
  notified_at timestamptz,
  updated_at timestamptz not null default now()
);

create index idx_queue_appointment on queue_status (appointment_id);

-- Function to update queue positions
create or replace function update_queue_positions(doc_id uuid, appt_date date)
returns void as $$
begin
  with ranked_appointments as (
    select 
      a.id,
      row_number() over (order by a.token_number) as new_position
    from appointments a
    where 
      a.doctor_id = doc_id
      and a.appointment_date = appt_date
      and a.status in ('confirmed', 'pending')
  )
  update queue_status qs
  set 
    current_position = ra.new_position,
    updated_at = now()
  from ranked_appointments ra
  where qs.appointment_id = ra.id;
end;
$$ language plpgsql;

-- ---------- RLS Policies for New Tables ----------

-- Medical records
alter table medical_records enable row level security;

create policy "medical_records_select"
  on medical_records for select
  using (
    patient_id = auth.uid()
    or exists (select 1 from doctors d where d.id = doctor_id and d.profile_id = auth.uid())
    or public.is_admin()
  );

create policy "medical_records_insert_doctor"
  on medical_records for insert
  with check (
    exists (select 1 from doctors d where d.id = doctor_id and d.profile_id = auth.uid())
    or public.is_admin()
  );

create policy "medical_records_update_doctor"
  on medical_records for update
  using (
    exists (select 1 from doctors d where d.id = doctor_id and d.profile_id = auth.uid())
    or public.is_admin()
  );

-- Prescriptions
alter table prescriptions enable row level security;

create policy "prescriptions_select"
  on prescriptions for select
  using (
    patient_id = auth.uid()
    or exists (select 1 from doctors d where d.id = doctor_id and d.profile_id = auth.uid())
    or public.is_admin()
  );

create policy "prescriptions_insert_doctor"
  on prescriptions for insert
  with check (
    exists (select 1 from doctors d where d.id = doctor_id and d.profile_id = auth.uid())
  );

-- Notifications
alter table notifications enable row level security;

create policy "notifications_select_own"
  on notifications for select
  using (user_id = auth.uid());

create policy "notifications_update_own"
  on notifications for update
  using (user_id = auth.uid());

-- Reviews
alter table reviews enable row level security;

create policy "reviews_select_all"
  on reviews for select
  using (true);

create policy "reviews_insert_patient"
  on reviews for insert
  with check (patient_id = auth.uid());

create policy "reviews_update_own"
  on reviews for update
  using (patient_id = auth.uid());

-- Documents
alter table documents enable row level security;

create policy "documents_select"
  on documents for select
  using (
    patient_id = auth.uid()
    or exists (
      select 1 from medical_records mr
      join doctors d on d.id = mr.doctor_id
      where mr.id = documents.medical_record_id
      and d.profile_id = auth.uid()
    )
    or public.is_admin()
  );

create policy "documents_insert"
  on documents for insert
  with check (
    patient_id = auth.uid()
    or public.is_admin()
  );

-- Activity logs (admin only)
alter table activity_logs enable row level security;

create policy "activity_logs_admin_only"
  on activity_logs for select
  using (public.is_admin());

-- Hospital settings (admin only)
alter table hospital_settings enable row level security;

create policy "settings_read_all"
  on hospital_settings for select
  using (true);

create policy "settings_write_admin"
  on hospital_settings for all
  using (public.is_admin());

-- Queue status (public read, doctor/admin write)
alter table queue_status enable row level security;

create policy "queue_select_all"
  on queue_status for select
  using (true);

create policy "queue_write_doctor_admin"
  on queue_status for all
  using (
    exists (
      select 1 from appointments a
      join doctors d on d.id = a.doctor_id
      where a.id = queue_status.appointment_id
      and d.profile_id = auth.uid()
    )
    or public.is_admin()
  );

-- ---------- Triggers for updated_at ----------

create or replace function update_updated_at_column()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- Apply to tables
create trigger update_profiles_updated_at before update on profiles
  for each row execute function update_updated_at_column();

create trigger update_doctors_updated_at before update on doctors
  for each row execute function update_updated_at_column();

create trigger update_appointments_updated_at before update on appointments
  for each row execute function update_updated_at_column();

create trigger update_medical_records_updated_at before update on medical_records
  for each row execute function update_updated_at_column();

-- ---------- Helper Functions ----------

-- Get today's queue for a doctor
create or replace function get_doctor_queue(doc_id uuid, appt_date date default current_date)
returns table (
  appointment_id uuid,
  token_number int,
  patient_name text,
  patient_phone text,
  appointment_time time,
  status appointment_status,
  check_in_time timestamptz,
  queue_position int,
  estimated_wait_minutes int
) as $$
begin
  return query
  select 
    a.id,
    a.token_number,
    p.full_name,
    p.phone,
    a.appointment_time,
    a.status,
    a.check_in_time,
    qs.current_position,
    qs.estimated_wait_minutes
  from appointments a
  join profiles p on p.id = a.patient_id
  left join queue_status qs on qs.appointment_id = a.id
  where 
    a.doctor_id = doc_id
    and a.appointment_date = appt_date
  order by a.token_number;
end;
$$ language plpgsql security definer;

-- Get patient's upcoming appointments
create or replace function get_patient_upcoming_appointments(pat_id uuid)
returns table (
  appointment_id uuid,
  token_number int,
  doctor_name text,
  department_name text,
  appointment_date date,
  appointment_time time,
  status appointment_status,
  queue_position int,
  estimated_wait_minutes int
) as $$
begin
  return query
  select 
    a.id,
    a.token_number,
    dp.full_name,
    dept.name,
    a.appointment_date,
    a.appointment_time,
    a.status,
    qs.current_position,
    qs.estimated_wait_minutes
  from appointments a
  join doctors d on d.id = a.doctor_id
  join profiles dp on dp.id = d.profile_id
  join departments dept on dept.id = a.department_id
  left join queue_status qs on qs.appointment_id = a.id
  where 
    a.patient_id = pat_id
    and a.appointment_date >= current_date
    and a.status not in ('cancelled', 'completed')
  order by a.appointment_date, a.appointment_time;
end;
$$ language plpgsql security definer;

-- Calculate next available slot for a doctor
create or replace function get_next_available_slot(
  doc_id uuid,
  from_date date default current_date
)
returns table (
  available_date date,
  available_time time,
  slot_count int
) as $$
declare
  doc_slot_duration int;
  check_date date;
  max_days int := 30;
begin
  -- Get doctor's slot duration
  select slot_duration_minutes into doc_slot_duration
  from doctors where id = doc_id;
  
  check_date := from_date;
  
  -- Loop through next 30 days
  while check_date <= from_date + max_days loop
    return query
    with day_availability as (
      select 
        da.start_time,
        da.end_time
      from doctor_availability da
      where 
        da.doctor_id = doc_id
        and da.day_of_week = extract(dow from check_date)::smallint
    ),
    booked_times as (
      select appointment_time
      from appointments
      where 
        doctor_id = doc_id
        and appointment_date = check_date
        and status in ('pending', 'confirmed')
    )
    select 
      check_date as available_date,
      gs.slot_time as available_time,
      1 as slot_count
    from day_availability da
    cross join lateral generate_series(
      da.start_time,
      da.end_time - (doc_slot_duration || ' minutes')::interval,
      (doc_slot_duration || ' minutes')::interval
    ) as gs(slot_time)
    where gs.slot_time not in (select appointment_time from booked_times)
    order by gs.slot_time
    limit 10;
    
    check_date := check_date + 1;
  end loop;
end;
$$ language plpgsql security definer;

-- =====================================================================
-- Sample Data for Development (optional)
-- =====================================================================

-- Insert sample departments (if not exists)
insert into departments (name, description) values
  ('Cardiology', 'Heart and cardiovascular system'),
  ('Orthopedics', 'Bones, joints, and muscles'),
  ('Pediatrics', 'Healthcare for infants, children, and adolescents'),
  ('Dermatology', 'Skin, hair, and nails'),
  ('Neurology', 'Brain and nervous system')
on conflict (name) do nothing;

