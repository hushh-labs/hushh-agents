import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const validTransitions: Record<string, string[]> = {
  archive: ["requested", "viewed", "need_more_info", "quoting", "quote_sent"],
  provide_more_info: ["need_more_info"],
  close: ["requested", "viewed", "need_more_info", "quoting", "quote_sent"],
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

  const { lead_id, action } = await req.json();
  if (!lead_id || !action) {
    return new Response(JSON.stringify({ error: "lead_id and action required" }), { status: 400, headers: corsHeaders });
  }

  const { data: lead } = await supabase
    .from("lead_requests")
    .select("*")
    .eq("id", lead_id)
    .eq("user_id", user.id)
    .single();

  if (!lead) {
    return new Response(JSON.stringify({ error: "Lead not found" }), { status: 404, headers: corsHeaders });
  }

  const allowed = validTransitions[action] ?? [];
  if (!allowed.includes(lead.status)) {
    return new Response(JSON.stringify({ error: `Cannot ${action} from ${lead.status}` }), { status: 400, headers: corsHeaders });
  }

  const newStatus = action === "archive" ? "archived" : action === "close" ? "closed_lost" : lead.status;

  await supabase.from("lead_requests")
    .update({ status: newStatus, updated_at: new Date().toISOString() })
    .eq("id", lead_id);

  await supabase.from("lead_events").insert({
    lead_request_id: lead_id,
    event_type: `user_${action}`,
    metadata: { previous_status: lead.status, new_status: newStatus },
  });

  return new Response(JSON.stringify({ ok: true, status: newStatus }), {
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
