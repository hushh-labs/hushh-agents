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
  const {
    agent_id, message, channel_pref = "in_app", urgency = "medium",
    callback_time = null, consent_reveal_contact = false,
    attachment_url = null, multi_agent = false,
  } = body;

  if (!agent_id) {
    return new Response(JSON.stringify({ error: "agent_id required" }), { status: 400, headers: corsHeaders });
  }

  // Insert lead request
  const { data: lead, error: leadErr } = await supabase
    .from("lead_requests")
    .insert({
      user_id: user.id,
      agent_id,
      message: message ?? "",
      channel_pref,
      urgency,
      callback_time,
      consent_reveal_contact,
      attachment_url,
      status: "requested",
    })
    .select()
    .single();

  if (leadErr) {
    return new Response(JSON.stringify({ error: leadErr.message }), { status: 500, headers: corsHeaders });
  }

  // Insert initial lead event
  await supabase.from("lead_events").insert({
    lead_request_id: lead.id,
    event_type: "lead_created",
    metadata: { channel_pref, urgency, multi_agent, consent_reveal_contact },
  });

  // Also record a contact_request in deck_interactions for consistency
  await supabase.from("deck_interactions").upsert({
    user_id: user.id,
    agent_id,
    action: "contact_request",
  }, { onConflict: "user_id,agent_id,action" });

  // Seed a conversation if channel is in_app
  if (channel_pref === "in_app" && message) {
    const { data: conv } = await supabase
      .from("conversations")
      .insert({
        user_id: user.id,
        agent_id,
        status: "requested",
        last_message_preview: message.slice(0, 100),
        last_message_at: new Date().toISOString(),
        unread_count: 0,
      })
      .select()
      .single();

    if (conv) {
      await supabase.from("messages").insert({
        conversation_id: conv.id,
        sender_type: "user",
        body: message,
      });
    }
  }

  return new Response(JSON.stringify({ lead, ok: true }), {
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
