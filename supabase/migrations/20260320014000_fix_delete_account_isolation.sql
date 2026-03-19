-- ============================================================
-- Fix: Rename delete_user_account → hushh_agents_delete_user_account
-- Fix: Remove auth.users deletion (shared across projects!)
-- Fix: Correct storage bucket name
-- ============================================================

-- Drop the old non-namespaced function
DROP FUNCTION IF EXISTS public.delete_user_account();

-- Create properly namespaced function
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

  -- 7. Delete profile images from storage (correct bucket name)
  DELETE FROM storage.objects
  WHERE bucket_id = 'hushh-agent-profile-images'
    AND (storage.foldername(name))[1] = _uid::text;

  -- NOTE: We do NOT delete from auth.users because it's shared
  -- across multiple projects on this Supabase instance.
  -- The client-side sign-out handles session cleanup.
END;
$$;

-- Grant execute to authenticated users only
GRANT EXECUTE ON FUNCTION public.hushh_agents_delete_user_account() TO authenticated;
