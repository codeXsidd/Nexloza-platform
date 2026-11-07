-- Migration: 00004_devices
-- Device management, credentials, and groups

create type public.hardware_platform as enum (
  'esp32', 'esp8266', 'raspberry_pi', 'arduino', 'generic_mqtt', 'other'
);

create table if not exists public.devices (
  id uuid default gen_random_uuid() primary key,
  project_id uuid references public.projects(id) on delete cascade not null,
  name text not null,
  description text,
  device_type text not null default 'generic',
  hardware_platform public.hardware_platform not null default 'esp32',
  firmware_version text,
  mac_address text,
  ip_address text,
  is_online boolean default false not null,
  last_seen_at timestamptz,
  metadata jsonb default '{}',
  tags text[] default '{}',
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null
);

create index idx_devices_project on public.devices (project_id);
create index idx_devices_online on public.devices (is_online);
create index idx_devices_mac on public.devices (mac_address) where mac_address is not null;

create table if not exists public.device_credentials (
  id uuid default gen_random_uuid() primary key,
  device_id uuid references public.devices(id) on delete cascade not null,
  api_key text not null unique,
  secret_hash text not null,
  is_active boolean default true not null,
  expires_at timestamptz,
  last_used_at timestamptz,
  created_at timestamptz default now() not null
);

create index idx_device_creds_apikey on public.device_credentials (api_key) where is_active = true;
create index idx_device_creds_device on public.device_credentials (device_id);

create table if not exists public.device_groups (
  id uuid default gen_random_uuid() primary key,
  project_id uuid references public.projects(id) on delete cascade not null,
  name text not null,
  description text,
  icon text,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null
);

create index idx_device_groups_project on public.device_groups (project_id);

create table if not exists public.device_group_members (
  device_group_id uuid references public.device_groups(id) on delete cascade not null,
  device_id uuid references public.devices(id) on delete cascade not null,
  added_at timestamptz default now() not null,
  primary key (device_group_id, device_id)
);

alter table public.devices enable row level security;
alter table public.device_credentials enable row level security;
alter table public.device_groups enable row level security;
alter table public.device_group_members enable row level security;

-- Devices: project members can view, developers+ can modify
create policy "Project members can view devices"
  on public.devices for select
  using (public.is_project_member(project_id));

create policy "Project developers can create devices"
  on public.devices for insert
  with check (public.can_modify_project(project_id));

create policy "Project developers can update devices"
  on public.devices for update
  using (public.can_modify_project(project_id));

create policy "Project developers can delete devices"
  on public.devices for delete
  using (public.can_modify_project(project_id));

-- Device credentials: only visible to project devs+
create policy "Project developers can view device credentials"
  on public.device_credentials for select
  using (
    exists (
      select 1 from public.devices d
      where d.id = device_id and public.can_modify_project(d.project_id)
    )
  );

create policy "Project developers can manage device credentials"
  on public.device_credentials for insert
  with check (
    exists (
      select 1 from public.devices d
      where d.id = device_id and public.can_modify_project(d.project_id)
    )
  );

create policy "Project developers can update device credentials"
  on public.device_credentials for update
  using (
    exists (
      select 1 from public.devices d
      where d.id = device_id and public.can_modify_project(d.project_id)
    )
  );

create policy "Project developers can delete device credentials"
  on public.device_credentials for delete
  using (
    exists (
      select 1 from public.devices d
      where d.id = device_id and public.can_modify_project(d.project_id)
    )
  );

-- Device groups
create policy "Project members can view device groups"
  on public.device_groups for select
  using (public.is_project_member(project_id));

create policy "Project developers can manage device groups"
  on public.device_groups for all
  using (public.can_modify_project(project_id));

-- Device group members
create policy "Project members can view group members"
  on public.device_group_members for select
  using (
    exists (
      select 1 from public.device_groups dg
      where dg.id = device_group_id and public.is_project_member(dg.project_id)
    )
  );

create policy "Project developers can manage group members"
  on public.device_group_members for all
  using (
    exists (
      select 1 from public.device_groups dg
      where dg.id = device_group_id and public.can_modify_project(dg.project_id)
    )
  );

create trigger devices_updated_at
  before update on public.devices
  for each row execute function public.update_updated_at();

create trigger device_groups_updated_at
  before update on public.device_groups
  for each row execute function public.update_updated_at();
