import { useState, useCallback, useMemo, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { getLoginContent, validateEmail } from "./LoginModel";

const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL || "https://gsqmwxqgqrgzhlhmbscg.supabase.co";
const SUPABASE_ANON_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY || "";

/** Simple analytics stub */
function trackEvent(event: string, data?: Record<string, unknown>) {
  console.log(`[analytics] ${event}`, data ?? "");
}

type LoadingPhase = "idle" | "checking" | "sending";

export function useLoginViewModel() {
  const navigate = useNavigate();
  const content = useMemo(() => getLoginContent(), []);

  const [email, setEmail] = useState("");
  const [error, setError] = useState("");
  const [loadingPhase, setLoadingPhase] = useState<LoadingPhase>("idle");

  const isLoading = loadingPhase !== "idle";

  // Analytics: auth_start on mount
  useEffect(() => {
    trackEvent("auth_start");
  }, []);

  /** Get the button label based on loading phase */
  const buttonLabel = useMemo(() => {
    switch (loadingPhase) {
      case "checking":
        return content.loadingPhase1;
      case "sending":
        return content.loadingPhase2;
      default:
        return content.ctaLabel;
    }
  }, [loadingPhase, content]);

  /** Go back to landing */
  const onBack = useCallback(() => {
    navigate("/");
  }, [navigate]);

  /** Handle email change */
  const onEmailChange = useCallback((value: string) => {
    setEmail(value);
    setError(""); // Clear error on change
  }, []);

  /** Handle send code */
  const onSendCode = useCallback(async () => {
    // Validate
    const validation = validateEmail(email);
    if (!validation.valid) {
      setError(validation.error || "");
      return;
    }

    setError("");

    // Phase 1: Checking workspace
    setLoadingPhase("checking");
    await new Promise((r) => setTimeout(r, 800)); // Brief delay for UX

    // Phase 2: Sending code
    setLoadingPhase("sending");

    try {
      const res = await fetch(`${SUPABASE_URL}/functions/v1/send-otp`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          ...(SUPABASE_ANON_KEY ? { apikey: SUPABASE_ANON_KEY, Authorization: `Bearer ${SUPABASE_ANON_KEY}` } : {}),
        },
        body: JSON.stringify({ email: email.trim() }),
      });
      const data = await res.json();

      if (!res.ok) {
        // Check if it's an unsupported email error
        const errorMsg = data.error || "Failed to send code";
        if (errorMsg.toLowerCase().includes("not enabled") || errorMsg.toLowerCase().includes("unsupported")) {
          throw new Error(content.validation.unsupported);
        }
        throw new Error(errorMsg);
      }

      trackEvent("otp_requested", { email: email.trim() });

      // Navigate to verify page
      navigate("/login/verify", { state: { email: email.trim() } });
    } catch (err: unknown) {
      setError((err as Error).message || "Something went wrong");
    } finally {
      setLoadingPhase("idle");
    }
  }, [email, navigate, content]);

  /** Handle secondary CTA */
  const onNeedHelp = useCallback(() => {
    // TODO: Open help modal or mailto
    console.log("Need help accessing email clicked");
  }, []);

  return {
    content,
    email,
    error,
    isLoading,
    buttonLabel,
    onBack,
    onEmailChange,
    onSendCode,
    onNeedHelp,
  };
}
