-- Migration: 00016_invitations
-- Unified invitation system for organizations and projects

create type public.invitation_type as enum ('organization', 'project');
create type public.invitation_status as enum ('pending', 'accepted', 'declined', 'expired', 'cancelled');

create table if not exists public.invitations (
  id uuid default gen_random_uuid() primary key,
  invitation_type public.invitation_type not null,
  organization_id uuid references public.organizations(id) on delete cascade,
  project_id uuid references public.projects(id) on delete cascade,
  invited_email text not null,
  invited_user_id uuid references public.profiles(id) on delete set null,
  invited_by uuid references public.profiles(id) on delete set null not null,
  role text not null,
  status public.invitation_status not null default 'pending',
  token uuid default gen_random_uuid() not null unique,
  message text,
  expires_at timestamptz default (now() + interval '7 days') not null,
  responded_at timestamptz,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null,
  check (
    (invitation_type = 'organization' and organization_id is not null)
    or (invitation_type = 'project' and project_id is not null)
  )
);

create index idx_invitations_email on public.invitations (invited_email) where status = 'pending';
create index idx_invitations_user on public.invitations (invited_user_id) where status = 'pending';
create index idx_invitations_org on public.invitations (organization_id) where status = 'pending';
create index idx_invitations_project on public.invitations (project_id) where status = 'pending';
create index idx_invitations_token on public.invitations (token) where status = 'pending';

alter table public.invitations enable row level security;

-- Invitees can see their own pending invitations
create policy "Users can view invitations sent to them"
  on public.invitations for select
  using (
    invited_email = (select email from public.profiles where id = auth.uid())
    or invited_user_id = auth.uid()
    or invited_by = auth.uid()
    or (invitation_type = 'organization' and organization_id is not null and public.is_org_admin(organization_id))
    or (invitation_type = 'project' and project_id is not null and public.can_modify_project(project_id))
  );

-- Org admins and project admins can create invitations
create policy "Admins can create invitations"
  on public.invitations for insert
  with check (
    invited_by = auth.uid()
    and (
      (invitation_type = 'organization' and public.is_org_admin(organization_id))
      or (invitation_type = 'project' and public.can_modify_project(project_id))
    )
  );

-- Invitees can accept/decline their own invitations
create policy "Invitees can update invitation status"
  on public.invitations for update
  using (
    invited_email = (select email from public.profiles where id = auth.uid())
    or invited_user_id = auth.uid()
    or invited_by = auth.uid()
  );

-- Admins can cancel invitations they manage
create policy "Admins can delete invitations"
  on public.invitations for delete
  using (
    invited_by = auth.uid()
    or (invitation_type = 'organization' and public.is_org_admin(organization_id))
    or (invitation_type = 'project' and public.can_modify_project(project_id))
  );

-- Function to accept an invitation and add user to the appropriate group
create or replace function public.accept_invitation(p_invitation_id uuid)
returns boolean as $$
declare
  v_invitation record;
  v_user_id uuid := auth.uid();
  v_user_email text;
begin
  select email into v_user_email from public.profiles where id = v_user_id;

  select * into v_invitation
  from public.invitations
  where id = p_invitation_id
    and status = 'pending'
    and expires_at > now()
    and (invited_email = v_user_email or invited_user_id = v_user_id);

  if v_invitation is null then
    return false;
  end if;

  if v_invitation.invitation_type = 'organization' then
    insert into public.organization_members (organization_id, user_id, role, invited_by)
    values (
      v_invitation.organization_id,
      v_user_id,
      v_invitation.role::public.org_role,
      v_invitation.invited_by
    )
    on conflict (organization_id, user_id) do nothing;
  elsif v_invitation.invitation_type = 'project' then
    insert into public.project_members (project_id, user_id, role, invited_by)
    values (
      v_invitation.project_id,
      v_user_id,
      v_invitation.role::public.project_role,
      v_invitation.invited_by
    )
    on conflict (project_id, user_id) do nothing;
  end if;

  update public.invitations
  set status = 'accepted',
      invited_user_id = v_user_id,
      responded_at = now(),
      updated_at = now()
  where id = p_invitation_id;

  return true;
end;
$$ language plpgsql security definer;

-- Function to decline an invitation
create or replace function public.decline_invitation(p_invitation_id uuid)
returns boolean as $$
declare
  v_user_id uuid := auth.uid();
  v_user_email text;
begin
  select email into v_user_email from public.profiles where id = v_user_id;

  update public.invitations
  set status = 'declined',
      invited_user_id = v_user_id,
      responded_at = now(),
      updated_at = now()
  where id = p_invitation_id
    and status = 'pending'
    and (invited_email = v_user_email or invited_user_id = v_user_id);

  return found;
end;
$$ language plpgsql security definer;

create trigger invitations_updated_at
  before update on public.invitations
  for each row execute function public.update_updated_at();
