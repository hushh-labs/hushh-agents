-- ============================================================
-- Remove direct storage.objects DELETE from the RPC.
-- Supabase forbids direct SQL deletes on storage.objects;
-- the iOS app will clean up profile images via the Storage API
-- before calling this RPC.
-- ============================================================

CREATE OR REPLACE FUNCTION public.hushh_agents_delete_user_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _uid uuid := auth.uid();
BEGIN
  IF _uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Delete rows owned by this user (children first).
  DELETE FROM public.hushh_agents_messages
  WHERE owner_user_id = _uid;

  DELETE FROM public.hushh_agents_conversations
  WHERE owner_user_id = _uid;

  DELETE FROM public.hushh_agents_matches
  WHERE owner_user_id = _uid;

  DELETE FROM public.hushh_agents_agent_swipes
  WHERE actor_user_id = _uid;

  DELETE FROM public.hushh_agents_profiles
  WHERE user_id = _uid;

  DELETE FROM public.hushh_agents_users
  WHERE user_id = _uid;

  -- NOTE: Storage cleanup (profile images) is handled by the
  -- client via the Supabase Storage API before invoking this RPC.
END;
$$;

GRANT EXECUTE ON FUNCTION public.hushh_agents_delete_user_account() TO authenticated;
