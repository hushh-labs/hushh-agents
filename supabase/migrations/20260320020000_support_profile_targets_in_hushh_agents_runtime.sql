-- Support discoverable hushh_agents_profiles as first-class runtime targets
-- This migration is intentionally scoped to hushh_agents_* runtime tables only.

-- ---------------------------------------------------------------------------
-- Extend hushh_agents_agent_swipes
-- ---------------------------------------------------------------------------

alter table public.hushh_agents_agent_swipes
  add column if not exists target_kind text,
  add column if not exists target_profile_user_id uuid;

update public.hushh_agents_agent_swipes
set target_kind = 'catalog'
where target_kind is null;

alter table public.hushh_agents_agent_swipes
  alter column target_kind set default 'catalog',
  alter column target_kind set not null,
  alter column target_agent_id drop not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'hushh_agents_agent_swipes_target_kind_check'
      and conrelid = 'public.hushh_agents_agent_swipes'::regclass
  ) then
    alter table public.hushh_agents_agent_swipes
      add constraint hushh_agents_agent_swipes_target_kind_check
      check (target_kind in ('catalog', 'profile'));
  end if;
end
$$;

alter table public.hushh_agents_agent_swipes
  drop constraint if exists hushh_agents_agent_swipes_target_identity_check;

alter table public.hushh_agents_agent_swipes
  add constraint hushh_agents_agent_swipes_target_identity_check
  check (
    (target_kind = 'catalog' and target_agent_id is not null and target_profile_user_id is null)
    or
    (target_kind = 'profile' and target_agent_id is null and target_profile_user_id is not null)
  );

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'hushh_agents_agent_swipes_target_profile_user_id_fkey'
      and conrelid = 'public.hushh_agents_agent_swipes'::regclass
  ) then
    alter table public.hushh_agents_agent_swipes
      add constraint hushh_agents_agent_swipes_target_profile_user_id_fkey
      foreign key (target_profile_user_id)
      references public.hushh_agents_profiles(user_id)
      on delete cascade;
  end if;
end
$$;

with ranked as (
  select
    ctid,
    row_number() over (
      partition by actor_user_id, target_kind, coalesce(target_agent_id, target_profile_user_id::text)
      order by coalesce(swiped_at, updated_at, created_at, now()) desc,
               updated_at desc,
               created_at desc,
               id desc
    ) as rn
  from public.hushh_agents_agent_swipes
  where (
    target_kind = 'catalog'
    and target_agent_id is not null
  ) or (
    target_kind = 'profile'
    and target_profile_user_id is not null
  )
)
delete from public.hushh_agents_agent_swipes t
using ranked r
where t.ctid = r.ctid
  and r.rn > 1;

create unique index if not exists idx_hushh_agents_agent_swipes_actor_target_unique
  on public.hushh_agents_agent_swipes (actor_user_id, target_agent_id);

create unique index if not exists idx_hushh_agents_agent_swipes_actor_profile_unique
  on public.hushh_agents_agent_swipes (actor_user_id, target_profile_user_id);

create index if not exists idx_hushh_agents_agent_swipes_target_profile_user
  on public.hushh_agents_agent_swipes (target_profile_user_id);

-- ---------------------------------------------------------------------------
-- Extend hushh_agents_conversations
-- ---------------------------------------------------------------------------

alter table public.hushh_agents_conversations
  add column if not exists target_kind text,
  add column if not exists target_profile_user_id uuid;

update public.hushh_agents_conversations
set target_kind = 'catalog'
where target_kind is null;

alter table public.hushh_agents_conversations
  alter column target_kind set default 'catalog',
  alter column target_kind set not null,
  alter column target_agent_id drop not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'hushh_agents_conversations_target_kind_check'
      and conrelid = 'public.hushh_agents_conversations'::regclass
  ) then
    alter table public.hushh_agents_conversations
      add constraint hushh_agents_conversations_target_kind_check
      check (target_kind in ('catalog', 'profile'));
  end if;
end
$$;

alter table public.hushh_agents_conversations
  drop constraint if exists hushh_agents_conversations_target_identity_check;

alter table public.hushh_agents_conversations
  add constraint hushh_agents_conversations_target_identity_check
  check (
    (target_kind = 'catalog' and target_agent_id is not null and target_profile_user_id is null)
    or
    (target_kind = 'profile' and target_agent_id is null and target_profile_user_id is not null)
  );

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'hushh_agents_conversations_target_profile_user_id_fkey'
      and conrelid = 'public.hushh_agents_conversations'::regclass
  ) then
    alter table public.hushh_agents_conversations
      add constraint hushh_agents_conversations_target_profile_user_id_fkey
      foreign key (target_profile_user_id)
      references public.hushh_agents_profiles(user_id)
      on delete cascade;
  end if;
end
$$;

with ranked as (
  select
    ctid,
    row_number() over (
      partition by owner_user_id, target_kind, coalesce(target_agent_id, target_profile_user_id::text)
      order by coalesce(last_message_at, updated_at, created_at, now()) desc,
               updated_at desc,
               created_at desc,
               id desc
    ) as rn
  from public.hushh_agents_conversations
  where (
    target_kind = 'catalog'
    and target_agent_id is not null
  ) or (
    target_kind = 'profile'
    and target_profile_user_id is not null
  )
)
delete from public.hushh_agents_conversations t
using ranked r
where t.ctid = r.ctid
  and r.rn > 1;

create unique index if not exists idx_hushh_agents_conversations_owner_target_unique
  on public.hushh_agents_conversations (owner_user_id, target_agent_id);

create unique index if not exists idx_hushh_agents_conversations_owner_profile_unique
  on public.hushh_agents_conversations (owner_user_id, target_profile_user_id);

create index if not exists idx_hushh_agents_conversations_target_profile_user
  on public.hushh_agents_conversations (target_profile_user_id);

-- ---------------------------------------------------------------------------
-- Extend hushh_agents_matches
-- ---------------------------------------------------------------------------

alter table public.hushh_agents_matches
  add column if not exists target_kind text,
  add column if not exists target_profile_user_id uuid;

update public.hushh_agents_matches
set target_kind = 'catalog'
where target_kind is null;

alter table public.hushh_agents_matches
  alter column target_kind set default 'catalog',
  alter column target_kind set not null,
  alter column target_agent_id drop not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'hushh_agents_matches_target_kind_check'
      and conrelid = 'public.hushh_agents_matches'::regclass
  ) then
    alter table public.hushh_agents_matches
      add constraint hushh_agents_matches_target_kind_check
      check (target_kind in ('catalog', 'profile'));
  end if;
end
$$;

alter table public.hushh_agents_matches
  drop constraint if exists hushh_agents_matches_target_identity_check;

alter table public.hushh_agents_matches
  add constraint hushh_agents_matches_target_identity_check
  check (
    (target_kind = 'catalog' and target_agent_id is not null and target_profile_user_id is null)
    or
    (target_kind = 'profile' and target_agent_id is null and target_profile_user_id is not null)
  );

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'hushh_agents_matches_target_profile_user_id_fkey'
      and conrelid = 'public.hushh_agents_matches'::regclass
  ) then
    alter table public.hushh_agents_matches
      add constraint hushh_agents_matches_target_profile_user_id_fkey
      foreign key (target_profile_user_id)
      references public.hushh_agents_profiles(user_id)
      on delete cascade;
  end if;
end
$$;

with ranked as (
  select
    ctid,
    row_number() over (
      partition by owner_user_id, target_kind, coalesce(target_agent_id, target_profile_user_id::text)
      order by coalesce(matched_at, updated_at, created_at, now()) desc,
               updated_at desc,
               created_at desc,
               id desc
    ) as rn
  from public.hushh_agents_matches
  where (
    target_kind = 'catalog'
    and target_agent_id is not null
  ) or (
    target_kind = 'profile'
    and target_profile_user_id is not null
  )
)
delete from public.hushh_agents_matches t
using ranked r
where t.ctid = r.ctid
  and r.rn > 1;

create unique index if not exists idx_hushh_agents_matches_owner_target_unique
  on public.hushh_agents_matches (owner_user_id, target_agent_id);

create unique index if not exists idx_hushh_agents_matches_owner_profile_unique
  on public.hushh_agents_matches (owner_user_id, target_profile_user_id);

create index if not exists idx_hushh_agents_matches_target_profile_user
  on public.hushh_agents_matches (target_profile_user_id);

-- ---------------------------------------------------------------------------
-- Update swipe -> match sync for both catalog and profile targets
-- ---------------------------------------------------------------------------

create or replace function public.hushh_agents_sync_match_from_swipe()
returns trigger
language plpgsql
as $$
begin
  if new.status = 'selected' then
    if new.target_kind = 'profile' then
      insert into public.hushh_agents_matches (
        owner_user_id,
        target_kind,
        target_agent_id,
        target_profile_user_id,
        status,
        matched_at,
        created_at,
        updated_at
      )
      values (
        new.actor_user_id,
        'profile',
        null,
        new.target_profile_user_id,
        'active',
        coalesce(new.swiped_at, now()),
        coalesce(new.created_at, now()),
        coalesce(new.updated_at, now())
      )
      on conflict (owner_user_id, target_profile_user_id) do update
      set
        target_kind = excluded.target_kind,
        status = 'active',
        matched_at = excluded.matched_at,
        updated_at = excluded.updated_at;
    else
      insert into public.hushh_agents_matches (
        owner_user_id,
        target_kind,
        target_agent_id,
        target_profile_user_id,
        status,
        matched_at,
        created_at,
        updated_at
      )
      values (
        new.actor_user_id,
        'catalog',
        new.target_agent_id,
        null,
        'active',
        coalesce(new.swiped_at, now()),
        coalesce(new.created_at, now()),
        coalesce(new.updated_at, now())
      )
      on conflict (owner_user_id, target_agent_id) do update
      set
        target_kind = excluded.target_kind,
        status = 'active',
        matched_at = excluded.matched_at,
        updated_at = excluded.updated_at;
    end if;
  elsif new.status = 'rejected' then
    if new.target_kind = 'profile' then
      insert into public.hushh_agents_matches (
        owner_user_id,
        target_kind,
        target_agent_id,
        target_profile_user_id,
        status,
        matched_at,
        created_at,
        updated_at
      )
      values (
        new.actor_user_id,
        'profile',
        null,
        new.target_profile_user_id,
        'archived',
        coalesce(new.swiped_at, now()),
        coalesce(new.created_at, now()),
        coalesce(new.updated_at, now())
      )
      on conflict (owner_user_id, target_profile_user_id) do update
      set
        target_kind = excluded.target_kind,
        status = 'archived',
        updated_at = excluded.updated_at;
    else
      insert into public.hushh_agents_matches (
        owner_user_id,
        target_kind,
        target_agent_id,
        target_profile_user_id,
        status,
        matched_at,
        created_at,
        updated_at
      )
      values (
        new.actor_user_id,
        'catalog',
        new.target_agent_id,
        null,
        'archived',
        coalesce(new.swiped_at, now()),
        coalesce(new.created_at, now()),
        coalesce(new.updated_at, now())
      )
      on conflict (owner_user_id, target_agent_id) do update
      set
        target_kind = excluded.target_kind,
        status = 'archived',
        updated_at = excluded.updated_at;
    end if;
  end if;

  return new;
end;
$$;

insert into public.hushh_agents_matches (
  owner_user_id,
  target_kind,
  target_agent_id,
  target_profile_user_id,
  status,
  matched_at,
  created_at,
  updated_at
)
select
  actor_user_id,
  'catalog',
  target_agent_id,
  null,
  case when status = 'selected' then 'active' else 'archived' end,
  coalesce(swiped_at, now()),
  coalesce(created_at, now()),
  coalesce(updated_at, now())
from public.hushh_agents_agent_swipes
where target_kind = 'catalog'
  and target_agent_id is not null
on conflict (owner_user_id, target_agent_id) do update
set
  target_kind = excluded.target_kind,
  status = excluded.status,
  matched_at = excluded.matched_at,
  updated_at = excluded.updated_at;

insert into public.hushh_agents_matches (
  owner_user_id,
  target_kind,
  target_agent_id,
  target_profile_user_id,
  status,
  matched_at,
  created_at,
  updated_at
)
select
  actor_user_id,
  'profile',
  null,
  target_profile_user_id,
  case when status = 'selected' then 'active' else 'archived' end,
  coalesce(swiped_at, now()),
  coalesce(created_at, now()),
  coalesce(updated_at, now())
from public.hushh_agents_agent_swipes
where target_kind = 'profile'
  and target_profile_user_id is not null
on conflict (owner_user_id, target_profile_user_id) do update
set
  target_kind = excluded.target_kind,
  status = excluded.status,
  matched_at = excluded.matched_at,
  updated_at = excluded.updated_at;
