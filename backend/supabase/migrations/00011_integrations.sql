-- Integrations

create type integration_type as enum ('alexa', 'google_home', 'webhook', 'mqtt_bridge', 'custom');

create table if not exists public.integrations (
  id uuid default gen_random_uuid() primary key,
  project_id uuid references public.projects(id) on delete cascade not null,
  integration_type integration_type not null,
  name text not null,
  config jsonb default '{}',
  credentials_encrypted text,
  is_active boolean default true,
  last_sync_at timestamptz,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null
);

create table if not exists public.integration_events (
  id uuid default gen_random_uuid() primary key,
  integration_id uuid references public.integrations(id) on delete cascade not null,
  event_type text not null,
  payload jsonb,
  status text default 'pending',
  error_message text,
  created_at timestamptz default now() not null
);

alter table public.integrations enable row level security;
alter table public.integration_events enable row level security;

create policy "Project admins can manage integrations"
  on public.integrations for all
  using (project_id in (
    select project_id from public.project_members
    where user_id = auth.uid() and role in ('owner', 'admin')
  ));

create policy "Project members can view integration events"
  on public.integration_events for select
  using (integration_id in (
    select i.id from public.integrations i
    join public.project_members pm on pm.project_id = i.project_id
    where pm.user_id = auth.uid()
  ));

create trigger integrations_updated_at
  before update on public.integrations
  for each row execute function public.update_updated_at();
