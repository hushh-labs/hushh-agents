-- S10: Deck interactions — saved/passed agents
create table if not exists public.deck_interactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  agent_id text not null,
  action text not null check (action in ('save','pass','view')),
  created_at timestamptz default now(),
  unique(user_id, agent_id, action)
);

alter table public.deck_interactions enable row level security;

create policy "Users manage own interactions"
  on public.deck_interactions for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Index for fast deck filtering
create index idx_deck_interactions_user on public.deck_interactions(user_id, action);
