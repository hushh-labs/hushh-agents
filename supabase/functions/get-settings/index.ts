import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  const authHeader = req.headers.get("Authorization")!;
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } }
  );

  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401, headers: corsHeaders });

  // Get user settings
  const { data: settings } = await supabase
    .from("user_settings")
    .select("*")
    .eq("user_id", user.id)
    .single();

  // Get profile from user_profiles
  const { data: profile } = await supabase
    .from("user_profiles")
    .select("*")
    .eq("user_id", user.id)
    .single();

  const result = {
    profile: {
      fullName: profile?.full_name ?? user.user_metadata?.full_name ?? "",
      email: user.email ?? "",
      zip: profile?.zip_code ?? "",
      contactPref: profile?.contact_preference ?? "email",
      avatarUrl: profile?.avatar_url ?? "",
    },
    notificationEmail: settings?.notification_email ?? true,
    notificationPush: settings?.notification_push ?? true,
    quietHoursStart: settings?.quiet_hours_start ?? "",
    quietHoursEnd: settings?.quiet_hours_end ?? "",
    dataSharing: settings?.data_sharing ?? true,
    blockedAgents: settings?.blocked_agents ?? [],
  };

  return new Response(JSON.stringify({ settings: result }), {
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
