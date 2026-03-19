alter table public.hushh_agents_users
  drop constraint if exists hushh_agents_users_onboarding_step_check;

alter table public.hushh_agents_users
  alter column onboarding_step set default 'welcome';

update public.hushh_agents_users
set onboarding_step = case
  when onboarding_step in ('welcome', 'profile', 'expertise', 'presence', 'complete')
    then onboarding_step
  when onboarding_step is null
    then 'welcome'
  else 'welcome'
end;

alter table public.hushh_agents_users
  add constraint hushh_agents_users_onboarding_step_check
  check (onboarding_step in ('welcome', 'profile', 'expertise', 'presence', 'complete'));

update public.hushh_agents_users
set profile_visibility = case
  when onboarding_step = 'complete' then 'discoverable'
  else 'draft'
end
where profile_visibility not in ('draft', 'discoverable', 'hidden')
   or profile_visibility is null;
