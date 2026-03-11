/* ── Connect / Quote Request Sheet — Model ── */

export type ChannelPref = "email" | "phone" | "in_app";
export type Urgency = "low" | "medium" | "high";

export interface ConnectDraft {
  agentId: string;
  agentName: string;
  message: string;
  channelPref: ChannelPref;
  callbackTime: string;
  urgency: Urgency;
  consentRevealContact: boolean;
  attachmentFile: File | null;
  attachmentUrl: string | null;
  multiAgent: boolean;
}

export interface ConnectState {
  open: boolean;
  draft: ConnectDraft;
  sending: boolean;
  success: boolean;
  error: string | null;
}

export const channelOptions: { label: string; value: ChannelPref }[] = [
  { label: "In-app message", value: "in_app" },
  { label: "Email", value: "email" },
  { label: "Phone call", value: "phone" },
];

export const urgencyOptions: { label: string; value: Urgency; desc: string }[] = [
  { label: "Low", value: "low", desc: "No rush" },
  { label: "Medium", value: "medium", desc: "Within a week" },
  { label: "High", value: "high", desc: "As soon as possible" },
];

export const callbackSlots = [
  "Morning (9–12)",
  "Afternoon (12–5)",
  "Evening (5–8)",
  "Any time",
];

export function getDefaultDraft(agentId: string, agentName: string): ConnectDraft {
  return {
    agentId,
    agentName,
    message: "",
    channelPref: "in_app",
    callbackTime: "",
    urgency: "medium",
    consentRevealContact: false,
    attachmentFile: null,
    attachmentUrl: null,
    multiAgent: false,
  };
}

export function getSheetContent() {
  return {
    title: "Connect with",
    messagePlaceholder: "Briefly describe what you're looking for…",
    consentLabel: "I agree to share my contact details with this professional",
    multiAgentLabel: "Send to similar professionals too",
    ctaLabel: "Send Request",
    successTitle: "Request sent!",
    successCopy: "You'll hear back once the professional reviews your request.",
    offlineCopy: "This professional typically responds within 24 hours.",
    errorCopy: "Something went wrong. Please try again.",
  };
}

export function validateDraft(d: ConnectDraft): string | null {
  if (!d.message.trim()) return "Please add a short message.";
  if (d.message.length < 10) return "Message too short. Tell them a bit more.";
  if (!d.consentRevealContact) return "Please consent to share your contact.";
  return null;
}
