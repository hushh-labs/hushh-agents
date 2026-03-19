-- Hushh Agents runtime consistency repair
-- Run this as a single repair migration against an existing DB that already has
-- the hushh_agents_* tables from the current complete schema.
--
-- Why this exists:
-- 1. The iOS app uses upsert on hushh_agents_agent_swipes with
--    onConflict: actor_user_id,target_agent_id
-- 2. The iOS app uses upsert on hushh_agents_conversations with
--    onConflict: owner_user_id,target_agent_id
-- 3. The swipe -> match trigger also uses on conflict for
--    owner_user_id,target_agent_id
--
-- If those unique constraints/indexes are missing, saves appear to "not stick",
-- chats do not materialize consistently, and realtime feels unreliable.

create or replace function public.hushh_agents_set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- Repair hushh_agents_agent_swipes
-- ---------------------------------------------------------------------------

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
  updated_at timestamp with time zone not null default now()
);

alter table public.hushh_agents_agent_swipes
  add column if not exists actor_user_id uuid references auth.users(id) on delete cascade,
  add column if not exists target_agent_id text references public.kirkland_agents(id) on delete cascade,
  add column if not exists status text,
  add column if not exists swiped_at timestamp with time zone default now(),
  add column if not exists created_at timestamp with time zone default now(),
  add column if not exists updated_at timestamp with time zone default now();

update public.hushh_agents_agent_swipes
set
  swiped_at = coalesce(swiped_at, updated_at, created_at, now()),
  created_at = coalesce(created_at, swiped_at, updated_at, now()),
  updated_at = coalesce(updated_at, swiped_at, created_at, now())
where swiped_at is null
   or created_at is null
   or updated_at is null;

do $$
begin
  if exists (
    select 1
    from pg_constraint
    where conname = 'hushh_agents_agent_swipes_status_check'
      and conrelid = 'public.hushh_agents_agent_swipes'::regclass
  ) then
    alter table public.hushh_agents_agent_swipes
      drop constraint hushh_agents_agent_swipes_status_check;
  end if;
end
$$;

alter table public.hushh_agents_agent_swipes
  add constraint hushh_agents_agent_swipes_status_check
  check (status in ('selected', 'rejected'));

with ranked as (
  select
    ctid,
    row_number() over (
      partition by actor_user_id, target_agent_id
      order by coalesce(swiped_at, updated_at, created_at, now()) desc,
               updated_at desc,
               created_at desc,
               id desc
    ) as rn
  from public.hushh_agents_agent_swipes
  where actor_user_id is not null
    and target_agent_id is not null
)
delete from public.hushh_agents_agent_swipes t
using ranked r
where t.ctid = r.ctid
  and r.rn > 1;

create unique index if not exists idx_hushh_agents_agent_swipes_actor_target_unique
  on public.hushh_agents_agent_swipes (actor_user_id, target_agent_id);

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

-- ---------------------------------------------------------------------------
-- Repair hushh_agents_conversations
-- ---------------------------------------------------------------------------

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
  updated_at timestamp with time zone not null default now()
);

alter table public.hushh_agents_conversations
  add column if not exists owner_user_id uuid references auth.users(id) on delete cascade,
  add column if not exists target_agent_id text references public.kirkland_agents(id) on delete cascade,
  add column if not exists target_agent_name text default '',
  add column if not exists target_agent_location text default '',
  add column if not exists target_agent_photo_url text,
  add column if not exists status text default 'active',
  add column if not exists last_message_preview text,
  add column if not exists last_message_at timestamp with time zone,
  add column if not exists created_at timestamp with time zone default now(),
  add column if not exists updated_at timestamp with time zone default now();

update public.hushh_agents_conversations
set
  target_agent_name = coalesce(target_agent_name, ''),
  target_agent_location = coalesce(target_agent_location, ''),
  status = coalesce(status, 'active'),
  created_at = coalesce(created_at, updated_at, now()),
  updated_at = coalesce(updated_at, created_at, now())
where target_agent_name is null
   or target_agent_location is null
   or status is null
   or created_at is null
   or updated_at is null;

do $$
begin
  if exists (
    select 1
    from pg_constraint
    where conname = 'hushh_agents_conversations_status_check'
      and conrelid = 'public.hushh_agents_conversations'::regclass
  ) then
    alter table public.hushh_agents_conversations
      drop constraint hushh_agents_conversations_status_check;
  end if;
end
$$;

alter table public.hushh_agents_conversations
  add constraint hushh_agents_conversations_status_check
  check (status in ('active', 'archived'));

with ranked as (
  select
    ctid,
    row_number() over (
      partition by owner_user_id, target_agent_id
      order by coalesce(last_message_at, updated_at, created_at, now()) desc,
               updated_at desc,
               created_at desc,
               id desc
    ) as rn
  from public.hushh_agents_conversations
  where owner_user_id is not null
    and target_agent_id is not null
)
delete from public.hushh_agents_conversations t
using ranked r
where t.ctid = r.ctid
  and r.rn > 1;

create unique index if not exists idx_hushh_agents_conversations_owner_target_unique
  on public.hushh_agents_conversations (owner_user_id, target_agent_id);

create index if not exists idx_hushh_agents_conversations_owner_status
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

insert into public.hushh_agents_conversations (
  owner_user_id,
  target_agent_id,
  target_agent_name,
  target_agent_location,
  target_agent_photo_url,
  status,
  created_at,
  updated_at
)
select
  s.actor_user_id,
  s.target_agent_id,
  k.name,
  concat_ws(', ', nullif(k.city, ''), nullif(k.state, '')),
  k.photo_url,
  case when s.status = 'selected' then 'active' else 'archived' end,
  coalesce(s.created_at, now()),
  coalesce(s.updated_at, now())
from public.hushh_agents_agent_swipes s
join public.kirkland_agents k
  on k.id = s.target_agent_id
on conflict (owner_user_id, target_agent_id) do update
set
  target_agent_name = excluded.target_agent_name,
  target_agent_location = excluded.target_agent_location,
  target_agent_photo_url = coalesce(excluded.target_agent_photo_url, public.hushh_agents_conversations.target_agent_photo_url),
  status = excluded.status,
  updated_at = greatest(public.hushh_agents_conversations.updated_at, excluded.updated_at);

-- ---------------------------------------------------------------------------
-- Repair hushh_agents_messages
-- ---------------------------------------------------------------------------

create table if not exists public.hushh_agents_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.hushh_agents_conversations(id) on delete cascade,
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  sender_role text not null,
  body text not null,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

alter table public.hushh_agents_messages
  add column if not exists conversation_id uuid references public.hushh_agents_conversations(id) on delete cascade,
  add column if not exists owner_user_id uuid references auth.users(id) on delete cascade,
  add column if not exists sender_role text,
  add column if not exists body text,
  add column if not exists created_at timestamp with time zone default now(),
  add column if not exists updated_at timestamp with time zone default now();

update public.hushh_agents_messages
set
  created_at = coalesce(created_at, updated_at, now()),
  updated_at = coalesce(updated_at, created_at, now())
where created_at is null
   or updated_at is null;

do $$
begin
  if exists (
    select 1
    from pg_constraint
    where conname = 'hushh_agents_messages_sender_role_check'
      and conrelid = 'public.hushh_agents_messages'::regclass
  ) then
    alter table public.hushh_agents_messages
      drop constraint hushh_agents_messages_sender_role_check;
  end if;
end
$$;

alter table public.hushh_agents_messages
  add constraint hushh_agents_messages_sender_role_check
  check (sender_role in ('owner', 'system'));

create index if not exists idx_hushh_agents_messages_conversation
  on public.hushh_agents_messages (conversation_id, created_at);

create index if not exists idx_hushh_agents_messages_owner
  on public.hushh_agents_messages (owner_user_id);

alter table public.hushh_agents_messages enable row level security;

drop policy if exists "Hushh Agents messages can view own rows" on public.hushh_agents_messages;
create policy "Hushh Agents messages can view own rows"
on public.hushh_agents_messages
for select
to authenticated
using (auth.uid() = owner_user_id);

drop policy if exists "Hushh Agents messages can insert own rows" on public.hushh_agents_messages;
create policy "Hushh Agents messages can insert own rows"
on public.hushh_agents_messages
for insert
to authenticated
with check (auth.uid() = owner_user_id);

drop trigger if exists hushh_agents_messages_set_updated_at on public.hushh_agents_messages;
create trigger hushh_agents_messages_set_updated_at
before update on public.hushh_agents_messages
for each row
execute function public.hushh_agents_set_updated_at();

create or replace function public.hushh_agents_sync_conversation_preview()
returns trigger
language plpgsql
as $$
begin
  update public.hushh_agents_conversations
  set
    last_message_preview = left(new.body, 140),
    last_message_at = new.created_at
  where id = new.conversation_id;

  return new;
end;
$$;

drop trigger if exists hushh_agents_messages_sync_preview on public.hushh_agents_messages;
create trigger hushh_agents_messages_sync_preview
after insert on public.hushh_agents_messages
for each row
execute function public.hushh_agents_sync_conversation_preview();

with latest_message as (
  select distinct on (conversation_id)
    conversation_id,
    left(body, 140) as preview,
    created_at
  from public.hushh_agents_messages
  order by conversation_id, created_at desc, id desc
)
update public.hushh_agents_conversations c
set
  last_message_preview = lm.preview,
  last_message_at = lm.created_at
from latest_message lm
where c.id = lm.conversation_id
  and (
    c.last_message_at is null
    or c.last_message_at <> lm.created_at
    or c.last_message_preview is distinct from lm.preview
  );

-- ---------------------------------------------------------------------------
-- Repair hushh_agents_matches
-- ---------------------------------------------------------------------------

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
  updated_at timestamp with time zone not null default now()
);

alter table public.hushh_agents_matches
  add column if not exists owner_user_id uuid references auth.users(id) on delete cascade,
  add column if not exists target_agent_id text references public.kirkland_agents(id) on delete cascade,
  add column if not exists status text default 'active',
  add column if not exists matched_at timestamp with time zone default now(),
  add column if not exists created_at timestamp with time zone default now(),
  add column if not exists updated_at timestamp with time zone default now();

update public.hushh_agents_matches
set
  status = coalesce(status, 'active'),
  matched_at = coalesce(matched_at, updated_at, created_at, now()),
  created_at = coalesce(created_at, matched_at, updated_at, now()),
  updated_at = coalesce(updated_at, matched_at, created_at, now())
where status is null
   or matched_at is null
   or created_at is null
   or updated_at is null;

do $$
begin
  if exists (
    select 1
    from pg_constraint
    where conname = 'hushh_agents_matches_status_check'
      and conrelid = 'public.hushh_agents_matches'::regclass
  ) then
    alter table public.hushh_agents_matches
      drop constraint hushh_agents_matches_status_check;
  end if;
end
$$;

alter table public.hushh_agents_matches
  add constraint hushh_agents_matches_status_check
  check (status in ('active', 'archived'));

with ranked as (
  select
    ctid,
    row_number() over (
      partition by owner_user_id, target_agent_id
      order by coalesce(matched_at, updated_at, created_at, now()) desc,
               updated_at desc,
               created_at desc,
               id desc
    ) as rn
  from public.hushh_agents_matches
  where owner_user_id is not null
    and target_agent_id is not null
)
delete from public.hushh_agents_matches t
using ranked r
where t.ctid = r.ctid
  and r.rn > 1;

create unique index if not exists idx_hushh_agents_matches_owner_target_unique
  on public.hushh_agents_matches (owner_user_id, target_agent_id);

create index if not exists idx_hushh_agents_matches_owner
  on public.hushh_agents_matches (owner_user_id, status);

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
      matched_at,
      created_at,
      updated_at
    )
    values (
      new.actor_user_id,
      new.target_agent_id,
      'active',
      coalesce(new.swiped_at, now()),
      coalesce(new.created_at, now()),
      coalesce(new.updated_at, now())
    )
    on conflict (owner_user_id, target_agent_id) do update
    set
      status = 'active',
      matched_at = excluded.matched_at,
      updated_at = excluded.updated_at;
  elsif new.status = 'rejected' then
    insert into public.hushh_agents_matches (
      owner_user_id,
      target_agent_id,
      status,
      matched_at,
      created_at,
      updated_at
    )
    values (
      new.actor_user_id,
      new.target_agent_id,
      'archived',
      coalesce(new.swiped_at, now()),
      coalesce(new.created_at, now()),
      coalesce(new.updated_at, now())
    )
    on conflict (owner_user_id, target_agent_id) do update
    set
      status = 'archived',
      updated_at = excluded.updated_at;
  end if;

  return new;
end;
$$;

drop trigger if exists hushh_agents_agent_swipes_sync_match on public.hushh_agents_agent_swipes;
create trigger hushh_agents_agent_swipes_sync_match
after insert or update of status on public.hushh_agents_agent_swipes
for each row
execute function public.hushh_agents_sync_match_from_swipe();

insert into public.hushh_agents_matches (
  owner_user_id,
  target_agent_id,
  status,
  matched_at,
  created_at,
  updated_at
)
select
  actor_user_id,
  target_agent_id,
  case when status = 'selected' then 'active' else 'archived' end,
  coalesce(swiped_at, now()),
  coalesce(created_at, now()),
  coalesce(updated_at, now())
from public.hushh_agents_agent_swipes
on conflict (owner_user_id, target_agent_id) do update
set
  status = excluded.status,
  matched_at = excluded.matched_at,
  updated_at = excluded.updated_at;

-- ---------------------------------------------------------------------------
-- Realtime publication wiring
-- ---------------------------------------------------------------------------

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
      and tablename = 'hushh_agents_messages'
  ) then
    alter publication supabase_realtime add table public.hushh_agents_messages;
  end if;
end
$$;

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
      and tablename = 'hushh_agents_matches'
  ) then
    alter publication supabase_realtime add table public.hushh_agents_matches;
  end if;
end
$$;
