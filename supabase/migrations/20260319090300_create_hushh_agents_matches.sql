do $$
begin
  if exists (
    select 1
    from information_schema.tables
    where table_schema = 'public'
      and table_name = 'hushh_agents_matches'
  ) and not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'hushh_agents_matches'
      and column_name = 'target_agent_id'
  ) then
    drop table public.hushh_agents_matches cascade;
  end if;
end
$$;

create table if not exists public.hushh_agents_matches (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  target_agent_id text not null references public.kirkland_agents(id) on delete cascade,
  status text not null default 'active',
  matched_at timestamp with time zone not null default now(),
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  constraint hushh_agents_matches_owner_agent_key unique (owner_user_id, target_agent_id),
  constraint hushh_agents_matches_status_check check (status in ('active', 'archived'))
);

create index if not exists idx_hushh_agents_matches_owner
  on public.hushh_agents_matches (owner_user_id, status);

create index if not exists idx_hushh_agents_matches_target_agent
  on public.hushh_agents_matches (target_agent_id);

alter table public.hushh_agents_matches enable row level security;

drop policy if exists "Hushh Agents matches can view own rows" on public.hushh_agents_matches;
create policy "Hushh Agents matches can view own rows"
on public.hushh_agents_matches
for select
to authenticated
using (auth.uid() = owner_user_id);

drop policy if exists "Hushh Agents matches can insert own rows" on public.hushh_agents_matches;
create policy "Hushh Agents matches can insert own rows"
on public.hushh_agents_matches
for insert
to authenticated
with check (auth.uid() = owner_user_id);

drop policy if exists "Hushh Agents matches can update own rows" on public.hushh_agents_matches;
create policy "Hushh Agents matches can update own rows"
on public.hushh_agents_matches
for update
to authenticated
using (auth.uid() = owner_user_id)
with check (auth.uid() = owner_user_id);

drop trigger if exists hushh_agents_matches_set_updated_at on public.hushh_agents_matches;
create trigger hushh_agents_matches_set_updated_at
before update on public.hushh_agents_matches
for each row
execute function public.hushh_agents_set_updated_at();

create or replace function public.hushh_agents_sync_match_from_swipe()
returns trigger
language plpgsql
as $$
begin
  if new.status = 'selected' then
    insert into public.hushh_agents_matches (
      owner_user_id,
      target_agent_id,
      status,
      matched_at
    )
    values (
      new.actor_user_id,
      new.target_agent_id,
      'active',
      coalesce(new.swiped_at, now())
    )
    on conflict (owner_user_id, target_agent_id) do update
    set
      status = 'active',
      matched_at = coalesce(public.hushh_agents_matches.matched_at, excluded.matched_at);
  elsif new.status = 'rejected' then
    insert into public.hushh_agents_matches (
      owner_user_id,
      target_agent_id,
      status,
      matched_at
    )
    values (
      new.actor_user_id,
      new.target_agent_id,
      'archived',
      coalesce(new.swiped_at, now())
    )
    on conflict (owner_user_id, target_agent_id) do update
    set status = 'archived';
  end if;

  return new;
end;
$$;

drop trigger if exists hushh_agents_agent_swipes_sync_match on public.hushh_agents_agent_swipes;
create trigger hushh_agents_agent_swipes_sync_match
after insert or update of status on public.hushh_agents_agent_swipes
for each row
execute function public.hushh_agents_sync_match_from_swipe();
