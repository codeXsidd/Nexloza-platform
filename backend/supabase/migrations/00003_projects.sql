-- Migration: 00003_projects
-- Projects and project membership

create type public.project_role as enum ('owner', 'admin', 'developer', 'viewer');

create type public.project_category as enum (
  'smart_home',
  'smart_agriculture',
  'industrial_monitoring',
  'smart_irrigation',
  'weather_monitoring',
  'smart_energy',
  'water_management',
  'health_environment',
  'home_security',
  'custom'
);

create table if not exists public.projects (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  description text,
  category public.project_category not null default 'custom',
  icon text,
  image_url text,
  organization_id uuid references public.organizations(id) on delete set null,
  owner_id uuid references public.profiles(id) on delete cascade not null,
  settings jsonb default '{}',
  is_active boolean default true not null,
  device_limit int default 50,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null
);

create index idx_projects_owner on public.projects (owner_id);
create index idx_projects_org on public.projects (organization_id);
create index idx_projects_active on public.projects (is_active) where is_active = true;

create table if not exists public.project_members (
  id uuid default gen_random_uuid() primary key,
  project_id uuid references public.projects(id) on delete cascade not null,
  user_id uuid references public.profiles(id) on delete cascade not null,
  role public.project_role not null default 'viewer',
  invited_by uuid references public.profiles(id) on delete set null,
  joined_at timestamptz default now() not null,
  unique (project_id, user_id)
);

create index idx_project_members_project on public.project_members (project_id);
create index idx_project_members_user on public.project_members (user_id);

alter table public.projects enable row level security;
alter table public.project_members enable row level security;

-- Helper: check if user is a project member (or owner)
create or replace function public.is_project_member(p_id uuid)
returns boolean as $$
  select exists (
    select 1 from public.projects where id = p_id and owner_id = auth.uid()
  ) or exists (
    select 1 from public.project_members
    where project_id = p_id and user_id = auth.uid()
  );
$$ language sql security definer stable;

-- Helper: check if user can modify project (owner, admin, or developer)
create or replace function public.can_modify_project(p_id uuid)
returns boolean as $$
  select exists (
    select 1 from public.projects where id = p_id and owner_id = auth.uid()
  ) or exists (
    select 1 from public.project_members
    where project_id = p_id
      and user_id = auth.uid()
      and role in ('admin', 'developer')
  );
$$ language sql security definer stable;

-- Projects: members can view, owner can do everything
create policy "Project members can view projects"
  on public.projects for select
  using (public.is_project_member(id));

create policy "Authenticated users can create projects"
  on public.projects for insert
  with check (auth.uid() = owner_id);

create policy "Project owner and admins can update"
  on public.projects for update
  using (
    owner_id = auth.uid() or exists (
      select 1 from public.project_members
      where project_id = id and user_id = auth.uid() and role = 'admin'
    )
  );

create policy "Project owner can delete"
  on public.projects for delete
  using (owner_id = auth.uid());

-- Project members
create policy "Project members can view members"
  on public.project_members for select
  using (public.is_project_member(project_id));

create policy "Project admins can add members"
  on public.project_members for insert
  with check (
    public.can_modify_project(project_id)
    or exists (
      select 1 from public.projects
      where id = project_id and owner_id = auth.uid()
    )
  );

create policy "Project admins can update members"
  on public.project_members for update
  using (
    exists (
      select 1 from public.projects
      where id = project_id and owner_id = auth.uid()
    ) or exists (
      select 1 from public.project_members pm
      where pm.project_id = project_members.project_id
        and pm.user_id = auth.uid()
        and pm.role = 'admin'
    )
  );

create policy "Project admins can remove members"
  on public.project_members for delete
  using (
    exists (
      select 1 from public.projects
      where id = project_id and owner_id = auth.uid()
    ) or exists (
      select 1 from public.project_members pm
      where pm.project_id = project_members.project_id
        and pm.user_id = auth.uid()
        and pm.role = 'admin'
    )
  );

create trigger projects_updated_at
  before update on public.projects
  for each row execute function public.update_updated_at();
