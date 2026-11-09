-- Migration: 00017_dashboard_phase6
-- Phase 6: Universal Dashboard Builder enhancements
-- Adds flexible widget types, grid dimensions, archive support, dashboard variables

-- Change widget_type from restrictive enum to text to support all 42+ NexWidgetType values
alter table public.dashboard_widgets
  alter column widget_type type text using widget_type::text;

-- Drop the old enum type (no longer needed)
drop type if exists public.widget_type;

-- Add grid dimensions for responsive layout
alter table public.dashboard_widgets
  add column if not exists grid_w int default 1 not null,
  add column if not exists grid_h int default 1 not null;

-- Add archive support and dashboard variables/filters
alter table public.dashboards
  add column if not exists is_archived boolean default false not null,
  add column if not exists variables jsonb default '{}' not null;

-- Index for filtering archived dashboards
create index if not exists idx_dashboards_archived
  on public.dashboards (project_id) where not is_archived;
