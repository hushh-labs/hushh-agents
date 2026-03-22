-- ============================================================
-- Fix hushh_agents_delete_user_account() to match current schema
-- Messages use owner_user_id
-- Matches use owner_user_id
-- Swipes use actor_user_id
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

  -- Delete rows owned by this user first.
  DELETE FROM public.hushh_agents_messages
  WHERE owner_user_id = _uid;

  DELETE FROM public.hushh_agents_conversations
  WHERE owner_user_id = _uid;

  DELETE FROM public.hushh_agents_matches
  WHERE owner_user_id = _uid;

  DELETE FROM public.hushh_agents_agent_swipes
  WHERE actor_user_id = _uid;

  -- Deleting the profile also cascades any inbound profile-target references.
  DELETE FROM public.hushh_agents_profiles
  WHERE user_id = _uid;

  DELETE FROM public.hushh_agents_users
  WHERE user_id = _uid;

  DELETE FROM storage.objects
  WHERE bucket_id = 'hushh-agent-profile-images'
    AND (storage.foldername(name))[1] = _uid::text;
END;
$$;

GRANT EXECUTE ON FUNCTION public.hushh_agents_delete_user_account() TO authenticated;
