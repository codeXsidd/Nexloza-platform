-- Phase 2 Migration 6: Private Schema and Helper Functions
-- Creates the private schema for SECURITY DEFINER implementation functions
-- and RLS helper functions that are NOT exposed via PostgREST.

CREATE SCHEMA IF NOT EXISTS private;

REVOKE ALL ON SCHEMA private FROM PUBLIC;
REVOKE ALL ON SCHEMA private FROM anon;
GRANT USAGE ON SCHEMA private TO authenticated;
GRANT USAGE ON SCHEMA private TO service_role;

-- ============================================================
-- RLS HELPER FUNCTIONS
-- Called by RLS policies. SECURITY DEFINER breaks recursion.
-- ============================================================

CREATE OR REPLACE FUNCTION private.is_org_member(_org_id UUID)
RETURNS BOOLEAN
LANGUAGE sql STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.organization_members
    WHERE organization_id = _org_id AND user_id = auth.uid()
  );
$$;

CREATE OR REPLACE FUNCTION private.get_org_role(_org_id UUID)
RETURNS TEXT
LANGUAGE sql STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT role FROM public.organization_members
  WHERE organization_id = _org_id AND user_id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION private.is_project_member(_project_id UUID)
RETURNS BOOLEAN
LANGUAGE sql STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.project_members
    WHERE project_id = _project_id AND user_id = auth.uid()
  );
$$;

CREATE OR REPLACE FUNCTION private.get_project_role(_project_id UUID)
RETURNS TEXT
LANGUAGE sql STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT role FROM public.project_members
  WHERE project_id = _project_id AND user_id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION private.shares_membership(_target_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT _target_user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.organization_members om1
      JOIN public.organization_members om2
        ON om1.organization_id = om2.organization_id
      WHERE om1.user_id = auth.uid() AND om2.user_id = _target_user_id
    )
    OR EXISTS (
      SELECT 1 FROM public.project_members pm1
      JOIN public.project_members pm2
        ON pm1.project_id = pm2.project_id
      WHERE pm1.user_id = auth.uid() AND pm2.user_id = _target_user_id
    );
$$;

-- Grant EXECUTE to authenticated (needed for RLS policy evaluation)
GRANT EXECUTE ON FUNCTION private.is_org_member(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION private.get_org_role(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION private.is_project_member(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION private.get_project_role(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION private.shares_membership(UUID) TO authenticated;

GRANT EXECUTE ON FUNCTION private.is_org_member(UUID) TO service_role;
GRANT EXECUTE ON FUNCTION private.get_org_role(UUID) TO service_role;
GRANT EXECUTE ON FUNCTION private.is_project_member(UUID) TO service_role;
GRANT EXECUTE ON FUNCTION private.get_project_role(UUID) TO service_role;
GRANT EXECUTE ON FUNCTION private.shares_membership(UUID) TO service_role;
