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
  /* ── Onboarding-sourced fields ── */
  goals: string[];
  primaryGoal: string;
  timeline: string;
  communicationStyle: string;
  connectPrefs: string[];
  coverageTimeline: string;
  insuredStatus: string;
  householdSize: string;
  /* ── Notification & privacy ── */
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
    goals: [],
    primaryGoal: "",
    timeline: "",
    communicationStyle: "",
    connectPrefs: [],
    coverageTimeline: "",
    insuredStatus: "",
    householdSize: "",
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
    deleteLabel: "Delete account",
    exportLabel: "Export my data",
    signOutLabel: "Sign out",
  };
}
