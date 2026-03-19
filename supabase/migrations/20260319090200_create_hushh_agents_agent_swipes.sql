do $$
begin
  if exists (
    select 1
    from information_schema.tables
    where table_schema = 'public'
      and table_name = 'hushh_agents_agent_swipes'
  ) and not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'hushh_agents_agent_swipes'
      and column_name = 'target_agent_id'
  ) then
    drop table public.hushh_agents_agent_swipes cascade;
  end if;
end
$$;

create table if not exists public.hushh_agents_agent_swipes (
  id uuid primary key default gen_random_uuid(),
  actor_user_id uuid not null references auth.users(id) on delete cascade,
  target_agent_id text not null references public.kirkland_agents(id) on delete cascade,
  status text not null,
  swiped_at timestamp with time zone not null default now(),
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  constraint hushh_agents_agent_swipes_actor_target_key unique (actor_user_id, target_agent_id)
);

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'hushh_agents_agent_swipes_status_check'
      and conrelid = 'public.hushh_agents_agent_swipes'::regclass
  ) then
    alter table public.hushh_agents_agent_swipes
      add constraint hushh_agents_agent_swipes_status_check
      check (status in ('selected', 'rejected'));
  end if;
end
$$;

create index if not exists idx_hushh_agents_agent_swipes_actor_status
  on public.hushh_agents_agent_swipes (actor_user_id, status);

create index if not exists idx_hushh_agents_agent_swipes_target_agent
  on public.hushh_agents_agent_swipes (target_agent_id);

alter table public.hushh_agents_agent_swipes enable row level security;

drop policy if exists "Hushh Agents swipes can view own outgoing rows" on public.hushh_agents_agent_swipes;
create policy "Hushh Agents swipes can view own outgoing rows"
on public.hushh_agents_agent_swipes
for select
to authenticated
using (auth.uid() = actor_user_id);

drop policy if exists "Hushh Agents swipes can insert own rows" on public.hushh_agents_agent_swipes;
create policy "Hushh Agents swipes can insert own rows"
on public.hushh_agents_agent_swipes
for insert
to authenticated
with check (auth.uid() = actor_user_id);

drop policy if exists "Hushh Agents swipes can update own rows" on public.hushh_agents_agent_swipes;
create policy "Hushh Agents swipes can update own rows"
on public.hushh_agents_agent_swipes
for update
to authenticated
using (auth.uid() = actor_user_id)
with check (auth.uid() = actor_user_id);

drop trigger if exists hushh_agents_agent_swipes_set_updated_at on public.hushh_agents_agent_swipes;
create trigger hushh_agents_agent_swipes_set_updated_at
before update on public.hushh_agents_agent_swipes
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
      and tablename = 'hushh_agents_agent_swipes'
  ) then
    alter publication supabase_realtime add table public.hushh_agents_agent_swipes;
  end if;
end
$$;
