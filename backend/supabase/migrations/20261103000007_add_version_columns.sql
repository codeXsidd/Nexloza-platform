-- Phase 2 Migration 7: Version Columns + Private Tables
-- Adds optimistic concurrency version columns to mutable tables
-- Creates idempotency ledger and change log for offline sync

ALTER TABLE public.profiles ADD COLUMN version INT NOT NULL DEFAULT 1;
ALTER TABLE public.organizations ADD COLUMN version INT NOT NULL DEFAULT 1;
ALTER TABLE public.projects ADD COLUMN version INT NOT NULL DEFAULT 1;

CREATE OR REPLACE FUNCTION public.increment_version()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  NEW.version := OLD.version + 1;
  RETURN NEW;
END;
$$;

CREATE TRIGGER profiles_version
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.increment_version();

CREATE TRIGGER organizations_version
  BEFORE UPDATE ON public.organizations
  FOR EACH ROW EXECUTE FUNCTION public.increment_version();

CREATE TRIGGER projects_version
  BEFORE UPDATE ON public.projects
  FOR EACH ROW EXECUTE FUNCTION public.increment_version();

-- Idempotency ledger: prevents duplicate creates on retry
CREATE TABLE private.idempotency_ledger (
  key        TEXT PRIMARY KEY,
  user_id    UUID NOT NULL,
  result     JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_idempotency_ttl ON private.idempotency_ledger(created_at);

-- Change log: stable sync cursor for offline clients
CREATE TABLE private.change_log (
  seq         BIGSERIAL PRIMARY KEY,
  entity_type TEXT NOT NULL,
  entity_id   UUID NOT NULL,
  action      TEXT NOT NULL CHECK (action IN ('insert', 'update', 'delete')),
  user_id     UUID,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_change_log_entity ON private.change_log(entity_type, entity_id);
CREATE INDEX idx_change_log_ttl ON private.change_log(created_at);
