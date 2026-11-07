-- Migration: 00008_automations
-- Automation engine: triggers, conditions, actions, executions

create type public.trigger_type as enum (
  'sensor_threshold', 'device_state_change', 'schedule', 'time',
  'webhook', 'manual', 'device_online', 'device_offline'
);

create type public.condition_type as enum (
  'value_comparison', 'time_window', 'device_status',
  'compound_and', 'compound_or'
);

create type public.action_type as enum (
  'device_command', 'notification', 'email', 'webhook',
  'run_scene', 'run_automation', 'ai_recommendation'
);

create type public.execution_status as enum (
  'running', 'completed', 'failed', 'cancelled'
);

create table if not exists public.automations (
  id uuid default gen_random_uuid() primary key,
  project_id uuid references public.projects(id) on delete cascade not null,
  name text not null,
  description text,
  is_enabled boolean default true not null,
  priority int default 0 not null,
  cooldown_seconds int default 60 not null,
  max_executions_per_hour int default 60 not null,
  last_executed_at timestamptz,
  execution_count bigint default 0 not null,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null
);

create index idx_automations_project on public.automations (project_id);
create index idx_automations_enabled on public.automations (is_enabled) where is_enabled = true;

create table if not exists public.automation_triggers (
  id uuid default gen_random_uuid() primary key,
  automation_id uuid references public.automations(id) on delete cascade not null,
  trigger_type public.trigger_type not null,
  config jsonb not null default '{}',
  -- config examples:
  -- sensor_threshold: {"device_id":"...","sensor_key":"temp","operator":"gt","value":30}
  -- schedule: {"cron":"0 8 * * *","timezone":"UTC"}
  -- device_online/offline: {"device_id":"..."}
  -- webhook: {"secret":"...","path":"/hook/abc"}
  is_active boolean default true not null,
  created_at timestamptz default now() not null
);

create index idx_triggers_automation on public.automation_triggers (automation_id);

create table if not exists public.automation_conditions (
  id uuid default gen_random_uuid() primary key,
  automation_id uuid references public.automations(id) on delete cascade not null,
  condition_type public.condition_type not null,
  config jsonb not null default '{}',
  -- config examples:
  -- value_comparison: {"sensor_key":"humidity","operator":"between","min":30,"max":70}
  -- time_window: {"start":"08:00","end":"22:00","timezone":"UTC","days":["mon","tue"]}
  -- device_status: {"device_id":"...","is_online":true}
  sort_order int default 0 not null,
  created_at timestamptz default now() not null
);

create index idx_conditions_automation on public.automation_conditions (automation_id);

create table if not exists public.automation_actions (
  id uuid default gen_random_uuid() primary key,
  automation_id uuid references public.automations(id) on delete cascade not null,
  action_type public.action_type not null,
  config jsonb not null default '{}',
  -- config examples:
  -- device_command: {"device_id":"...","command":"set_state","payload":{"relay":true}}
  -- notification: {"title":"Alert","body":"Temp too high","severity":"warning"}
  -- webhook: {"url":"https://...","method":"POST","headers":{},"body_template":"..."}
  -- run_scene: {"scene_id":"..."}
  sort_order int default 0 not null,
  delay_seconds int default 0 not null,
  created_at timestamptz default now() not null
);

create index idx_actions_automation on public.automation_actions (automation_id);

create table if not exists public.automation_executions (
  id uuid default gen_random_uuid() primary key,
  automation_id uuid references public.automations(id) on delete cascade not null,
  trigger_id uuid references public.automation_triggers(id) on delete set null,
  trigger_data jsonb default '{}',
  status public.execution_status not null default 'running',
  started_at timestamptz default now() not null,
  completed_at timestamptz,
  error_message text,
  actions_executed jsonb default '[]',
  -- [{action_id, status, result, executed_at}]
  duration_ms int
);

create index idx_executions_automation on public.automation_executions (automation_id, started_at desc);
create index idx_executions_status on public.automation_executions (status) where status = 'running';

alter table public.automations enable row level security;
alter table public.automation_triggers enable row level security;
alter table public.automation_conditions enable row level security;
alter table public.automation_actions enable row level security;
alter table public.automation_executions enable row level security;

-- Automations RLS
create policy "Project members can view automations"
  on public.automations for select
  using (public.is_project_member(project_id));

create policy "Project developers can create automations"
  on public.automations for insert
  with check (public.can_modify_project(project_id));

create policy "Project developers can update automations"
  on public.automations for update
  using (public.can_modify_project(project_id));

create policy "Project developers can delete automations"
  on public.automations for delete
  using (public.can_modify_project(project_id));

-- Triggers, conditions, actions: inherit from automation
create policy "View triggers" on public.automation_triggers for select
  using (exists (select 1 from public.automations a where a.id = automation_id and public.is_project_member(a.project_id)));
create policy "Manage triggers" on public.automation_triggers for all
  using (exists (select 1 from public.automations a where a.id = automation_id and public.can_modify_project(a.project_id)));

create policy "View conditions" on public.automation_conditions for select
  using (exists (select 1 from public.automations a where a.id = automation_id and public.is_project_member(a.project_id)));
create policy "Manage conditions" on public.automation_conditions for all
  using (exists (select 1 from public.automations a where a.id = automation_id and public.can_modify_project(a.project_id)));

create policy "View actions" on public.automation_actions for select
  using (exists (select 1 from public.automations a where a.id = automation_id and public.is_project_member(a.project_id)));
create policy "Manage actions" on public.automation_actions for all
  using (exists (select 1 from public.automations a where a.id = automation_id and public.can_modify_project(a.project_id)));

create policy "View executions" on public.automation_executions for select
  using (exists (select 1 from public.automations a where a.id = automation_id and public.is_project_member(a.project_id)));

create trigger automations_updated_at
  before update on public.automations
  for each row execute function public.update_updated_at();
