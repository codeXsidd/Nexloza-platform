-- Phase 2 Migration 3: Project Categories
-- Predefined categories for IoT project types

CREATE TABLE public.project_categories (
  id    TEXT PRIMARY KEY,
  label TEXT NOT NULL,
  icon  TEXT NOT NULL DEFAULT 'folder'
);

-- No RLS needed — categories are public read-only
ALTER TABLE public.project_categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY categories_select ON public.project_categories
  FOR SELECT USING (true);

-- Seed data
INSERT INTO public.project_categories (id, label, icon) VALUES
  ('smart_home',        'Smart Home',              'home'),
  ('smart_agriculture', 'Smart Agriculture',       'grass'),
  ('greenhouse',        'Smart Greenhouse',        'eco'),
  ('industrial',        'Industrial IoT',          'factory'),
  ('energy',            'Energy Monitoring',       'bolt'),
  ('water',             'Water Quality',           'water_drop'),
  ('weather',           'Weather Monitoring',      'cloud'),
  ('parking',           'Smart Parking',           'local_parking'),
  ('environmental',     'Environmental Monitoring','nature'),
  ('custom',            'Custom Project',          'settings');
