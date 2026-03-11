import { useState, useCallback, useMemo, useEffect, useRef } from "react";
import { useNavigate, useLocation } from "react-router-dom";
import { getVerifyContent, validateOtp } from "./VerifyModel";
import { supabase } from "../../lib/supabase";

const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL || "https://gsqmwxqgqrgzhlhmbscg.supabase.co";
const SUPABASE_ANON_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY || "";
const authHeaders: Record<string, string> = SUPABASE_ANON_KEY
  ? { apikey: SUPABASE_ANON_KEY, Authorization: `Bearer ${SUPABASE_ANON_KEY}` }
  : {};
const RESEND_COOLDOWN = 30; // seconds

/** Simple analytics stub */
function trackEvent(event: string, data?: Record<string, unknown>) {
  console.log(`[analytics] ${event}`, data ?? "");
}

export function useVerifyViewModel() {
  const navigate = useNavigate();
  const location = useLocation();
  const email = (location.state as { email?: string })?.email || "";

  const content = useMemo(() => getVerifyContent(email), [email]);

  const [otp, setOtp] = useState(["", "", "", "", "", ""]);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const [resending, setResending] = useState(false);
  const [success, setSuccess] = useState(false);
  const [resendTimer, setResendTimer] = useState(RESEND_COOLDOWN);

  const inputRefs = useRef<(HTMLInputElement | null)[]>([]);

  // Redirect if no email
  useEffect(() => {
    if (!email) navigate("/login/email", { replace: true });
  }, [email, navigate]);

  // Resend cooldown timer
  useEffect(() => {
    if (resendTimer <= 0) return;
    const interval = setInterval(() => {
      setResendTimer((prev) => prev - 1);
    }, 1000);
    return () => clearInterval(interval);
  }, [resendTimer]);

  const canResend = resendTimer <= 0;

  /** Resend button label */
  const resendLabel = useMemo(() => {
    if (resending) return content.resending;
    if (!canResend) return content.resendWaiting(resendTimer);
    return content.resendReady;
  }, [resending, canResend, resendTimer, content]);

  /** Handle digit change */
  const onDigitChange = useCallback(
    (index: number, value: string) => {
      if (value.length > 1) value = value.slice(-1);
      if (!/^\d*$/.test(value)) return;

      const newOtp = [...otp];
      newOtp[index] = value;
      setOtp(newOtp);
      setError("");

      // Auto-focus next
      if (value && index < 5) {
        inputRefs.current[index + 1]?.focus();
      }

      // Auto-submit when all filled
      if (newOtp.every((d) => d !== "")) {
        handleVerify(newOtp);
      }
    },
    [otp]
  );

  /** Handle backspace */
  const onKeyDown = useCallback(
    (index: number, e: React.KeyboardEvent) => {
      if (e.key === "Backspace" && !otp[index] && index > 0) {
        inputRefs.current[index - 1]?.focus();
      }
    },
    [otp]
  );

  /** Handle paste */
  const onPaste = useCallback((e: React.ClipboardEvent) => {
    e.preventDefault();
    const pasted = e.clipboardData.getData("text").replace(/\D/g, "").slice(0, 6);
    if (pasted.length === 6) {
      const newOtp = pasted.split("");
      setOtp(newOtp);
      inputRefs.current[5]?.focus();
      handleVerify(newOtp);
    }
  }, []);

  /** Verify OTP */
  const handleVerify = useCallback(
    async (digits?: string[]) => {
      const currentOtp = digits || otp;
      const validation = validateOtp(currentOtp);
      if (!validation.valid) {
        setError(validation.error || "");
        return;
      }

      setLoading(true);
      setError("");

      try {
        const res = await fetch(`${SUPABASE_URL}/functions/v1/verify-otp`, {
          method: "POST",
          headers: { "Content-Type": "application/json", ...authHeaders },
          body: JSON.stringify({ email, otp: currentOtp.join("") }),
        });
        const data = await res.json();

        if (!res.ok) {
          const errMsg = data.error || "Verification failed";
          if (errMsg.toLowerCase().includes("expired")) {
            throw new Error(content.validation.expiredCode);
          }
          throw new Error(content.validation.wrongCode);
        }

        trackEvent("auth_success", { email });

        // Persist email for onboarding flow
        localStorage.setItem("hushh_user_email", email);

        // Exchange token_hash for a real Supabase session (JWT)
        if (data.token_hash) {
          try {
            const { error: sessionErr } = await supabase.auth.verifyOtp({
              token_hash: data.token_hash,
              type: "magiclink",
            });
            if (!sessionErr) {
              trackEvent("session_created");
            } else {
              console.warn("Session exchange failed:", sessionErr.message);
            }
          } catch (e) {
            console.warn("Session exchange error:", e);
          }
        }

        setSuccess(true);

        // Brief success state then navigate to S4 Welcome
        setTimeout(() => {
          navigate("/onboarding/welcome", { replace: true });
        }, 2000);
      } catch (err: unknown) {
        trackEvent("auth_failed", { email });
        setError((err as Error).message || "Something went wrong");
        setOtp(["", "", "", "", "", ""]);
        inputRefs.current[0]?.focus();
      } finally {
        setLoading(false);
      }
    },
    [otp, email, navigate, content]
  );

  /** Resend code */
  const onResend = useCallback(async () => {
    if (!canResend || resending) return;

    setResending(true);
    setError("");
    try {
      const res = await fetch(`${SUPABASE_URL}/functions/v1/send-otp`, {
        method: "POST",
        headers: { "Content-Type": "application/json", ...authHeaders },
        body: JSON.stringify({ email }),
      });
      if (!res.ok) throw new Error("Failed to resend");

      trackEvent("otp_resent", { email });
      setOtp(["", "", "", "", "", ""]);
      inputRefs.current[0]?.focus();
      setResendTimer(RESEND_COOLDOWN);
    } catch {
      setError("Failed to resend code");
    } finally {
      setResending(false);
    }
  }, [canResend, resending, email]);

  /** Go back — preserve email */
  const onBack = useCallback(() => {
    navigate("/login/email", { state: { email } });
  }, [navigate, email]);

  /** Change email */
  const onChangeEmail = useCallback(() => {
    navigate("/login/email");
  }, [navigate]);

  /** CTA click */
  const onVerify = useCallback(() => {
    handleVerify();
  }, [handleVerify]);

  return {
    content,
    email,
    otp,
    error,
    loading,
    success,
    resendLabel,
    canResend,
    resending,
    inputRefs,
    onDigitChange,
    onKeyDown,
    onPaste,
    onVerify,
    onResend,
    onBack,
    onChangeEmail,
  };
}
