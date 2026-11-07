-- AI conversations and messages

create type ai_role as enum ('user', 'assistant', 'system', 'tool');

create table if not exists public.ai_conversations (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  project_id uuid references public.projects(id) on delete set null,
  title text,
  model_id text,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null
);

create table if not exists public.ai_messages (
  id uuid default gen_random_uuid() primary key,
  conversation_id uuid references public.ai_conversations(id) on delete cascade not null,
  role ai_role not null,
  content text not null,
  tool_calls jsonb,
  tool_results jsonb,
  tokens_used int,
  created_at timestamptz default now() not null
);

create index idx_ai_conversations_user on public.ai_conversations(user_id, updated_at desc);
create index idx_ai_messages_conversation on public.ai_messages(conversation_id, created_at);

alter table public.ai_conversations enable row level security;
alter table public.ai_messages enable row level security;

create policy "Users can manage own conversations"
  on public.ai_conversations for all using (auth.uid() = user_id);

create policy "Users can manage messages in own conversations"
  on public.ai_messages for all
  using (conversation_id in (
    select id from public.ai_conversations where user_id = auth.uid()
  ));

create trigger ai_conversations_updated_at
  before update on public.ai_conversations
  for each row execute function public.update_updated_at();
