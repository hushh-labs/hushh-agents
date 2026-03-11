/* ── Settings ViewModel ── Pre-populates from onboarding localStorage + Supabase ── */

import { useState, useEffect, useCallback } from "react";
import { useNavigate } from "react-router-dom";
import { getDefaultSettings, type SettingsData, type SettingsState } from "./SettingsModel";
import { supabase } from "../../lib/supabase";

function trackEvent(event: string, data?: Record<string, unknown>) {
  console.log(`[analytics] ${event}`, data ?? "");
}

/** Merge onboarding localStorage drafts into settings defaults */
function loadOnboardingDefaults(): Partial<SettingsData> {
  const partial: Partial<SettingsData> = {};

  try {
    const profile = JSON.parse(localStorage.getItem("hushh_profile_draft") || "{}");
    if (profile.firstName || profile.lastName) {
      partial.profile = {
        fullName: [profile.firstName, profile.lastName].filter(Boolean).join(" "),
        email: localStorage.getItem("hushh_user_email") || profile.email || "",
        zip: profile.zipCode || "",
        contactPref: profile.preferredContact || "email",
        avatarUrl: "",
      };
    }
  } catch { /* silent */ }

  try {
    const goals = JSON.parse(localStorage.getItem("hushh_goals_draft") || "{}");
    if (goals.selectedGoals?.length) {
      partial.goals = goals.selectedGoals;
      partial.primaryGoal = goals.primaryGoal || goals.selectedGoals[0] || "";
      partial.timeline = goals.timeline || "";
      partial.communicationStyle = goals.communicationStyle || "";
    }
  } catch { /* silent */ }

  try {
    const location = JSON.parse(localStorage.getItem("hushh_location_draft") || "{}");
    if (location.connectPrefs?.length || location.coverageTimeline) {
      partial.connectPrefs = location.connectPrefs || [];
      partial.coverageTimeline = location.coverageTimeline || "";
      partial.insuredStatus = location.insuredStatus || "";
      partial.householdSize = location.householdSize || "";
    }
  } catch { /* silent */ }

  try {
    const notifs = JSON.parse(localStorage.getItem("hushh_notifications_draft") || "{}");
    if (notifs.emailAlerts !== undefined) {
      partial.notificationEmail = notifs.emailAlerts ?? true;
      partial.notificationPush = notifs.pushEnabled ?? true;
    }
  } catch { /* silent */ }

  return partial;
}

export function useSettingsViewModel() {
  const navigate = useNavigate();
  const [state, setState] = useState<SettingsState>({
    data: getDefaultSettings(),
    loading: true,
    saving: false,
    error: null,
    successMsg: null,
    dirty: false,
    deleteConfirmOpen: false,
    exportRequested: false,
  });

  useEffect(() => {
    trackEvent("settings_viewed");
    loadSettings();
  }, []);

  async function loadSettings() {
    setState(s => ({ ...s, loading: true }));

    // 1. Start with onboarding defaults from localStorage
    const onboardingDefaults = loadOnboardingDefaults();
    const merged = { ...getDefaultSettings(), ...onboardingDefaults };
    if (onboardingDefaults.profile) {
      merged.profile = { ...getDefaultSettings().profile, ...onboardingDefaults.profile };
    }

    // Fill email from localStorage if still empty
    if (!merged.profile.email) {
      merged.profile.email = localStorage.getItem("hushh_user_email") || "";
    }

    // 2. Try to load from Supabase (overrides localStorage if server data exists)
    try {
      const res = await supabase.functions.invoke("get-settings", {});
      const server = res.data;
      if (server?.profile) {
        merged.profile = {
          fullName: server.profile.full_name || server.profile.fullName || merged.profile.fullName,
          email: server.profile.email || merged.profile.email,
          zip: server.profile.zip_code || server.profile.zip || merged.profile.zip,
          contactPref: server.profile.contact_preference || server.profile.contactPref || merged.profile.contactPref,
          avatarUrl: server.profile.avatar_url || server.profile.avatarUrl || merged.profile.avatarUrl,
        };
      }
      if (server?.settings) {
        merged.notificationEmail = server.settings.notification_email ?? merged.notificationEmail;
        merged.notificationPush = server.settings.notification_push ?? merged.notificationPush;
        merged.quietHoursStart = server.settings.quiet_hours_start || merged.quietHoursStart;
        merged.quietHoursEnd = server.settings.quiet_hours_end || merged.quietHoursEnd;
        merged.dataSharing = server.settings.data_sharing ?? merged.dataSharing;
      }
    } catch { /* use localStorage defaults */ }

    setState(s => ({ ...s, data: merged, loading: false }));
  }

  /* ── Field update helpers ── */
  const updateProfile = useCallback((field: string, value: string) => {
    setState(s => ({
      ...s,
      dirty: true,
      data: { ...s.data, profile: { ...s.data.profile, [field]: value } },
    }));
  }, []);

  const toggleNotifEmail = useCallback(() => {
    setState(s => ({
      ...s,
      dirty: true,
      data: { ...s.data, notificationEmail: !s.data.notificationEmail },
    }));
  }, []);

  const toggleNotifPush = useCallback(() => {
    setState(s => ({
      ...s,
      dirty: true,
      data: { ...s.data, notificationPush: !s.data.notificationPush },
    }));
  }, []);

  const toggleDataSharing = useCallback(() => {
    setState(s => ({
      ...s,
      dirty: true,
      data: { ...s.data, dataSharing: !s.data.dataSharing },
    }));
  }, []);

  /* ── Save ── */
  const onSave = useCallback(async () => {
    setState(s => ({ ...s, saving: true, error: null, successMsg: null }));
    try {
      await supabase.functions.invoke("save-settings", {
        body: {
          full_name: state.data.profile.fullName,
          zip_code: state.data.profile.zip,
          contact_preference: state.data.profile.contactPref,
          notification_email: state.data.notificationEmail,
          notification_push: state.data.notificationPush,
          quiet_hours_start: state.data.quietHoursStart,
          quiet_hours_end: state.data.quietHoursEnd,
          data_sharing: state.data.dataSharing,
        },
      });
      trackEvent("settings_saved");
      setState(s => ({ ...s, saving: false, dirty: false, successMsg: "Settings saved!" }));
      setTimeout(() => setState(s => ({ ...s, successMsg: null })), 3000);
    } catch {
      setState(s => ({ ...s, saving: false, error: "Failed to save settings" }));
    }
  }, [state.data]);

  /* ── Export data ── */
  const onExportData = useCallback(() => {
    trackEvent("data_export_requested");
    const exportData = {
      profile: state.data.profile,
      goals: state.data.goals,
      primaryGoal: state.data.primaryGoal,
      timeline: state.data.timeline,
      connectPrefs: state.data.connectPrefs,
      notificationEmail: state.data.notificationEmail,
      notificationPush: state.data.notificationPush,
      dataSharing: state.data.dataSharing,
      analyticsLog: JSON.parse(localStorage.getItem("hushh_analytics_log") || "[]"),
      exportedAt: new Date().toISOString(),
    };
    const blob = new Blob([JSON.stringify(exportData, null, 2)], { type: "application/json" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `hushh-data-export-${new Date().toISOString().split("T")[0]}.json`;
    a.click();
    URL.revokeObjectURL(url);
    setState(s => ({ ...s, exportRequested: true }));
  }, [state.data]);

  /* ── Delete account ── */
  const onDeleteAccount = useCallback(async () => {
    setState(s => ({ ...s, saving: true }));
    try {
      await supabase.functions.invoke("delete-account", {});
      trackEvent("account_deleted");
      localStorage.clear();
      navigate("/");
    } catch {
      setState(s => ({ ...s, saving: false, error: "Failed to delete account" }));
    }
  }, [navigate]);

  const onToggleDeleteConfirm = useCallback(() => {
    setState(s => ({ ...s, deleteConfirmOpen: !s.deleteConfirmOpen }));
  }, []);

  const onBack = useCallback(() => navigate(-1), [navigate]);
  const onSignOut = useCallback(() => {
    trackEvent("sign_out");
    localStorage.clear();
    navigate("/");
  }, [navigate]);

  return {
    ...state,
    updateProfile,
    toggleNotifEmail,
    toggleNotifPush,
    toggleDataSharing,
    onSave,
    onExportData,
    onDeleteAccount,
    onToggleDeleteConfirm,
    onBack,
    onSignOut,
  };
}
