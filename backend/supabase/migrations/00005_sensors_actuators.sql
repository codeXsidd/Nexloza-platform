-- Migration: 00005_sensors_actuators
-- Sensor and actuator definitions

create type public.sensor_type as enum (
  'temperature', 'humidity', 'pressure', 'gas', 'smoke',
  'motion', 'ultrasonic', 'water_level', 'soil_moisture',
  'light', 'sound', 'vibration', 'current', 'voltage',
  'energy', 'gps', 'air_quality', 'ph', 'flow_rate',
  'weight', 'color', 'uv', 'magnetic', 'custom'
);

create type public.actuator_type as enum (
  'relay', 'light', 'fan', 'pump', 'motor', 'servo',
  'buzzer', 'switch', 'smart_plug', 'valve', 'heater',
  'cooler', 'lock', 'rgb_led', 'display', 'custom'
);

create type public.control_type as enum (
  'toggle', 'slider', 'numeric', 'multi_level', 'color', 'custom'
);

create table if not exists public.sensor_definitions (
  id uuid default gen_random_uuid() primary key,
  device_id uuid references public.devices(id) on delete cascade not null,
  project_id uuid references public.projects(id) on delete cascade not null,
  name text not null,
  sensor_type public.sensor_type not null default 'custom',
  unit text,
  telemetry_key text not null,
  sampling_interval_ms int default 60000,
  calibration jsonb default '{}',
  min_value double precision,
  max_value double precision,
  warning_threshold_low double precision,
  warning_threshold_high double precision,
  critical_threshold_low double precision,
  critical_threshold_high double precision,
  is_active boolean default true not null,
  metadata jsonb default '{}',
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null
);

create index idx_sensor_defs_device on public.sensor_definitions (device_id);
create index idx_sensor_defs_project on public.sensor_definitions (project_id);
create index idx_sensor_defs_key on public.sensor_definitions (device_id, telemetry_key);

create table if not exists public.actuator_definitions (
  id uuid default gen_random_uuid() primary key,
  device_id uuid references public.devices(id) on delete cascade not null,
  project_id uuid references public.projects(id) on delete cascade not null,
  name text not null,
  actuator_type public.actuator_type not null default 'custom',
  control_type public.control_type not null default 'toggle',
  telemetry_key text,
  command_key text not null,
  min_value double precision default 0,
  max_value double precision default 1,
  step double precision default 1,
  current_state jsonb default '{"value": 0, "is_on": false}',
  safety_limits jsonb default '{}',
  is_active boolean default true not null,
  metadata jsonb default '{}',
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null
);

create index idx_actuator_defs_device on public.actuator_definitions (device_id);
create index idx_actuator_defs_project on public.actuator_definitions (project_id);
create index idx_actuator_defs_key on public.actuator_definitions (device_id, command_key);

alter table public.sensor_definitions enable row level security;
alter table public.actuator_definitions enable row level security;

create policy "Project members can view sensors"
  on public.sensor_definitions for select
  using (public.is_project_member(project_id));

create policy "Project developers can create sensors"
  on public.sensor_definitions for insert
  with check (public.can_modify_project(project_id));

create policy "Project developers can update sensors"
  on public.sensor_definitions for update
  using (public.can_modify_project(project_id));

create policy "Project developers can delete sensors"
  on public.sensor_definitions for delete
  using (public.can_modify_project(project_id));

create policy "Project members can view actuators"
  on public.actuator_definitions for select
  using (public.is_project_member(project_id));

create policy "Project developers can create actuators"
  on public.actuator_definitions for insert
  with check (public.can_modify_project(project_id));

create policy "Project developers can update actuators"
  on public.actuator_definitions for update
  using (public.can_modify_project(project_id));

create policy "Project developers can delete actuators"
  on public.actuator_definitions for delete
  using (public.can_modify_project(project_id));

create trigger sensor_defs_updated_at
  before update on public.sensor_definitions
  for each row execute function public.update_updated_at();

create trigger actuator_defs_updated_at
  before update on public.actuator_definitions
  for each row execute function public.update_updated_at();
