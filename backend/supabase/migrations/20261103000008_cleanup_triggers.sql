-- Phase 2 Migration 8: Trigger and Function Cleanup
-- Consolidates signup triggers (handle_new_user + handle_new_user_org → one)
-- Removes project creation trigger (replaced by RPC function)
-- Fixes SET search_path on existing functions

-- 1. Drop obsolete triggers
DROP TRIGGER IF EXISTS on_project_created ON public.projects;
DROP TRIGGER IF EXISTS on_auth_user_created_org ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- 2. Drop obsolete functions
DROP FUNCTION IF EXISTS public.handle_new_project();
DROP FUNCTION IF EXISTS public.handle_new_user_org();
DROP FUNCTION IF EXISTS public.handle_new_user();

-- 3. Consolidated signup handler
--    Creates: profile + personal org + owner membership + audit log
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  _display_name TEXT;
  _org_id UUID;
BEGIN
  _display_name := coalesce(
    NEW.raw_user_meta_data->>'display_name',
    split_part(NEW.email, '@', 1)
  );

  INSERT INTO public.profiles (id, display_name)
  VALUES (NEW.id, _display_name);

  INSERT INTO public.organizations (name, owner_id)
  VALUES (_display_name || '''s Organization', NEW.id)
  RETURNING id INTO _org_id;

  INSERT INTO public.organization_members (organization_id, user_id, role)
  VALUES (_org_id, NEW.id, 'owner');

  INSERT INTO public.audit_logs (user_id, action, entity, entity_id, metadata)
  VALUES (NEW.id, 'user_signup', 'profile', NEW.id,
    jsonb_build_object('email', NEW.email, 'org_id', _org_id));

  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 4. Fix update_updated_at (add SET search_path)
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;
