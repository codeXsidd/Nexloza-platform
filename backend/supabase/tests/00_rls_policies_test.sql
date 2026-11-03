-- pgTAP tests for NexIoza RLS policies and security model
-- Run: supabase db test (requires supabase CLI + Docker)

BEGIN;

SELECT plan(24);

-- ============================================================
-- Schema existence tests
-- ============================================================

SELECT has_schema('private', 'private schema exists');
SELECT has_schema('public', 'public schema exists');

-- ============================================================
-- Table existence tests
-- ============================================================

SELECT has_table('public', 'profiles', 'profiles table exists');
SELECT has_table('public', 'organizations', 'organizations table exists');
SELECT has_table('public', 'organization_members', 'organization_members table exists');
SELECT has_table('public', 'projects', 'projects table exists');
SELECT has_table('public', 'project_members', 'project_members table exists');
SELECT has_table('public', 'invitations', 'invitations table exists');
SELECT has_table('public', 'project_categories', 'project_categories table exists');
SELECT has_table('public', 'audit_logs', 'audit_logs table exists');

-- ============================================================
-- RLS enabled tests
-- ============================================================

SELECT policies_are('public', 'profiles', ARRAY[
  'profiles_select_own',
  'profiles_insert_block',
  'profiles_update_block',
  'profiles_delete_block'
], 'profiles has correct RLS policies');

SELECT policies_are('public', 'organizations', ARRAY[
  'organizations_select_member',
  'organizations_insert_block',
  'organizations_update_block',
  'organizations_delete_block'
], 'organizations has correct RLS policies');

SELECT policies_are('public', 'projects', ARRAY[
  'projects_select_member',
  'projects_insert_block',
  'projects_update_block',
  'projects_delete_block'
], 'projects has correct RLS policies');

-- ============================================================
-- Version columns exist
-- ============================================================

SELECT has_column('public', 'profiles', 'version', 'profiles has version column');
SELECT has_column('public', 'organizations', 'version', 'organizations has version column');
SELECT has_column('public', 'projects', 'version', 'projects has version column');

-- ============================================================
-- Private schema function tests (existence)
-- ============================================================

SELECT has_function('private', 'is_org_member', ARRAY['uuid', 'uuid'],
  'private.is_org_member exists');
SELECT has_function('private', 'is_org_role', ARRAY['uuid', 'uuid', 'text[]'],
  'private.is_org_role exists');
SELECT has_function('private', 'is_project_member', ARRAY['uuid', 'uuid'],
  'private.is_project_member exists');
SELECT has_function('private', 'is_project_role', ARRAY['uuid', 'uuid', 'text[]'],
  'private.is_project_role exists');

-- ============================================================
-- Public API wrapper existence
-- ============================================================

SELECT has_function('public', 'create_organization', 'create_organization wrapper exists');
SELECT has_function('public', 'create_project', 'create_project wrapper exists');
SELECT has_function('public', 'create_invitation', 'create_invitation wrapper exists');
SELECT has_function('public', 'update_profile', 'update_profile wrapper exists');

SELECT * FROM finish();

ROLLBACK;
