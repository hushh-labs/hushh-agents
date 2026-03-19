create table if not exists public.hushh_agents_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users(id) on delete cascade,
  catalog_agent_id text unique references public.kirkland_agents(id) on delete set null,
  business_name text not null default '',
  alias text,
  source text not null default 'hushh_agents_app',
  categories text[] not null default '{}'::text[],
  services text[] not null default '{}'::text[],
  specialties text not null default '',
  history text not null default '',
  representative_name text not null default '',
  representative_role text not null default '',
  representative_bio text not null default '',
  representative_photo_url text,
  phone text not null default '',
  formatted_phone text not null default '',
  website_url text not null default '',
  address1 text not null default '',
  address2 text not null default '',
  address3 text not null default '',
  city text not null default '',
  state text not null default '',
  zip text not null default '',
  country text not null default 'US',
  latitude double precision,
  longitude double precision,
  formatted_address text not null default '',
  short_address text not null default '',
  average_rating double precision not null default 0,
  rounded_rating double precision not null default 0,
  review_count integer not null default 0,
  primary_photo_url text,
  photo_count integer not null default 0,
  photo_list jsonb not null default '[]'::jsonb,
  is_closed boolean not null default false,
  is_chain boolean not null default false,
  is_yelp_guaranteed boolean,
  hours text[] not null default '{}'::text[],
  year_established integer,
  messaging_enabled boolean not null default false,
  messaging_type text not null default 'none',
  messaging_display_text text not null default '',
  messaging_response_time text not null default '',
  messaging_reply_rate text not null default '',
  annotations jsonb not null default '[]'::jsonb,
  business_url text not null default '',
  share_url text not null default '',
  profile_status text not null default 'draft',
  discovery_enabled boolean not null default true,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'hushh_agents_profiles_profile_status_check'
      and conrelid = 'public.hushh_agents_profiles'::regclass
  ) then
    alter table public.hushh_agents_profiles
      add constraint hushh_agents_profiles_profile_status_check
      check (profile_status in ('draft', 'discoverable', 'hidden'));
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'hushh_agents_profiles_photo_list_is_array_check'
      and conrelid = 'public.hushh_agents_profiles'::regclass
  ) then
    alter table public.hushh_agents_profiles
      add constraint hushh_agents_profiles_photo_list_is_array_check
      check (jsonb_typeof(photo_list) = 'array');
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'hushh_agents_profiles_annotations_is_array_check'
      and conrelid = 'public.hushh_agents_profiles'::regclass
  ) then
    alter table public.hushh_agents_profiles
      add constraint hushh_agents_profiles_annotations_is_array_check
      check (jsonb_typeof(annotations) = 'array');
  end if;
end
$$;

create index if not exists idx_hushh_agents_profiles_user_id
  on public.hushh_agents_profiles (user_id);

create index if not exists idx_hushh_agents_profiles_catalog_agent_id
  on public.hushh_agents_profiles (catalog_agent_id);

create index if not exists idx_hushh_agents_profiles_location
  on public.hushh_agents_profiles (state, city, zip);

create index if not exists idx_hushh_agents_profiles_status
  on public.hushh_agents_profiles (profile_status, discovery_enabled);

create index if not exists idx_hushh_agents_profiles_categories_gin
  on public.hushh_agents_profiles
  using gin (categories);

create index if not exists idx_hushh_agents_profiles_services_gin
  on public.hushh_agents_profiles
  using gin (services);

alter table public.hushh_agents_profiles enable row level security;

drop policy if exists "Hushh Agents profiles can view own row" on public.hushh_agents_profiles;
create policy "Hushh Agents profiles can view own row"
on public.hushh_agents_profiles
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Hushh Agents profiles are publicly discoverable" on public.hushh_agents_profiles;
create policy "Hushh Agents profiles are publicly discoverable"
on public.hushh_agents_profiles
for select
to authenticated
using (profile_status = 'discoverable' and discovery_enabled = true);

drop policy if exists "Hushh Agents profiles can insert own row" on public.hushh_agents_profiles;
create policy "Hushh Agents profiles can insert own row"
on public.hushh_agents_profiles
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Hushh Agents profiles can update own row" on public.hushh_agents_profiles;
create policy "Hushh Agents profiles can update own row"
on public.hushh_agents_profiles
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop trigger if exists hushh_agents_profiles_set_updated_at on public.hushh_agents_profiles;
create trigger hushh_agents_profiles_set_updated_at
before update on public.hushh_agents_profiles
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
      and tablename = 'hushh_agents_profiles'
  ) then
    alter publication supabase_realtime add table public.hushh_agents_profiles;
  end if;
end
$$;
