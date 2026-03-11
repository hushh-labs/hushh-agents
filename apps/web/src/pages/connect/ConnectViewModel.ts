/* ── Connect / Quote Request Sheet — ViewModel ── */

import { useState, useCallback } from "react";
import type { ConnectState, ChannelPref, Urgency } from "./ConnectModel";
import { getDefaultDraft, validateDraft } from "./ConnectModel";
import { supabase } from "../../lib/supabase";

function trackEvent(event: string, data?: Record<string, unknown>) {
  console.log(`[analytics] ${event}`, data ?? "");
}

export function useConnectViewModel() {
  const [state, setState] = useState<ConnectState>({
    open: false,
    draft: getDefaultDraft("", ""),
    sending: false,
    success: false,
    error: null,
  });

  const openSheet = useCallback((agentId: string, agentName: string) => {
    trackEvent("connect_sheet_opened", { agentId });
    setState({
      open: true,
      draft: getDefaultDraft(agentId, agentName),
      sending: false,
      success: false,
      error: null,
    });
  }, []);

  const closeSheet = useCallback(() => {
    setState(s => ({ ...s, open: false }));
  }, []);

  const onChangeMessage = useCallback((msg: string) => {
    setState(s => ({ ...s, draft: { ...s.draft, message: msg }, error: null }));
  }, []);

  const onSetChannel = useCallback((ch: ChannelPref) => {
    setState(s => ({ ...s, draft: { ...s.draft, channelPref: ch } }));
  }, []);

  const onSetUrgency = useCallback((u: Urgency) => {
    setState(s => ({ ...s, draft: { ...s.draft, urgency: u } }));
  }, []);

  const onSetCallbackTime = useCallback((t: string) => {
    setState(s => ({ ...s, draft: { ...s.draft, callbackTime: t } }));
  }, []);

  const onToggleConsent = useCallback(() => {
    setState(s => ({ ...s, draft: { ...s.draft, consentRevealContact: !s.draft.consentRevealContact } }));
  }, []);

  const onToggleMultiAgent = useCallback(() => {
    setState(s => ({ ...s, draft: { ...s.draft, multiAgent: !s.draft.multiAgent } }));
  }, []);

  const onAttachFile = useCallback((file: File | null) => {
    setState(s => ({ ...s, draft: { ...s.draft, attachmentFile: file } }));
    if (file) trackEvent("attachment_uploaded", { name: file.name });
  }, []);

  const onSubmit = useCallback(async () => {
    const validationError = validateDraft(state.draft);
    if (validationError) {
      setState(s => ({ ...s, error: validationError }));
      return;
    }

    setState(s => ({ ...s, sending: true, error: null }));

    try {
      

      const res = await supabase.functions.invoke("create-lead-request", {
        body: {
          agent_id: state.draft.agentId,
          message: state.draft.message,
          channel_pref: state.draft.channelPref,
          urgency: state.draft.urgency,
          callback_time: state.draft.callbackTime || null,
          consent_reveal_contact: state.draft.consentRevealContact,
          attachment_url: state.draft.attachmentUrl,
          multi_agent: state.draft.multiAgent,
        },
        headers: { Authorization: `Bearer ${import.meta.env.VITE_SUPABASE_ANON_KEY}` },
      });

      if (res.error) throw res.error;

      trackEvent("lead_request_submitted", {
        agentId: state.draft.agentId,
        urgency: state.draft.urgency,
        channel: state.draft.channelPref,
      });

      setState(s => ({ ...s, sending: false, success: true }));
    } catch {
      setState(s => ({ ...s, sending: false, error: "Something went wrong. Please try again." }));
    }
  }, [state.draft]);

  return {
    ...state,
    openSheet,
    closeSheet,
    onChangeMessage,
    onSetChannel,
    onSetUrgency,
    onSetCallbackTime,
    onToggleConsent,
    onToggleMultiAgent,
    onAttachFile,
    onSubmit,
  };
}
