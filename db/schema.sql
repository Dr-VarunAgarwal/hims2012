-- HIMS MBBS 2012 reunion: database schema (Postgres on Supabase)
-- Run this whole file once in: Supabase dashboard > SQL Editor > New query > Run.
-- Safe to re-run: every statement is idempotent or drops first.

-- ---------------------------------------------------------------------------
-- 1. TABLES
-- A table = one kind of thing. A row = one instance. A column = one attribute.
-- ---------------------------------------------------------------------------

-- PUBLIC profile: anyone visiting the site may read this (it powers the directory).
create table if not exists attendees (
  id                    text primary key,            -- 'ATT-001' (primary key: unique, never null)
  batch_no              text not null unique,        -- 'Doctor #001'
  name                  text not null,
  is_female             boolean not null default false,
  maiden_name           text,
  qualifications        text,
  working_at            text,
  city_based            text,
  personal_statement    text,
  alumni_photo_url      text,
  attendance_status     text not null default 'Not Responded',
  is_dormant            boolean not null default true,   -- true until the person fills their profile
  adults                int  not null default 1 check (adults >= 0),
  kids                  int  not null default 0 check (kids  >= 0),
  is_intra_batch_couple boolean not null default false,
  -- Foreign key: must point at another real attendee (or be null). The database
  -- refuses a spouse id that doesn't exist; the browser can't "forget" to check.
  linked_batch_spouse_id text references attendees(id) on delete set null,
  updated_at            timestamptz not null default now()
);

-- PRIVATE details: phone, email, money, PIN. One row per attendee (1-to-1 with attendees).
create table if not exists attendee_private (
  attendee_id        text primary key references attendees(id) on delete cascade,
  email              text,
  phone              text,
  dob                date,
  package            text,
  amount_expected    int not null default 0,
  amount_paid        int not null default 0,
  payment_status     text,
  payment_ref        text,
  hoodie_sizes       text,
  food_pref          text,
  shuttle_request    text,
  room_booking       text,
  spouse_name        text,
  spouse_profession  text,
  children_details   jsonb,                           -- flexible list; fine as JSON
  notes              text,
  pin_hash           text                              -- bcrypt hash, never the PIN itself
);

create table if not exists expenses (
  id         text primary key,
  date       date not null,
  category   text not null,
  title      text not null,
  vendor     text,
  added_by   text,
  amount     int  not null check (amount >= 0),
  status     text not null default 'Paid',
  paid_by    text,
  receipt_url text,
  notes      text
);

-- Append-only audit trail: rows are inserted, never edited.
create table if not exists change_log (
  id        bigint generated always as identity primary key,
  at        timestamptz not null default now(),
  author    text,
  action    text not null,
  entity    text,
  details   text
);

-- Speeds up directory search by name (an index = a sorted lookup structure).
create index if not exists attendees_name_idx on attendees (lower(name));

-- ---------------------------------------------------------------------------
-- 2. ROW LEVEL SECURITY (RLS)
-- The browser talks to the database directly with a PUBLIC key, so the database
-- itself must decide who may do what. RLS on + no policy = nobody gets in.
-- ---------------------------------------------------------------------------
alter table attendees        enable row level security;
alter table attendee_private enable row level security;
alter table expenses         enable row level security;
alter table change_log       enable row level security;

drop policy if exists "directory is public" on attendees;
create policy "directory is public" on attendees for select using (true);

-- attendee_private / expenses: no policy => invisible to the public key.
-- change_log: public may read (transparency), but cannot write directly.
drop policy if exists "audit log is readable" on change_log;
create policy "audit log is readable" on change_log for select using (true);

-- ---------------------------------------------------------------------------
-- 3. FUNCTIONS (the only door for writing)
-- "security definer" = runs with the owner's rights, so it can touch tables the
-- caller can't. It checks the PIN first, so that is where the rules live.
-- ---------------------------------------------------------------------------
create extension if not exists pgcrypto;

-- Save a profile. First save sets the PIN; later saves must supply the same PIN.
create or replace function save_profile(p_id text, p_pin text, p_public jsonb, p_private jsonb)
returns void
language plpgsql security definer set search_path = public, extensions
as $$
declare
  stored text;
begin
  if p_pin is null or length(p_pin) < 4 then
    raise exception 'PIN must be at least 4 characters';
  end if;

  insert into attendee_private (attendee_id) values (p_id) on conflict do nothing;
  select pin_hash into stored from attendee_private where attendee_id = p_id;

  if stored is not null and stored <> crypt(p_pin, stored) then
    raise exception 'Wrong PIN';
  end if;
  if stored is null then
    update attendee_private set pin_hash = crypt(p_pin, gen_salt('bf')) where attendee_id = p_id;
  end if;

  update attendees set
    name               = coalesce(p_public->>'name', name),
    maiden_name        = coalesce(p_public->>'maiden_name', maiden_name),
    qualifications     = coalesce(p_public->>'qualifications', qualifications),
    working_at         = coalesce(p_public->>'working_at', working_at),
    city_based         = coalesce(p_public->>'city_based', city_based),
    personal_statement = coalesce(p_public->>'personal_statement', personal_statement),
    alumni_photo_url   = coalesce(p_public->>'alumni_photo_url', alumni_photo_url),
    attendance_status  = coalesce(p_public->>'attendance_status', attendance_status),
    adults             = coalesce((p_public->>'adults')::int, adults),
    kids               = coalesce((p_public->>'kids')::int, kids),
    is_dormant         = false,
    updated_at         = now()
  where id = p_id;

  update attendee_private set
    email          = coalesce(p_private->>'email', email),
    phone          = coalesce(p_private->>'phone', phone),
    package        = coalesce(p_private->>'package', package),
    hoodie_sizes   = coalesce(p_private->>'hoodie_sizes', hoodie_sizes),
    food_pref      = coalesce(p_private->>'food_pref', food_pref),
    shuttle_request= coalesce(p_private->>'shuttle_request', shuttle_request),
    room_booking   = coalesce(p_private->>'room_booking', room_booking),
    spouse_name    = coalesce(p_private->>'spouse_name', spouse_name),
    children_details = coalesce(p_private->'children_details', children_details)
  where attendee_id = p_id;

  insert into change_log (author, action, entity, details)
  values (p_public->>'name', 'Furnished Profile', p_id, 'Profile saved');
end $$;

-- Read your own private row back (needs the PIN).
create or replace function get_my_private(p_id text, p_pin text)
returns attendee_private
language plpgsql security definer set search_path = public, extensions
as $$
declare r attendee_private;
begin
  select * into r from attendee_private where attendee_id = p_id;
  if r.pin_hash is null or r.pin_hash <> crypt(p_pin, r.pin_hash) then
    raise exception 'Wrong PIN';
  end if;
  r.pin_hash := null;
  return r;
end $$;

grant execute on function save_profile(text, text, jsonb, jsonb) to anon;
grant execute on function get_my_private(text, text) to anon;
