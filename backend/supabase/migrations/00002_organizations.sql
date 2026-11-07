-- Migration: 00002_organizations
-- Organizations and membership with role-based access

create type public.org_role as enum ('owner', 'admin', 'member', 'viewer');

create table if not exists public.organizations (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  slug text not null unique,
  description text,
  logo_url text,
  website text,
  settings jsonb default '{}',
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null
);

create index idx_organizations_slug on public.organizations (slug);
create index idx_organizations_created_by on public.organizations (created_by);

create table if not exists public.organization_members (
  id uuid default gen_random_uuid() primary key,
  organization_id uuid references public.organizations(id) on delete cascade not null,
  user_id uuid references public.profiles(id) on delete cascade not null,
  role public.org_role not null default 'member',
  invited_by uuid references public.profiles(id) on delete set null,
  joined_at timestamptz default now() not null,
  unique (organization_id, user_id)
);

create index idx_org_members_org on public.organization_members (organization_id);
create index idx_org_members_user on public.organization_members (user_id);

alter table public.organizations enable row level security;
alter table public.organization_members enable row level security;

-- Helper: check if user is a member of an org
create or replace function public.is_org_member(org_id uuid)
returns boolean as $$
  select exists (
    select 1 from public.organization_members
    where organization_id = org_id and user_id = auth.uid()
  );
$$ language sql security definer stable;

-- Helper: check if user is org owner or admin
create or replace function public.is_org_admin(org_id uuid)
returns boolean as $$
  select exists (
    select 1 from public.organization_members
    where organization_id = org_id
      and user_id = auth.uid()
      and role in ('owner', 'admin')
  );
$$ language sql security definer stable;

-- Organizations: members can view, owner/admin can modify
create policy "Org members can view organization"
  on public.organizations for select
  using (public.is_org_member(id));

create policy "Org admins can update organization"
  on public.organizations for update
  using (public.is_org_admin(id));

create policy "Authenticated users can create organizations"
  on public.organizations for insert
  with check (auth.uid() = created_by);

create policy "Org owners can delete organization"
  on public.organizations for delete
  using (
    exists (
      select 1 from public.organization_members
      where organization_id = id
        and user_id = auth.uid()
        and role = 'owner'
    )
  );

-- Organization members: members can view, admins can manage
create policy "Org members can view members"
  on public.organization_members for select
  using (public.is_org_member(organization_id));

create policy "Org admins can add members"
  on public.organization_members for insert
  with check (public.is_org_admin(organization_id));

create policy "Org admins can update members"
  on public.organization_members for update
  using (public.is_org_admin(organization_id));

create policy "Org admins can remove members"
  on public.organization_members for delete
  using (public.is_org_admin(organization_id));

create trigger organizations_updated_at
  before update on public.organizations
  for each row execute function public.update_updated_at();
