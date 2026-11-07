-- Notifications and preferences

create type notification_category as enum ('device', 'automation', 'security', 'system', 'alert');
create type notification_severity as enum ('info', 'warning', 'critical');

create table if not exists public.notifications (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  project_id uuid references public.projects(id) on delete set null,
  title text not null,
  body text not null,
  category notification_category default 'system',
  severity notification_severity default 'info',
  is_read boolean default false,
  data jsonb,
  created_at timestamptz default now() not null
);

create table if not exists public.notification_preferences (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  category notification_category not null,
  push_enabled boolean default true,
  email_enabled boolean default false,
  in_app_enabled boolean default true,
  unique(user_id, category)
);

create index idx_notifications_user on public.notifications(user_id, created_at desc);
create index idx_notifications_unread on public.notifications(user_id) where is_read = false;

alter table public.notifications enable row level security;
alter table public.notification_preferences enable row level security;

create policy "Users can view own notifications"
  on public.notifications for select using (auth.uid() = user_id);

create policy "Users can update own notifications"
  on public.notifications for update using (auth.uid() = user_id);

create policy "Users can manage own preferences"
  on public.notification_preferences for all using (auth.uid() = user_id);
