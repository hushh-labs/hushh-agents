import { useState, useCallback, useMemo, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { getNotificationsContent, getValueBullets } from "./NotificationsModel";

const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL || "https://gsqmwxqgqrgzhlhmbscg.supabase.co";
const SUPABASE_ANON_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY || "";
const authHeaders: Record<string, string> = SUPABASE_ANON_KEY ? { apikey: SUPABASE_ANON_KEY, Authorization: `Bearer ${SUPABASE_ANON_KEY}` } : {};

function trackEvent(event: string, data?: Record<string, unknown>) {
  console.log(`[analytics] ${event}`, data ?? "");
}

export function useNotificationsViewModel() {
  const navigate = useNavigate();
  const content = useMemo(() => getNotificationsContent(), []);
  const valueBullets = useMemo(() => getValueBullets(), []);

  const [status, setStatus] = useState<"idle" | "requesting" | "granted" | "denied" | "unsupported">("idle");
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    trackEvent("screen_view_notifications");
  }, []);

  /** Save notification preference to Supabase */
  const savePreference = useCallback(async (enabled: boolean) => {
    const email = localStorage.getItem("hushh_user_email") || "";
    try {
      await fetch(`${SUPABASE_URL}/functions/v1/save-notifications`, {
        method: "POST",
        headers: { "Content-Type": "application/json", ...authHeaders },
        body: JSON.stringify({ email, notification_enabled: enabled }),
      });
    } catch (err) {
      console.error("Save notifications error:", err);
    }
  }, []);

  /** Request browser notification permission */
  const onEnable = useCallback(async () => {
    if (!("Notification" in window)) {
      setStatus("unsupported");
      trackEvent("notifications_unsupported");
      // Still save and continue
      await savePreference(false);
      setTimeout(() => navigate("/onboarding/ready"), 2000);
      return;
    }

    setStatus("requesting");
    setLoading(true);

    try {
      const permission = await Notification.requestPermission();

      if (permission === "granted") {
        setStatus("granted");
        trackEvent("notifications_granted");
        await savePreference(true);

        // Show success, then navigate
        setTimeout(() => navigate("/onboarding/ready"), 1500);
      } else {
        setStatus("denied");
        trackEvent("notifications_denied");
        await savePreference(false);

        // Show error, then auto-navigate after delay
        setTimeout(() => navigate("/onboarding/ready"), 3000);
      }
    } catch {
      setStatus("denied");
      await savePreference(false);
      setTimeout(() => navigate("/onboarding/ready"), 3000);
    } finally {
      setLoading(false);
    }
  }, [navigate, savePreference]);

  /** Maybe later — skip notifications */
  const onSkip = useCallback(async () => {
    trackEvent("notifications_skipped");
    setLoading(true);
    await savePreference(false);
    setLoading(false);
    navigate("/onboarding/ready");
  }, [navigate, savePreference]);

  /** Go back */
  const onBack = useCallback(() => {
    navigate("/onboarding/location");
  }, [navigate]);

  return {
    content,
    valueBullets,
    status,
    loading,
    onEnable,
    onSkip,
    onBack,
  };
}
