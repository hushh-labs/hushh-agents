-- ============================================================
-- Repair: Ensure chat trigger functions exist and work reliably
-- ============================================================

-- 1. Ensure the updated_at trigger function exists
create or replace function public.hushh_agents_set_updated_at()
returns trigger
language plpgsql
security definer
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- 2. Recreate conversation preview sync as SECURITY DEFINER
--    so it can update conversations even through RLS
create or replace function public.hushh_agents_sync_conversation_preview()
returns trigger
language plpgsql
security definer
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

-- 3. Ensure triggers are attached
drop trigger if exists hushh_agents_conversations_set_updated_at on public.hushh_agents_conversations;
create trigger hushh_agents_conversations_set_updated_at
before update on public.hushh_agents_conversations
for each row
execute function public.hushh_agents_set_updated_at();

drop trigger if exists hushh_agents_messages_set_updated_at on public.hushh_agents_messages;
create trigger hushh_agents_messages_set_updated_at
before update on public.hushh_agents_messages
for each row
execute function public.hushh_agents_set_updated_at();

drop trigger if exists hushh_agents_messages_sync_preview on public.hushh_agents_messages;
create trigger hushh_agents_messages_sync_preview
after insert on public.hushh_agents_messages
for each row
execute function public.hushh_agents_sync_conversation_preview();

-- 4. Ensure conversations has proper UPDATE policy for upsert
drop policy if exists "Hushh Agents conversations can update own rows" on public.hushh_agents_conversations;
create policy "Hushh Agents conversations can update own rows"
on public.hushh_agents_conversations
for update
to authenticated
using (auth.uid() = owner_user_id)
with check (auth.uid() = owner_user_id);

-- 5. Ensure realtime is enabled for both tables
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime')
     and not exists (
       select 1 from pg_publication_tables
       where pubname = 'supabase_realtime'
         and schemaname = 'public'
         and tablename = 'hushh_agents_conversations'
     )
  then
    alter publication supabase_realtime add table public.hushh_agents_conversations;
  end if;

  if exists (select 1 from pg_publication where pubname = 'supabase_realtime')
     and not exists (
       select 1 from pg_publication_tables
       where pubname = 'supabase_realtime'
         and schemaname = 'public'
         and tablename = 'hushh_agents_messages'
     )
  then
    alter publication supabase_realtime add table public.hushh_agents_messages;
  end if;
end
$$;
