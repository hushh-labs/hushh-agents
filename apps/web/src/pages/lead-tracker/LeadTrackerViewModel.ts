/* ── Lead / Quote Status Tracker — ViewModel ── */

import { useState, useEffect, useCallback } from "react";
import { useNavigate } from "react-router-dom";
import type { LeadTrackerState } from "./LeadTrackerModel";
import { supabase } from "../../lib/supabase";

function trackEvent(event: string, data?: Record<string, unknown>) {
  console.log(`[analytics] ${event}`, data ?? "");
}

export function useLeadTrackerViewModel() {
  const navigate = useNavigate();
  const [state, setState] = useState<LeadTrackerState>({
    leads: [], loading: true, error: null, selectedLeadId: null,
  });

  useEffect(() => {
    trackEvent("lead_status_viewed");
    loadLeads();
  }, []);

  async function loadLeads() {
    setState(s => ({ ...s, loading: true }));
    try {
      const res = await supabase.functions.invoke("get-lead-status", {
        
      });
      setState(s => ({ ...s, leads: res.data?.leads ?? [], loading: false, error: null }));
    } catch {
      setState(s => ({ ...s, loading: false, error: "Failed to load leads" }));
    }
  }

  const onSelectLead = useCallback((leadId: string) => {
    setState(s => ({ ...s, selectedLeadId: s.selectedLeadId === leadId ? null : leadId }));
  }, []);

  const onAction = useCallback(async (leadId: string, action: string) => {
    trackEvent("lead_status_changed", { leadId, action });
    try {
      await supabase.functions.invoke("lead-action", {
        body: { lead_id: leadId, action },
        
      });
      // Refresh
      await loadLeads();
    } catch { /* silent */ }
  }, []);

  const onArchive = useCallback((leadId: string) => onAction(leadId, "archive"), [onAction]);
  const onProvideInfo = useCallback((leadId: string) => onAction(leadId, "provide_more_info"), [onAction]);
  const onClose = useCallback((leadId: string) => onAction(leadId, "close"), [onAction]);

  const onOpenChat = useCallback((agentId: string) => {
    // Navigate to messages filtered for this agent
    navigate("/messages");
  }, [navigate]);

  const onGoToDiscover = useCallback(() => navigate("/deck"), [navigate]);

  const isEmpty = !state.loading && state.leads.length === 0;
  const selectedLead = state.leads.find(l => l.id === state.selectedLeadId) ?? null;

  return {
    ...state,
    isEmpty,
    selectedLead,
    onSelectLead,
    onArchive,
    onProvideInfo,
    onClose,
    onOpenChat,
    onGoToDiscover,
  };
}
