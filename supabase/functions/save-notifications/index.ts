import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { email, notification_enabled } = await req.json();

    if (!email) {
      return new Response(
        JSON.stringify({ error: "Email is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
    const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // Update user_preferences
    const { error: prefsError } = await supabase
      .from("user_preferences")
      .upsert(
        { email, notification_enabled: notification_enabled ?? false },
        { onConflict: "email" }
      );

    if (prefsError) console.error("Prefs error:", prefsError.message);

    // Update onboarding step
    await supabase
      .from("user_profiles")
      .upsert(
        { email, onboarding_step: "notifications_completed" },
        { onConflict: "email" }
      );

    return new Response(
      JSON.stringify({ success: true, message: "Notification preference saved" }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("save-notifications error:", error);
    return new Response(
      JSON.stringify({ error: (error as Error).message || "Failed to save" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
