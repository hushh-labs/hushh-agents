-- ============================================================
-- RPC: delete_user_account
-- Permanently deletes all user data and the auth user.
-- SECURITY DEFINER so it can access auth.users.
-- The caller must be the authenticated user themselves.
-- ============================================================

CREATE OR REPLACE FUNCTION public.delete_user_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  _uid uuid := auth.uid();
BEGIN
  IF _uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- 1. Delete messages authored by this user
  DELETE FROM public.hushh_agents_messages
  WHERE sender_user_id = _uid;

  -- 2. Delete conversations owned by this user
  DELETE FROM public.hushh_agents_conversations
  WHERE owner_user_id = _uid;

  -- 3. Delete matches involving this user
  DELETE FROM public.hushh_agents_matches
  WHERE user_id = _uid;

  -- 4. Delete swipes by this user
  DELETE FROM public.hushh_agents_agent_swipes
  WHERE user_id = _uid;

  -- 5. Delete agent profile
  DELETE FROM public.hushh_agents_profiles
  WHERE user_id = _uid;

  -- 6. Delete user account row
  DELETE FROM public.hushh_agents_users
  WHERE user_id = _uid;

  -- 7. Delete profile images from storage
  DELETE FROM storage.objects
  WHERE bucket_id = 'hushh-agents-profile-images'
    AND (storage.foldername(name))[1] = _uid::text;

  -- 8. Delete the auth user (this is the nuclear option)
  DELETE FROM auth.users
  WHERE id = _uid;
END;
$$;

-- Grant execute to authenticated users only
GRANT EXECUTE ON FUNCTION public.delete_user_account() TO authenticated;
