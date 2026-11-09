-- Migration: 00018_virtual_devices_phase7
-- Phase 7: Virtual Devices and Digital Twin System
-- Adds virtual device support to existing devices table and creates digital twin state tracking

-- Add virtual device markers to existing devices table
alter table public.devices
  add column if not exists is_virtual boolean default false not null,
  add column if not exists simulation_profile text;

-- Index for filtering virtual devices per project
create index if not exists idx_devices_virtual
  on public.devices (project_id, is_virtual) where is_virtual = true;

-- Digital Twin state table — tracks desired vs reported state per device
create table if not exists public.device_twin_state (
  id uuid default gen_random_uuid() primary key,
  device_id uuid references public.devices(id) on delete cascade not null unique,
  reported_state jsonb default '{}' not null,
  desired_state jsonb default '{}' not null,
  reported_version int default 0 not null,
  desired_version int default 0 not null,
  reported_at timestamptz,
  desired_at timestamptz,
  sync_status text default 'synced' not null,
  last_sync_at timestamptz,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null,
  constraint valid_sync_status check (sync_status in ('synced', 'pending', 'failed', 'stale'))
);

create index idx_twin_state_device on public.device_twin_state (device_id);
create index idx_twin_state_sync on public.device_twin_state (sync_status)
  where sync_status != 'synced';

alter table public.device_twin_state enable row level security;

-- Twin state: project members can view (via device → project join)
create policy "Project members can view twin state"
  on public.device_twin_state for select
  using (
    exists (
      select 1 from public.devices d
      where d.id = device_id and public.is_project_member(d.project_id)
    )
  );

-- Twin state: project developers can create
create policy "Project developers can create twin state"
  on public.device_twin_state for insert
  with check (
    exists (
      select 1 from public.devices d
      where d.id = device_id and public.can_modify_project(d.project_id)
    )
  );

-- Twin state: project developers can update
create policy "Project developers can update twin state"
  on public.device_twin_state for update
  using (
    exists (
      select 1 from public.devices d
      where d.id = device_id and public.can_modify_project(d.project_id)
    )
  );

-- Twin state: project developers can delete
create policy "Project developers can delete twin state"
  on public.device_twin_state for delete
  using (
    exists (
      select 1 from public.devices d
      where d.id = device_id and public.can_modify_project(d.project_id)
    )
  );

create trigger twin_state_updated_at
  before update on public.device_twin_state
  for each row execute function public.update_updated_at();
