/* ── Settings / My Profile — Model ── */

export interface UserProfile {
  fullName: string;
  email: string;
  zip: string;
  contactPref: string;
  avatarUrl: string;
}

export interface SettingsData {
  profile: UserProfile;
  notificationEmail: boolean;
  notificationPush: boolean;
  quietHoursStart: string;
  quietHoursEnd: string;
  dataSharing: boolean;
  blockedAgents: string[];
}

export interface SettingsState {
  data: SettingsData;
  loading: boolean;
  saving: boolean;
  error: string | null;
  successMsg: string | null;
  dirty: boolean;
  deleteConfirmOpen: boolean;
  exportRequested: boolean;
}

export function getDefaultSettings(): SettingsData {
  return {
    profile: { fullName: "", email: "", zip: "", contactPref: "email", avatarUrl: "" },
    notificationEmail: true,
    notificationPush: true,
    quietHoursStart: "",
    quietHoursEnd: "",
    dataSharing: true,
    blockedAgents: [],
  };
}

export function getSettingsContent() {
  return {
    title: "My Profile",
    saveLabel: "Save changes",
    savedMsg: "Changes saved",
    exportLabel: "Export my data",
    deleteLabel: "Delete account",
    deleteWarning: "Your account will be scheduled for deletion in 30 days. You can recover it within this window.",
    deleteConfirmLabel: "Yes, delete my account",
    cancelLabel: "Cancel",
  };
}
