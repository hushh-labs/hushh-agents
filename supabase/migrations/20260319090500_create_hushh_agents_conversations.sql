create table if not exists public.hushh_agents_conversations (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  target_agent_id text not null references public.kirkland_agents(id) on delete cascade,
  target_agent_name text not null default '',
  target_agent_location text not null default '',
  target_agent_photo_url text,
  status text not null default 'active',
  last_message_preview text,
  last_message_at timestamp with time zone,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  constraint hushh_agents_conversations_owner_agent_key unique (owner_user_id, target_agent_id),
  constraint hushh_agents_conversations_status_check check (status in ('active', 'archived'))
);

create index if not exists idx_hushh_agents_conversations_owner
  on public.hushh_agents_conversations (owner_user_id, status);

alter table public.hushh_agents_conversations enable row level security;

drop policy if exists "Hushh Agents conversations can view own rows" on public.hushh_agents_conversations;
create policy "Hushh Agents conversations can view own rows"
on public.hushh_agents_conversations
for select
to authenticated
using (auth.uid() = owner_user_id);

drop policy if exists "Hushh Agents conversations can insert own rows" on public.hushh_agents_conversations;
create policy "Hushh Agents conversations can insert own rows"
on public.hushh_agents_conversations
for insert
to authenticated
with check (auth.uid() = owner_user_id);

drop policy if exists "Hushh Agents conversations can update own rows" on public.hushh_agents_conversations;
create policy "Hushh Agents conversations can update own rows"
on public.hushh_agents_conversations
for update
to authenticated
using (auth.uid() = owner_user_id)
with check (auth.uid() = owner_user_id);

drop trigger if exists hushh_agents_conversations_set_updated_at on public.hushh_agents_conversations;
create trigger hushh_agents_conversations_set_updated_at
before update on public.hushh_agents_conversations
for each row
execute function public.hushh_agents_set_updated_at();

do $$
begin
  if exists (
    select 1
    from pg_publication
    where pubname = 'supabase_realtime'
  ) and not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'hushh_agents_conversations'
  ) then
    alter publication supabase_realtime add table public.hushh_agents_conversations;
  end if;
end
$$;
