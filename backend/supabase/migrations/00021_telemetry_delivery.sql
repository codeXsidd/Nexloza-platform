-- Identified batches are replay-safe. Legacy writers can omit message_id.
alter table public.telemetry add column message_id uuid;
alter table public.telemetry add constraint telemetry_message_sensor_unique
  unique (device_id, message_id, sensor_key);

create policy "Project developers can write virtual device telemetry"
  on public.telemetry for insert to authenticated
  with check (
    exists (
      select 1 from public.devices d
      where d.id = device_id and d.is_virtual
        and public.can_modify_project(d.project_id)
    )
  );

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime')
    and not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public'
        and tablename = 'telemetry'
    )
  then
    alter publication supabase_realtime add table public.telemetry;
  end if;
end;
$$;
