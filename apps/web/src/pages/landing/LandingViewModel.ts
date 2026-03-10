import { useMemo, useCallback, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import {
  getAgentCards,
  getCityInfo,
  getTrustChips,
  getHeroContent,
} from "./LandingModel";

/** Simple analytics stub — fires events to console (replace with real SDK later) */
function trackEvent(event: string, data?: Record<string, unknown>) {
  console.log(`[analytics] ${event}`, data ?? "");
}

/** ViewModel hook — connects Model data to the View */
export function useLandingViewModel() {
  const navigate = useNavigate();
  const agentCards = useMemo(() => getAgentCards(), []);
  const cityInfo = useMemo(() => getCityInfo(), []);
  const trustChips = useMemo(() => getTrustChips(), []);
  const heroContent = useMemo(() => getHeroContent(), []);

  // Analytics: landing_view event on mount
  useEffect(() => {
    trackEvent("landing_view");
  }, []);

  // Edge case: If user returns with a valid session, bypass S1
  useEffect(() => {
    const session = localStorage.getItem("hushh_session");
    if (session) {
      // User has a valid session — bypass landing, route to post-auth state
      navigate("/login", { replace: true });
    }
  }, [navigate]);

  const onContinue = useCallback(() => {
    trackEvent("cta_continue_clicked");
    navigate("/login");
  }, [navigate]);

  const onLogin = useCallback(() => {
    trackEvent("login_clicked");
    navigate("/login");
  }, [navigate]);

  return {
    agentCards,
    cityInfo,
    trustChips,
    heroContent,
    onContinue,
    onLogin,
  };
}
