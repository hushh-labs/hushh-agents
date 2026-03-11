import { useState, useCallback, useMemo, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import {
  getGoalsContent,
  getGoalChips,
  getTimelineOptions,
  getCommStyleOptions,
  getInitialGoalsData,
  validateGoals,
  type GoalsFormData,
} from "./GoalsModel";

const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL || "https://gsqmwxqgqrgzhlhmbscg.supabase.co";
const SUPABASE_ANON_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY || "";
const authHeaders: Record<string, string> = SUPABASE_ANON_KEY ? { apikey: SUPABASE_ANON_KEY, Authorization: `Bearer ${SUPABASE_ANON_KEY}` } : {};

function trackEvent(event: string, data?: Record<string, unknown>) {
  console.log(`[analytics] ${event}`, data ?? "");
}

export function useGoalsViewModel() {
  const navigate = useNavigate();
  const content = useMemo(() => getGoalsContent(), []);
  const goalChips = useMemo(() => getGoalChips(), []);
  const timelineOptions = useMemo(() => getTimelineOptions(), []);
  const commStyleOptions = useMemo(() => getCommStyleOptions(), []);

  const [form, setForm] = useState<GoalsFormData>(() => {
    const saved = localStorage.getItem("hushh_goals_draft");
    return saved ? JSON.parse(saved) : getInitialGoalsData();
  });

  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    trackEvent("screen_view_goals");
  }, []);

  useEffect(() => {
    localStorage.setItem("hushh_goals_draft", JSON.stringify(form));
  }, [form]);

  /** Toggle a goal chip */
  const toggleGoal = useCallback((goalValue: string) => {
    setForm((prev) => {
      const isSelected = prev.selectedGoals.includes(goalValue);
      let newGoals: string[];
      let newPrimary = prev.primaryGoal;

      if (isSelected) {
        newGoals = prev.selectedGoals.filter((g) => g !== goalValue);
        if (newPrimary === goalValue) {
          newPrimary = newGoals[0] || "";
        }
      } else {
        newGoals = [...prev.selectedGoals, goalValue];
        if (!newPrimary) newPrimary = goalValue; // First selected becomes primary
      }

      trackEvent("goal_selected", { goal: goalValue, action: isSelected ? "removed" : "added" });
      return { ...prev, selectedGoals: newGoals, primaryGoal: newPrimary };
    });
    setError("");
  }, []);

  /** Set primary goal */
  const setPrimaryGoal = useCallback((goalValue: string) => {
    setForm((prev) => ({ ...prev, primaryGoal: goalValue }));
  }, []);

  /** Set timeline */
  const setTimeline = useCallback((value: string) => {
    setForm((prev) => ({ ...prev, timeline: prev.timeline === value ? "" : value }));
  }, []);

  /** Set communication style */
  const setCommStyle = useCallback((value: string) => {
    setForm((prev) => ({
      ...prev,
      communicationStyle: prev.communicationStyle === value ? "" : value,
    }));
  }, []);

  /** Continue — save goals */
  const onContinue = useCallback(async () => {
    const validation = validateGoals(form);
    if (!validation.valid) {
      setError(validation.error || "");
      return;
    }

    setLoading(true);
    setError("");

    try {
      const email = localStorage.getItem("hushh_user_email") || "";

      const goalsPayload = form.selectedGoals.map((g) => ({
        goal: g,
        is_primary: g === form.primaryGoal,
      }));

      const res = await fetch(`${SUPABASE_URL}/functions/v1/save-goals`, {
        method: "POST",
        headers: { "Content-Type": "application/json", ...authHeaders },
        body: JSON.stringify({
          email,
          goals: goalsPayload,
          timeline: form.timeline || null,
          communication_style: form.communicationStyle || null,
          language_pref: form.languagePref,
        }),
      });

      if (!res.ok) {
        const data = await res.json();
        throw new Error(data.error || "Failed to save goals");
      }

      trackEvent("goals_saved", {
        count: form.selectedGoals.length,
        primary: form.primaryGoal,
      });

      localStorage.removeItem("hushh_goals_draft");
      navigate("/onboarding/location");
    } catch (err: unknown) {
      setError((err as Error).message || "Failed to save");
    } finally {
      setLoading(false);
    }
  }, [form, navigate]);

  /** Not sure yet — set exploratory */
  const onNotSure = useCallback(async () => {
    setLoading(true);
    try {
      const email = localStorage.getItem("hushh_user_email") || "";

      await fetch(`${SUPABASE_URL}/functions/v1/save-goals`, {
        method: "POST",
        headers: { "Content-Type": "application/json", ...authHeaders },
        body: JSON.stringify({
          email,
          goals: [],
          intent_status: "exploratory",
        }),
      });

      trackEvent("goals_skipped");
      localStorage.removeItem("hushh_goals_draft");
      navigate("/onboarding/location");
    } catch {
      navigate("/onboarding/location");
    } finally {
      setLoading(false);
    }
  }, [navigate]);

  const onBack = useCallback(() => {
    navigate("/onboarding/profile");
  }, [navigate]);

  return {
    content,
    goalChips,
    timelineOptions,
    commStyleOptions,
    form,
    error,
    loading,
    toggleGoal,
    setPrimaryGoal,
    setTimeline,
    setCommStyle,
    onContinue,
    onNotSure,
    onBack,
  };
}
