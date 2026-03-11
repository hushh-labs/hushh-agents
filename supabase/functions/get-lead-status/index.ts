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

  // Fetch all lead requests for user
  const { data: leads } = await supabase
    .from("lead_requests")
    .select("*")
    .eq("user_id", user.id)
    .order("created_at", { ascending: false });

  // Fetch events for each lead
  const leadIds = (leads ?? []).map((l: any) => l.id);
  const { data: events } = leadIds.length > 0
    ? await supabase.from("lead_events").select("*").in("lead_request_id", leadIds).order("created_at", { ascending: true })
    : { data: [] };

  const catalog = getAgentCatalog();

  const enriched = (leads ?? []).map((l: any) => {
    const agent = catalog.find((a: any) => a.id === l.agent_id);
    return {
      ...l,
      agentName: agent?.name ?? "Unknown",
      agentPhotoUrl: agent?.photoUrl ?? "",
      agentCategory: agent?.category ?? "",
      events: (events ?? []).filter((e: any) => e.lead_request_id === l.id),
    };
  });

  return new Response(JSON.stringify({ leads: enriched }), {
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});

function getAgentCatalog() {
  return [
    { id: "bFonJrvPDL9xQyKzwnf18g", name: "Sound Planning Group", photoUrl: "https://s3-media0.fl.yelpcdn.com/bphoto/ZICxBk4t2Y-px5ukoqthOA/o.jpg", category: "Financial Advising" },
    { id: "QgpwBegvxMjyxhJdwU_bgw", name: "Elite Wealth Management", photoUrl: "https://s3-media0.fl.yelpcdn.com/bphoto/sl_OxP_e0sL4Vhu5rKaBRA/o.jpg", category: "Investing" },
    { id: "0-MNwe7lYFs5Se3H3_KbvQ", name: "WaterRock Global Asset Management", photoUrl: "https://s3-media0.fl.yelpcdn.com/bphoto/YM9xrs_TYAVwRIqgSWAbPQ/o.jpg", category: "Investing" },
    { id: "AYucftD4SCNB8KZYtVqZSA", name: "Edward Jones — Calen H Johnson", photoUrl: "https://s3-media0.fl.yelpcdn.com/bphoto/TKnSYZUhBYZGEEN_JHoVGA/o.jpg", category: "Financial Advising" },
    { id: "fWaWs04lwUfAspU6QQ_-7w", name: "PCM Encore", photoUrl: "https://s3-media0.fl.yelpcdn.com/bphoto/rt3hNSy7Y-vlEh_-ZEtHOA/o.jpg", category: "Insurance" },
    { id: "60i_PglouDRdQ7Y2CWg0EQ", name: "Capital Planning", photoUrl: "https://s3-media0.fl.yelpcdn.com/bphoto/3n4Wsr34h37aS7Ji8DMlkA/o.jpg", category: "Financial Advising" },
    { id: "P4vPLVOYnfu0AzwhGv2IBw", name: "Huddleston Tax CPAs", photoUrl: "https://s3-media0.fl.yelpcdn.com/bphoto/BwvPHsF0zObh6hHRlafGGA/o.jpg", category: "Tax Services" },
    { id: "CYpZ6QZRfjPgTw0unYxabQ", name: "Blue Mountain Wealth Management", photoUrl: "https://s3-media0.fl.yelpcdn.com/bphoto/Lui3vi2ma_mVd8_hkX8teA/o.jpg", category: "Financial Advising" },
  ];
}
