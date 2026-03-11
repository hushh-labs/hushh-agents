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

  const url = new URL(req.url);
  const conversationId = url.searchParams.get("conversation_id");
  if (!conversationId) {
    return new Response(JSON.stringify({ error: "conversation_id required" }), { status: 400, headers: corsHeaders });
  }

  // Verify ownership
  const { data: convo } = await supabase
    .from("conversations")
    .select("id, agent_id, status")
    .eq("id", conversationId)
    .eq("user_id", user.id)
    .single();

  if (!convo) {
    return new Response(JSON.stringify({ error: "Conversation not found" }), { status: 404, headers: corsHeaders });
  }

  // Fetch messages
  const { data: messages } = await supabase
    .from("messages")
    .select("id, sender_type, body, created_at")
    .eq("conversation_id", conversationId)
    .order("created_at", { ascending: true });

  // Mark as read
  await supabase
    .from("conversations")
    .update({ unread_count: 0 })
    .eq("id", conversationId);

  // Get agent info
  const catalog = getAgentCatalog();
  const agent = catalog.find((a: any) => a.id === convo.agent_id);

  return new Response(JSON.stringify({
    conversation: convo,
    agentName: agent?.name ?? "Unknown",
    agentPhotoUrl: agent?.photoUrl ?? "",
    messages: messages ?? [],
  }), {
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});

function getAgentCatalog() {
  return [
    { id: "bFonJrvPDL9xQyKzwnf18g", name: "Sound Planning Group", photoUrl: "https://s3-media0.fl.yelpcdn.com/bphoto/ZICxBk4t2Y-px5ukoqthOA/o.jpg" },
    { id: "QgpwBegvxMjyxhJdwU_bgw", name: "Elite Wealth Management", photoUrl: "https://s3-media0.fl.yelpcdn.com/bphoto/sl_OxP_e0sL4Vhu5rKaBRA/o.jpg" },
    { id: "0-MNwe7lYFs5Se3H3_KbvQ", name: "WaterRock Global Asset Management", photoUrl: "https://s3-media0.fl.yelpcdn.com/bphoto/YM9xrs_TYAVwRIqgSWAbPQ/o.jpg" },
    { id: "AYucftD4SCNB8KZYtVqZSA", name: "Edward Jones — Calen H Johnson", photoUrl: "https://s3-media0.fl.yelpcdn.com/bphoto/TKnSYZUhBYZGEEN_JHoVGA/o.jpg" },
    { id: "fWaWs04lwUfAspU6QQ_-7w", name: "PCM Encore", photoUrl: "https://s3-media0.fl.yelpcdn.com/bphoto/rt3hNSy7Y-vlEh_-ZEtHOA/o.jpg" },
    { id: "60i_PglouDRdQ7Y2CWg0EQ", name: "Capital Planning", photoUrl: "https://s3-media0.fl.yelpcdn.com/bphoto/3n4Wsr34h37aS7Ji8DMlkA/o.jpg" },
    { id: "P4vPLVOYnfu0AzwhGv2IBw", name: "Huddleston Tax CPAs", photoUrl: "https://s3-media0.fl.yelpcdn.com/bphoto/BwvPHsF0zObh6hHRlafGGA/o.jpg" },
    { id: "CYpZ6QZRfjPgTw0unYxabQ", name: "Blue Mountain Wealth Management", photoUrl: "https://s3-media0.fl.yelpcdn.com/bphoto/Lui3vi2ma_mVd8_hkX8teA/o.jpg" },
  ];
}
