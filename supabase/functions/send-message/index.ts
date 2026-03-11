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

  const { conversation_id, body } = await req.json();
  if (!conversation_id || !body?.trim()) {
    return new Response(JSON.stringify({ error: "conversation_id and body required" }), { status: 400, headers: corsHeaders });
  }

  // Verify ownership
  const { data: convo } = await supabase
    .from("conversations")
    .select("id")
    .eq("id", conversation_id)
    .eq("user_id", user.id)
    .single();

  if (!convo) {
    return new Response(JSON.stringify({ error: "Conversation not found" }), { status: 404, headers: corsHeaders });
  }

  // Insert message
  const { data: message, error } = await supabase
    .from("messages")
    .insert({ conversation_id, sender_type: "user", body: body.trim() })
    .select("id, sender_type, body, created_at")
    .single();

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500, headers: corsHeaders });
  }

  // Update conversation preview
  await supabase
    .from("conversations")
    .update({
      last_message_preview: body.trim().slice(0, 120),
      last_message_at: new Date().toISOString(),
      status: "requested",
    })
    .eq("id", conversation_id);

  return new Response(JSON.stringify({ message }), {
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
