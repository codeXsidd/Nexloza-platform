-- Firmware versions and OTA deployments

create table if not exists public.firmware_versions (
  id uuid default gen_random_uuid() primary key,
  project_id uuid references public.projects(id) on delete cascade,
  device_type text not null,
  version text not null,
  description text,
  file_url text,
  file_hash text,
  file_size bigint,
  is_stable boolean default false,
  created_at timestamptz default now() not null
);

create type ota_status as enum ('pending', 'downloading', 'installing', 'completed', 'failed', 'rolled_back');

create table if not exists public.ota_deployments (
  id uuid default gen_random_uuid() primary key,
  firmware_version_id uuid references public.firmware_versions(id) on delete cascade not null,
  device_id uuid references public.devices(id) on delete cascade,
  device_group_id uuid references public.device_groups(id) on delete cascade,
  status ota_status default 'pending',
  started_at timestamptz,
  completed_at timestamptz,
  error_message text,
  created_at timestamptz default now() not null,
  check (device_id is not null or device_group_id is not null)
);

alter table public.firmware_versions enable row level security;
alter table public.ota_deployments enable row level security;

create policy "Project members can view firmware"
  on public.firmware_versions for select
  using (project_id is null or project_id in (
    select project_id from public.project_members where user_id = auth.uid()
  ));

create policy "Admins can manage firmware"
  on public.firmware_versions for all
  using (project_id in (
    select project_id from public.project_members
    where user_id = auth.uid() and role in ('owner', 'admin')
  ));

create policy "Admins can manage OTA deployments"
  on public.ota_deployments for all
  using (firmware_version_id in (
    select fv.id from public.firmware_versions fv
    join public.project_members pm on pm.project_id = fv.project_id
    where pm.user_id = auth.uid() and pm.role in ('owner', 'admin')
  ));
