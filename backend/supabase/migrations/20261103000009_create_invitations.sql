-- Phase 2 Migration 9: Invitations Table
-- Stores hashed tokens only; raw token returned once on creation

CREATE TABLE public.invitations (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_type   TEXT NOT NULL CHECK (entity_type IN ('organization', 'project')),
  entity_id     UUID NOT NULL,
  invited_email TEXT NOT NULL,
  invited_by    UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  role          TEXT NOT NULL,
  token_hash    TEXT NOT NULL UNIQUE,
  status        TEXT NOT NULL DEFAULT 'pending'
                  CHECK (status IN ('pending', 'accepted', 'rejected', 'expired')),
  expires_at    TIMESTAMPTZ NOT NULL DEFAULT (now() + INTERVAL '7 days'),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  responded_at  TIMESTAMPTZ,
  CONSTRAINT valid_invitation_role CHECK (
    (entity_type = 'organization' AND role IN ('admin', 'member'))
    OR (entity_type = 'project' AND role IN ('admin', 'editor', 'viewer'))
  )
);

CREATE UNIQUE INDEX idx_invitations_pending
  ON public.invitations (entity_type, entity_id, invited_email)
  WHERE status = 'pending';

CREATE INDEX idx_invitations_email ON public.invitations(invited_email);
CREATE INDEX idx_invitations_entity ON public.invitations(entity_type, entity_id);
CREATE INDEX idx_invitations_expires ON public.invitations(expires_at)
  WHERE status = 'pending';

ALTER TABLE public.invitations ENABLE ROW LEVEL SECURITY;

-- Cleanup trigger: expire invitations when parent entity is deleted
CREATE OR REPLACE FUNCTION private.cleanup_entity_invitations()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  UPDATE public.invitations
  SET status = 'expired'
  WHERE entity_type = TG_ARGV[0]
    AND entity_id = OLD.id
    AND status = 'pending';
  RETURN OLD;
END;
$$;

CREATE TRIGGER cleanup_project_invitations
  BEFORE DELETE ON public.projects
  FOR EACH ROW EXECUTE FUNCTION private.cleanup_entity_invitations('project');

CREATE TRIGGER cleanup_org_invitations
  BEFORE DELETE ON public.organizations
  FOR EACH ROW EXECUTE FUNCTION private.cleanup_entity_invitations('organization');
