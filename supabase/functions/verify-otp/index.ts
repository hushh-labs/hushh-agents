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
    const { email, otp } = await req.json();

    if (!email || !otp) {
      return new Response(
        JSON.stringify({ error: "Email and OTP are required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
    const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // Find the OTP record
    const { data, error: fetchError } = await supabase
      .from("otp_codes")
      .select("*")
      .eq("email", email)
      .eq("otp_code", otp)
      .eq("verified", false)
      .order("created_at", { ascending: false })
      .limit(1)
      .single();

    if (fetchError || !data) {
      return new Response(
        JSON.stringify({ error: "Invalid OTP code" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Check expiry
    if (new Date(data.expires_at) < new Date()) {
      await supabase.from("otp_codes").delete().eq("id", data.id);
      return new Response(
        JSON.stringify({ error: "OTP has expired. Please request a new one." }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Mark as verified
    await supabase.from("otp_codes").update({ verified: true }).eq("id", data.id);

    // Clean up old OTPs for this email
    await supabase.from("otp_codes").delete().eq("email", email).neq("id", data.id);

    /* ── Create or find Supabase Auth user ── */
    const normalizedEmail = email.trim().toLowerCase();
    let userId: string | null = null;

    // Try to create auth user (idempotent — if exists, we catch the error)
    const tempPassword = crypto.randomUUID();
    const { data: newUser, error: createErr } = await supabase.auth.admin.createUser({
      email: normalizedEmail,
      email_confirm: true,
      password: tempPassword,
    });

    if (!createErr && newUser?.user?.id) {
      userId = newUser.user.id;
    } else {
      // User already exists — find them
      const { data: listData } = await supabase.auth.admin.listUsers();
      const found = listData?.users?.find((u: any) => u.email === normalizedEmail);
      if (found) {
        userId = found.id;
      }
    }

    /* ── Generate magic link token for frontend session ── */
    let accessToken: string | null = null;
    let refreshToken: string | null = null;

    if (userId) {
      try {
        const { data: linkData } = await supabase.auth.admin.generateLink({
          type: "magiclink",
          email: normalizedEmail,
        });

        if (linkData?.properties?.hashed_token) {
          // Return the hashed token so frontend can exchange it for a session
          return new Response(
            JSON.stringify({
              success: true,
              message: "OTP verified successfully",
              email: normalizedEmail,
              user_id: userId,
              token_hash: linkData.properties.hashed_token,
            }),
            { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }
      } catch (e) {
        console.error("Failed to generate link:", e);
      }
    }

    // Fallback: return success without token (email-based flow continues to work)
    return new Response(
      JSON.stringify({
        success: true,
        message: "OTP verified successfully",
        email: normalizedEmail,
        user_id: userId,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("verify-otp error:", error);
    return new Response(
      JSON.stringify({ error: (error as Error).message || "Verification failed" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
