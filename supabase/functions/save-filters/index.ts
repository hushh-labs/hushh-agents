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

  if (req.method === "GET") {
    const { data } = await supabase
      .from("deck_filter_preferences")
      .select("*")
      .eq("user_id", user.id)
      .single();
    return new Response(JSON.stringify({ filters: data ?? null }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  // POST — save filters
  const body = await req.json();
  const { error } = await supabase.from("deck_filter_preferences").upsert({
    user_id: user.id,
    categories: body.categories ?? [],
    min_rating: body.min_rating ?? 0,
    remote_ok: body.remote_ok ?? true,
    in_person_ok: body.in_person_ok ?? true,
    max_response_minutes: body.max_response_minutes ?? null,
    sort_by: body.sort_by ?? "recommended",
    updated_at: new Date().toISOString(),
  }, { onConflict: "user_id" });

  if (error) return new Response(JSON.stringify({ error: error.message }), { status: 500, headers: corsHeaders });

  return new Response(JSON.stringify({ ok: true }), {
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
