create or replace function public.hushh_agents_set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

alter table public.hushh_agents_users
  add column if not exists full_name text,
  add column if not exists phone text,
  add column if not exists account_role text default 'advisor',
  add column if not exists profile_visibility text default 'draft',
  add column if not exists discovery_enabled boolean default true,
  add column if not exists onboarding_step text default 'welcome',
  add column if not exists onboarding_deferred_at timestamp with time zone,
  add column if not exists onboarding_completed_at timestamp with time zone,
  add column if not exists metadata jsonb default '{}'::jsonb;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'hushh_agents_users_account_role_check'
      and conrelid = 'public.hushh_agents_users'::regclass
  ) then
    alter table public.hushh_agents_users
      add constraint hushh_agents_users_account_role_check
      check (account_role in ('advisor'));
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'hushh_agents_users_profile_visibility_check'
      and conrelid = 'public.hushh_agents_users'::regclass
  ) then
    alter table public.hushh_agents_users
      add constraint hushh_agents_users_profile_visibility_check
      check (profile_visibility in ('draft', 'discoverable', 'hidden'));
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'hushh_agents_users_onboarding_step_check'
      and conrelid = 'public.hushh_agents_users'::regclass
  ) then
    alter table public.hushh_agents_users
      add constraint hushh_agents_users_onboarding_step_check
      check (onboarding_step in ('welcome', 'profile', 'expertise', 'presence', 'complete'));
  end if;
end
$$;

alter table public.hushh_agents_users
  drop constraint if exists hushh_agents_users_onboarding_step_check;

create index if not exists idx_hushh_agents_users_user_id
  on public.hushh_agents_users (user_id);

create index if not exists idx_hushh_agents_users_onboarding_step
  on public.hushh_agents_users (onboarding_step);

create index if not exists idx_hushh_agents_users_profile_visibility
  on public.hushh_agents_users (profile_visibility);

alter table public.hushh_agents_users enable row level security;

drop policy if exists "Hushh Agents users can view own row" on public.hushh_agents_users;
create policy "Hushh Agents users can view own row"
on public.hushh_agents_users
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Hushh Agents users can insert own row" on public.hushh_agents_users;
create policy "Hushh Agents users can insert own row"
on public.hushh_agents_users
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Hushh Agents users can update own row" on public.hushh_agents_users;
create policy "Hushh Agents users can update own row"
on public.hushh_agents_users
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop trigger if exists hushh_agents_users_set_updated_at on public.hushh_agents_users;
create trigger hushh_agents_users_set_updated_at
before update on public.hushh_agents_users
for each row
execute function public.hushh_agents_set_updated_at();

update public.hushh_agents_users
set
  full_name = coalesce(full_name, name),
  account_role = coalesce(account_role, 'advisor'),
  profile_visibility = case
    when onboarding_step = 'complete' then coalesce(profile_visibility, 'discoverable')
    else coalesce(profile_visibility, 'draft')
  end,
  discovery_enabled = coalesce(discovery_enabled, true),
  onboarding_step = case
    when onboarding_step in ('welcome', 'profile', 'expertise', 'presence', 'complete')
      then onboarding_step
    when onboarding_step is null
      then 'welcome'
    else 'welcome'
  end,
  metadata = coalesce(metadata, '{}'::jsonb);

alter table public.hushh_agents_users
  add constraint hushh_agents_users_onboarding_step_check
  check (onboarding_step in ('welcome', 'profile', 'expertise', 'presence', 'complete'));
