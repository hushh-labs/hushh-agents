import { useState, useCallback, useMemo, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import {
  getLocationContent,
  getCommPrefChips,
  getTimelineOptions,
  getInsuredOptions,
  getHouseholdOptions,
  getInitialLocationData,
  type LocationFormData,
} from "./LocationModel";

const SUPABASE_URL = "https://gsqmwxqgqrgzhlhmbscg.supabase.co";

function trackEvent(event: string, data?: Record<string, unknown>) {
  console.log(`[analytics] ${event}`, data ?? "");
}

export function useLocationViewModel() {
  const navigate = useNavigate();
  const content = useMemo(() => getLocationContent(), []);
  const commPrefChips = useMemo(() => getCommPrefChips(), []);
  const timelineOptions = useMemo(() => getTimelineOptions(), []);
  const insuredOptions = useMemo(() => getInsuredOptions(), []);
  const householdOptions = useMemo(() => getHouseholdOptions(), []);

  const [form, setForm] = useState<LocationFormData>(() => {
    const saved = localStorage.getItem("hushh_location_draft");
    if (saved) return JSON.parse(saved);

    // Pre-fill ZIP from profile draft
    const profileDraft = localStorage.getItem("hushh_profile_draft");
    const initial = getInitialLocationData();
    if (profileDraft) {
      try {
        const p = JSON.parse(profileDraft);
        if (p.zipCode) initial.zipCode = p.zipCode;
      } catch { /* ignore */ }
    }
    return initial;
  });

  const [loading, setLoading] = useState(false);
  const [gpsError, setGpsError] = useState("");
  const [gpsLoading, setGpsLoading] = useState(false);

  useEffect(() => {
    trackEvent("screen_view_location");
  }, []);

  useEffect(() => {
    localStorage.setItem("hushh_location_draft", JSON.stringify(form));
  }, [form]);

  /** Request GPS location */
  const requestGPS = useCallback(() => {
    if (!navigator.geolocation) {
      setGpsError(content.errorDenied);
      return;
    }

    setGpsLoading(true);
    setGpsError("");

    navigator.geolocation.getCurrentPosition(
      (pos) => {
        setForm((prev) => ({
          ...prev,
          locationSource: "gps",
          latitude: pos.coords.latitude,
          longitude: pos.coords.longitude,
        }));
        setGpsLoading(false);
        trackEvent("location_granted");
      },
      () => {
        setGpsError(content.errorDenied);
        setGpsLoading(false);
        trackEvent("location_denied");
      },
      { enableHighAccuracy: false, timeout: 10000 }
    );
  }, [content]);

  /** Use ZIP instead */
  const useZip = useCallback(() => {
    setForm((prev) => ({ ...prev, locationSource: "zip" }));
    setGpsError("");
  }, []);

  /** Toggle comm pref */
  const toggleCommPref = useCallback((value: string) => {
    setForm((prev) => {
      const has = prev.commPrefs.includes(value);
      return {
        ...prev,
        commPrefs: has
          ? prev.commPrefs.filter((v) => v !== value)
          : [...prev.commPrefs, value],
      };
    });
  }, []);

  /** Set context fields */
  const setTimeline = useCallback((v: string) => {
    setForm((prev) => ({ ...prev, timeline: prev.timeline === v ? "" : v }));
  }, []);

  const setInsured = useCallback((v: string) => {
    setForm((prev) => ({ ...prev, insuredStatus: prev.insuredStatus === v ? "" : v }));
  }, []);

  const setHousehold = useCallback((v: string) => {
    setForm((prev) => ({ ...prev, householdSize: prev.householdSize === v ? "" : v }));
  }, []);

  const setCarrier = useCallback((v: string) => {
    setForm((prev) => ({ ...prev, currentCarrier: v }));
  }, []);

  /** Continue — save */
  const onContinue = useCallback(async () => {
    setLoading(true);

    try {
      const email = localStorage.getItem("hushh_user_email") || "";

      const res = await fetch(`${SUPABASE_URL}/functions/v1/save-location`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          email,
          location_source: form.locationSource,
          latitude: form.latitude,
          longitude: form.longitude,
          zip_code: form.zipCode || null,
          comm_prefs: form.commPrefs,
          timeline: form.timeline || null,
          insured_status: form.insuredStatus || null,
          household_size: form.householdSize || null,
          current_carrier: form.currentCarrier || null,
        }),
      });

      if (!res.ok) {
        const data = await res.json();
        throw new Error(data.error || "Failed to save");
      }

      trackEvent("context_saved", { location_source: form.locationSource });
      localStorage.removeItem("hushh_location_draft");
      navigate("/onboarding/notifications");
    } catch (err) {
      console.error("Save location error:", err);
      // Non-blocking — continue anyway
      navigate("/onboarding/notifications");
    } finally {
      setLoading(false);
    }
  }, [form, navigate]);

  /** Skip */
  const onSkip = useCallback(async () => {
    trackEvent("context_skipped");
    const email = localStorage.getItem("hushh_user_email") || "";
    try {
      await fetch(`${SUPABASE_URL}/functions/v1/save-location`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, location_source: "none" }),
      });
    } catch { /* non-blocking */ }
    localStorage.removeItem("hushh_location_draft");
    navigate("/onboarding/notifications");
  }, [navigate]);

  const onBack = useCallback(() => {
    navigate("/onboarding/goals");
  }, [navigate]);

  /** Dynamic CTA label */
  const ctaLabel = useMemo(() => {
    if (loading) return "Saving…";
    return form.locationSource === "gps"
      ? content.ctaUseLocation
      : content.ctaContinueZip;
  }, [loading, form.locationSource, content]);

  return {
    content,
    commPrefChips,
    timelineOptions,
    insuredOptions,
    householdOptions,
    form,
    loading,
    gpsError,
    gpsLoading,
    ctaLabel,
    requestGPS,
    useZip,
    toggleCommPref,
    setTimeline,
    setInsured,
    setHousehold,
    setCarrier,
    onContinue,
    onSkip,
    onBack,
  };
}
