/* ── Messages ViewModel ── */

import { useState, useEffect, useCallback, useMemo } from "react";
import { useNavigate } from "react-router-dom";
import type { Conversation, MessagesState, MessageFilter } from "./MessagesModel";
import { supabase } from "../../lib/supabase";

export function useMessagesViewModel() {
  const navigate = useNavigate();
  const [state, setState] = useState<MessagesState>({
    conversations: [], loading: true, error: null, filter: "all", totalUnread: 0, waitingOnYou: 0,
  });

  useEffect(() => { loadConversations(); }, []);

  async function loadConversations() {
    setState(s => ({ ...s, loading: true }));
    try {
      const res = await supabase.functions.invoke("get-conversations", {
        
      });
      const d = res.data ?? {};
      setState(s => ({
        ...s,
        conversations: d.conversations ?? [],
        totalUnread: d.totalUnread ?? 0,
        waitingOnYou: d.waitingOnYou ?? 0,
        loading: false,
        error: null,
      }));
    } catch {
      setState(s => ({ ...s, loading: false, error: "Failed to load messages" }));
    }
  }

  const filtered = useMemo(() => {
    if (state.filter === "all") return state.conversations;
    if (state.filter === "waiting") return state.conversations.filter(c => c.status === "waiting_on_you");
    if (state.filter === "unread") return state.conversations.filter(c => c.unread_count > 0);
    return state.conversations;
  }, [state.conversations, state.filter]);

  const onSetFilter = useCallback((f: MessageFilter) => {
    setState(s => ({ ...s, filter: f }));
  }, []);

  const onOpenThread = useCallback((conversationId: string) => {
    navigate(`/messages/${conversationId}`);
  }, [navigate]);

  const onGoToDiscover = useCallback(() => navigate("/deck"), [navigate]);

  const isEmpty = !state.loading && state.conversations.length === 0;

  function formatTime(iso: string): string {
    const d = new Date(iso);
    const now = new Date();
    const diffMs = now.getTime() - d.getTime();
    const diffMins = Math.floor(diffMs / 60000);
    if (diffMins < 1) return "now";
    if (diffMins < 60) return `${diffMins}m`;
    const diffHrs = Math.floor(diffMins / 60);
    if (diffHrs < 24) return `${diffHrs}h`;
    const diffDays = Math.floor(diffHrs / 24);
    if (diffDays < 7) return `${diffDays}d`;
    return d.toLocaleDateString(undefined, { month: "short", day: "numeric" });
  }

  return { ...state, filtered, isEmpty, onSetFilter, onOpenThread, onGoToDiscover, formatTime };
}
