-- Migration: 00020_alarm_engine_phase9
-- Phase 9: Alarm Engine, Escalation and Notification System
-- Adds alarm management, escalation policies, notification outbox

-- ============================================================================
-- 1. Alarm severity and source enums
-- ============================================================================

create type public.alarm_severity as enum (
  'critical', 'high', 'medium', 'warning', 'informational'
);

create type public.alarm_status as enum (
  'active', 'acknowledged', 'cleared'
);

create type public.alarm_source as enum (
  'sensor_threshold',
  'repeated_telemetry',
  'device_offline',
  'stale_data',
  'twin_mismatch',
  'actuator_failure',
  'virtual_device_fault',
  'rule_action',
  'manual'
);

create type public.alarm_activity_type as enum (
  'created',
  'acknowledged',
  'escalated',
  'cleared',
  'severity_changed',
  'comment_added',
  'suppressed'
);

create type public.outbox_status as enum (
  'pending', 'processing', 'delivered', 'failed', 'dead_letter'
);

create type public.escalation_task_status as enum (
  'pending', 'executed', 'cancelled'
);

-- ============================================================================
-- 2. Alarms table — core alarm records
-- ============================================================================

create table if not exists public.alarms (
  id uuid default gen_random_uuid() primary key,
  alarm_key text not null,
  project_id uuid references public.projects(id) on delete cascade not null,
  device_id uuid references public.devices(id) on delete set null,
  organization_id uuid references public.organizations(id) on delete cascade not null,
  severity public.alarm_severity not null default 'warning',
  status public.alarm_status not null default 'active',
  source public.alarm_source not null default 'manual',
  title text not null,
  message text,
  category text not null default 'general',
  condition_value double precision,
  threshold_value double precision,
  hysteresis_clear_value double precision,
  acknowledged_by uuid references public.profiles(id) on delete set null,
  acknowledged_at timestamptz,
  cleared_by uuid references public.profiles(id) on delete set null,
  cleared_at timestamptz,
  cleared_reason text,
  occurrence_count int not null default 1,
  first_occurred_at timestamptz not null default now(),
  last_occurred_at timestamptz not null default now(),
  data jsonb default '{}',
  escalation_policy_id uuid,
  escalation_stage int,
  escalated_at timestamptz,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null,
  unique (alarm_key, project_id)
);

create index idx_alarms_project_status on public.alarms (project_id, status);
create index idx_alarms_project_severity on public.alarms (project_id, severity)
  where status = 'active';
create index idx_alarms_device on public.alarms (device_id, status)
  where device_id is not null;
create index idx_alarms_alarm_key on public.alarms (alarm_key, project_id);
create index idx_alarms_org on public.alarms (organization_id, status);
create index idx_alarms_active on public.alarms (project_id, created_at desc)
  where status = 'active';
create index idx_alarms_escalation on public.alarms (escalation_policy_id)
  where escalation_policy_id is not null and status = 'active';

alter table public.alarms enable row level security;

create policy "Project members can view alarms"
  on public.alarms for select
  using (public.is_project_member(project_id));

create policy "Project developers can create alarms"
  on public.alarms for insert
  with check (public.can_modify_project(project_id));

create policy "Project developers can update alarms"
  on public.alarms for update
  using (public.can_modify_project(project_id));

create policy "Project developers can delete alarms"
  on public.alarms for delete
  using (public.can_modify_project(project_id));

create trigger alarms_updated_at
  before update on public.alarms
  for each row execute function public.update_updated_at();

-- ============================================================================
-- 3. Alarm configurations — threshold rules for automatic alarm generation
-- ============================================================================

create table if not exists public.alarm_configurations (
  id uuid default gen_random_uuid() primary key,
  project_id uuid references public.projects(id) on delete cascade not null,
  device_id uuid references public.devices(id) on delete set null,
  organization_id uuid references public.organizations(id) on delete cascade not null,
  name text not null,
  source public.alarm_source not null default 'sensor_threshold',
  sensor_key text,
  condition_operator text not null default 'gt',
  threshold_value double precision,
  hysteresis_enabled boolean default false not null,
  hysteresis_clear_value double precision,
  debounce_seconds int default 0 not null,
  cooldown_seconds int default 60 not null,
  severity public.alarm_severity not null default 'warning',
  category text not null default 'general',
  message_template text,
  is_enabled boolean default true not null,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null,
  constraint alarm_config_operator_check
    check (condition_operator in ('gt', 'gte', 'lt', 'lte', 'eq', 'neq', 'between', 'outside'))
);

create index idx_alarm_configs_project on public.alarm_configurations (project_id, is_enabled);
create index idx_alarm_configs_device on public.alarm_configurations (device_id)
  where device_id is not null;

alter table public.alarm_configurations enable row level security;

create policy "Project members can view alarm configurations"
  on public.alarm_configurations for select
  using (public.is_project_member(project_id));

create policy "Project developers can create alarm configurations"
  on public.alarm_configurations for insert
  with check (public.can_modify_project(project_id));

create policy "Project developers can update alarm configurations"
  on public.alarm_configurations for update
  using (public.can_modify_project(project_id));

create policy "Project developers can delete alarm configurations"
  on public.alarm_configurations for delete
  using (public.can_modify_project(project_id));

create trigger alarm_configs_updated_at
  before update on public.alarm_configurations
  for each row execute function public.update_updated_at();

-- ============================================================================
-- 4. Alarm activity — audit trail
-- ============================================================================

create table if not exists public.alarm_activity (
  id uuid default gen_random_uuid() primary key,
  alarm_id uuid references public.alarms(id) on delete cascade not null,
  activity_type public.alarm_activity_type not null,
  performed_by uuid references public.profiles(id) on delete set null,
  comment text,
  previous_severity public.alarm_severity,
  new_severity public.alarm_severity,
  data jsonb default '{}',
  created_at timestamptz default now() not null
);

create index idx_alarm_activity_alarm on public.alarm_activity (alarm_id, created_at desc);
create index idx_alarm_activity_type on public.alarm_activity (activity_type, created_at desc);

alter table public.alarm_activity enable row level security;

create policy "Project members can view alarm activity"
  on public.alarm_activity for select
  using (exists (
    select 1 from public.alarms a
    where a.id = alarm_id and public.is_project_member(a.project_id)
  ));

create policy "Project developers can create alarm activity"
  on public.alarm_activity for insert
  with check (exists (
    select 1 from public.alarms a
    where a.id = alarm_id and public.can_modify_project(a.project_id)
  ));

-- ============================================================================
-- 5. Escalation policies
-- ============================================================================

create table if not exists public.escalation_policies (
  id uuid default gen_random_uuid() primary key,
  project_id uuid references public.projects(id) on delete cascade not null,
  organization_id uuid references public.organizations(id) on delete cascade not null,
  name text not null,
  description text,
  is_enabled boolean default true not null,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null
);

create index idx_escalation_policies_project on public.escalation_policies (project_id, is_enabled);

alter table public.escalation_policies enable row level security;

create policy "Project members can view escalation policies"
  on public.escalation_policies for select
  using (public.is_project_member(project_id));

create policy "Project developers can create escalation policies"
  on public.escalation_policies for insert
  with check (public.can_modify_project(project_id));

create policy "Project developers can update escalation policies"
  on public.escalation_policies for update
  using (public.can_modify_project(project_id));

create policy "Project developers can delete escalation policies"
  on public.escalation_policies for delete
  using (public.can_modify_project(project_id));

create trigger escalation_policies_updated_at
  before update on public.escalation_policies
  for each row execute function public.update_updated_at();

-- Add FK from alarms to escalation_policies now that the table exists
alter table public.alarms
  add constraint alarms_escalation_policy_fk
  foreign key (escalation_policy_id) references public.escalation_policies(id)
  on delete set null;

-- ============================================================================
-- 6. Escalation stages — ordered stages within a policy
-- ============================================================================

create table if not exists public.escalation_stages (
  id uuid default gen_random_uuid() primary key,
  policy_id uuid references public.escalation_policies(id) on delete cascade not null,
  stage_number int not null,
  delay_minutes int not null default 15,
  notification_targets jsonb not null default '[]',
  action_type text not null default 'notify',
  created_at timestamptz default now() not null,
  unique (policy_id, stage_number),
  constraint escalation_stage_action_check
    check (action_type in ('notify', 'reassign', 'auto_acknowledge'))
);

create index idx_escalation_stages_policy on public.escalation_stages (policy_id, stage_number);

alter table public.escalation_stages enable row level security;

create policy "Project members can view escalation stages"
  on public.escalation_stages for select
  using (exists (
    select 1 from public.escalation_policies ep
    where ep.id = policy_id and public.is_project_member(ep.project_id)
  ));

create policy "Project developers can manage escalation stages"
  on public.escalation_stages for insert
  with check (exists (
    select 1 from public.escalation_policies ep
    where ep.id = policy_id and public.can_modify_project(ep.project_id)
  ));

create policy "Project developers can update escalation stages"
  on public.escalation_stages for update
  using (exists (
    select 1 from public.escalation_policies ep
    where ep.id = policy_id and public.can_modify_project(ep.project_id)
  ));

create policy "Project developers can delete escalation stages"
  on public.escalation_stages for delete
  using (exists (
    select 1 from public.escalation_policies ep
    where ep.id = policy_id and public.can_modify_project(ep.project_id)
  ));

-- ============================================================================
-- 7. Escalation tasks — durable scheduled work items
-- ============================================================================

create table if not exists public.escalation_tasks (
  id uuid default gen_random_uuid() primary key,
  alarm_id uuid references public.alarms(id) on delete cascade not null,
  policy_id uuid references public.escalation_policies(id) on delete cascade not null,
  stage_id uuid references public.escalation_stages(id) on delete cascade not null,
  scheduled_at timestamptz not null,
  executed_at timestamptz,
  status public.escalation_task_status not null default 'pending',
  result jsonb default '{}',
  created_at timestamptz default now() not null
);

create index idx_escalation_tasks_pending on public.escalation_tasks (scheduled_at)
  where status = 'pending';
create index idx_escalation_tasks_alarm on public.escalation_tasks (alarm_id);

alter table public.escalation_tasks enable row level security;

create policy "Project members can view escalation tasks"
  on public.escalation_tasks for select
  using (exists (
    select 1 from public.alarms a
    where a.id = alarm_id and public.is_project_member(a.project_id)
  ));

-- ============================================================================
-- 8. Notification outbox — reliable delivery pattern
-- ============================================================================

create table if not exists public.notification_outbox (
  id uuid default gen_random_uuid() primary key,
  notification_id uuid references public.notifications(id) on delete set null,
  channel text not null default 'in_app',
  recipient_user_id uuid references public.profiles(id) on delete cascade not null,
  payload jsonb default '{}',
  status public.outbox_status not null default 'pending',
  attempts int not null default 0,
  max_attempts int not null default 3,
  last_attempt_at timestamptz,
  next_retry_at timestamptz,
  idempotency_key text unique,
  error_message text,
  created_at timestamptz default now() not null,
  constraint outbox_channel_check
    check (channel in ('in_app', 'email', 'push'))
);

create index idx_outbox_pending on public.notification_outbox (status, next_retry_at)
  where status in ('pending', 'failed');
create index idx_outbox_recipient on public.notification_outbox (recipient_user_id, created_at desc);
create index idx_outbox_notification on public.notification_outbox (notification_id)
  where notification_id is not null;

alter table public.notification_outbox enable row level security;

create policy "Users can view own outbox entries"
  on public.notification_outbox for select
  using (auth.uid() = recipient_user_id);

-- ============================================================================
-- 9. Extend notifications table for alarm linking
-- ============================================================================

alter table public.notifications
  add column if not exists alarm_id uuid references public.alarms(id) on delete set null,
  add column if not exists read_at timestamptz,
  add column if not exists navigation_target text;

create index if not exists idx_notifications_alarm on public.notifications (alarm_id)
  where alarm_id is not null;

-- ============================================================================
-- 10. Extend notification_preferences for quiet hours
-- ============================================================================

alter table public.notification_preferences
  add column if not exists quiet_hours_enabled boolean default false not null,
  add column if not exists quiet_hours_start time,
  add column if not exists quiet_hours_end time,
  add column if not exists timezone text default 'UTC',
  add column if not exists min_severity notification_severity default 'info';
