/* ── Agent Profile Model ── Pure data types ── */

import type { DeckAgent } from "../deck/DeckModel";

export type AgentProfileAgent = DeckAgent;

export interface AgentProfileState {
  agent: AgentProfileAgent | null;
  loading: boolean;
  error: string | null;
  saved: boolean;
  connectRequested: boolean;
  reported: boolean;
}
