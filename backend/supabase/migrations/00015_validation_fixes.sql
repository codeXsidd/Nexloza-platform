-- Migration: 00015_validation_fixes
-- Fixes identified during Supabase-First Database & Backend Validation audit:
--   1. Auto-add org creator as owner member
--   2. Fix RLS policies on integrations, audit_logs, firmware (use helper functions)
--   3. Add DELETE policy on notifications
--   4. Add missing indexes
--   5. Telemetry retention cleanup function
--   6. Rate-limit helper for telemetry ingestion
--   7. Fix audit_logs RLS so users can see their own user-level logs
--   8. Ensure sensor/actuator project_id matches device.project_id

-- ============================================================
-- 1. Auto-add organization creator as owner member
-- ============================================================
create or replace function public.handle_new_organization()
returns trigger as $$
begin
  insert into public.organization_members (organization_id, user_id, role)
  values (new.id, new.created_by, 'owner');
  return new;
end;
$$ language plpgsql security definer;

create trigger on_organization_created
  after insert on public.organizations
  for each row execute function public.handle_new_organization();

-- ============================================================
-- 2. Fix RLS on integrations — use helper functions
-- ============================================================
drop policy if exists "Project admins can manage integrations" on public.integrations;

create policy "Project members can view integrations"
  on public.integrations for select
  using (public.is_project_member(project_id));

create policy "Project admins can create integrations"
  on public.integrations for insert
  with check (
    exists (
      select 1 from public.projects where id = project_id and owner_id = auth.uid()
    ) or exists (
      select 1 from public.project_members
      where project_id = integrations.project_id
        and user_id = auth.uid()
        and role in ('owner', 'admin')
    )
  );

create policy "Project admins can update integrations"
  on public.integrations for update
  using (
    exists (
      select 1 from public.projects where id = project_id and owner_id = auth.uid()
    ) or exists (
      select 1 from public.project_members
      where project_id = integrations.project_id
        and user_id = auth.uid()
        and role in ('owner', 'admin')
    )
  );

create policy "Project admins can delete integrations"
  on public.integrations for delete
  using (
    exists (
      select 1 from public.projects where id = project_id and owner_id = auth.uid()
    ) or exists (
      select 1 from public.project_members
      where project_id = integrations.project_id
        and user_id = auth.uid()
        and role in ('owner', 'admin')
    )
  );

-- Fix integration_events RLS
drop policy if exists "Project members can view integration events" on public.integration_events;

create policy "Project members can view integration events"
  on public.integration_events for select
  using (
    exists (
      select 1 from public.integrations i
      where i.id = integration_id and public.is_project_member(i.project_id)
    )
  );

-- ============================================================
-- 3. Fix RLS on audit_logs — use helper functions + own logs
-- ============================================================
drop policy if exists "Project admins can view audit logs" on public.audit_logs;

create policy "Project admins can view project audit logs"
  on public.audit_logs for select
  using (
    -- Project-scoped logs: project owner or admin
    (project_id is not null and (
      exists (
        select 1 from public.projects where id = project_id and owner_id = auth.uid()
      ) or exists (
        select 1 from public.project_members
        where project_id = audit_logs.project_id
          and user_id = auth.uid()
          and role in ('owner', 'admin')
      )
    ))
    or
    -- User-scoped logs: own logs
    (user_id = auth.uid())
  );

-- ============================================================
-- 4. Fix RLS on firmware_versions — use helper functions
-- ============================================================
drop policy if exists "Project members can view firmware" on public.firmware_versions;
drop policy if exists "Admins can manage firmware" on public.firmware_versions;
drop policy if exists "Admins can manage OTA deployments" on public.ota_deployments;

create policy "Project members can view firmware"
  on public.firmware_versions for select
  using (
    project_id is null
    or public.is_project_member(project_id)
  );

create policy "Project admins can manage firmware"
  on public.firmware_versions for insert
  with check (
    exists (
      select 1 from public.projects where id = project_id and owner_id = auth.uid()
    ) or exists (
      select 1 from public.project_members
      where project_id = firmware_versions.project_id
        and user_id = auth.uid()
        and role in ('owner', 'admin')
    )
  );

create policy "Project admins can update firmware"
  on public.firmware_versions for update
  using (
    exists (
      select 1 from public.projects where id = project_id and owner_id = auth.uid()
    ) or exists (
      select 1 from public.project_members
      where project_id = firmware_versions.project_id
        and user_id = auth.uid()
        and role in ('owner', 'admin')
    )
  );

create policy "Project admins can delete firmware"
  on public.firmware_versions for delete
  using (
    exists (
      select 1 from public.projects where id = project_id and owner_id = auth.uid()
    ) or exists (
      select 1 from public.project_members
      where project_id = firmware_versions.project_id
        and user_id = auth.uid()
        and role in ('owner', 'admin')
    )
  );

create policy "Project members can view OTA deployments"
  on public.ota_deployments for select
  using (
    exists (
      select 1 from public.firmware_versions fv
      where fv.id = firmware_version_id
        and public.is_project_member(fv.project_id)
    )
  );

create policy "Project admins can manage OTA deployments"
  on public.ota_deployments for insert
  with check (
    exists (
      select 1 from public.firmware_versions fv
      where fv.id = firmware_version_id and (
        exists (select 1 from public.projects where id = fv.project_id and owner_id = auth.uid())
        or exists (
          select 1 from public.project_members
          where project_id = fv.project_id
            and user_id = auth.uid()
            and role in ('owner', 'admin')
        )
      )
    )
  );

create policy "Project admins can update OTA deployments"
  on public.ota_deployments for update
  using (
    exists (
      select 1 from public.firmware_versions fv
      where fv.id = firmware_version_id and (
        exists (select 1 from public.projects where id = fv.project_id and owner_id = auth.uid())
        or exists (
          select 1 from public.project_members
          where project_id = fv.project_id
            and user_id = auth.uid()
            and role in ('owner', 'admin')
        )
      )
    )
  );

create policy "Project admins can delete OTA deployments"
  on public.ota_deployments for delete
  using (
    exists (
      select 1 from public.firmware_versions fv
      where fv.id = firmware_version_id and (
        exists (select 1 from public.projects where id = fv.project_id and owner_id = auth.uid())
        or exists (
          select 1 from public.project_members
          where project_id = fv.project_id
            and user_id = auth.uid()
            and role in ('owner', 'admin')
        )
      )
    )
  );

-- ============================================================
-- 5. Add DELETE policy on notifications
-- ============================================================
create policy "Users can delete own notifications"
  on public.notifications for delete
  using (auth.uid() = user_id);

-- ============================================================
-- 6. Missing indexes
-- ============================================================
create index if not exists idx_integrations_project
  on public.integrations (project_id);
create index if not exists idx_integration_events_integration
  on public.integration_events (integration_id, created_at desc);
create index if not exists idx_firmware_versions_project
  on public.firmware_versions (project_id);
create index if not exists idx_ota_deployments_device
  on public.ota_deployments (device_id) where device_id is not null;
create index if not exists idx_ota_deployments_group
  on public.ota_deployments (device_group_id) where device_group_id is not null;
create index if not exists idx_ota_deployments_firmware
  on public.ota_deployments (firmware_version_id);
create index if not exists idx_telemetry_device
  on public.telemetry (device_id);

-- ============================================================
-- 7. Telemetry retention — delete data older than N days
-- ============================================================
create or replace function public.cleanup_old_telemetry(retention_days int default 90)
returns bigint as $$
declare
  deleted_count bigint;
begin
  delete from public.telemetry
  where recorded_at < now() - (retention_days || ' days')::interval;
  get diagnostics deleted_count = row_count;
  return deleted_count;
end;
$$ language plpgsql security definer;

create or replace function public.cleanup_old_audit_logs(retention_days int default 365)
returns bigint as $$
declare
  deleted_count bigint;
begin
  delete from public.audit_logs
  where created_at < now() - (retention_days || ' days')::interval;
  get diagnostics deleted_count = row_count;
  return deleted_count;
end;
$$ language plpgsql security definer;

-- ============================================================
-- 8. Rate-limit helper for telemetry ingestion
-- ============================================================
create or replace function public.check_telemetry_rate_limit(
  p_device_id uuid,
  max_per_minute int default 60
)
returns boolean as $$
declare
  recent_count int;
begin
  select count(*) into recent_count
  from public.telemetry
  where device_id = p_device_id
    and received_at > now() - interval '1 minute';
  return recent_count < max_per_minute;
end;
$$ language plpgsql security definer stable;

-- ============================================================
-- 9. Ensure sensor/actuator project_id consistency with device
-- ============================================================
create or replace function public.validate_sensor_project_id()
returns trigger as $$
begin
  if new.project_id != (select project_id from public.devices where id = new.device_id) then
    raise exception 'sensor project_id must match device project_id';
  end if;
  return new;
end;
$$ language plpgsql;

create trigger sensor_project_consistency
  before insert or update on public.sensor_definitions
  for each row execute function public.validate_sensor_project_id();

create or replace function public.validate_actuator_project_id()
returns trigger as $$
begin
  if new.project_id != (select project_id from public.devices where id = new.device_id) then
    raise exception 'actuator project_id must match device project_id';
  end if;
  return new;
end;
$$ language plpgsql;

create trigger actuator_project_consistency
  before insert or update on public.actuator_definitions
  for each row execute function public.validate_actuator_project_id();
