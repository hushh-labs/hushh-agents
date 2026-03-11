-- S12: Shortlist enhancements — add contact_request + report actions, status tracking
-- Expand action check constraint to support new interaction types
alter table public.deck_interactions drop constraint if exists deck_interactions_action_check;
alter table public.deck_interactions add constraint deck_interactions_action_check
  check (action in ('save','pass','view','contact_request','report','unsave'));

-- Index for fast shortlist queries (saved agents)
create index if not exists idx_deck_interactions_saved
  on public.deck_interactions(user_id, agent_id)
  where action = 'save';
