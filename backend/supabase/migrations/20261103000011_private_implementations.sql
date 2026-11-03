-- Phase 2 Migration 11: Private Implementation Functions
-- All SECURITY DEFINER functions with SET search_path = ''
-- Called by public SECURITY INVOKER wrappers (M12)

-- ============================================================
-- 1. CREATE ORGANIZATION
-- ============================================================

CREATE OR REPLACE FUNCTION private.create_organization_impl(
  _name TEXT,
  _idempotency_key TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  _user_id UUID;
  _org_id UUID;
  _clean_name TEXT;
  _cached JSONB;
BEGIN
  _user_id := auth.uid();
  IF _user_id IS NULL THEN
    RAISE EXCEPTION 'authentication_required';
  END IF;

  IF _idempotency_key IS NOT NULL THEN
    SELECT result INTO _cached FROM private.idempotency_ledger
    WHERE key = _idempotency_key AND user_id = _user_id;
    IF FOUND THEN
      RETURN (_cached->>'organization_id')::UUID;
    END IF;
  END IF;

  _clean_name := trim(_name);
  IF _clean_name IS NULL OR char_length(_clean_name) < 1
     OR char_length(_clean_name) > 200 THEN
    RAISE EXCEPTION 'invalid_name: must be 1-200 characters';
  END IF;

  INSERT INTO public.organizations (name, owner_id)
  VALUES (_clean_name, _user_id)
  RETURNING id INTO _org_id;

  INSERT INTO public.organization_members (organization_id, user_id, role)
  VALUES (_org_id, _user_id, 'owner');

  INSERT INTO public.audit_logs (user_id, action, entity, entity_id, metadata)
  VALUES (_user_id, 'organization_created', 'organization', _org_id,
    jsonb_build_object('name', _clean_name));

  INSERT INTO private.change_log (entity_type, entity_id, action, user_id)
  VALUES ('organization', _org_id, 'insert', _user_id);

  IF _idempotency_key IS NOT NULL THEN
    INSERT INTO private.idempotency_ledger (key, user_id, result)
    VALUES (_idempotency_key, _user_id,
      jsonb_build_object('organization_id', _org_id))
    ON CONFLICT (key) DO NOTHING;
  END IF;

  RETURN _org_id;
END;
$$;

-- ============================================================
-- 2. UPDATE ORGANIZATION
-- ============================================================

CREATE OR REPLACE FUNCTION private.update_organization_impl(
  _org_id UUID,
  _expected_version INT,
  _name TEXT
)
RETURNS public.organizations
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  _user_id UUID;
  _org_role TEXT;
  _clean_name TEXT;
  _result public.organizations;
BEGIN
  _user_id := auth.uid();
  IF _user_id IS NULL THEN
    RAISE EXCEPTION 'authentication_required';
  END IF;

  SELECT role INTO _org_role
  FROM public.organization_members
  WHERE organization_id = _org_id AND user_id = _user_id
  FOR SHARE;

  IF _org_role IS NULL OR _org_role NOT IN ('owner', 'admin') THEN
    RAISE EXCEPTION 'insufficient_permissions';
  END IF;

  _clean_name := trim(_name);
  IF _clean_name IS NULL OR char_length(_clean_name) < 1
     OR char_length(_clean_name) > 200 THEN
    RAISE EXCEPTION 'invalid_name: must be 1-200 characters';
  END IF;

  UPDATE public.organizations
  SET name = _clean_name
  WHERE id = _org_id AND version = _expected_version
  RETURNING * INTO _result;

  IF NOT FOUND THEN
    IF EXISTS (SELECT 1 FROM public.organizations WHERE id = _org_id) THEN
      RAISE EXCEPTION 'version_conflict';
    ELSE
      RAISE EXCEPTION 'organization_not_found';
    END IF;
  END IF;

  INSERT INTO public.audit_logs (user_id, action, entity, entity_id, metadata)
  VALUES (_user_id, 'organization_updated', 'organization', _org_id,
    jsonb_build_object('name', _clean_name));

  INSERT INTO private.change_log (entity_type, entity_id, action, user_id)
  VALUES ('organization', _org_id, 'update', _user_id);

  RETURN _result;
END;
$$;

-- ============================================================
-- 3. DELETE ORGANIZATION
-- ============================================================

CREATE OR REPLACE FUNCTION private.delete_organization_impl(
  _org_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  _user_id UUID;
  _org RECORD;
BEGIN
  _user_id := auth.uid();
  IF _user_id IS NULL THEN
    RAISE EXCEPTION 'authentication_required';
  END IF;

  SELECT * INTO _org FROM public.organizations
  WHERE id = _org_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'organization_not_found';
  END IF;

  IF _org.owner_id != _user_id THEN
    RAISE EXCEPTION 'insufficient_permissions: only owner can delete';
  END IF;

  INSERT INTO public.audit_logs (user_id, action, entity, entity_id, metadata)
  VALUES (_user_id, 'organization_deleted', 'organization', _org_id,
    jsonb_build_object('name', _org.name));

  INSERT INTO private.change_log (entity_type, entity_id, action, user_id)
  VALUES ('organization', _org_id, 'delete', _user_id);

  DELETE FROM public.organizations WHERE id = _org_id;
END;
$$;

-- ============================================================
-- 4. TRANSFER ORGANIZATION OWNERSHIP
-- ============================================================

CREATE OR REPLACE FUNCTION private.transfer_org_ownership_impl(
  _org_id UUID,
  _new_owner_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  _user_id UUID;
  _org RECORD;
  _new_owner_member RECORD;
BEGIN
  _user_id := auth.uid();
  IF _user_id IS NULL THEN
    RAISE EXCEPTION 'authentication_required';
  END IF;

  IF _new_owner_id = _user_id THEN
    RAISE EXCEPTION 'invalid_input: cannot transfer to yourself';
  END IF;

  SELECT * INTO _org FROM public.organizations
  WHERE id = _org_id FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'organization_not_found';
  END IF;

  IF _org.owner_id != _user_id THEN
    RAISE EXCEPTION 'insufficient_permissions: only owner can transfer';
  END IF;

  SELECT * INTO _new_owner_member FROM public.organization_members
  WHERE organization_id = _org_id AND user_id = _new_owner_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'user_not_a_member';
  END IF;

  UPDATE public.organizations SET owner_id = _new_owner_id WHERE id = _org_id;
  UPDATE public.organization_members SET role = 'admin'
  WHERE organization_id = _org_id AND user_id = _user_id;
  UPDATE public.organization_members SET role = 'owner'
  WHERE organization_id = _org_id AND user_id = _new_owner_id;

  INSERT INTO public.audit_logs (user_id, action, entity, entity_id, metadata)
  VALUES (_user_id, 'ownership_transferred', 'organization', _org_id,
    jsonb_build_object('new_owner', _new_owner_id));

  INSERT INTO private.change_log (entity_type, entity_id, action, user_id)
  VALUES ('organization', _org_id, 'update', _user_id);
END;
$$;

-- ============================================================
-- 5. CREATE PROJECT
-- ============================================================

CREATE OR REPLACE FUNCTION private.create_project_impl(
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
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  _project_id UUID;
  _user_id UUID;
  _org_role TEXT;
  _clean_name TEXT;
  _cached JSONB;
BEGIN
  _user_id := auth.uid();
  IF _user_id IS NULL THEN
    RAISE EXCEPTION 'authentication_required';
  END IF;

  IF _idempotency_key IS NOT NULL THEN
    SELECT result INTO _cached FROM private.idempotency_ledger
    WHERE key = _idempotency_key AND user_id = _user_id;
    IF FOUND THEN
      RETURN (_cached->>'project_id')::UUID;
    END IF;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.organizations WHERE id = _organization_id
  ) THEN
    RAISE EXCEPTION 'organization_not_found';
  END IF;

  SELECT role INTO _org_role
  FROM public.organization_members
  WHERE organization_id = _organization_id AND user_id = _user_id
  FOR SHARE;

  IF _org_role IS NULL OR _org_role NOT IN ('owner', 'admin') THEN
    RAISE EXCEPTION 'insufficient_org_permissions';
  END IF;

  _clean_name := trim(_name);
  IF _clean_name IS NULL OR char_length(_clean_name) < 1
     OR char_length(_clean_name) > 200 THEN
    RAISE EXCEPTION 'invalid_name: must be 1-200 characters';
  END IF;

  IF _category_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.project_categories WHERE id = _category_id
  ) THEN
    RAISE EXCEPTION 'invalid_category';
  END IF;

  IF _color IS NOT NULL AND _color !~ '^#[0-9a-fA-F]{6}$' THEN
    RAISE EXCEPTION 'invalid_color: must be hex #RRGGBB';
  END IF;

  IF _metadata IS NOT NULL AND jsonb_typeof(_metadata) != 'object' THEN
    RAISE EXCEPTION 'invalid_metadata: must be a JSON object';
  END IF;
  IF _metadata IS NOT NULL AND octet_length(_metadata::text) > 10240 THEN
    RAISE EXCEPTION 'invalid_metadata: exceeds 10KB';
  END IF;

  INSERT INTO public.projects (
    organization_id, name, description, category_id, icon, color, metadata
  ) VALUES (
    _organization_id,
    _clean_name,
    coalesce(left(_description, 2000), ''),
    _category_id,
    coalesce(left(_icon, 50), 'folder'),
    coalesce(_color, '#0891B2'),
    coalesce(_metadata, '{}')
  ) RETURNING id INTO _project_id;

  INSERT INTO public.project_members (project_id, user_id, role)
  VALUES (_project_id, _user_id, 'owner');

  INSERT INTO public.audit_logs (user_id, action, entity, entity_id, metadata)
  VALUES (_user_id, 'project_created', 'project', _project_id,
    jsonb_build_object('name', _clean_name, 'org_id', _organization_id));

  INSERT INTO private.change_log (entity_type, entity_id, action, user_id)
  VALUES ('project', _project_id, 'insert', _user_id);

  IF _idempotency_key IS NOT NULL THEN
    INSERT INTO private.idempotency_ledger (key, user_id, result)
    VALUES (_idempotency_key, _user_id,
      jsonb_build_object('project_id', _project_id))
    ON CONFLICT (key) DO NOTHING;
  END IF;

  RETURN _project_id;
END;
$$;

-- ============================================================
-- 6. UPDATE PROJECT
-- ============================================================

CREATE OR REPLACE FUNCTION private.update_project_impl(
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
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  _user_id UUID;
  _proj_role TEXT;
  _result public.projects;
BEGIN
  _user_id := auth.uid();
  IF _user_id IS NULL THEN
    RAISE EXCEPTION 'authentication_required';
  END IF;

  SELECT role INTO _proj_role
  FROM public.project_members
  WHERE project_id = _project_id AND user_id = _user_id
  FOR SHARE;

  IF _proj_role IS NULL OR _proj_role NOT IN ('owner', 'admin', 'editor') THEN
    RAISE EXCEPTION 'insufficient_permissions';
  END IF;

  IF _name IS NULL AND _description IS NULL AND _icon IS NULL
     AND _color IS NULL AND _metadata IS NULL THEN
    RAISE EXCEPTION 'no_changes: at least one field required';
  END IF;

  IF _name IS NOT NULL THEN
    _name := trim(_name);
    IF char_length(_name) < 1 OR char_length(_name) > 200 THEN
      RAISE EXCEPTION 'invalid_name: must be 1-200 characters';
    END IF;
  END IF;

  IF _color IS NOT NULL AND _color !~ '^#[0-9a-fA-F]{6}$' THEN
    RAISE EXCEPTION 'invalid_color: must be hex #RRGGBB';
  END IF;

  IF _metadata IS NOT NULL THEN
    IF jsonb_typeof(_metadata) != 'object' THEN
      RAISE EXCEPTION 'invalid_metadata: must be a JSON object';
    END IF;
    IF octet_length(_metadata::text) > 10240 THEN
      RAISE EXCEPTION 'invalid_metadata: exceeds 10KB';
    END IF;
  END IF;

  UPDATE public.projects
  SET
    name = coalesce(_name, name),
    description = coalesce(left(_description, 2000), description),
    icon = coalesce(left(_icon, 50), icon),
    color = coalesce(_color, color),
    metadata = coalesce(_metadata, metadata)
  WHERE id = _project_id AND version = _expected_version
  RETURNING * INTO _result;

  IF NOT FOUND THEN
    IF EXISTS (SELECT 1 FROM public.projects WHERE id = _project_id) THEN
      RAISE EXCEPTION 'version_conflict';
    ELSE
      RAISE EXCEPTION 'project_not_found';
    END IF;
  END IF;

  INSERT INTO public.audit_logs (user_id, action, entity, entity_id)
  VALUES (_user_id, 'project_updated', 'project', _project_id);

  INSERT INTO private.change_log (entity_type, entity_id, action, user_id)
  VALUES ('project', _project_id, 'update', _user_id);

  RETURN _result;
END;
$$;

-- ============================================================
-- 7. DELETE PROJECT
-- ============================================================

CREATE OR REPLACE FUNCTION private.delete_project_impl(
  _project_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  _user_id UUID;
  _proj_role TEXT;
  _proj RECORD;
BEGIN
  _user_id := auth.uid();
  IF _user_id IS NULL THEN
    RAISE EXCEPTION 'authentication_required';
  END IF;

  SELECT role INTO _proj_role
  FROM public.project_members
  WHERE project_id = _project_id AND user_id = _user_id
  FOR SHARE;

  IF _proj_role IS NULL OR _proj_role != 'owner' THEN
    RAISE EXCEPTION 'insufficient_permissions: only owner can delete';
  END IF;

  SELECT * INTO _proj FROM public.projects WHERE id = _project_id;

  INSERT INTO public.audit_logs (user_id, action, entity, entity_id, metadata)
  VALUES (_user_id, 'project_deleted', 'project', _project_id,
    jsonb_build_object('name', _proj.name));

  INSERT INTO private.change_log (entity_type, entity_id, action, user_id)
  VALUES ('project', _project_id, 'delete', _user_id);

  DELETE FROM public.projects WHERE id = _project_id;
END;
$$;

-- ============================================================
-- 8. CREATE INVITATION (returns invitation_id + raw token)
-- ============================================================

CREATE OR REPLACE FUNCTION private.create_invitation_impl(
  _entity_type TEXT,
  _entity_id UUID,
  _email TEXT,
  _role TEXT
)
RETURNS TABLE(invitation_id UUID, token TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  _user_id UUID;
  _caller_role TEXT;
  _clean_email TEXT;
  _raw_token TEXT;
  _token_hash TEXT;
  _inv_id UUID;
BEGIN
  _user_id := auth.uid();
  IF _user_id IS NULL THEN
    RAISE EXCEPTION 'authentication_required';
  END IF;

  IF _entity_type NOT IN ('organization', 'project') THEN
    RAISE EXCEPTION 'invalid_entity_type';
  END IF;

  _clean_email := lower(trim(_email));
  IF _clean_email IS NULL OR _clean_email !~ '^[^@]+@[^@]+\.[^@]+$' THEN
    RAISE EXCEPTION 'invalid_email';
  END IF;

  IF _entity_type = 'organization' THEN
    IF NOT EXISTS (SELECT 1 FROM public.organizations WHERE id = _entity_id) THEN
      RAISE EXCEPTION 'entity_not_found';
    END IF;

    SELECT om.role INTO _caller_role
    FROM public.organization_members om
    WHERE om.organization_id = _entity_id AND om.user_id = _user_id
    FOR SHARE;

    IF _caller_role IS NULL OR _caller_role NOT IN ('owner', 'admin') THEN
      RAISE EXCEPTION 'insufficient_permissions';
    END IF;

    IF _caller_role = 'admin' AND _role = 'admin' THEN
      RAISE EXCEPTION 'privilege_escalation: admin cannot grant admin';
    END IF;

  ELSIF _entity_type = 'project' THEN
    IF NOT EXISTS (SELECT 1 FROM public.projects WHERE id = _entity_id) THEN
      RAISE EXCEPTION 'entity_not_found';
    END IF;

    SELECT pm.role INTO _caller_role
    FROM public.project_members pm
    WHERE pm.project_id = _entity_id AND pm.user_id = _user_id
    FOR SHARE;

    IF _caller_role IS NULL OR _caller_role NOT IN ('owner', 'admin') THEN
      RAISE EXCEPTION 'insufficient_permissions';
    END IF;

    IF _caller_role = 'admin' AND _role = 'admin' THEN
      RAISE EXCEPTION 'privilege_escalation: admin cannot grant admin';
    END IF;
  END IF;

  UPDATE public.invitations SET status = 'expired'
  WHERE entity_type = _entity_type
    AND entity_id = _entity_id
    AND invited_email = _clean_email
    AND status = 'pending'
    AND expires_at <= now();

  _raw_token := encode(gen_random_bytes(32), 'hex');
  _token_hash := encode(sha256(_raw_token::bytea), 'hex');

  INSERT INTO public.invitations (
    entity_type, entity_id, invited_email, invited_by, role, token_hash
  ) VALUES (
    _entity_type, _entity_id, _clean_email, _user_id, _role, _token_hash
  ) RETURNING id INTO _inv_id;

  INSERT INTO public.audit_logs (user_id, action, entity, entity_id, metadata)
  VALUES (_user_id, 'invitation_created', _entity_type, _entity_id,
    jsonb_build_object('email', _clean_email, 'role', _role));

  RETURN QUERY SELECT _inv_id, _raw_token;
END;
$$;

-- ============================================================
-- 9. ACCEPT INVITATION
-- ============================================================

CREATE OR REPLACE FUNCTION private.accept_invitation_impl(
  _token TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  _user_id UUID;
  _user_email TEXT;
  _token_hash TEXT;
  _inv RECORD;
  _inviter_role TEXT;
BEGIN
  _user_id := auth.uid();
  IF _user_id IS NULL THEN
    RAISE EXCEPTION 'authentication_required';
  END IF;

  IF _token IS NULL OR char_length(_token) = 0 THEN
    RAISE EXCEPTION 'invalid_token';
  END IF;

  _token_hash := encode(sha256(_token::bytea), 'hex');

  SELECT * INTO _inv FROM public.invitations
  WHERE token_hash = _token_hash
    AND status = 'pending'
    AND expires_at > now()
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'invitation_invalid_or_expired';
  END IF;

  SELECT email INTO _user_email FROM auth.users WHERE id = _user_id;
  IF lower(_user_email) != _inv.invited_email THEN
    RAISE EXCEPTION 'email_mismatch';
  END IF;

  IF _inv.entity_type = 'organization' THEN
    IF NOT EXISTS (SELECT 1 FROM public.organizations WHERE id = _inv.entity_id) THEN
      UPDATE public.invitations SET status = 'expired' WHERE id = _inv.id;
      RAISE EXCEPTION 'entity_deleted';
    END IF;
  ELSIF _inv.entity_type = 'project' THEN
    IF NOT EXISTS (SELECT 1 FROM public.projects WHERE id = _inv.entity_id) THEN
      UPDATE public.invitations SET status = 'expired' WHERE id = _inv.id;
      RAISE EXCEPTION 'entity_deleted';
    END IF;
  END IF;

  IF _inv.invited_by IS NOT NULL THEN
    IF _inv.entity_type = 'organization' THEN
      SELECT role INTO _inviter_role FROM public.organization_members
      WHERE organization_id = _inv.entity_id AND user_id = _inv.invited_by
      FOR SHARE;

      IF _inviter_role IS NULL OR _inviter_role NOT IN ('owner', 'admin') THEN
        RAISE EXCEPTION 'inviter_no_longer_authorized';
      END IF;
      IF _inv.role = 'admin' AND _inviter_role != 'owner' THEN
        RAISE EXCEPTION 'inviter_no_longer_authorized';
      END IF;

    ELSIF _inv.entity_type = 'project' THEN
      SELECT role INTO _inviter_role FROM public.project_members
      WHERE project_id = _inv.entity_id AND user_id = _inv.invited_by
      FOR SHARE;

      IF _inviter_role IS NULL OR _inviter_role NOT IN ('owner', 'admin') THEN
        RAISE EXCEPTION 'inviter_no_longer_authorized';
      END IF;
      IF _inv.role = 'admin' AND _inviter_role != 'owner' THEN
        RAISE EXCEPTION 'inviter_no_longer_authorized';
      END IF;
    END IF;
  END IF;

  IF _inv.entity_type = 'organization' THEN
    INSERT INTO public.organization_members (organization_id, user_id, role)
    VALUES (_inv.entity_id, _user_id, _inv.role)
    ON CONFLICT (organization_id, user_id) DO NOTHING;
  ELSIF _inv.entity_type = 'project' THEN
    INSERT INTO public.project_members (project_id, user_id, role)
    VALUES (_inv.entity_id, _user_id, _inv.role)
    ON CONFLICT (project_id, user_id) DO NOTHING;
  END IF;

  UPDATE public.invitations
  SET status = 'accepted', responded_at = now()
  WHERE id = _inv.id;

  INSERT INTO public.audit_logs (user_id, action, entity, entity_id, metadata)
  VALUES (_user_id, 'invitation_accepted', _inv.entity_type, _inv.entity_id,
    jsonb_build_object('role', _inv.role, 'invitation_id', _inv.id));

  INSERT INTO private.change_log (entity_type, entity_id, action, user_id)
  VALUES (_inv.entity_type, _inv.entity_id, 'update', _user_id);

  RETURN _inv.entity_id;
END;
$$;

-- ============================================================
-- 10. REJECT INVITATION
-- ============================================================

CREATE OR REPLACE FUNCTION private.reject_invitation_impl(
  _token TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  _user_id UUID;
  _user_email TEXT;
  _token_hash TEXT;
  _inv RECORD;
BEGIN
  _user_id := auth.uid();
  IF _user_id IS NULL THEN
    RAISE EXCEPTION 'authentication_required';
  END IF;

  _token_hash := encode(sha256(_token::bytea), 'hex');

  SELECT * INTO _inv FROM public.invitations
  WHERE token_hash = _token_hash
    AND status = 'pending'
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'invitation_not_found';
  END IF;

  SELECT email INTO _user_email FROM auth.users WHERE id = _user_id;
  IF lower(_user_email) != _inv.invited_email THEN
    RAISE EXCEPTION 'email_mismatch';
  END IF;

  UPDATE public.invitations
  SET status = 'rejected', responded_at = now()
  WHERE id = _inv.id;

  RETURN _inv.entity_id;
END;
$$;

-- ============================================================
-- 11. CANCEL INVITATION
-- ============================================================

CREATE OR REPLACE FUNCTION private.cancel_invitation_impl(
  _invitation_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  _user_id UUID;
  _inv RECORD;
  _caller_role TEXT;
BEGIN
  _user_id := auth.uid();
  IF _user_id IS NULL THEN
    RAISE EXCEPTION 'authentication_required';
  END IF;

  SELECT * INTO _inv FROM public.invitations
  WHERE id = _invitation_id AND status = 'pending'
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'invitation_not_found_or_not_pending';
  END IF;

  IF _inv.entity_type = 'organization' THEN
    SELECT role INTO _caller_role FROM public.organization_members
    WHERE organization_id = _inv.entity_id AND user_id = _user_id;
    IF _caller_role IS NULL OR _caller_role NOT IN ('owner', 'admin') THEN
      RAISE EXCEPTION 'insufficient_permissions';
    END IF;
  ELSIF _inv.entity_type = 'project' THEN
    SELECT role INTO _caller_role FROM public.project_members
    WHERE project_id = _inv.entity_id AND user_id = _user_id;
    IF _caller_role IS NULL OR _caller_role NOT IN ('owner', 'admin') THEN
      RAISE EXCEPTION 'insufficient_permissions';
    END IF;
  END IF;

  UPDATE public.invitations
  SET status = 'expired', responded_at = now()
  WHERE id = _invitation_id;

  INSERT INTO public.audit_logs (user_id, action, entity, entity_id, metadata)
  VALUES (_user_id, 'invitation_cancelled', _inv.entity_type, _inv.entity_id,
    jsonb_build_object('invitation_id', _invitation_id));
END;
$$;

-- ============================================================
-- 12. UPDATE MEMBER ROLE
-- ============================================================

CREATE OR REPLACE FUNCTION private.update_member_role_impl(
  _entity_type TEXT,
  _entity_id UUID,
  _target_user_id UUID,
  _new_role TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  _user_id UUID;
  _caller_role TEXT;
  _target_role TEXT;
BEGIN
  _user_id := auth.uid();
  IF _user_id IS NULL THEN
    RAISE EXCEPTION 'authentication_required';
  END IF;

  IF _target_user_id = _user_id THEN
    RAISE EXCEPTION 'cannot_modify_own_role';
  END IF;

  IF _entity_type = 'organization' THEN
    IF _new_role NOT IN ('admin', 'member') THEN
      RAISE EXCEPTION 'invalid_role';
    END IF;

    SELECT role INTO _caller_role FROM public.organization_members
    WHERE organization_id = _entity_id AND user_id = _user_id
    FOR SHARE;

    IF _caller_role IS NULL OR _caller_role NOT IN ('owner', 'admin') THEN
      RAISE EXCEPTION 'insufficient_permissions';
    END IF;

    IF _new_role = 'admin' AND _caller_role != 'owner' THEN
      RAISE EXCEPTION 'privilege_escalation: only owner can grant admin';
    END IF;

    SELECT role INTO _target_role FROM public.organization_members
    WHERE organization_id = _entity_id AND user_id = _target_user_id
    FOR UPDATE;

    IF _target_role IS NULL THEN
      RAISE EXCEPTION 'user_not_a_member';
    END IF;

    IF _target_role = 'owner' THEN
      RAISE EXCEPTION 'cannot_modify_owner: use transfer_ownership';
    END IF;

    UPDATE public.organization_members
    SET role = _new_role
    WHERE organization_id = _entity_id AND user_id = _target_user_id;

  ELSIF _entity_type = 'project' THEN
    IF _new_role NOT IN ('admin', 'editor', 'viewer') THEN
      RAISE EXCEPTION 'invalid_role';
    END IF;

    SELECT role INTO _caller_role FROM public.project_members
    WHERE project_id = _entity_id AND user_id = _user_id
    FOR SHARE;

    IF _caller_role IS NULL OR _caller_role NOT IN ('owner', 'admin') THEN
      RAISE EXCEPTION 'insufficient_permissions';
    END IF;

    IF _new_role = 'admin' AND _caller_role != 'owner' THEN
      RAISE EXCEPTION 'privilege_escalation: only owner can grant admin';
    END IF;

    SELECT role INTO _target_role FROM public.project_members
    WHERE project_id = _entity_id AND user_id = _target_user_id
    FOR UPDATE;

    IF _target_role IS NULL THEN
      RAISE EXCEPTION 'user_not_a_member';
    END IF;

    IF _target_role = 'owner' THEN
      RAISE EXCEPTION 'cannot_modify_owner: use transfer_ownership';
    END IF;

    UPDATE public.project_members
    SET role = _new_role
    WHERE project_id = _entity_id AND user_id = _target_user_id;
  ELSE
    RAISE EXCEPTION 'invalid_entity_type';
  END IF;

  INSERT INTO public.audit_logs (user_id, action, entity, entity_id, metadata)
  VALUES (_user_id, 'member_role_updated', _entity_type, _entity_id,
    jsonb_build_object('target', _target_user_id, 'new_role', _new_role));
END;
$$;

-- ============================================================
-- 13. REMOVE MEMBER
-- ============================================================

CREATE OR REPLACE FUNCTION private.remove_member_impl(
  _entity_type TEXT,
  _entity_id UUID,
  _target_user_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  _user_id UUID;
  _caller_role TEXT;
  _target_role TEXT;
  _is_self BOOLEAN;
BEGIN
  _user_id := auth.uid();
  IF _user_id IS NULL THEN
    RAISE EXCEPTION 'authentication_required';
  END IF;

  _is_self := (_target_user_id = _user_id);

  IF _entity_type = 'organization' THEN
    SELECT role INTO _target_role FROM public.organization_members
    WHERE organization_id = _entity_id AND user_id = _target_user_id
    FOR UPDATE;

    IF _target_role IS NULL THEN
      RAISE EXCEPTION 'user_not_a_member';
    END IF;

    IF _target_role = 'owner' THEN
      RAISE EXCEPTION 'cannot_remove_owner: transfer ownership first';
    END IF;

    IF NOT _is_self THEN
      SELECT role INTO _caller_role FROM public.organization_members
      WHERE organization_id = _entity_id AND user_id = _user_id
      FOR SHARE;

      IF _caller_role IS NULL OR _caller_role NOT IN ('owner', 'admin') THEN
        RAISE EXCEPTION 'insufficient_permissions';
      END IF;
    END IF;

    DELETE FROM public.organization_members
    WHERE organization_id = _entity_id AND user_id = _target_user_id;

  ELSIF _entity_type = 'project' THEN
    SELECT role INTO _target_role FROM public.project_members
    WHERE project_id = _entity_id AND user_id = _target_user_id
    FOR UPDATE;

    IF _target_role IS NULL THEN
      RAISE EXCEPTION 'user_not_a_member';
    END IF;

    IF _target_role = 'owner' THEN
      RAISE EXCEPTION 'cannot_remove_owner: transfer ownership first';
    END IF;

    IF NOT _is_self THEN
      SELECT role INTO _caller_role FROM public.project_members
      WHERE project_id = _entity_id AND user_id = _user_id
      FOR SHARE;

      IF _caller_role IS NULL OR _caller_role NOT IN ('owner', 'admin') THEN
        RAISE EXCEPTION 'insufficient_permissions';
      END IF;
    END IF;

    DELETE FROM public.project_members
    WHERE project_id = _entity_id AND user_id = _target_user_id;
  ELSE
    RAISE EXCEPTION 'invalid_entity_type';
  END IF;

  INSERT INTO public.audit_logs (user_id, action, entity, entity_id, metadata)
  VALUES (_user_id, 'member_removed', _entity_type, _entity_id,
    jsonb_build_object('target', _target_user_id, 'self', _is_self));

  INSERT INTO private.change_log (entity_type, entity_id, action, user_id)
  VALUES (_entity_type, _entity_id, 'update', _user_id);
END;
$$;

-- ============================================================
-- 14. UPDATE PROFILE
-- ============================================================

CREATE OR REPLACE FUNCTION private.update_profile_impl(
  _expected_version INT,
  _display_name TEXT DEFAULT NULL,
  _avatar_url TEXT DEFAULT NULL
)
RETURNS public.profiles
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  _user_id UUID;
  _result public.profiles;
BEGIN
  _user_id := auth.uid();
  IF _user_id IS NULL THEN
    RAISE EXCEPTION 'authentication_required';
  END IF;

  IF _display_name IS NULL AND _avatar_url IS NULL THEN
    RAISE EXCEPTION 'no_changes: at least one field required';
  END IF;

  IF _display_name IS NOT NULL THEN
    _display_name := trim(_display_name);
    IF char_length(_display_name) < 1 OR char_length(_display_name) > 200 THEN
      RAISE EXCEPTION 'invalid_name: must be 1-200 characters';
    END IF;
  END IF;

  IF _avatar_url IS NOT NULL AND _avatar_url != '' THEN
    IF _avatar_url !~ ('^avatars/' || _user_id::text || '/') THEN
      RAISE EXCEPTION 'invalid_avatar: must reference own storage path';
    END IF;
  END IF;

  UPDATE public.profiles
  SET
    display_name = coalesce(_display_name, display_name),
    avatar_url = CASE
      WHEN _avatar_url = '' THEN NULL
      ELSE coalesce(_avatar_url, avatar_url)
    END
  WHERE id = _user_id AND version = _expected_version
  RETURNING * INTO _result;

  IF NOT FOUND THEN
    IF EXISTS (SELECT 1 FROM public.profiles WHERE id = _user_id) THEN
      RAISE EXCEPTION 'version_conflict';
    ELSE
      RAISE EXCEPTION 'profile_not_found';
    END IF;
  END IF;

  INSERT INTO public.audit_logs (user_id, action, entity, entity_id)
  VALUES (_user_id, 'profile_updated', 'profile', _user_id);

  INSERT INTO private.change_log (entity_type, entity_id, action, user_id)
  VALUES ('profile', _user_id, 'update', _user_id);

  RETURN _result;
END;
$$;

-- ============================================================
-- 15. DELETE ACCOUNT (service_role only)
-- ============================================================

CREATE OR REPLACE FUNCTION private.delete_account_impl(
  _target_user_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  _org RECORD;
  _next_admin UUID;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = _target_user_id) THEN
    RAISE EXCEPTION 'user_not_found';
  END IF;

  FOR _org IN
    SELECT o.id, o.name,
      (SELECT count(*) FROM public.organization_members
       WHERE organization_id = o.id AND user_id != _target_user_id) AS other_count
    FROM public.organizations o
    WHERE o.owner_id = _target_user_id
  LOOP
    IF _org.other_count = 0 THEN
      DELETE FROM public.organizations WHERE id = _org.id;
    ELSE
      SELECT user_id INTO _next_admin
      FROM public.organization_members
      WHERE organization_id = _org.id
        AND user_id != _target_user_id
      ORDER BY
        CASE role WHEN 'admin' THEN 1 WHEN 'member' THEN 2 ELSE 3 END,
        created_at
      LIMIT 1;

      UPDATE public.organizations SET owner_id = _next_admin WHERE id = _org.id;
      UPDATE public.organization_members SET role = 'owner'
      WHERE organization_id = _org.id AND user_id = _next_admin;
    END IF;
  END LOOP;

  DELETE FROM public.organization_members WHERE user_id = _target_user_id;
  DELETE FROM public.project_members WHERE user_id = _target_user_id;

  UPDATE public.invitations SET status = 'expired'
  WHERE invited_by = _target_user_id AND status = 'pending';

  INSERT INTO public.audit_logs (user_id, action, entity, entity_id)
  VALUES (_target_user_id, 'account_deleted', 'profile', _target_user_id);

  DELETE FROM public.profiles WHERE id = _target_user_id;
END;
$$;

-- ============================================================
-- 16. GET CHANGES SINCE (sync cursor)
-- ============================================================

CREATE OR REPLACE FUNCTION private.get_changes_since_impl(
  _last_seq BIGINT,
  _limit INT DEFAULT 100
)
RETURNS TABLE(seq BIGINT, entity_type TEXT, entity_id UUID, action TEXT, created_at TIMESTAMPTZ)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  _user_id UUID;
BEGIN
  _user_id := auth.uid();
  IF _user_id IS NULL THEN
    RAISE EXCEPTION 'authentication_required';
  END IF;

  RETURN QUERY
  SELECT cl.seq, cl.entity_type, cl.entity_id, cl.action, cl.created_at
  FROM private.change_log cl
  WHERE cl.seq > coalesce(_last_seq, 0)
    AND (
      (cl.entity_type = 'project' AND private.is_project_member(cl.entity_id))
      OR (cl.entity_type = 'organization' AND private.is_org_member(cl.entity_id))
      OR (cl.entity_type = 'profile' AND (cl.entity_id = _user_id OR private.shares_membership(cl.entity_id)))
    )
  ORDER BY cl.seq
  LIMIT least(coalesce(_limit, 100), 500);
END;
$$;

-- ============================================================
-- GRANTS: all private implementations
-- ============================================================

REVOKE ALL ON FUNCTION private.create_organization_impl FROM PUBLIC;
REVOKE ALL ON FUNCTION private.update_organization_impl FROM PUBLIC;
REVOKE ALL ON FUNCTION private.delete_organization_impl FROM PUBLIC;
REVOKE ALL ON FUNCTION private.transfer_org_ownership_impl FROM PUBLIC;
REVOKE ALL ON FUNCTION private.create_project_impl FROM PUBLIC;
REVOKE ALL ON FUNCTION private.update_project_impl FROM PUBLIC;
REVOKE ALL ON FUNCTION private.delete_project_impl FROM PUBLIC;
REVOKE ALL ON FUNCTION private.create_invitation_impl FROM PUBLIC;
REVOKE ALL ON FUNCTION private.accept_invitation_impl FROM PUBLIC;
REVOKE ALL ON FUNCTION private.reject_invitation_impl FROM PUBLIC;
REVOKE ALL ON FUNCTION private.cancel_invitation_impl FROM PUBLIC;
REVOKE ALL ON FUNCTION private.update_member_role_impl FROM PUBLIC;
REVOKE ALL ON FUNCTION private.remove_member_impl FROM PUBLIC;
REVOKE ALL ON FUNCTION private.update_profile_impl FROM PUBLIC;
REVOKE ALL ON FUNCTION private.delete_account_impl FROM PUBLIC;
REVOKE ALL ON FUNCTION private.get_changes_since_impl FROM PUBLIC;

GRANT EXECUTE ON FUNCTION private.create_organization_impl TO authenticated;
GRANT EXECUTE ON FUNCTION private.update_organization_impl TO authenticated;
GRANT EXECUTE ON FUNCTION private.delete_organization_impl TO authenticated;
GRANT EXECUTE ON FUNCTION private.transfer_org_ownership_impl TO authenticated;
GRANT EXECUTE ON FUNCTION private.create_project_impl TO authenticated;
GRANT EXECUTE ON FUNCTION private.update_project_impl TO authenticated;
GRANT EXECUTE ON FUNCTION private.delete_project_impl TO authenticated;
GRANT EXECUTE ON FUNCTION private.create_invitation_impl TO authenticated;
GRANT EXECUTE ON FUNCTION private.accept_invitation_impl TO authenticated;
GRANT EXECUTE ON FUNCTION private.reject_invitation_impl TO authenticated;
GRANT EXECUTE ON FUNCTION private.cancel_invitation_impl TO authenticated;
GRANT EXECUTE ON FUNCTION private.update_member_role_impl TO authenticated;
GRANT EXECUTE ON FUNCTION private.remove_member_impl TO authenticated;
GRANT EXECUTE ON FUNCTION private.update_profile_impl TO authenticated;
GRANT EXECUTE ON FUNCTION private.get_changes_since_impl TO authenticated;

-- delete_account_impl: service_role ONLY
REVOKE ALL ON FUNCTION private.delete_account_impl FROM authenticated;
GRANT EXECUTE ON FUNCTION private.delete_account_impl TO service_role;

GRANT EXECUTE ON FUNCTION private.create_organization_impl TO service_role;
GRANT EXECUTE ON FUNCTION private.update_organization_impl TO service_role;
GRANT EXECUTE ON FUNCTION private.delete_organization_impl TO service_role;
GRANT EXECUTE ON FUNCTION private.transfer_org_ownership_impl TO service_role;
GRANT EXECUTE ON FUNCTION private.create_project_impl TO service_role;
GRANT EXECUTE ON FUNCTION private.update_project_impl TO service_role;
GRANT EXECUTE ON FUNCTION private.delete_project_impl TO service_role;
GRANT EXECUTE ON FUNCTION private.create_invitation_impl TO service_role;
GRANT EXECUTE ON FUNCTION private.accept_invitation_impl TO service_role;
GRANT EXECUTE ON FUNCTION private.reject_invitation_impl TO service_role;
GRANT EXECUTE ON FUNCTION private.cancel_invitation_impl TO service_role;
GRANT EXECUTE ON FUNCTION private.update_member_role_impl TO service_role;
GRANT EXECUTE ON FUNCTION private.remove_member_impl TO service_role;
GRANT EXECUTE ON FUNCTION private.update_profile_impl TO service_role;
GRANT EXECUTE ON FUNCTION private.get_changes_since_impl TO service_role;
