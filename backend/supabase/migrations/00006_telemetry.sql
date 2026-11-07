-- Migration: 00006_telemetry
-- Telemetry storage, device commands, and command results

create table if not exists public.telemetry (
  id bigserial primary key,
  device_id uuid references public.devices(id) on delete cascade not null,
  sensor_key text not null,
  value_numeric double precision,
  value_text text,
  value_json jsonb,
  recorded_at timestamptz default now() not null,
  received_at timestamptz default now() not null
);

create index idx_telemetry_device_key_time
  on public.telemetry (device_id, sensor_key, recorded_at desc);
create index idx_telemetry_recorded
  on public.telemetry (recorded_at desc);

create type public.command_status as enum (
  'pending', 'sent', 'acknowledged', 'executed', 'failed', 'timeout'
);

create table if not exists public.device_commands (
  id uuid default gen_random_uuid() primary key,
  device_id uuid references public.devices(id) on delete cascade not null,
  issued_by uuid references public.profiles(id) on delete set null,
  command_type text not null,
  payload jsonb not null default '{}',
  status public.command_status not null default 'pending',
  sent_at timestamptz,
  acknowledged_at timestamptz,
  executed_at timestamptz,
  expires_at timestamptz default (now() + interval '5 minutes'),
  retry_count int default 0 not null,
  max_retries int default 3 not null,
  error_message text,
  created_at timestamptz default now() not null
);

create index idx_commands_device on public.device_commands (device_id, created_at desc);
create index idx_commands_status on public.device_commands (status) where status in ('pending', 'sent');

create table if not exists public.command_results (
  id uuid default gen_random_uuid() primary key,
  command_id uuid references public.device_commands(id) on delete cascade not null,
  device_id uuid references public.devices(id) on delete cascade not null,
  success boolean not null,
  result_data jsonb default '{}',
  error_message text,
  created_at timestamptz default now() not null
);

create index idx_command_results_command on public.command_results (command_id);

alter table public.telemetry enable row level security;
alter table public.device_commands enable row level security;
alter table public.command_results enable row level security;

-- Telemetry: project members can view, service role inserts via edge function
create policy "Project members can view telemetry"
  on public.telemetry for select
  using (
    exists (
      select 1 from public.devices d
      where d.id = device_id and public.is_project_member(d.project_id)
    )
  );

-- Commands: project members can view, developers can issue
create policy "Project members can view commands"
  on public.device_commands for select
  using (
    exists (
      select 1 from public.devices d
      where d.id = device_id and public.is_project_member(d.project_id)
    )
  );

create policy "Project developers can create commands"
  on public.device_commands for insert
  with check (
    exists (
      select 1 from public.devices d
      where d.id = device_id and public.can_modify_project(d.project_id)
    )
  );

create policy "Project developers can update commands"
  on public.device_commands for update
  using (
    exists (
      select 1 from public.devices d
      where d.id = device_id and public.can_modify_project(d.project_id)
    )
  );

-- Command results: same as telemetry
create policy "Project members can view command results"
  on public.command_results for select
  using (
    exists (
      select 1 from public.devices d
      where d.id = device_id and public.is_project_member(d.project_id)
    )
  );
