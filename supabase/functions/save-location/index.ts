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
    const {
      email,
      location_source,
      latitude,
      longitude,
      zip_code,
      comm_prefs,
      // Context fields
      timeline,
      insured_status,
      household_size,
      current_carrier,
    } = body;

    if (!email) {
      return new Response(
        JSON.stringify({ error: "Email is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
    const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // Upsert location preferences
    const locationData: Record<string, unknown> = { email };
    if (location_source) locationData.location_source = location_source;
    if (latitude !== undefined) locationData.latitude = latitude;
    if (longitude !== undefined) locationData.longitude = longitude;
    if (zip_code) locationData.zip_code = zip_code;
    if (comm_prefs) locationData.comm_prefs = comm_prefs;

    const { error: locError } = await supabase
      .from("location_preferences")
      .upsert(locationData, { onConflict: "email" });

    if (locError) throw new Error(`Location DB error: ${locError.message}`);

    // Upsert insurance context if provided
    if (timeline || insured_status || household_size || current_carrier) {
      const ctxData: Record<string, unknown> = { email };
      if (timeline) ctxData.timeline = timeline;
      if (insured_status) ctxData.insured_status = insured_status;
      if (household_size) ctxData.household_size = household_size;
      if (current_carrier) ctxData.current_carrier = current_carrier;

      const { error: ctxError } = await supabase
        .from("insurance_context")
        .upsert(ctxData, { onConflict: "email" });

      if (ctxError) console.error("Context save error (non-fatal):", ctxError.message);
    }

    // Update onboarding step
    await supabase
      .from("user_profiles")
      .upsert(
        { email, onboarding_step: "location_completed" },
        { onConflict: "email" }
      );

    return new Response(
      JSON.stringify({ success: true, message: "Location & context saved" }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("save-location error:", error);
    return new Response(
      JSON.stringify({ error: (error as Error).message || "Failed to save" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
