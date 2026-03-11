/* ── Settings / My Profile — ViewModel ── */

import { useState, useEffect, useCallback } from "react";
import type { SettingsState, SettingsData } from "./SettingsModel";
import { getDefaultSettings } from "./SettingsModel";
import { supabase } from "../../lib/supabase";

function trackEvent(event: string, data?: Record<string, unknown>) {
  console.log(`[analytics] ${event}`, data ?? "");
}

export function useSettingsViewModel() {
  const [state, setState] = useState<SettingsState>({
    data: getDefaultSettings(),
    loading: true, saving: false, error: null, successMsg: null,
    dirty: false, deleteConfirmOpen: false, exportRequested: false,
  });

  useEffect(() => {
    trackEvent("settings_viewed");
    loadSettings();
  }, []);

  async function loadSettings() {
    setState(s => ({ ...s, loading: true }));
    try {
      const res = await supabase.functions.invoke("get-settings", {
        
      });
      const d = res.data?.settings;
      if (d) setState(s => ({ ...s, data: d, loading: false, error: null }));
      else setState(s => ({ ...s, loading: false }));
    } catch {
      setState(s => ({ ...s, loading: false, error: "Failed to load settings" }));
    }
  }

  const updateField = useCallback(<K extends keyof SettingsData>(key: K, value: SettingsData[K]) => {
    setState(s => ({ ...s, data: { ...s.data, [key]: value }, dirty: true, successMsg: null }));
  }, []);

  const updateProfile = useCallback((field: string, value: string) => {
    setState(s => ({
      ...s,
      data: { ...s.data, profile: { ...s.data.profile, [field]: value } },
      dirty: true, successMsg: null,
    }));
  }, []);

  const onSave = useCallback(async () => {
    setState(s => ({ ...s, saving: true, error: null }));
    try {
      await supabase.functions.invoke("save-settings", {
        body: state.data,
        
      });
      trackEvent("settings_saved");
      setState(s => ({ ...s, saving: false, dirty: false, successMsg: "Changes saved" }));
    } catch {
      setState(s => ({ ...s, saving: false, error: "Failed to save" }));
    }
  }, [state.data]);

  const onExportData = useCallback(async () => {
    trackEvent("export_requested");
    setState(s => ({ ...s, exportRequested: true }));
    // Future: trigger actual data export
  }, []);

  const onOpenDeleteConfirm = useCallback(() => {
    setState(s => ({ ...s, deleteConfirmOpen: true }));
  }, []);

  const onCancelDelete = useCallback(() => {
    setState(s => ({ ...s, deleteConfirmOpen: false }));
  }, []);

  const onConfirmDelete = useCallback(async () => {
    trackEvent("delete_requested");
    try {
      await supabase.functions.invoke("delete-account", {
        body: {},
        
      });
      setState(s => ({ ...s, deleteConfirmOpen: false, successMsg: "Account deletion scheduled." }));
    } catch {
      setState(s => ({ ...s, error: "Failed to request deletion" }));
    }
  }, []);

  const onUnblock = useCallback((agentId: string) => {
    setState(s => ({
      ...s,
      data: { ...s.data, blockedAgents: s.data.blockedAgents.filter(a => a !== agentId) },
      dirty: true,
    }));
  }, []);

  return {
    ...state,
    updateField,
    updateProfile,
    onSave,
    onExportData,
    onOpenDeleteConfirm,
    onCancelDelete,
    onConfirmDelete,
    onUnblock,
  };
}
