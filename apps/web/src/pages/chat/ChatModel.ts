/* ── Chat Model ── Pure data types ── */

export type SenderType = "user" | "agent" | "system";

export interface ChatMessage {
  id: string;
  sender_type: SenderType;
  body: string;
  created_at: string;
  sending?: boolean;
  failed?: boolean;
}

export interface ChatState {
  conversationId: string | null;
  agentName: string;
  agentPhotoUrl: string;
  status: string;
  messages: ChatMessage[];
  loading: boolean;
  error: string | null;
  draft: string;
  sending: boolean;
  menuOpen: boolean;
}

export const quickPrompts = [
  "Request availability",
  "Ask about services",
  "Schedule a call",
  "Share goals",
];

export function getTrustBanner() {
  return "This conversation may be used to prepare recommendations or quotes. Avoid sharing sensitive account details until requested securely.";
}

export function getEmptyThreadContent() {
  return {
    copy: "Start the conversation with a short summary of what you need.",
  };
}
