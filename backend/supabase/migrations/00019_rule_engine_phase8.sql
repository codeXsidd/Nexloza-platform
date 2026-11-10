-- Migration: 00019_rule_engine_phase8
-- Visual Rule Engine: graph model, rule versions, event inbox, execution tracing

-- ============================================================================
-- 1. Extend automations table for visual rule graphs
-- ============================================================================

alter table public.automations
  add column if not exists rule_graph jsonb,
  add column if not exists status text not null default 'draft',
  add column if not exists graph_version int not null default 1,
  add column if not exists published_at timestamptz,
  add column if not exists published_by uuid references public.profiles(id) on delete set null;

alter table public.automations
  add constraint automations_status_check
  check (status in ('draft', 'validated', 'published', 'enabled', 'disabled', 'archived'));

create index if not exists idx_automations_status on public.automations (status);
create index if not exists idx_automations_project_status
  on public.automations (project_id, status)
  where status in ('published', 'enabled');

-- ============================================================================
-- 2. Rule versions — immutable published snapshots
-- ============================================================================

create table if not exists public.rule_versions (
  id uuid default gen_random_uuid() primary key,
  automation_id uuid references public.automations(id) on delete cascade not null,
  version_number int not null,
  graph_snapshot jsonb not null,
  published_at timestamptz default now() not null,
  published_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz default now() not null,
  unique (automation_id, version_number)
);

create index idx_rule_versions_automation on public.rule_versions (automation_id, version_number desc);

alter table public.rule_versions enable row level security;

create policy "Project members can view rule versions"
  on public.rule_versions for select
  using (exists (
    select 1 from public.automations a
    where a.id = automation_id and public.is_project_member(a.project_id)
  ));

create policy "Project developers can create rule versions"
  on public.rule_versions for insert
  with check (exists (
    select 1 from public.automations a
    where a.id = automation_id and public.can_modify_project(a.project_id)
  ));

-- ============================================================================
-- 3. Rule events — durable event inbox with deduplication
-- ============================================================================

create table if not exists public.rule_events (
  id uuid default gen_random_uuid() primary key,
  event_type text not null,
  device_id uuid references public.devices(id) on delete set null,
  project_id uuid references public.projects(id) on delete cascade not null,
  organization_id uuid references public.organizations(id) on delete cascade not null,
  payload jsonb not null default '{}',
  idempotency_key text unique,
  correlation_id uuid not null default gen_random_uuid(),
  causation_id uuid,
  depth int not null default 0,
  status text not null default 'pending',
  processed_at timestamptz,
  error_message text,
  created_at timestamptz default now() not null,
  constraint rule_events_status_check check (status in ('pending', 'processing', 'completed', 'failed', 'skipped')),
  constraint rule_events_depth_check check (depth >= 0 and depth <= 10)
);

create index idx_rule_events_status on public.rule_events (status, created_at) where status = 'pending';
create index idx_rule_events_correlation on public.rule_events (correlation_id);
create index idx_rule_events_project on public.rule_events (project_id, created_at desc);
create index idx_rule_events_device on public.rule_events (device_id, created_at desc) where device_id is not null;

alter table public.rule_events enable row level security;

create policy "Project members can view rule events"
  on public.rule_events for select
  using (public.is_project_member(project_id));

-- ============================================================================
-- 4. Extend automation_executions for graph tracing
-- ============================================================================

alter table public.automation_executions
  add column if not exists correlation_id uuid,
  add column if not exists execution_depth int not null default 0,
  add column if not exists node_results jsonb not null default '[]',
  add column if not exists rule_version_id uuid references public.rule_versions(id) on delete set null,
  add column if not exists dry_run boolean not null default false;

create index if not exists idx_executions_correlation on public.automation_executions (correlation_id)
  where correlation_id is not null;
create index if not exists idx_executions_version on public.automation_executions (rule_version_id)
  where rule_version_id is not null;
create index if not exists idx_executions_dry_run on public.automation_executions (dry_run)
  where dry_run = true;
