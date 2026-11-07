-- Migration: 00009_scenes
-- Scenes and scene actions

create table if not exists public.scenes (
  id uuid default gen_random_uuid() primary key,
  project_id uuid references public.projects(id) on delete cascade not null,
  name text not null,
  description text,
  icon text,
  is_active boolean default true not null,
  last_activated_at timestamptz,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null
);

create index idx_scenes_project on public.scenes (project_id);

create table if not exists public.scene_actions (
  id uuid default gen_random_uuid() primary key,
  scene_id uuid references public.scenes(id) on delete cascade not null,
  device_id uuid references public.devices(id) on delete cascade not null,
  actuator_id uuid references public.actuator_definitions(id) on delete cascade,
  action_type text not null default 'set_state',
  target_state jsonb not null default '{}',
  sort_order int default 0 not null,
  delay_ms int default 0 not null
);

create index idx_scene_actions_scene on public.scene_actions (scene_id);

alter table public.scenes enable row level security;
alter table public.scene_actions enable row level security;

create policy "Project members can view scenes"
  on public.scenes for select
  using (public.is_project_member(project_id));

create policy "Project developers can create scenes"
  on public.scenes for insert
  with check (public.can_modify_project(project_id));

create policy "Project developers can update scenes"
  on public.scenes for update
  using (public.can_modify_project(project_id));

create policy "Project developers can delete scenes"
  on public.scenes for delete
  using (public.can_modify_project(project_id));

create policy "View scene actions" on public.scene_actions for select
  using (exists (select 1 from public.scenes s where s.id = scene_id and public.is_project_member(s.project_id)));

create policy "Manage scene actions" on public.scene_actions for all
  using (exists (select 1 from public.scenes s where s.id = scene_id and public.can_modify_project(s.project_id)));

create trigger scenes_updated_at
  before update on public.scenes
  for each row execute function public.update_updated_at();
