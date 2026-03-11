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

  /* ── fetch conversations ── */
  const { data: convos, error } = await supabase
    .from("conversations")
    .select("id, agent_id, status, last_message_preview, last_message_at, unread_count, created_at")
    .eq("user_id", user.id)
    .order("last_message_at", { ascending: false });

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500, headers: corsHeaders });
  }

  /* ── enrich with agent catalog data ── */
  const catalog = getAgentCatalog();
  const enriched = (convos || []).map((c: any) => {
    const agent = catalog.find((a: any) => a.id === c.agent_id);
    return {
      ...c,
      agentName: agent?.name ?? "Unknown",
      agentPhotoUrl: agent?.photoUrl ?? "",
      agentCategory: agent?.category ?? "",
    };
  });

  /* ── compute summary ── */
  const totalUnread = enriched.reduce((sum: number, c: any) => sum + (c.unread_count || 0), 0);
  const waitingOnYou = enriched.filter((c: any) => c.status === "waiting_on_you").length;

  return new Response(JSON.stringify({ conversations: enriched, totalUnread, waitingOnYou }), {
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});

function getAgentCatalog() {
  return [
    { id: "bFonJrvPDL9xQyKzwnf18g", name: "Sound Planning Group", category: "Financial Advising", photoUrl: "https://s3-media0.fl.yelpcdn.com/bphoto/ZICxBk4t2Y-px5ukoqthOA/o.jpg" },
    { id: "QgpwBegvxMjyxhJdwU_bgw", name: "Elite Wealth Management", category: "Financial Advising", photoUrl: "https://s3-media0.fl.yelpcdn.com/bphoto/sl_OxP_e0sL4Vhu5rKaBRA/o.jpg" },
    { id: "0-MNwe7lYFs5Se3H3_KbvQ", name: "WaterRock Global Asset Management", category: "Investing", photoUrl: "https://s3-media0.fl.yelpcdn.com/bphoto/YM9xrs_TYAVwRIqgSWAbPQ/o.jpg" },
    { id: "AYucftD4SCNB8KZYtVqZSA", name: "Edward Jones — Calen H Johnson", category: "Financial Advising", photoUrl: "https://s3-media0.fl.yelpcdn.com/bphoto/TKnSYZUhBYZGEEN_JHoVGA/o.jpg" },
    { id: "BRQ8LMvOZ7vIBhXvQzlWbA", name: "Joanna Maliva Lee", category: "Financial Advising", photoUrl: "https://s3-media0.fl.yelpcdn.com/bphoto/Gs9UL_L2Pga0d_s8pcPukg/o.jpg" },
    { id: "LpPdpZuUUOg2RdcB2pfthg", name: "Jeff LaDue NMLS", category: "Mortgage Brokers", photoUrl: "https://s3-media0.fl.yelpcdn.com/bphoto/iKIT4QQYHcI0pehfhC3hgA/o.jpg" },
    { id: "Jp7A0Tr371KXqvi0oWLk5g", name: "Snider Financial Group", category: "Financial Advising", photoUrl: "https://s3-media0.fl.yelpcdn.com/bphoto/SfWptRgnIlREsGTXUtw7Rg/o.jpg" },
    { id: "fWaWs04lwUfAspU6QQ_-7w", name: "PCM Encore", category: "Financial Advising", photoUrl: "https://s3-media0.fl.yelpcdn.com/bphoto/rt3hNSy7Y-vlEh_-ZEtHOA/o.jpg" },
    { id: "60i_PglouDRdQ7Y2CWg0EQ", name: "Capital Planning", category: "Investing", photoUrl: "https://s3-media0.fl.yelpcdn.com/bphoto/3n4Wsr34h37aS7Ji8DMlkA/o.jpg" },
    { id: "1rChid6jzJkCDnmDQ3p0zg", name: "Brein Wealth Management", category: "Insurance", photoUrl: "https://s3-media0.fl.yelpcdn.com/bphoto/9WgWaf3QRde9YPbFFbqYnw/o.jpg" },
    { id: "gRsyspyAVzLDA9VEnrFLLw", name: "Charles Schwab", category: "Investing", photoUrl: "https://s3-media0.fl.yelpcdn.com/bphoto/6xbdbQmooh6RlCARYjYyZg/o.jpg" },
    { id: "-1aNzHQj9_MEEX9mmbyuFw", name: "KE & Associates", category: "Accountants", photoUrl: "https://s3-media0.fl.yelpcdn.com/bphoto/IsU6si2Plvx1t7jH8hyRqA/o.jpg" },
    { id: "P4vPLVOYnfu0AzwhGv2IBw", name: "Huddleston Tax CPAs", category: "Accountants", photoUrl: "https://s3-media0.fl.yelpcdn.com/bphoto/BwvPHsF0zObh6hHRlafGGA/o.jpg" },
    { id: "jJVfV0bpp-t4vhbMBqndPg", name: "Omega Financial & Insurance", category: "Insurance", photoUrl: "https://s3-media0.fl.yelpcdn.com/bphoto/bDjBj-By-bn7cgigAlJq9Q/o.jpg" },
    { id: "-Kzo5KZEZ7f2AmL205boZw", name: "Edward Jones — Loren P Winter", category: "Financial Advising", photoUrl: "https://s3-media0.fl.yelpcdn.com/bphoto/JQZgXtzmbFi6nQ9TOzLg7w/o.jpg" },
    { id: "Ic2A6wTvAp44GNTk_6rx6g", name: "Edward Jones — Kagan C. Wolfe", category: "Investing", photoUrl: "https://s3-media0.fl.yelpcdn.com/bphoto/wAuEpOW8dyfET85XSjO9AA/o.jpg" },
    { id: "9Kv4DCB3Lo1RqSLnY_6o5A", name: "ICON Consulting", category: "Financial Advising", photoUrl: "https://s3-media0.fl.yelpcdn.com/bphoto/tZf_8LLmkkeqSTglOnGJvg/o.jpg" },
    { id: "T7ydqxESWzzIwa-9SPNQKQ", name: "HighTower Bellevue", category: "Investing", photoUrl: "https://s3-media0.fl.yelpcdn.com/bphoto/WsTJ2QdTaSJEIMu0kDNW7w/o.jpg" },
    { id: "CYpZ6QZRfjPgTw0unYxabQ", name: "Blue Mountain Wealth Management", category: "Financial Advising", photoUrl: "https://s3-media0.fl.yelpcdn.com/bphoto/Lui3vi2ma_mVd8_hkX8teA/o.jpg" },
  ];
}
