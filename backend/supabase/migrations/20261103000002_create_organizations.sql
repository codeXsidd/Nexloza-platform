-- Phase 2 Migration 2: Organizations and Members
-- Multi-tenancy container for projects

CREATE TABLE public.organizations (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name       TEXT NOT NULL,
  owner_id   UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.organization_members (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role            TEXT NOT NULL DEFAULT 'member'
                    CHECK (role IN ('owner', 'admin', 'member')),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (organization_id, user_id)
);

CREATE INDEX idx_org_members_org ON public.organization_members(organization_id);
CREATE INDEX idx_org_members_user ON public.organization_members(user_id);

-- Triggers
CREATE TRIGGER organizations_updated_at
  BEFORE UPDATE ON public.organizations
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- RLS: Organizations
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;

CREATE POLICY orgs_select ON public.organizations
  FOR SELECT USING (
    id IN (
      SELECT organization_id FROM public.organization_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY orgs_insert ON public.organizations
  FOR INSERT WITH CHECK (owner_id = auth.uid());

CREATE POLICY orgs_update ON public.organizations
  FOR UPDATE USING (owner_id = auth.uid());

CREATE POLICY orgs_delete ON public.organizations
  FOR DELETE USING (owner_id = auth.uid());

-- RLS: Organization Members
ALTER TABLE public.organization_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY org_members_select ON public.organization_members
  FOR SELECT USING (
    organization_id IN (
      SELECT organization_id FROM public.organization_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY org_members_insert ON public.organization_members
  FOR INSERT WITH CHECK (
    organization_id IN (
      SELECT organization_id FROM public.organization_members
      WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
    )
  );

CREATE POLICY org_members_delete ON public.organization_members
  FOR DELETE USING (
    organization_id IN (
      SELECT organization_id FROM public.organization_members
      WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
    )
    OR user_id = auth.uid()
  );

-- Auto-create a personal org and add owner as member on signup
CREATE OR REPLACE FUNCTION public.handle_new_user_org()
RETURNS TRIGGER AS $$
DECLARE
  org_id UUID;
BEGIN
  INSERT INTO public.organizations (name, owner_id)
  VALUES (
    COALESCE(NEW.raw_user_meta_data ->> 'display_name', 'My Organization'),
    NEW.id
  )
  RETURNING id INTO org_id;

  INSERT INTO public.organization_members (organization_id, user_id, role)
  VALUES (org_id, NEW.id, 'owner');

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created_org
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user_org();
