create table if not exists public.hushh_agents_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.hushh_agents_conversations(id) on delete cascade,
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  sender_role text not null,
  body text not null,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  constraint hushh_agents_messages_sender_role_check check (sender_role in ('owner', 'system'))
);

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
