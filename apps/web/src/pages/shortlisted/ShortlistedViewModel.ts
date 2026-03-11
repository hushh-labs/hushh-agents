/* ── Shortlisted ViewModel ── Enhanced with archive, sort, lead states ── */

import { useState, useEffect, useCallback, useMemo } from "react";
import { useNavigate } from "react-router-dom";
import type { ShortlistedAgent, ShortlistedState, FilterStatus, SortBy } from "./ShortlistedModel";
import { supabase } from "../../lib/supabase";

function trackEvent(event: string, data?: Record<string, unknown>) {
  console.log(`[analytics] ${event}`, data ?? "");
}

export function useShortlistedViewModel() {
  const navigate = useNavigate();
  const [state, setState] = useState<ShortlistedState>({
    agents: [], loading: true, error: null, filterStatus: "all", sortBy: "newest", editMode: false,
  });

  useEffect(() => {
    trackEvent("shortlist_viewed");
    loadShortlisted();
  }, []);

  async function loadShortlisted() {
    setState(s => ({ ...s, loading: true }));
    try {
      const res = await supabase.functions.invoke("get-shortlisted", {
        
      });
      const agents: ShortlistedAgent[] = (res.data?.agents ?? []).map((a: any) => ({
        ...a,
        leadStatus: a.leadStatus ?? "none",
        fitScore: a.fitScore ?? 0,
      }));
      setState(s => ({ ...s, agents, loading: false, error: null }));
    } catch {
      setState(s => ({ ...s, loading: false, error: "Failed to load saved agents" }));
    }
  }

  /* ── sorted + filtered list ── */
  const filteredAgents = useMemo(() => {
    let list = state.agents;
    if (state.filterStatus !== "all") {
      list = list.filter(a => a.status === state.filterStatus);
    }
    if (state.sortBy === "newest") {
      list = [...list].sort((a, b) => new Date(b.savedAt).getTime() - new Date(a.savedAt).getTime());
    } else {
      list = [...list].sort((a, b) => (b.fitScore ?? 0) - (a.fitScore ?? 0));
    }
    return list;
  }, [state.agents, state.filterStatus, state.sortBy]);

  /* ── actions ── */
  const onOpenProfile = useCallback((agentId: string) => {
    navigate(`/agents/${agentId}`);
  }, [navigate]);

  const onConnect = useCallback(async (agentId: string) => {
    trackEvent("shortlist_connect_clicked", { agentId });
    try {
      await supabase.functions.invoke("save-action", {
        body: { agent_id: agentId, action: "contact_request" },
        
      });
      setState(s => ({
        ...s,
        agents: s.agents.map(a =>
          a.id === agentId ? { ...a, status: "Contacted" as const, leadStatus: "pending" as const } : a
        ),
      }));
    } catch { /* silent */ }
  }, []);

  const onArchive = useCallback(async (agentId: string) => {
    trackEvent("shortlist_archived", { agentId });
    try {
      await supabase.functions.invoke("save-action", {
        body: { agent_id: agentId, action: "archive" },
        
      });
      setState(s => ({
        ...s,
        agents: s.agents.map(a =>
          a.id === agentId ? { ...a, status: "Archived" as const } : a
        ),
      }));
    } catch { /* silent */ }
  }, []);

  const onRemove = useCallback(async (agentId: string) => {
    try {
      await supabase.functions.invoke("save-action", {
        body: { agent_id: agentId, action: "unsave" },
        
      });
      setState(s => ({ ...s, agents: s.agents.filter(a => a.id !== agentId) }));
    } catch { /* silent */ }
  }, []);

  const onSetFilter = useCallback((f: FilterStatus) => {
    setState(s => ({ ...s, filterStatus: f }));
  }, []);

  const onSetSort = useCallback((s: SortBy) => {
    setState(st => ({ ...st, sortBy: s }));
  }, []);

  const onToggleEdit = useCallback(() => {
    setState(s => ({ ...s, editMode: !s.editMode }));
  }, []);

  const onGoToDiscover = useCallback(() => navigate("/deck"), [navigate]);

  const isEmpty = !state.loading && state.agents.length === 0;

  return {
    ...state,
    filteredAgents,
    isEmpty,
    onOpenProfile,
    onConnect,
    onArchive,
    onRemove,
    onSetFilter,
    onSetSort,
    onToggleEdit,
    onGoToDiscover,
  };
}
