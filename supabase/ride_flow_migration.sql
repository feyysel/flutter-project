-- ============================================================
-- DriveOn — Full ride lifecycle migration
-- Run this once in the Supabase SQL Editor.
-- Idempotent: safe to run multiple times.
-- ============================================================

-- 1. Driver payout / bank details ------------------------------
alter table public.profiles
  add column if not exists bank_name text,
  add column if not exists bank_account_holder text,
  add column if not exists bank_account_number text;

-- 2. Trip scheduling + trip state on posts ---------------------
alter table public.posts
  add column if not exists departure_at timestamptz,
  add column if not exists trip_status text not null default 'scheduled',
  add column if not exists trip_started_at timestamptz,
  add column if not exists trip_finished_at timestamptz;

-- 3. Payment / ticket / pickup / dropoff state on ride_requests
alter table public.ride_requests
  add column if not exists pay_bank_name text,
  add column if not exists pay_bank_holder text,
  add column if not exists pay_account_number text,
  add column if not exists payment_receipt_url text,
  add column if not exists payment_txn text,
  add column if not exists payment_submitted_at timestamptz,
  add column if not exists payment_verified_at timestamptz,
  add column if not exists ticket_code text,
  add column if not exists picked_at timestamptz,
  add column if not exists dropped_at timestamptz;

-- 4. Storage bucket for payment receipt screenshots ------------
insert into storage.buckets (id, name, public)
values ('payment-receipts', 'payment-receipts', true)
on conflict (id) do nothing;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage' and tablename = 'objects'
      and policyname = 'Public read payment receipts'
  ) then
    create policy "Public read payment receipts"
      on storage.objects for select
      using (bucket_id = 'payment-receipts');
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage' and tablename = 'objects'
      and policyname = 'Authenticated upload payment receipts'
  ) then
    create policy "Authenticated upload payment receipts"
      on storage.objects for insert
      to authenticated
      with check (bucket_id = 'payment-receipts');
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage' and tablename = 'objects'
      and policyname = 'Authenticated update payment receipts'
  ) then
    create policy "Authenticated update payment receipts"
      on storage.objects for update
      to authenticated
      using (bucket_id = 'payment-receipts');
  end if;
end $$;

-- 5. Realtime: add tables to the supabase_realtime publication -------------
-- Without this, live updates (status changes, new requests) never reach the app.
do $$
begin
  begin alter publication supabase_realtime add table public.posts;
  exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table public.ride_requests;
  exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table public.notifications;
  exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table public.profiles;
  exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table public.ride_history;
  exception when duplicate_object then null; end;
end $$;

-- 6. Allow updates on ride_requests by BOTH sides of the ride ---------------
-- Passengers update their rows (send receipts, share location).
-- Drivers update them too (verify payment, pickup/dropoff ticks,
-- and marking requests completed when the trip finishes).
do $$
begin
  drop policy if exists "Passengers can update own requests" on public.ride_requests;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'ride_requests'
      and policyname = 'Ride parties can update own requests'
  ) then
    create policy "Ride parties can update own requests"
      on public.ride_requests for update
      to authenticated
      using (auth.uid() = passenger_id or auth.uid() = driver_id)
      with check (auth.uid() = passenger_id or auth.uid() = driver_id);
  end if;
end $$;

-- 7. Allow drivers to save completed rides into history ---------------------
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'ride_history'
      and policyname = 'Authenticated insert ride history'
  ) then
    create policy "Authenticated insert ride history"
      on public.ride_history for insert
      to authenticated
      with check (auth.uid() = driver_id);
  end if;
end $$;

-- 8. Allow drivers to update their own posts (seats, trip status) -----------
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'posts'
      and policyname = 'Drivers update own posts'
  ) then
    create policy "Drivers update own posts"
      on public.posts for update
      to authenticated
      using (auth.uid() = driver_id)
      with check (auth.uid() = driver_id);
  end if;
end $$;

-- 9. Widen the status check constraint to cover the full ride lifecycle -----
do $$
begin
  begin
    alter table public.ride_requests drop constraint if exists ride_requests_status_check;
    alter table public.ride_requests add constraint ride_requests_status_check
      check (status in (
        'pending',
        'accepted',
        'declined',
        'cancelled',
        'payment_submitted',
        'confirmed',
        'picked_up',
        'dropped_off'
      ));
  exception when others then null;
  end;
end $$;

-- 10. Guarantee the full ride_history shape (Finish Trip depends on it) ------
create table if not exists public.ride_history (
  id uuid primary key default gen_random_uuid(),
  ride_id uuid,
  driver_id uuid,
  driver_name text default '',
  passenger_id uuid,
  passenger_name text default '',
  passenger_phone text default '',
  "from" text default '',
  "to" text default '',
  price text default '0',
  time text default '',
  ticket_code text default '',
  status text default 'completed',
  created_at timestamptz default now()
);

alter table public.ride_history enable row level security;

do $$
begin
  alter table public.ride_history add column if not exists driver_name text default '';
  alter table public.ride_history add column if not exists passenger_name text default '';
  alter table public.ride_history add column if not exists passenger_phone text default '';
  alter table public.ride_history add column if not exists "from" text default '';
  alter table public.ride_history add column if not exists "to" text default '';
  alter table public.ride_history add column if not exists price text default '0';
  alter table public.ride_history add column if not exists time text default '';
  alter table public.ride_history add column if not exists ticket_code text default '';
  alter table public.ride_history add column if not exists status text default 'completed';
end $$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'ride_history'
      and policyname = 'Ride parties read own history'
  ) then
    create policy "Ride parties read own history"
      on public.ride_history for select
      to authenticated
      using (auth.uid() = driver_id or auth.uid() = passenger_id);
  end if;
end $$;

do $$
begin
  drop policy if exists "Authenticated insert ride history" on public.ride_history;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'ride_history'
      and policyname = 'Drivers insert own history'
  ) then
    create policy "Drivers insert own history"
      on public.ride_history for insert
      to authenticated
      with check (auth.uid() = driver_id);
  end if;
end $$;
