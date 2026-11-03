-- Phase 2 Migration 12: Public API Wrappers + Storage
-- Thin SECURITY INVOKER wrappers exposed via PostgREST

-- ============================================================
-- 1. CREATE ORGANIZATION
-- ============================================================

CREATE OR REPLACE FUNCTION public.create_organization(
  _name TEXT,
  _idempotency_key TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $$
BEGIN
  IF _name IS NULL THEN
    RAISE EXCEPTION 'invalid_input: name required';
  END IF;
  RETURN private.create_organization_impl(_name, _idempotency_key);
END;
$$;

-- ============================================================
-- 2. UPDATE ORGANIZATION
-- ============================================================

CREATE OR REPLACE FUNCTION public.update_organization(
  _org_id UUID,
  _expected_version INT,
  _name TEXT
)
RETURNS public.organizations
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $$
BEGIN
  IF _org_id IS NULL OR _name IS NULL THEN
    RAISE EXCEPTION 'invalid_input: org_id and name required';
  END IF;
  RETURN private.update_organization_impl(_org_id, _expected_version, _name);
END;
$$;

-- ============================================================
-- 3. DELETE ORGANIZATION
-- ============================================================

CREATE OR REPLACE FUNCTION public.delete_organization(
  _org_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $$
BEGIN
  IF _org_id IS NULL THEN
    RAISE EXCEPTION 'invalid_input: org_id required';
  END IF;
  PERFORM private.delete_organization_impl(_org_id);
END;
$$;

-- ============================================================
-- 4. TRANSFER ORGANIZATION OWNERSHIP
-- ============================================================

CREATE OR REPLACE FUNCTION public.transfer_org_ownership(
  _org_id UUID,
  _new_owner_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $$
BEGIN
  IF _org_id IS NULL OR _new_owner_id IS NULL THEN
    RAISE EXCEPTION 'invalid_input: org_id and new_owner_id required';
  END IF;
  PERFORM private.transfer_org_ownership_impl(_org_id, _new_owner_id);
END;
$$;

-- ============================================================
-- 5. CREATE PROJECT
-- ============================================================

CREATE OR REPLACE FUNCTION public.create_project(
  _organization_id UUID,
  _name TEXT,
  _description TEXT DEFAULT '',
  _category_id TEXT DEFAULT NULL,
  _icon TEXT DEFAULT 'folder',
  _color TEXT DEFAULT '#0891B2',
  _metadata JSONB DEFAULT '{}',
  _idempotency_key TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $$
BEGIN
  IF _organization_id IS NULL OR _name IS NULL THEN
    RAISE EXCEPTION 'invalid_input: organization_id and name required';
  END IF;
  RETURN private.create_project_impl(
    _organization_id, _name, _description, _category_id,
    _icon, _color, _metadata, _idempotency_key
  );
END;
$$;

-- ============================================================
-- 6. UPDATE PROJECT
-- ============================================================

CREATE OR REPLACE FUNCTION public.update_project(
  _project_id UUID,
  _expected_version INT,
  _name TEXT DEFAULT NULL,
  _description TEXT DEFAULT NULL,
  _icon TEXT DEFAULT NULL,
  _color TEXT DEFAULT NULL,
  _metadata JSONB DEFAULT NULL
)
RETURNS public.projects
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $$
BEGIN
  IF _project_id IS NULL THEN
    RAISE EXCEPTION 'invalid_input: project_id required';
  END IF;
  RETURN private.update_project_impl(
    _project_id, _expected_version, _name, _description,
    _icon, _color, _metadata
  );
END;
$$;

-- ============================================================
-- 7. DELETE PROJECT
-- ============================================================

CREATE OR REPLACE FUNCTION public.delete_project(
  _project_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $$
BEGIN
  IF _project_id IS NULL THEN
    RAISE EXCEPTION 'invalid_input: project_id required';
  END IF;
  PERFORM private.delete_project_impl(_project_id);
END;
$$;

-- ============================================================
-- 8. CREATE INVITATION
-- ============================================================

CREATE OR REPLACE FUNCTION public.create_invitation(
  _entity_type TEXT,
  _entity_id UUID,
  _email TEXT,
  _role TEXT
)
RETURNS TABLE(invitation_id UUID, token TEXT)
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $$
BEGIN
  IF _entity_type IS NULL OR _entity_id IS NULL
     OR _email IS NULL OR _role IS NULL THEN
    RAISE EXCEPTION 'invalid_input: all fields required';
  END IF;
  RETURN QUERY SELECT * FROM private.create_invitation_impl(
    _entity_type, _entity_id, _email, _role
  );
END;
$$;

-- ============================================================
-- 9. ACCEPT INVITATION
-- ============================================================

CREATE OR REPLACE FUNCTION public.accept_invitation(
  _token TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $$
BEGIN
  IF _token IS NULL THEN
    RAISE EXCEPTION 'invalid_input: token required';
  END IF;
  RETURN private.accept_invitation_impl(_token);
END;
$$;

-- ============================================================
-- 10. REJECT INVITATION
-- ============================================================

CREATE OR REPLACE FUNCTION public.reject_invitation(
  _token TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $$
BEGIN
  IF _token IS NULL THEN
    RAISE EXCEPTION 'invalid_input: token required';
  END IF;
  RETURN private.reject_invitation_impl(_token);
END;
$$;

-- ============================================================
-- 11. CANCEL INVITATION
-- ============================================================

CREATE OR REPLACE FUNCTION public.cancel_invitation(
  _invitation_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $$
BEGIN
  IF _invitation_id IS NULL THEN
    RAISE EXCEPTION 'invalid_input: invitation_id required';
  END IF;
  PERFORM private.cancel_invitation_impl(_invitation_id);
END;
$$;

-- ============================================================
-- 12. UPDATE MEMBER ROLE
-- ============================================================

CREATE OR REPLACE FUNCTION public.update_member_role(
  _entity_type TEXT,
  _entity_id UUID,
  _target_user_id UUID,
  _new_role TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $$
BEGIN
  IF _entity_type IS NULL OR _entity_id IS NULL
     OR _target_user_id IS NULL OR _new_role IS NULL THEN
    RAISE EXCEPTION 'invalid_input: all fields required';
  END IF;
  PERFORM private.update_member_role_impl(
    _entity_type, _entity_id, _target_user_id, _new_role
  );
END;
$$;

-- ============================================================
-- 13. REMOVE MEMBER
-- ============================================================

CREATE OR REPLACE FUNCTION public.remove_member(
  _entity_type TEXT,
  _entity_id UUID,
  _target_user_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $$
BEGIN
  IF _entity_type IS NULL OR _entity_id IS NULL
     OR _target_user_id IS NULL THEN
    RAISE EXCEPTION 'invalid_input: all fields required';
  END IF;
  PERFORM private.remove_member_impl(
    _entity_type, _entity_id, _target_user_id
  );
END;
$$;

-- ============================================================
-- 14. UPDATE PROFILE
-- ============================================================

CREATE OR REPLACE FUNCTION public.update_profile(
  _expected_version INT,
  _display_name TEXT DEFAULT NULL,
  _avatar_url TEXT DEFAULT NULL
)
RETURNS public.profiles
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $$
BEGIN
  RETURN private.update_profile_impl(
    _expected_version, _display_name, _avatar_url
  );
END;
$$;

-- ============================================================
-- 15. GET CHANGES SINCE (sync cursor)
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_changes_since(
  _last_seq BIGINT DEFAULT 0,
  _limit INT DEFAULT 100
)
RETURNS TABLE(seq BIGINT, entity_type TEXT, entity_id UUID, action TEXT, created_at TIMESTAMPTZ)
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $$
BEGIN
  RETURN QUERY SELECT * FROM private.get_changes_since_impl(_last_seq, _limit);
END;
$$;

-- ============================================================
-- 16. DELETE ACCOUNT ADMIN (service_role only)
-- ============================================================

CREATE OR REPLACE FUNCTION public.delete_account_admin(
  _target_user_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $$
BEGIN
  IF _target_user_id IS NULL THEN
    RAISE EXCEPTION 'invalid_input: target_user_id required';
  END IF;
  PERFORM private.delete_account_impl(_target_user_id);
END;
$$;

-- ============================================================
-- GRANTS: Public wrappers
-- ============================================================

REVOKE ALL ON FUNCTION public.create_organization FROM PUBLIC;
REVOKE ALL ON FUNCTION public.update_organization FROM PUBLIC;
REVOKE ALL ON FUNCTION public.delete_organization FROM PUBLIC;
REVOKE ALL ON FUNCTION public.transfer_org_ownership FROM PUBLIC;
REVOKE ALL ON FUNCTION public.create_project FROM PUBLIC;
REVOKE ALL ON FUNCTION public.update_project FROM PUBLIC;
REVOKE ALL ON FUNCTION public.delete_project FROM PUBLIC;
REVOKE ALL ON FUNCTION public.create_invitation FROM PUBLIC;
REVOKE ALL ON FUNCTION public.accept_invitation FROM PUBLIC;
REVOKE ALL ON FUNCTION public.reject_invitation FROM PUBLIC;
REVOKE ALL ON FUNCTION public.cancel_invitation FROM PUBLIC;
REVOKE ALL ON FUNCTION public.update_member_role FROM PUBLIC;
REVOKE ALL ON FUNCTION public.remove_member FROM PUBLIC;
REVOKE ALL ON FUNCTION public.update_profile FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_changes_since FROM PUBLIC;
REVOKE ALL ON FUNCTION public.delete_account_admin FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.create_organization TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_organization TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_organization TO authenticated;
GRANT EXECUTE ON FUNCTION public.transfer_org_ownership TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_project TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_project TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_project TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_invitation TO authenticated;
GRANT EXECUTE ON FUNCTION public.accept_invitation TO authenticated;
GRANT EXECUTE ON FUNCTION public.reject_invitation TO authenticated;
GRANT EXECUTE ON FUNCTION public.cancel_invitation TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_member_role TO authenticated;
GRANT EXECUTE ON FUNCTION public.remove_member TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_profile TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_changes_since TO authenticated;

-- delete_account_admin: service_role ONLY
REVOKE ALL ON FUNCTION public.delete_account_admin FROM authenticated;
GRANT EXECUTE ON FUNCTION public.delete_account_admin TO service_role;

-- ============================================================
-- STORAGE: Avatars bucket
-- ============================================================

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'avatars', 'avatars', false, 2097152,
  ARRAY['image/png', 'image/jpeg', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY avatar_insert ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY avatar_select ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'avatars'
    AND (
      (storage.foldername(name))[1] = auth.uid()::text
      OR private.shares_membership(((storage.foldername(name))[1])::uuid)
    )
  );

CREATE POLICY avatar_update ON storage.objects
  FOR UPDATE TO authenticated
  USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY avatar_delete ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
