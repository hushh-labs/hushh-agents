/* ── Lead / Quote Status Tracker — Model ── */

export type LeadStatus =
  | "requested" | "viewed" | "need_more_info" | "quoting"
  | "quote_sent" | "closed_won" | "closed_lost" | "archived";

export interface LeadEvent {
  id: string;
  event_type: string;
  metadata: Record<string, unknown>;
  created_at: string;
}

export interface LeadRequest {
  id: string;
  agent_id: string;
  agentName: string;
  agentPhotoUrl: string;
  agentCategory: string;
  message: string;
  channel_pref: string;
  urgency: string;
  status: LeadStatus;
  created_at: string;
  updated_at: string;
  events: LeadEvent[];
}

export interface LeadTrackerState {
  leads: LeadRequest[];
  loading: boolean;
  error: string | null;
  selectedLeadId: string | null;
}

export const statusSteps: { key: LeadStatus; label: string; color: string }[] = [
  { key: "requested", label: "Requested", color: "bg-yellow-500/20 text-yellow-300" },
  { key: "viewed", label: "Viewed", color: "bg-blue-500/20 text-blue-300" },
  { key: "need_more_info", label: "Need more info", color: "bg-orange-500/20 text-orange-300" },
  { key: "quoting", label: "Quoting", color: "bg-purple-500/20 text-purple-300" },
  { key: "quote_sent", label: "Quote sent", color: "bg-[#e6ff00]/20 text-[#e6ff00]" },
  { key: "closed_won", label: "Closed won", color: "bg-green-500/20 text-green-300" },
  { key: "closed_lost", label: "Closed lost", color: "bg-red-500/20 text-red-300" },
  { key: "archived", label: "Archived", color: "bg-white/10 text-white/30" },
];

export function getEmptyContent() {
  return {
    title: "No active requests.",
    copy: "When you connect with a professional, the status of your request will appear here.",
    ctaLabel: "Discover advisors",
  };
}

export function getHeaderContent() {
  return {
    title: "Lead Tracker",
    subtitle: "Track the status of your requests and quotes.",
  };
}

export function getStatusStep(status: LeadStatus) {
  return statusSteps.find(s => s.key === status) ?? statusSteps[0];
}
