import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

/* ── Fisher-Yates shuffle ── */
function shuffle<T>(arr: T[]): T[] {
  const a = [...arr];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    const { email } = await req.json();

    if (!email || typeof email !== "string") {
      return new Response(JSON.stringify({ error: "Email required" }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    /* ── Email-based auth gate — check OTP verification ── */
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: verified } = await supabase
      .from("otp_codes")
      .select("id")
      .eq("email", email.trim().toLowerCase())
      .eq("verified", true)
      .limit(1)
      .single();

    if (!verified) {
      return new Response(JSON.stringify({ error: "Unauthorized — please verify your account first" }), {
        status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    /* ── Return all agents, shuffled ── */
    const agents = shuffle(getDeckAgents());

    return new Response(JSON.stringify({ agents }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: "Internal server error" }), {
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

function getDeckAgents() {
  return [
    { id: "bFonJrvPDL9xQyKzwnf18g", name: "Sound Planning Group", category: "Financial Advising", rating: 5.0, reviewCount: 8, city: "Kirkland", state: "WA", address: "11411 NE 124th St", phone: "(425) 821-9442", photoUrl: "https://s3-media0.fl.yelpcdn.com/bphoto/ZICxBk4t2Y-px5ukoqthOA/o.jpg", services: ["Wealth Management","Trust Planning","Investment Management","Financial Planning","Retirement Planning","Insurance Planning","Estate Planning"], bio: "CEO David Stryzewski leads a team of CFP® Investment Advisor Representatives in Kirkland, WA.", website: null, hours: "Mon-Fri 8:30am-5pm", yearEstablished: null, specialties: null, representative: null, locallyOwned: false, certified: false, messagingEnabled: false, messagingText: null, responseTime: null },
    { id: "QgpwBegvxMjyxhJdwU_bgw", name: "Elite Wealth Management", category: "Financial Advising", rating: 4.3, reviewCount: 14, city: "Kirkland", state: "WA", address: "1014 Market St", phone: "(425) 828-4300", photoUrl: "https://s3-media0.fl.yelpcdn.com/bphoto/sl_OxP_e0sL4Vhu5rKaBRA/o.jpg", services: ["Financial Advising","Investing"], bio: "Investment advisor specializing in financial asset management in Kirkland, WA.", website: null, hours: null, yearEstablished: null, specialties: null, representative: null, locallyOwned: false, certified: false, messagingEnabled: false, messagingText: null, responseTime: null },
    { id: "0-MNwe7lYFs5Se3H3_KbvQ", name: "WaterRock Global Asset Management", category: "Investing", rating: 4.8, reviewCount: 22, city: "Bellevue", state: "WA", address: "29 148th Ave SE", phone: "(425) 698-1463", photoUrl: "https://s3-media0.fl.yelpcdn.com/bphoto/YM9xrs_TYAVwRIqgSWAbPQ/o.jpg", services: ["Virtual Consultations","Investment Management"], bio: "Adam Droker, CRPC® AIF® — excellent investment and retirement planner for gay couples, executives, and business owners.", website: "http://www.waterrockglobal.com", hours: "Mon-Fri 9am-5pm", yearEstablished: 2009, specialties: "Registered investment advisor in WA, OR, CA, AZ, & FL.", representative: { name: "Adam D.", role: "business_owner", bio: "Chief Investment Officer at WaterRock Global." }, locallyOwned: false, certified: false, messagingEnabled: true, messagingText: "Request information", responseTime: null },
    { id: "AYucftD4SCNB8KZYtVqZSA", name: "Edward Jones — Calen H Johnson", category: "Financial Advising", rating: 5.0, reviewCount: 8, city: "Kirkland", state: "WA", address: "11250 Kirkland Way, Ste 202", phone: "(425) 803-4632", photoUrl: "https://s3-media0.fl.yelpcdn.com/bphoto/TKnSYZUhBYZGEEN_JHoVGA/o.jpg", services: ["Virtual Consultations","Investing","Insurance"], bio: "Super knowledgeable financial advisor. Prepare for retirement, save for education, and be a tax-smart investor.", website: "https://www.edwardjones.com/calen-johnson", hours: "Mon-Fri 8am-5pm", yearEstablished: 2009, specialties: null, representative: { name: "Calen J.", role: "business_owner", bio: "Calen Johnson - Owner" }, locallyOwned: false, certified: false, messagingEnabled: false, messagingText: null, responseTime: null },
    { id: "BRQ8LMvOZ7vIBhXvQzlWbA", name: "Joanna Maliva Lee", category: "Financial Advising", rating: 1.0, reviewCount: 1, city: "Kirkland", state: "WA", address: "Kirkland, WA 98033", phone: "", photoUrl: "https://s3-media0.fl.yelpcdn.com/bphoto/Gs9UL_L2Pga0d_s8pcPukg/o.jpg", services: ["Virtual Consultations","Financial Advising"], bio: "Financial adviser in Kirkland, WA.", website: null, hours: null, yearEstablished: null, specialties: null, representative: null, locallyOwned: false, certified: false, messagingEnabled: false, messagingText: null, responseTime: null },
    { id: "LpPdpZuUUOg2RdcB2pfthg", name: "Jeff LaDue NMLS", category: "Mortgage Brokers", rating: 5.0, reviewCount: 22, city: "Kirkland", state: "WA", address: "4055 Lake Washington Blvd NE", phone: "(206) 226-8687", photoUrl: "https://s3-media0.fl.yelpcdn.com/bphoto/iKIT4QQYHcI0pehfhC3hgA/o.jpg", services: ["Mortgage Brokers","Financial Advising"], bio: "Mortgage brokerage and financial advising on Lake Washington Blvd.", website: null, hours: null, yearEstablished: null, specialties: null, representative: null, locallyOwned: false, certified: false, messagingEnabled: false, messagingText: null, responseTime: null },
    { id: "Jp7A0Tr371KXqvi0oWLk5g", name: "Snider Financial Group", category: "Financial Advising", rating: 5.0, reviewCount: 1, city: "Bellevue", state: "WA", address: "12505 Bel Red Rd, Ste 200", phone: "(425) 453-7080", photoUrl: "https://s3-media0.fl.yelpcdn.com/bphoto/SfWptRgnIlREsGTXUtw7Rg/o.jpg", services: ["Financial Planning","Retirement Planning"], bio: "Monte Snider — one of the few financial planners recommended for investment and retirement management.", website: "http://www.sniderfinancialgroup.com", hours: "Mon-Fri 8am-4:30pm", yearEstablished: null, specialties: null, representative: { name: "Monte S.", role: "business_owner", bio: "President of Snider Financial Group." }, locallyOwned: false, certified: false, messagingEnabled: false, messagingText: null, responseTime: null },
    { id: "fWaWs04lwUfAspU6QQ_-7w", name: "PCM Encore", category: "Financial Advising", rating: 0, reviewCount: 0, city: "Bellevue", state: "WA", address: "10900 NE 4th St, Ste 2406", phone: "(425) 214-1755", photoUrl: "https://s3-media0.fl.yelpcdn.com/bphoto/rt3hNSy7Y-vlEh_-ZEtHOA/o.jpg", services: ["Inheritance Planning","Insurance Planning","Trust Planning","Tax Planning","Investment Management","Asset Allocation","Wealth Management","Estate Planning","Financial Planning","Virtual Consultations"], bio: "Independent fiduciary financial advisor with a multi-billion family office background.", website: "https://encoreinvestment.com", hours: "Mon-Sun 8am-6pm", yearEstablished: null, specialties: null, representative: null, locallyOwned: true, certified: true, messagingEnabled: true, messagingText: "Request information", responseTime: "20 mins" },
    { id: "60i_PglouDRdQ7Y2CWg0EQ", name: "Capital Planning", category: "Investing", rating: 5.0, reviewCount: 4, city: "Bellevue", state: "WA", address: "10900 NE 4th St, Ste 2300", phone: "(425) 643-1800", photoUrl: "https://s3-media0.fl.yelpcdn.com/bphoto/3n4Wsr34h37aS7Ji8DMlkA/o.jpg", services: ["Investment Management","Wealth Management"], bio: "Since 1983, providing wealth management solutions for corporate executives, business owners, and high net worth families.", website: "https://www.capplanllc.com", hours: "Mon-Fri 7:30am-4pm", yearEstablished: 1983, specialties: null, representative: { name: "Michael M.", role: "business_owner", bio: "Helping executive clients." }, locallyOwned: false, certified: false, messagingEnabled: false, messagingText: null, responseTime: null },
    { id: "1rChid6jzJkCDnmDQ3p0zg", name: "Brein Wealth Management", category: "Insurance", rating: 5.0, reviewCount: 1, city: "Bellevue", state: "WA", address: "11900 NE 1st St, Ste 300", phone: "(425) 442-6003", photoUrl: "https://s3-media0.fl.yelpcdn.com/bphoto/9WgWaf3QRde9YPbFFbqYnw/o.jpg", services: ["Insurance","Financial Advising"], bio: "Insurance and financial advising services in Bellevue.", website: null, hours: null, yearEstablished: null, specialties: null, representative: null, locallyOwned: false, certified: false, messagingEnabled: false, messagingText: null, responseTime: null },
    { id: "gRsyspyAVzLDA9VEnrFLLw", name: "Charles Schwab", category: "Investing", rating: 4.5, reviewCount: 2, city: "Redmond", state: "WA", address: "8862 161st Ave NE, Ste 106", phone: "(425) 558-3420", photoUrl: "https://s3-media0.fl.yelpcdn.com/bphoto/6xbdbQmooh6RlCARYjYyZg/o.jpg", services: ["Investment Management","Wealth Management","Savings Accounts","Retirement Planning","Personal Banking"], bio: "Full range of brokerage, banking, and financial advisory services. Established 1973.", website: "http://www.schwab.com", hours: "Mon-Fri 8:30am-5pm", yearEstablished: 1973, specialties: null, representative: null, locallyOwned: false, certified: false, messagingEnabled: false, messagingText: null, responseTime: null },
    { id: "-1aNzHQj9_MEEX9mmbyuFw", name: "KE & Associates", category: "Accountants", rating: 3.9, reviewCount: 25, city: "Kirkland", state: "WA", address: "13020 NE 73rd St", phone: "(206) 729-0795", photoUrl: "https://s3-media0.fl.yelpcdn.com/bphoto/IsU6si2Plvx1t7jH8hyRqA/o.jpg", services: ["Accounting","Tax Services","Financial Advising"], bio: "Accountants, tax services, and financial advising in Kirkland.", website: null, hours: null, yearEstablished: null, specialties: null, representative: null, locallyOwned: false, certified: false, messagingEnabled: false, messagingText: null, responseTime: null },
    { id: "FGtvfYMj-rRkgicEC1yWPg", name: "M3 Tax and Accounting", category: "Financial Advising", rating: 5.0, reviewCount: 1, city: "Kirkland", state: "WA", address: "5400 Carollin Point", phone: "", photoUrl: "", services: ["Financial Advising","Tax Services","Accountants"], bio: "Very professional accounting and financial service.", website: null, hours: null, yearEstablished: null, specialties: null, representative: null, locallyOwned: false, certified: false, messagingEnabled: false, messagingText: null, responseTime: null },
    { id: "P4vPLVOYnfu0AzwhGv2IBw", name: "Huddleston Tax CPAs", category: "Accountants", rating: 3.9, reviewCount: 19, city: "Bellevue", state: "WA", address: "40 Lake Bellevue, Ste 100", phone: "(206) 310-8363", photoUrl: "https://s3-media0.fl.yelpcdn.com/bphoto/BwvPHsF0zObh6hHRlafGGA/o.jpg", services: ["Accounting","Tax Services","Financial Advising"], bio: "John Huddleston, CPA — focus on tax needs of small businesses.", website: "https://huddlestontaxcpas.com/locations/bellevue", hours: "Mon-Fri 9am-5pm", yearEstablished: 2002, specialties: null, representative: { name: "John H.", role: "business_owner", bio: "Masters in Tax Law from UW School of Law." }, locallyOwned: false, certified: false, messagingEnabled: true, messagingText: "Request information", responseTime: "50 mins" },
    { id: "jJVfV0bpp-t4vhbMBqndPg", name: "Omega Financial & Insurance", category: "Insurance", rating: 5.0, reviewCount: 2, city: "Kirkland", state: "WA", address: "10827 NE 68th St S, Ste 200", phone: "(425) 822-5722", photoUrl: "https://s3-media0.fl.yelpcdn.com/bphoto/bDjBj-By-bn7cgigAlJq9Q/o.jpg", services: ["Insurance","Financial Advising"], bio: "Omega Financial and Insurance Services — comprehensive insurance and financial planning.", website: null, hours: null, yearEstablished: null, specialties: null, representative: null, locallyOwned: false, certified: false, messagingEnabled: false, messagingText: null, responseTime: null },
    { id: "-Kzo5KZEZ7f2AmL205boZw", name: "Edward Jones — Loren P Winter", category: "Financial Advising", rating: 5.0, reviewCount: 1, city: "Kirkland", state: "WA", address: "9710 NE 119th Way", phone: "(425) 821-0285", photoUrl: "https://s3-media0.fl.yelpcdn.com/bphoto/JQZgXtzmbFi6nQ9TOzLg7w/o.jpg", services: ["Financial Advising"], bio: "Edward Jones financial advisor in Kirkland, WA.", website: "http://www.edwardjones.com", hours: null, yearEstablished: null, specialties: null, representative: null, locallyOwned: false, certified: false, messagingEnabled: false, messagingText: null, responseTime: null },
    { id: "Ic2A6wTvAp44GNTk_6rx6g", name: "Edward Jones — Kagan C. Wolfe", category: "Investing", rating: 0, reviewCount: 0, city: "Kirkland", state: "WA", address: "963 6th St S", phone: "(425) 828-9087", photoUrl: "https://s3-media0.fl.yelpcdn.com/bphoto/wAuEpOW8dyfET85XSjO9AA/o.jpg", services: ["Investing","Insurance","Financial Advising"], bio: "Edward Jones financial advisor in Kirkland, WA.", website: "http://www.edwardjones.com", hours: null, yearEstablished: null, specialties: null, representative: null, locallyOwned: false, certified: false, messagingEnabled: false, messagingText: null, responseTime: null },
    { id: "9Kv4DCB3Lo1RqSLnY_6o5A", name: "ICON Consulting", category: "Financial Advising", rating: 0, reviewCount: 0, city: "Bellevue", state: "WA", address: "1412 112th Ave NE, Ste 102", phone: "(425) 562-4266", photoUrl: "https://s3-media0.fl.yelpcdn.com/bphoto/tZf_8LLmkkeqSTglOnGJvg/o.jpg", services: ["Financial Advising"], bio: "Financial advising in Bellevue, WA.", website: null, hours: null, yearEstablished: null, specialties: null, representative: null, locallyOwned: false, certified: false, messagingEnabled: false, messagingText: null, responseTime: null },
    { id: "b16asns7tqatMZ8R2Rqc1A", name: "Green Financial", category: "Financial Advising", rating: 5.0, reviewCount: 1, city: "Kirkland", state: "WA", address: "11930 Slater Ave NE, Ste 100", phone: "(425) 821-1111", photoUrl: "", services: ["Financial Advising","Health Insurance","Life Insurance"], bio: "Financial advising, health insurance, and life insurance services in Kirkland.", website: null, hours: null, yearEstablished: null, specialties: null, representative: null, locallyOwned: false, certified: false, messagingEnabled: false, messagingText: null, responseTime: null },
    { id: "T7ydqxESWzzIwa-9SPNQKQ", name: "HighTower Bellevue", category: "Investing", rating: 5.0, reviewCount: 1, city: "Bellevue", state: "WA", address: "777 108th Ave NE, Ste 1800", phone: "(425) 455-6623", photoUrl: "https://s3-media0.fl.yelpcdn.com/bphoto/WsTJ2QdTaSJEIMu0kDNW7w/o.jpg", services: ["Investing","Financial Advising"], bio: "HighTower Bellevue — investment advisory and financial planning.", website: null, hours: null, yearEstablished: null, specialties: null, representative: null, locallyOwned: false, certified: false, messagingEnabled: false, messagingText: null, responseTime: null },
    { id: "CYpZ6QZRfjPgTw0unYxabQ", name: "Blue Mountain Wealth Management", category: "Financial Advising", rating: 5.0, reviewCount: 2, city: "Monroe", state: "WA", address: "20026 209th Ave SE", phone: "(509) 301-8701", photoUrl: "https://s3-media0.fl.yelpcdn.com/bphoto/Lui3vi2ma_mVd8_hkX8teA/o.jpg", services: ["Virtual Consultations","Financial Planning","Retirement Planning","Inheritance Planning","Wealth Management","Estate Planning"], bio: "Truly personalized approach to financial success — listening to your goals and aligning strategies.", website: "https://bluemountainwealthmanagement.com", hours: null, yearEstablished: null, specialties: null, representative: null, locallyOwned: false, certified: false, messagingEnabled: false, messagingText: null, responseTime: null },
  ];
}
