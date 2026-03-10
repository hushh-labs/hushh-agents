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
    const body = await req.json();
    const { email, goals, timeline, communication_style, language_pref, intent_status } = body;

    if (!email) {
      return new Response(
        JSON.stringify({ error: "Email is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
    const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // Delete old goals for this email (fresh save each time)
    await supabase.from("insurance_goals").delete().eq("email", email);

    // Insert new goals
    if (goals && goals.length > 0) {
      const goalRecords = goals.map((g: { goal: string; is_primary: boolean }) => ({
        email,
        goal: g.goal,
        is_primary: g.is_primary || false,
        intent_status: intent_status || "active",
        timeline: timeline || null,
        communication_style: communication_style || null,
        language_pref: language_pref || "en",
      }));

      const { error: goalsError } = await supabase
        .from("insurance_goals")
        .insert(goalRecords);

      if (goalsError) throw new Error(`Goals DB error: ${goalsError.message}`);
    }

    // Update onboarding step
    const { error: profileError } = await supabase
      .from("user_profiles")
      .upsert(
        { email, onboarding_step: "goals_completed" },
        { onConflict: "email" }
      );

    if (profileError) console.error("Profile update error:", profileError.message);

    return new Response(
      JSON.stringify({
        success: true,
        message: "Goals saved",
        goals_count: goals?.length || 0,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("save-goals error:", error);
    return new Response(
      JSON.stringify({ error: (error as Error).message || "Failed to save goals" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
