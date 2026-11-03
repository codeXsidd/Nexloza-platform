-- Phase 2 Migration 10: RLS Policy Overhaul
-- Drops all 22 existing policies, creates 32 new ones
-- Blocks ALL direct mutations; everything goes through SECURITY DEFINER functions

-- ============================================================
-- DROP ALL 22 EXISTING POLICIES (exact names from M1-M5)
-- ============================================================

DROP POLICY IF EXISTS profiles_select ON public.profiles;
DROP POLICY IF EXISTS profiles_insert ON public.profiles;
DROP POLICY IF EXISTS profiles_update ON public.profiles;
DROP POLICY IF EXISTS profiles_delete ON public.profiles;

DROP POLICY IF EXISTS orgs_select ON public.organizations;
DROP POLICY IF EXISTS orgs_insert ON public.organizations;
DROP POLICY IF EXISTS orgs_update ON public.organizations;
DROP POLICY IF EXISTS orgs_delete ON public.organizations;

DROP POLICY IF EXISTS org_members_select ON public.organization_members;
DROP POLICY IF EXISTS org_members_insert ON public.organization_members;
DROP POLICY IF EXISTS org_members_delete ON public.organization_members;

DROP POLICY IF EXISTS categories_select ON public.project_categories;

DROP POLICY IF EXISTS projects_select ON public.projects;
DROP POLICY IF EXISTS projects_insert ON public.projects;
DROP POLICY IF EXISTS projects_update ON public.projects;
DROP POLICY IF EXISTS projects_delete ON public.projects;

DROP POLICY IF EXISTS pm_select ON public.project_members;
DROP POLICY IF EXISTS pm_insert ON public.project_members;
DROP POLICY IF EXISTS pm_update ON public.project_members;
DROP POLICY IF EXISTS pm_delete ON public.project_members;

DROP POLICY IF EXISTS audit_select ON public.audit_logs;
DROP POLICY IF EXISTS audit_insert ON public.audit_logs;

-- ============================================================
-- REVOKE TABLE-LEVEL GRANTS (defense in depth)
-- ============================================================

REVOKE INSERT, UPDATE, DELETE ON public.profiles FROM authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.organizations FROM authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.organization_members FROM authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.project_categories FROM authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.projects FROM authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.project_members FROM authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.invitations FROM authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.audit_logs FROM authenticated;

REVOKE ALL ON public.profiles FROM anon;
REVOKE ALL ON public.organizations FROM anon;
REVOKE ALL ON public.organization_members FROM anon;
REVOKE ALL ON public.project_categories FROM anon;
REVOKE ALL ON public.projects FROM anon;
REVOKE ALL ON public.project_members FROM anon;
REVOKE ALL ON public.invitations FROM anon;
REVOKE ALL ON public.audit_logs FROM anon;

GRANT SELECT ON public.project_categories TO anon;

-- ============================================================
-- CREATE 32 NEW POLICIES (8 tables x 4 operations)
-- ============================================================

-- PROFILES (4)
CREATE POLICY profiles_select_v2 ON public.profiles
  FOR SELECT TO authenticated
  USING (private.shares_membership(id));

CREATE POLICY profiles_insert_v2 ON public.profiles
  FOR INSERT TO authenticated
  WITH CHECK (false);

CREATE POLICY profiles_update_v2 ON public.profiles
  FOR UPDATE TO authenticated
  USING (false);

CREATE POLICY profiles_delete_v2 ON public.profiles
  FOR DELETE TO authenticated
  USING (false);

-- ORGANIZATIONS (4)
CREATE POLICY orgs_select_v2 ON public.organizations
  FOR SELECT TO authenticated
  USING (private.is_org_member(id));

CREATE POLICY orgs_insert_v2 ON public.organizations
  FOR INSERT TO authenticated
  WITH CHECK (false);

CREATE POLICY orgs_update_v2 ON public.organizations
  FOR UPDATE TO authenticated
  USING (false);

CREATE POLICY orgs_delete_v2 ON public.organizations
  FOR DELETE TO authenticated
  USING (false);

-- ORGANIZATION MEMBERS (4)
CREATE POLICY om_select_v2 ON public.organization_members
  FOR SELECT TO authenticated
  USING (private.is_org_member(organization_id));

CREATE POLICY om_insert_v2 ON public.organization_members
  FOR INSERT TO authenticated
  WITH CHECK (false);

CREATE POLICY om_update_v2 ON public.organization_members
  FOR UPDATE TO authenticated
  USING (false);

CREATE POLICY om_delete_v2 ON public.organization_members
  FOR DELETE TO authenticated
  USING (false);

-- PROJECT CATEGORIES (4)
CREATE POLICY cat_select_v2 ON public.project_categories
  FOR SELECT
  USING (true);

CREATE POLICY cat_insert_v2 ON public.project_categories
  FOR INSERT TO authenticated
  WITH CHECK (false);

CREATE POLICY cat_update_v2 ON public.project_categories
  FOR UPDATE TO authenticated
  USING (false);

CREATE POLICY cat_delete_v2 ON public.project_categories
  FOR DELETE TO authenticated
  USING (false);

-- PROJECTS (4)
CREATE POLICY proj_select_v2 ON public.projects
  FOR SELECT TO authenticated
  USING (
    private.is_project_member(id)
    OR private.get_org_role(organization_id) = 'owner'
  );

CREATE POLICY proj_insert_v2 ON public.projects
  FOR INSERT TO authenticated
  WITH CHECK (false);

CREATE POLICY proj_update_v2 ON public.projects
  FOR UPDATE TO authenticated
  USING (false);

CREATE POLICY proj_delete_v2 ON public.projects
  FOR DELETE TO authenticated
  USING (false);

-- PROJECT MEMBERS (4)
CREATE POLICY pm_select_v2 ON public.project_members
  FOR SELECT TO authenticated
  USING (private.is_project_member(project_id));

CREATE POLICY pm_insert_v2 ON public.project_members
  FOR INSERT TO authenticated
  WITH CHECK (false);

CREATE POLICY pm_update_v2 ON public.project_members
  FOR UPDATE TO authenticated
  USING (false);

CREATE POLICY pm_delete_v2 ON public.project_members
  FOR DELETE TO authenticated
  USING (false);

-- INVITATIONS (4)
CREATE POLICY inv_select_v2 ON public.invitations
  FOR SELECT TO authenticated
  USING (
    CASE entity_type
      WHEN 'organization' THEN
        private.get_org_role(entity_id) IN ('owner', 'admin')
      WHEN 'project' THEN
        private.get_project_role(entity_id) IN ('owner', 'admin')
      ELSE false
    END
    OR invited_email = lower(
      current_setting('request.jwt.claims', true)::jsonb->>'email'
    )
  );

CREATE POLICY inv_insert_v2 ON public.invitations
  FOR INSERT TO authenticated
  WITH CHECK (false);

CREATE POLICY inv_update_v2 ON public.invitations
  FOR UPDATE TO authenticated
  USING (false);

CREATE POLICY inv_delete_v2 ON public.invitations
  FOR DELETE TO authenticated
  USING (false);

-- AUDIT LOGS (4)
CREATE POLICY audit_select_v2 ON public.audit_logs
  FOR SELECT TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY audit_insert_v2 ON public.audit_logs
  FOR INSERT TO authenticated
  WITH CHECK (false);

CREATE POLICY audit_update_v2 ON public.audit_logs
  FOR UPDATE TO authenticated
  USING (false);

CREATE POLICY audit_delete_v2 ON public.audit_logs
  FOR DELETE TO authenticated
  USING (false);

-- ============================================================
-- TEMPLATE VIEW (sanitized: hides organization_id)
-- ============================================================

CREATE VIEW public.project_templates AS
SELECT id, name, description, category_id, icon, color, metadata
FROM public.projects WHERE is_template = true;

GRANT SELECT ON public.project_templates TO authenticated;
