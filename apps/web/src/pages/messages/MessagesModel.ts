/* ── Messages Model ── Pure data types ── */

export type ConversationStatus = "requested" | "replied" | "waiting_on_you" | "closed";
export type MessageFilter = "all" | "waiting" | "unread";

export interface Conversation {
  id: string;
  agent_id: string;
  agentName: string;
  agentPhotoUrl: string;
  agentCategory: string;
  status: ConversationStatus;
  last_message_preview: string | null;
  last_message_at: string;
  unread_count: number;
}

export interface MessagesState {
  conversations: Conversation[];
  loading: boolean;
  error: string | null;
  filter: MessageFilter;
  totalUnread: number;
  waitingOnYou: number;
}

export const statusLabels: Record<ConversationStatus, string> = {
  requested: "Requested",
  replied: "Replied",
  waiting_on_you: "Waiting on you",
  closed: "Closed",
};

export const statusColors: Record<ConversationStatus, string> = {
  requested: "bg-yellow-500/20 text-yellow-300",
  replied: "bg-green-500/20 text-green-300",
  waiting_on_you: "bg-brand-primary/20 text-brand-primary",
  closed: "bg-white/10 text-white/40",
};

export function getEmptyContent() {
  return {
    title: "No conversations yet.",
    copy: "When you request info from a professional, the conversation will appear here.",
    ctaLabel: "Discover advisors",
  };
}
