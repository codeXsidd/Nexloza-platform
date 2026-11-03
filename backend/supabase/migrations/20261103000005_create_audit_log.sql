-- Phase 2 Migration 5: Audit Log
-- Track important actions for security and debugging

CREATE TABLE public.audit_logs (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  action     TEXT NOT NULL,
  entity     TEXT NOT NULL,
  entity_id  UUID,
  metadata   JSONB NOT NULL DEFAULT '{}',
  ip_address INET,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_audit_logs_user ON public.audit_logs(user_id);
CREATE INDEX idx_audit_logs_entity ON public.audit_logs(entity, entity_id);
CREATE INDEX idx_audit_logs_created ON public.audit_logs(created_at DESC);

ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- Users can only see their own audit logs
CREATE POLICY audit_select ON public.audit_logs
  FOR SELECT USING (user_id = auth.uid());

-- Inserts happen via server-side functions only (SECURITY DEFINER)
CREATE POLICY audit_insert ON public.audit_logs
  FOR INSERT WITH CHECK (user_id = auth.uid());
