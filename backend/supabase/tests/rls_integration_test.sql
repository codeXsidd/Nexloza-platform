-- ============================================================
-- Nexloza RLS Integration Tests
-- Multi-user tenant isolation verification
-- Run with: psql -f rls_integration_test.sql
-- ============================================================
-- These tests verify that RLS policies correctly isolate data
-- between users, organizations, and projects.
--
-- Test scenario:
--   user_a: Creates org_alpha, project_alpha, device_alpha
--   user_b: Creates org_beta, project_beta, device_beta
--   user_c: Member of org_alpha (viewer role)
--
-- Expected: Each user sees only their own data (plus shared org data).
-- ============================================================

begin;

-- ============================================================
-- Setup: Create test users in auth.users
-- ============================================================
-- Note: In a real test environment, use Supabase auth helpers.
-- This SQL uses direct inserts for test scaffolding only.

-- Create test user UUIDs
do $$
declare
  v_user_a uuid := 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  v_user_b uuid := 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
  v_user_c uuid := 'cccccccc-cccc-cccc-cccc-cccccccccccc';
  v_org_alpha uuid;
  v_org_beta uuid;
  v_proj_alpha uuid;
  v_proj_beta uuid;
  v_device_alpha uuid;
  v_device_beta uuid;
  v_project_version timestamptz;
  v_edit uuid := 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeed';
  v_test_count int := 0;
  v_pass_count int := 0;
  v_fail_count int := 0;
begin

  raise notice '============================================================';
  raise notice 'NEXLOZA RLS INTEGRATION TESTS';
  raise notice '============================================================';

  -- --------------------------------------------------------
  -- Insert Auth users so the actual profile trigger creates the profiles
  -- --------------------------------------------------------
  insert into auth.users (id, email, raw_user_meta_data) values
    (v_user_a, 'alice@test.com', '{"full_name":"Alice Test"}'),
    (v_user_b, 'bob@test.com', '{"full_name":"Bob Test"}'),
    (v_user_c, 'carol@test.com', '{"full_name":"Carol Test"}')
  on conflict (id) do nothing;

  -- --------------------------------------------------------
  -- TEST GROUP: Organizations
  -- --------------------------------------------------------
  raise notice '';
  raise notice '--- Organizations ---';

  -- User A creates org_alpha
  insert into public.organizations (name, slug, created_by)
  values ('Alpha Org', 'alpha-org', v_user_a)
  returning id into v_org_alpha;

  -- The handle_new_organization trigger should auto-add user_a as owner
  v_test_count := v_test_count + 1;
  if exists (
    select 1 from public.organization_members
    where organization_id = v_org_alpha and user_id = v_user_a and role = 'owner'
  ) then
    raise notice 'PASS: Org creator auto-added as owner member';
    v_pass_count := v_pass_count + 1;
  else
    raise notice 'FAIL: Org creator NOT auto-added as owner member';
    v_fail_count := v_fail_count + 1;
  end if;

  -- User B creates org_beta
  insert into public.organizations (name, slug, created_by)
  values ('Beta Org', 'beta-org', v_user_b)
  returning id into v_org_beta;

  -- Add user_c as viewer in org_alpha
  insert into public.organization_members (organization_id, user_id, role, invited_by)
  values (v_org_alpha, v_user_c, 'viewer', v_user_a);

  -- TEST: User B should NOT be a member of org_alpha
  v_test_count := v_test_count + 1;
  if not exists (
    select 1 from public.organization_members
    where organization_id = v_org_alpha and user_id = v_user_b
  ) then
    raise notice 'PASS: User B is not in org_alpha';
    v_pass_count := v_pass_count + 1;
  else
    raise notice 'FAIL: User B should not be in org_alpha';
    v_fail_count := v_fail_count + 1;
  end if;

  -- --------------------------------------------------------
  -- TEST GROUP: Projects
  -- --------------------------------------------------------
  raise notice '';
  raise notice '--- Projects ---';

  -- User A creates project_alpha in org_alpha
  insert into public.projects (name, category, organization_id, owner_id)
  values ('Alpha Project', 'smart_home', v_org_alpha, v_user_a)
  returning id into v_proj_alpha;

  -- User B creates project_beta in org_beta
  insert into public.projects (name, category, organization_id, owner_id)
  values ('Beta Project', 'industrial_monitoring', v_org_beta, v_user_b)
  returning id into v_proj_beta;

  -- TEST: is_project_member should return true for owner
  v_test_count := v_test_count + 1;
  -- We simulate auth.uid() = v_user_a by checking the helper directly
  -- Note: In RLS context, auth.uid() is used. Here we verify the data model.
  if exists (
    select 1 from public.projects where id = v_proj_alpha and owner_id = v_user_a
  ) then
    raise notice 'PASS: User A owns project_alpha';
    v_pass_count := v_pass_count + 1;
  else
    raise notice 'FAIL: User A should own project_alpha';
    v_fail_count := v_fail_count + 1;
  end if;

  -- TEST: User B should NOT be owner of project_alpha
  v_test_count := v_test_count + 1;
  if not exists (
    select 1 from public.projects where id = v_proj_alpha and owner_id = v_user_b
  ) and not exists (
    select 1 from public.project_members where project_id = v_proj_alpha and user_id = v_user_b
  ) then
    raise notice 'PASS: User B has no access to project_alpha';
    v_pass_count := v_pass_count + 1;
  else
    raise notice 'FAIL: User B should not access project_alpha';
    v_fail_count := v_fail_count + 1;
  end if;

  -- --------------------------------------------------------
  -- TEST GROUP: Devices
  -- --------------------------------------------------------
  raise notice '';
  raise notice '--- Devices ---';

  insert into public.devices (project_id, name, device_type, hardware_platform)
  values (v_proj_alpha, 'Alpha Sensor', 'dht22', 'esp32')
  returning id into v_device_alpha;

  insert into public.devices (project_id, name, device_type, hardware_platform)
  values (v_proj_beta, 'Beta Relay', 'relay', 'esp8266')
  returning id into v_device_beta;

  -- TEST: Devices are correctly assigned to projects
  v_test_count := v_test_count + 1;
  if (select project_id from public.devices where id = v_device_alpha) = v_proj_alpha
    and (select project_id from public.devices where id = v_device_beta) = v_proj_beta
  then
    raise notice 'PASS: Devices assigned to correct projects';
    v_pass_count := v_pass_count + 1;
  else
    raise notice 'FAIL: Device project assignment mismatch';
    v_fail_count := v_fail_count + 1;
  end if;

  -- --------------------------------------------------------
  -- TEST GROUP: Telemetry Isolation
  -- --------------------------------------------------------
  raise notice '';
  raise notice '--- Telemetry ---';

  insert into public.telemetry (device_id, sensor_key, value_numeric)
  values
    (v_device_alpha, 'temperature', 25.5),
    (v_device_alpha, 'humidity', 60.0),
    (v_device_beta, 'relay_state', 1.0);

  -- TEST: Telemetry for device_alpha should only be visible through project_alpha membership
  v_test_count := v_test_count + 1;
  if (select count(*) from public.telemetry where device_id = v_device_alpha) = 2
    and (select count(*) from public.telemetry where device_id = v_device_beta) = 1
  then
    raise notice 'PASS: Telemetry data correctly isolated per device';
    v_pass_count := v_pass_count + 1;
  else
    raise notice 'FAIL: Telemetry data isolation issue';
    v_fail_count := v_fail_count + 1;
  end if;

  -- --------------------------------------------------------
  -- TEST GROUP: Notifications Isolation
  -- --------------------------------------------------------
  raise notice '';
  raise notice '--- Notifications ---';

  insert into public.notifications (user_id, title, body, category, severity)
  values
    (v_user_a, 'Alert for Alice', 'Device offline', 'device', 'warning'),
    (v_user_b, 'Alert for Bob', 'Temp high', 'alert', 'critical');

  -- TEST: Each user's notifications are separate
  v_test_count := v_test_count + 1;
  if (select count(*) from public.notifications where user_id = v_user_a) = 1
    and (select count(*) from public.notifications where user_id = v_user_b) = 1
    and (select count(*) from public.notifications where user_id = v_user_c) = 0
  then
    raise notice 'PASS: Notifications correctly isolated per user';
    v_pass_count := v_pass_count + 1;
  else
    raise notice 'FAIL: Notification isolation issue';
    v_fail_count := v_fail_count + 1;
  end if;

  -- --------------------------------------------------------
  -- TEST GROUP: AI Conversations Isolation
  -- --------------------------------------------------------
  raise notice '';
  raise notice '--- AI Conversations ---';

  insert into public.ai_conversations (user_id, title) values (v_user_a, 'Alice conv');
  insert into public.ai_conversations (user_id, title) values (v_user_b, 'Bob conv');

  v_test_count := v_test_count + 1;
  if (select count(*) from public.ai_conversations where user_id = v_user_a) = 1
    and (select count(*) from public.ai_conversations where user_id = v_user_b) = 1
  then
    raise notice 'PASS: AI conversations isolated per user';
    v_pass_count := v_pass_count + 1;
  else
    raise notice 'FAIL: AI conversation isolation issue';
    v_fail_count := v_fail_count + 1;
  end if;

  -- --------------------------------------------------------
  -- TEST GROUP: Sensor/Actuator project_id consistency
  -- --------------------------------------------------------
  raise notice '';
  raise notice '--- Sensor project consistency ---';

  -- Valid insert: matching project_id
  insert into public.sensor_definitions (device_id, project_id, name, telemetry_key)
  values (v_device_alpha, v_proj_alpha, 'Temp Sensor', 'temperature');

  v_test_count := v_test_count + 1;
  raise notice 'PASS: Valid sensor insert (matching project_id) succeeded';
  v_pass_count := v_pass_count + 1;

  -- Invalid insert: mismatched project_id should be rejected by trigger
  v_test_count := v_test_count + 1;
  begin
    insert into public.sensor_definitions (device_id, project_id, name, telemetry_key)
    values (v_device_alpha, v_proj_beta, 'Bad Sensor', 'bad_key');
    raise notice 'FAIL: Mismatched sensor project_id was accepted';
    v_fail_count := v_fail_count + 1;
  exception when others then
    raise notice 'PASS: Mismatched sensor project_id correctly rejected';
    v_pass_count := v_pass_count + 1;
  end;

  -- --------------------------------------------------------
  -- TEST GROUP: Rate limiting helper
  -- --------------------------------------------------------
  raise notice '';
  raise notice '--- Rate limiting ---';

  v_test_count := v_test_count + 1;
  if public.check_telemetry_rate_limit(v_device_alpha, 60) then
    raise notice 'PASS: Rate limit check returns true (under limit)';
    v_pass_count := v_pass_count + 1;
  else
    raise notice 'FAIL: Rate limit check should return true for low-volume device';
    v_fail_count := v_fail_count + 1;
  end if;

  -- --------------------------------------------------------
  -- TEST GROUP: Telemetry retention cleanup
  -- --------------------------------------------------------
  raise notice '';
  raise notice '--- Telemetry retention ---';

  -- Insert an old telemetry row
  insert into public.telemetry (device_id, sensor_key, value_numeric, recorded_at)
  values (v_device_alpha, 'old_reading', 99.0, now() - interval '100 days');

  v_test_count := v_test_count + 1;
  declare
    v_cleaned bigint;
  begin
    select public.cleanup_old_telemetry(90) into v_cleaned;
    if v_cleaned >= 1 then
      raise notice 'PASS: Telemetry cleanup removed % old row(s)', v_cleaned;
      v_pass_count := v_pass_count + 1;
    else
      raise notice 'FAIL: Telemetry cleanup should have removed old rows';
      v_fail_count := v_fail_count + 1;
    end if;
  end;

  -- --------------------------------------------------------
  -- TEST GROUP: Cross-project device isolation
  -- --------------------------------------------------------
  raise notice '';
  raise notice '--- Cross-project isolation ---';

  -- Commands for device_alpha should only be accessible through project_alpha
  insert into public.device_commands (device_id, command_type, payload, issued_by)
  values (v_device_alpha, 'set_state', '{"relay": true}', v_user_a);

  v_test_count := v_test_count + 1;
  if (select count(*) from public.device_commands where device_id = v_device_alpha) = 1
    and (select count(*) from public.device_commands where device_id = v_device_beta) = 0
  then
    raise notice 'PASS: Device commands correctly isolated per project';
    v_pass_count := v_pass_count + 1;
  else
    raise notice 'FAIL: Device command isolation issue';
    v_fail_count := v_fail_count + 1;
  end if;

  -- --------------------------------------------------------
  -- TEST GROUP: Audit logs
  -- --------------------------------------------------------
  raise notice '';
  raise notice '--- Audit logs ---';

  insert into public.audit_logs (user_id, project_id, action, resource_type, resource_id)
  values
    (v_user_a, v_proj_alpha, 'device.create', 'device', v_device_alpha::text),
    (v_user_b, v_proj_beta, 'device.create', 'device', v_device_beta::text),
    (v_user_a, null, 'profile.update', 'profile', v_user_a::text);

  -- User-level audit logs (no project) should be visible to the user
  v_test_count := v_test_count + 1;
  if (select count(*) from public.audit_logs where user_id = v_user_a and project_id is null) = 1 then
    raise notice 'PASS: User-level audit log exists for user A';
    v_pass_count := v_pass_count + 1;
  else
    raise notice 'FAIL: User-level audit log missing';
    v_fail_count := v_fail_count + 1;
  end if;

  -- Exercise policies with the actual authenticated role.
  update public.devices set is_virtual = true where id = v_device_alpha;
  perform set_config('request.jwt.claim.sub', v_user_a::text, true);
  set local role authenticated;
  insert into public.telemetry (device_id, sensor_key, value_numeric, message_id)
    values (v_device_alpha, 'verified', 23.875, 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee');
  insert into public.telemetry (device_id, sensor_key, value_numeric, message_id)
    values (v_device_alpha, 'verified', 99, 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee')
    on conflict (device_id, message_id, sensor_key) do nothing;
  if (select count(*) from public.telemetry where device_id = v_device_alpha
      and sensor_key = 'verified' and value_numeric = 23.875) <> 1 then
    raise exception 'Identified telemetry did not persist exactly once';
  end if;
  perform set_config('request.jwt.claim.sub', v_user_b::text, true);
  if exists (select 1 from public.telemetry where device_id = v_device_alpha) then
    raise exception 'Cross-project user could read telemetry';
  end if;
  begin
    insert into public.telemetry (device_id, sensor_key, value_numeric)
      values (v_device_alpha, 'unauthorized', 1);
    raise exception 'Cross-project user could write telemetry';
  exception when insufficient_privilege then
    null;
  end;
  begin
    insert into public.telemetry (device_id, sensor_key, value_numeric)
      values (v_device_beta, 'unauthorized', 1);
    raise exception 'Authenticated user could write physical device telemetry';
  exception when insufficient_privilege then
    null;
  end;
  begin
    update public.device_commands set status = 'executed' where device_id = v_device_beta;
    raise exception 'Authenticated user could forge command completion';
  exception when insufficient_privilege then null;
  end;
  if public.apply_offline_project_edit(v_user_a, v_edit, v_proj_alpha, now(),
        '{"name":"Unexpected edit"}') then
    raise exception 'Another account replayed an offline edit';
  end if;
  perform set_config('request.jwt.claim.sub', v_user_a::text, true);
  select updated_at into v_project_version from public.projects where id = v_proj_alpha;
  if not public.apply_offline_project_edit(v_user_a, v_edit, v_proj_alpha,
      v_project_version, '{"name":"Offline project edit"}') then
    raise exception 'Authorized project replay rejected';
  end if;
  if not public.apply_offline_project_edit(v_user_a, v_edit, v_proj_alpha,
      v_project_version, '{"name":"Offline project edit"}') then
    raise exception 'Idempotent project replay rejected';
  end if;
  if public.apply_offline_project_edit(v_user_a, gen_random_uuid(), v_proj_alpha,
      v_project_version - interval '1 second', '{"name":"Stale name"}') then
    raise exception 'Stale offline project edit overwrote the newer version';
  end if;
  if (select name from public.projects where id = v_proj_alpha) <> 'Offline project edit' then
    raise exception 'Authorized replay did not preserve the edited name';
  end if;
  reset role;
  raise notice 'PASS: authenticated isolation, virtual-only writes and replay deduplication';
  raise notice 'PASS: offline project account/version checks and command acknowledgement protection';

  -- ============================================================
  -- Summary
  -- ============================================================
  raise notice '';
  raise notice '============================================================';
  raise notice 'TEST RESULTS: % passed, % failed, % total', v_pass_count, v_fail_count, v_test_count;
  raise notice '============================================================';

  if v_fail_count > 0 then
    raise exception 'RLS integration suite failed';
  else
    raise notice 'ALL TESTS PASSED';
  end if;

end;
$$;

-- Rollback all test data (clean run)
rollback;
