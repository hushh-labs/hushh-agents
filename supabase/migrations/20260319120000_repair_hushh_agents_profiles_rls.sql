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
