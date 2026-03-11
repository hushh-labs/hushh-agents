import { useState, useEffect, useCallback } from "react";
import { useNavigate } from "react-router-dom";
import type { DeckAgent, DeckState, SwipeAction } from "./DeckModel";
import { supabase } from "../../lib/supabase";

/* ── Analytics: log events to console + localStorage for audit trail ── */
function trackEvent(event: string, data?: Record<string, unknown>) {
  const entry = { event, ...data, ts: new Date().toISOString() };
  console.log(`[analytics] ${event}`, data ?? "");
  try {
    const log: unknown[] = JSON.parse(localStorage.getItem("hushh_analytics_log") || "[]");
    log.push(entry);
    // Keep last 500 events to avoid storage bloat
    if (log.length > 500) log.splice(0, log.length - 500);
    localStorage.setItem("hushh_analytics_log", JSON.stringify(log));
  } catch { /* silent */ }
}

/* ── Fisher-Yates shuffle (client-side double-shuffle for extra randomness) ── */
function shuffle<T>(arr: T[]): T[] {
  const a = [...arr];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

const initial: DeckState = { agents: [], currentIndex: 0, loading: true, error: null, animatingDirection: null };

export function useDeckViewModel() {
  const [state, setState] = useState<DeckState>(initial);
  const navigate = useNavigate();

  useEffect(() => { loadDeck(); }, []);

  async function loadDeck() {
    setState(s => ({ ...s, loading: true, error: null }));
    try {
      const email = localStorage.getItem("hushh_user_email") || "";

      if (!email) {
        navigate("/login/email", { replace: true });
        return;
      }

      const res = await supabase.functions.invoke("get-deck", {
        body: { email },
      });

      /* ── Handle 401 → redirect to login ── */
      if (res.error) {
        const status = (res.error as any)?.status ?? (res.error as any)?.context?.status;
        if (status === 401 || res.data?.error?.includes?.("Unauthorized")) {
          navigate("/login/email", { replace: true });
          return;
        }
        throw new Error(res.data?.error || "Failed to load agents");
      }

      const agents: DeckAgent[] = res.data?.agents ?? [];

      /* ── Client-side shuffle for extra randomness ── */
      const shuffled = shuffle(agents);

      trackEvent("deck_loaded", { agentCount: shuffled.length });
      setState({ agents: shuffled, currentIndex: 0, loading: false, error: null, animatingDirection: null });
    } catch (err: any) {
      setState(s => ({ ...s, loading: false, error: err?.message || "Failed to load agents" }));
    }
  }

  const current = state.agents[state.currentIndex] ?? null;

  const recordAction = useCallback(async (action: SwipeAction) => {
    if (!current) return;
    try {
      const email = localStorage.getItem("hushh_user_email") || "";
      await supabase.functions.invoke("save-action", {
        body: { agent_id: current.id, action, email },
      });
    } catch { /* silent */ }
  }, [current]);

  const onPass = useCallback(() => {
    if (!current) return;
    trackEvent("deck_pass", { agentId: current.id, agentName: current.name });
    setState(s => ({ ...s, animatingDirection: "left" }));
    recordAction("pass");

    // Override handling: if previously liked, remove from liked list (Bug 4)
    try {
      const liked: string[] = JSON.parse(localStorage.getItem("hushh_liked_agents") || "[]");
      if (liked.includes(current.id)) {
        const updated = liked.filter((id: string) => id !== current.id);
        localStorage.setItem("hushh_liked_agents", JSON.stringify(updated));
        window.dispatchEvent(new Event("hushh_liked_update"));
        trackEvent("deck_override", { agentId: current.id, from: "save", to: "pass" });
      }
    } catch { /* silent */ }

    setTimeout(() => {
      setState(s => ({ ...s, currentIndex: s.currentIndex + 1, animatingDirection: null }));
    }, 300);
  }, [current, recordAction]);

  const onSave = useCallback(() => {
    if (!current) return;
    trackEvent("deck_save", { agentId: current.id, agentName: current.name });
    setState(s => ({ ...s, animatingDirection: "right" }));
    recordAction("save");

    // Track liked agents in localStorage for badge count + consistency (Bug 3 & 4)
    try {
      const liked: string[] = JSON.parse(localStorage.getItem("hushh_liked_agents") || "[]");
      if (!liked.includes(current.id)) liked.push(current.id);
      localStorage.setItem("hushh_liked_agents", JSON.stringify(liked));
      window.dispatchEvent(new Event("hushh_liked_update"));
    } catch { /* silent */ }

    setTimeout(() => {
      setState(s => ({ ...s, currentIndex: s.currentIndex + 1, animatingDirection: null }));
    }, 300);
  }, [current, recordAction]);

  const onViewProfile = useCallback(() => {
    if (!current) return;
    trackEvent("deck_view_profile", { agentId: current.id, agentName: current.name });
    recordAction("view");
    navigate(`/agents/${current.id}`);
  }, [current, navigate, recordAction]);

  /* ── Shuffle & Start Over: reshuffle all agents, reset index ── */
  const onStartOver = useCallback(() => {
    trackEvent("deck_reshuffle", { agentCount: state.agents.length });
    setState(s => ({
      ...s,
      agents: shuffle(s.agents),
      currentIndex: 0,
      animatingDirection: null,
    }));
  }, [state.agents.length]);

  /* ── Retry: reload from API ── */
  const onRetry = useCallback(() => {
    loadDeck();
  }, []);

  const deckExhausted = !state.loading && state.currentIndex >= state.agents.length && state.agents.length > 0;

  return { ...state, current, deckExhausted, onPass, onSave, onViewProfile, onStartOver, onRetry };
}
