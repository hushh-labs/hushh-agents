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

  const body = await req.json();

  // Upsert settings
  await supabase.from("user_settings").upsert({
    user_id: user.id,
    notification_email: body.notificationEmail ?? true,
    notification_push: body.notificationPush ?? true,
    quiet_hours_start: body.quietHoursStart || null,
    quiet_hours_end: body.quietHoursEnd || null,
    data_sharing: body.dataSharing ?? true,
    blocked_agents: body.blockedAgents ?? [],
    updated_at: new Date().toISOString(),
  }, { onConflict: "user_id" });

  // Upsert profile
  if (body.profile) {
    await supabase.from("user_profiles").upsert({
      user_id: user.id,
      full_name: body.profile.fullName ?? "",
      zip_code: body.profile.zip ?? "",
      contact_preference: body.profile.contactPref ?? "email",
      avatar_url: body.profile.avatarUrl ?? "",
      updated_at: new Date().toISOString(),
    }, { onConflict: "user_id" });
  }

  return new Response(JSON.stringify({ ok: true }), {
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
