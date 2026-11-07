-- Audit logs

create table if not exists public.audit_logs (
  id bigserial primary key,
  user_id uuid references public.profiles(id) on delete set null,
  project_id uuid references public.projects(id) on delete set null,
  action text not null,
  resource_type text not null,
  resource_id text,
  details jsonb,
  ip_address inet,
  created_at timestamptz default now() not null
);

create index idx_audit_project_time on public.audit_logs(project_id, created_at desc);
create index idx_audit_user_time on public.audit_logs(user_id, created_at desc);

alter table public.audit_logs enable row level security;

create policy "Project admins can view audit logs"
  on public.audit_logs for select
  using (project_id in (
    select project_id from public.project_members
    where user_id = auth.uid() and role in ('owner', 'admin')
  ));
