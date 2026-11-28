-- The client can retry after losing the response to a committed project edit.
create table public.offline_project_edit_receipts (
  account uuid not null references auth.users(id) on delete cascade,
  operation_id uuid not null,
  project_id uuid not null,
  created_at timestamptz not null default now(),
  primary key (account, operation_id)
);
alter table public.offline_project_edit_receipts enable row level security;
revoke all on public.offline_project_edit_receipts from anon, authenticated;

create function public.apply_offline_project_edit(
  p_account uuid, p_operation uuid, p_project uuid, p_expected_version timestamptz, p_changes jsonb
) returns boolean
language plpgsql security definer set search_path = ''
as $$
declare
  account_id uuid := auth.uid();
  target public.projects%rowtype;
begin
  if account_id is null or p_account is distinct from account_id or p_operation is null then
    return false;
  end if;
  if p_changes is null or jsonb_typeof(p_changes) <> 'object' or
     p_changes = '{}'::jsonb or p_changes - array['name', 'description', 'category', 'is_active'] <> '{}'::jsonb then
    raise exception 'Unsupported offline project edit' using errcode = '22023';
  end if;

  select * into target from public.projects where id = p_project for update;
  if not found or (target.owner_id <> account_id and not exists (
    select 1 from public.project_members
    where project_id = p_project and user_id = account_id and role = 'admin'
  )) then return false; end if;
  if exists (
    select 1 from public.offline_project_edit_receipts
    where account = account_id and operation_id = p_operation and project_id = p_project
  ) then return true; end if;
  if target.updated_at is distinct from p_expected_version then return false; end if;

  update public.projects set
    name = case when p_changes ? 'name' then p_changes->>'name' else target.name end,
    description = case when p_changes ? 'description' then p_changes->>'description' else target.description end,
    category = case when p_changes ? 'category' then (p_changes->>'category')::public.project_category else target.category end,
    is_active = case when p_changes ? 'is_active' then (p_changes->>'is_active')::boolean else target.is_active end
  where id = p_project;
  insert into public.offline_project_edit_receipts(account, operation_id, project_id)
    values (account_id, p_operation, p_project);
  return true;
end;
$$;
revoke all on function public.apply_offline_project_edit(uuid,uuid,uuid,timestamptz,jsonb) from public, anon;
grant execute on function public.apply_offline_project_edit(uuid,uuid,uuid,timestamptz,jsonb) to authenticated;
