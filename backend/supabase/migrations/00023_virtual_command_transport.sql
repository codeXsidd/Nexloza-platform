-- Command completion is recorded only by the authenticated device transport.
drop policy "Project developers can update commands" on public.device_commands;
revoke update on public.device_commands from authenticated, anon;
drop policy "Project developers can create commands" on public.device_commands;
create policy "Project developers can queue pending commands"
  on public.device_commands for insert to authenticated
  with check (
    status = 'pending' and issued_by = auth.uid()
    and sent_at is null and acknowledged_at is null and executed_at is null
    and coalesce(retry_count, 0) = 0
    and exists (
      select 1 from public.devices d
      where d.id = device_id and public.can_modify_project(d.project_id)
    )
  );

create function public.dispatch_virtual_commands(p_device uuid)
returns setof public.device_commands language plpgsql set search_path = '' as $$
begin
  update public.device_commands set status = 'timeout'
  where device_id = p_device and status in ('pending', 'sent')
    and expires_at <= now();

  return query
    with ready as (
      select id from public.device_commands
      where device_id = p_device and expires_at > now() and (
        status = 'pending' or (status = 'sent' and sent_at < now() - interval '4 seconds')
      )
      order by created_at, id limit 10 for update skip locked
    )
    update public.device_commands c
    set status = 'sent', sent_at = now(), retry_count = coalesce(retry_count, 0) + 1
    from ready where c.id = ready.id returning c.*;
end;
$$;
revoke all on function public.dispatch_virtual_commands(uuid) from public, anon, authenticated;
grant execute on function public.dispatch_virtual_commands(uuid) to service_role;

create function public.complete_virtual_command(
  p_device uuid, p_command uuid, p_success boolean, p_value double precision
) returns boolean language plpgsql set search_path = '' as $$
declare
  command public.device_commands%rowtype;
  capability public.actuator_definitions%rowtype;
  reported jsonb;
begin
  select * into command from public.device_commands
    where id = p_command and device_id = p_device for update;
  if not found then return false; end if;
  if command.status in ('executed', 'failed') then return true; end if;
  if command.status <> 'sent' or command.expires_at <= now() then return false; end if;

  if p_success then
    select * into capability from public.actuator_definitions
      where device_id = p_device and command_key = command.command_type and is_active
        and id::text = coalesce(command.payload->>'actuator_id', id::text)
      limit 1;
    if not found or p_value is null or p_value not between
       coalesce(capability.min_value, 0) and coalesce(capability.max_value, 1)
       or (capability.control_type = 'toggle' and p_value not in (0, 1))
       or p_value is distinct from (case jsonb_typeof(command.payload->'value')
         when 'boolean' then case when (command.payload->>'value')::boolean then 1 else 0 end
         when 'number' then (command.payload->>'value')::double precision
         else null end)
    then return false; end if;

    reported := jsonb_build_object(command.command_type, p_value);
    update public.actuator_definitions
      set current_state = jsonb_build_object('value', p_value, 'is_on', p_value > 0)
      where id = capability.id;
    insert into public.device_twin_state (device_id, reported_state, reported_version, reported_at)
      values (p_device, reported, 1, now())
      on conflict (device_id) do update set
        reported_state = public.device_twin_state.reported_state || excluded.reported_state,
        reported_version = public.device_twin_state.reported_version + 1,
        reported_at = now(),
        sync_status = case when
          public.device_twin_state.desired_state <@ (public.device_twin_state.reported_state || excluded.reported_state)
          then 'synced' else 'pending' end;
  end if;

  insert into public.command_results (command_id, device_id, success, result_data, error_message)
    values (p_command, p_device, p_success, coalesce(reported, '{}'::jsonb),
      case when p_success then null else 'Device rejected command' end);
  update public.device_commands set
    status = case when p_success then 'executed'::public.command_status else 'failed'::public.command_status end,
    acknowledged_at = now(), executed_at = case when p_success then now() else null end
    where id = p_command;
  return true;
end;
$$;
revoke all on function public.complete_virtual_command(uuid,uuid,boolean,double precision) from public, anon, authenticated;
grant execute on function public.complete_virtual_command(uuid,uuid,boolean,double precision) to service_role;

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime'
        and schemaname = 'public' and tablename = 'device_commands') then
      alter publication supabase_realtime add table public.device_commands;
    end if;
    if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime'
        and schemaname = 'public' and tablename = 'device_twin_state') then
      alter publication supabase_realtime add table public.device_twin_state;
    end if;
  end if;
end;
$$;
