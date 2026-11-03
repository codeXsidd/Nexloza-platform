-- Phase 2 Migration 4: Projects
-- Core multi-project entity

CREATE TABLE public.projects (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  name            TEXT NOT NULL,
  description     TEXT NOT NULL DEFAULT '',
  category_id     TEXT REFERENCES public.project_categories(id) ON DELETE SET NULL,
  icon            TEXT NOT NULL DEFAULT 'folder',
  color           TEXT NOT NULL DEFAULT '#0891B2',
  is_template     BOOLEAN NOT NULL DEFAULT false,
  template_id     UUID REFERENCES public.projects(id) ON DELETE SET NULL,
  metadata        JSONB NOT NULL DEFAULT '{}',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_projects_org ON public.projects(organization_id);
CREATE INDEX idx_projects_category ON public.projects(category_id);
CREATE INDEX idx_projects_template ON public.projects(is_template) WHERE is_template = true;

CREATE TRIGGER projects_updated_at
  BEFORE UPDATE ON public.projects
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- Project Members (permissions)
CREATE TABLE public.project_members (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
  user_id    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role       TEXT NOT NULL DEFAULT 'viewer'
               CHECK (role IN ('owner', 'admin', 'editor', 'viewer')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (project_id, user_id)
);

CREATE INDEX idx_project_members_project ON public.project_members(project_id);
CREATE INDEX idx_project_members_user ON public.project_members(user_id);

-- RLS: Projects
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;

-- Users can see projects they are a member of, plus public templates
CREATE POLICY projects_select ON public.projects
  FOR SELECT USING (
    id IN (
      SELECT project_id FROM public.project_members
      WHERE user_id = auth.uid()
    )
    OR is_template = true
  );

-- Insert: user must be owner/admin of the org
CREATE POLICY projects_insert ON public.projects
  FOR INSERT WITH CHECK (
    organization_id IN (
      SELECT organization_id FROM public.organization_members
      WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
    )
  );

-- Update: user must be owner/admin/editor of the project
CREATE POLICY projects_update ON public.projects
  FOR UPDATE USING (
    id IN (
      SELECT project_id FROM public.project_members
      WHERE user_id = auth.uid() AND role IN ('owner', 'admin', 'editor')
    )
  );

-- Delete: only project owner
CREATE POLICY projects_delete ON public.projects
  FOR DELETE USING (
    id IN (
      SELECT project_id FROM public.project_members
      WHERE user_id = auth.uid() AND role = 'owner'
    )
  );

-- RLS: Project Members
ALTER TABLE public.project_members ENABLE ROW LEVEL SECURITY;

-- See members if you are a member of the same project
CREATE POLICY pm_select ON public.project_members
  FOR SELECT USING (
    project_id IN (
      SELECT project_id FROM public.project_members
      WHERE user_id = auth.uid()
    )
  );

-- Only owner/admin can add members
CREATE POLICY pm_insert ON public.project_members
  FOR INSERT WITH CHECK (
    project_id IN (
      SELECT project_id FROM public.project_members
      WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
    )
  );

-- Owner/admin can remove members, users can remove themselves
CREATE POLICY pm_update ON public.project_members
  FOR UPDATE USING (
    project_id IN (
      SELECT project_id FROM public.project_members
      WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
    )
  );

CREATE POLICY pm_delete ON public.project_members
  FOR DELETE USING (
    project_id IN (
      SELECT project_id FROM public.project_members
      WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
    )
    OR user_id = auth.uid()
  );

-- Function: auto-add project creator as owner member
CREATE OR REPLACE FUNCTION public.handle_new_project()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.project_members (project_id, user_id, role)
  VALUES (NEW.id, auth.uid(), 'owner');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_project_created
  AFTER INSERT ON public.projects
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_project();
