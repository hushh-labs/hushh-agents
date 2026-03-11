/* ── Chat ViewModel ── */

import { useState, useEffect, useCallback, useRef } from "react";
import { useParams, useNavigate } from "react-router-dom";
import type { ChatState, ChatMessage } from "./ChatModel";
import { supabase } from "../../lib/supabase";

export function useChatViewModel() {
  const { conversationId } = useParams<{ conversationId: string }>();
  const navigate = useNavigate();
  const bottomRef = useRef<HTMLDivElement | null>(null);

  // Draft persistence: restore from sessionStorage
  const draftKey = `chat_draft_${conversationId ?? ""}`;
  const savedDraft = typeof window !== "undefined" ? sessionStorage.getItem(draftKey) ?? "" : "";

  const [state, setState] = useState<ChatState>({
    conversationId: conversationId ?? null,
    agentName: "", agentPhotoUrl: "", status: "",
    messages: [], loading: true, error: null,
    draft: savedDraft, sending: false, menuOpen: false,
  });

  useEffect(() => {
    if (conversationId) loadThread(conversationId);
  }, [conversationId]);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [state.messages.length]);

  async function loadThread(id: string) {
    setState(s => ({ ...s, loading: true }));
    try {
      const res2 = await fetch(
        `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/get-messages?conversation_id=${id}`,
        {}
      );
      const data = await res2.json();
      setState(s => ({
        ...s,
        agentName: data.agentName ?? "",
        agentPhotoUrl: data.agentPhotoUrl ?? "",
        status: data.conversation?.status ?? "",
        messages: data.messages ?? [],
        loading: false, error: null,
      }));
    } catch {
      setState(s => ({ ...s, loading: false, error: "Failed to load messages" }));
    }
  }

  // Persist draft to sessionStorage so it survives back-navigation
  const onChangeDraft = useCallback((text: string) => {
    setState(s => ({ ...s, draft: text }));
    sessionStorage.setItem(draftKey, text);
  }, [draftKey]);

  const onSend = useCallback(async () => {
    const body = state.draft.trim();
    if (!body || !state.conversationId) return;

    const optimistic: ChatMessage = {
      id: `temp-${Date.now()}`,
      sender_type: "user",
      body,
      created_at: new Date().toISOString(),
      sending: true,
    };

    // Clear persisted draft on send
    sessionStorage.removeItem(draftKey);

    setState(s => ({
      ...s,
      messages: [...s.messages, optimistic],
      draft: "",
      sending: true,
    }));

    try {
      const res = await supabase.functions.invoke("send-message", {
        body: { conversation_id: state.conversationId, body },
        
      });
      const msg = res.data?.message;
      setState(s => ({
        ...s,
        sending: false,
        messages: s.messages.map(m =>
          m.id === optimistic.id ? (msg ?? { ...m, sending: false }) : m
        ),
      }));
    } catch {
      setState(s => ({
        ...s,
        sending: false,
        messages: s.messages.map(m =>
          m.id === optimistic.id ? { ...m, sending: false, failed: true } : m
        ),
      }));
    }
  }, [state.draft, state.conversationId]);

  const onRetry = useCallback(async (msgId: string) => {
    const msg = state.messages.find(m => m.id === msgId);
    if (!msg) return;
    setState(s => ({
      ...s,
      messages: s.messages.filter(m => m.id !== msgId),
      draft: msg.body,
    }));
  }, [state.messages]);

  const onQuickPrompt = useCallback((text: string) => {
    setState(s => ({ ...s, draft: text }));
  }, []);

  const onToggleMenu = useCallback(() => {
    setState(s => ({ ...s, menuOpen: !s.menuOpen }));
  }, []);

  const onArchive = useCallback(async () => {
    try {
      await supabase.from("conversations")
        .update({ status: "closed" })
        .eq("id", state.conversationId);
    } catch { /* silent */ }
    navigate("/messages");
  }, [state.conversationId, navigate]);

  const onReport = useCallback(() => {
    if (!state.conversationId) return;
    // Report via deck interaction
    console.log("[chat] report conversation", state.conversationId);
    setState(s => ({ ...s, menuOpen: false }));
  }, [state.conversationId]);

  const onAttachFile = useCallback(() => {
    // Future: open file picker, upload, attach to message
    console.log("[chat] attach file requested");
  }, []);

  const onRequestCallback = useCallback(() => {
    // Send a system message requesting callback
    const callbackMsg = "I'd like to request a callback at your earliest convenience.";
    setState(s => ({ ...s, draft: callbackMsg, menuOpen: false }));
  }, []);

  const onBack = useCallback(() => navigate("/messages"), [navigate]);

  const isEmpty = !state.loading && state.messages.length === 0;

  return { ...state, bottomRef, isEmpty, onChangeDraft, onSend, onRetry, onQuickPrompt, onToggleMenu, onArchive, onRequestCallback, onAttachFile, onReport, onBack };
}
