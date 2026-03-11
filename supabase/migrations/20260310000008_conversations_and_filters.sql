-- S13: Conversations table for messaging + filter preferences

-- ── conversations (one per user↔agent pair) ──
create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  agent_id text not null,
  status text not null default 'requested' check (status in ('requested','replied','waiting_on_you','closed')),
  last_message_preview text,
  last_message_at timestamptz default now(),
  unread_count int default 0,
  created_at timestamptz default now(),
  unique(user_id, agent_id)
);

alter table public.conversations enable row level security;
create policy "Users manage own conversations"
  on public.conversations for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create index idx_conversations_user on public.conversations(user_id, last_message_at desc);

-- ── messages within conversations ──
create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_type text not null check (sender_type in ('user','agent','system')),
  body text not null,
  created_at timestamptz default now()
);

alter table public.messages enable row level security;
create policy "Users see own conversation messages"
  on public.messages for all
  using (
    exists (
      select 1 from public.conversations c
      where c.id = messages.conversation_id and c.user_id = auth.uid()
    )
  );

create index idx_messages_conversation on public.messages(conversation_id, created_at);

-- ── filter preferences (persisted per user) ──
create table if not exists public.deck_filter_preferences (
  user_id uuid primary key references auth.users(id) on delete cascade,
  categories text[] default '{}',
  min_rating numeric default 0,
  remote_ok boolean default true,
  in_person_ok boolean default true,
  max_response_minutes int,
  sort_by text default 'recommended' check (sort_by in ('recommended','rating','distance','response_time')),
  updated_at timestamptz default now()
);

alter table public.deck_filter_preferences enable row level security;
create policy "Users manage own filter preferences"
  on public.deck_filter_preferences for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
