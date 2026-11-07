-- Migration: 00007_dashboards
-- Dashboard layouts and widgets

create type public.widget_type as enum (
  'button', 'switch', 'slider', 'gauge', 'circular_progress',
  'temperature', 'humidity', 'numeric_value', 'line_chart',
  'bar_chart', 'pie_chart', 'historical_graph', 'map',
  'device_status', 'battery', 'text_display', 'led_indicator',
  'alarm', 'joystick', 'rgb_picker', 'schedule',
  'camera', 'sparkline', 'stat_card', 'custom'
);

create table if not exists public.dashboards (
  id uuid default gen_random_uuid() primary key,
  project_id uuid references public.projects(id) on delete cascade not null,
  name text not null,
  description text,
  layout jsonb default '{"columns": 4, "row_height": 80}',
  is_default boolean default false not null,
  sort_order int default 0 not null,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null
);

create index idx_dashboards_project on public.dashboards (project_id);

create table if not exists public.dashboard_widgets (
  id uuid default gen_random_uuid() primary key,
  dashboard_id uuid references public.dashboards(id) on delete cascade not null,
  widget_type public.widget_type not null,
  title text,
  config jsonb not null default '{}',
  -- config schema: {
  --   "position": {"x": 0, "y": 0},
  --   "size": {"w": 2, "h": 2},
  --   "data_source": {"device_id": "...", "sensor_key": "...", "actuator_key": "..."},
  --   "display": {"color": "#...", "icon": "...", "unit": "..."},
  --   "thresholds": [{"value": 30, "color": "red"}],
  --   "chart": {"period": "24h", "aggregation": "avg"}
  -- }
  sort_order int default 0 not null,
  is_visible boolean default true not null,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null
);

create index idx_widgets_dashboard on public.dashboard_widgets (dashboard_id);

alter table public.dashboards enable row level security;
alter table public.dashboard_widgets enable row level security;

create policy "Project members can view dashboards"
  on public.dashboards for select
  using (public.is_project_member(project_id));

create policy "Project developers can create dashboards"
  on public.dashboards for insert
  with check (public.can_modify_project(project_id));

create policy "Project developers can update dashboards"
  on public.dashboards for update
  using (public.can_modify_project(project_id));

create policy "Project developers can delete dashboards"
  on public.dashboards for delete
  using (public.can_modify_project(project_id));

create policy "Project members can view widgets"
  on public.dashboard_widgets for select
  using (
    exists (
      select 1 from public.dashboards d
      where d.id = dashboard_id and public.is_project_member(d.project_id)
    )
  );

create policy "Project developers can manage widgets"
  on public.dashboard_widgets for insert
  with check (
    exists (
      select 1 from public.dashboards d
      where d.id = dashboard_id and public.can_modify_project(d.project_id)
    )
  );

create policy "Project developers can update widgets"
  on public.dashboard_widgets for update
  using (
    exists (
      select 1 from public.dashboards d
      where d.id = dashboard_id and public.can_modify_project(d.project_id)
    )
  );

create policy "Project developers can delete widgets"
  on public.dashboard_widgets for delete
  using (
    exists (
      select 1 from public.dashboards d
      where d.id = dashboard_id and public.can_modify_project(d.project_id)
    )
  );

create trigger dashboards_updated_at
  before update on public.dashboards
  for each row execute function public.update_updated_at();

create trigger widgets_updated_at
  before update on public.dashboard_widgets
  for each row execute function public.update_updated_at();
