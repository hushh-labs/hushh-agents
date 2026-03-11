/* ── Shortlisted Model ── Pure data types ── */

import type { DeckAgent } from "../deck/DeckModel";

export type ShortlistStatus = "Saved" | "Contacted" | "Replied" | "Archived";
export type LeadRequestStatus = "none" | "pending" | "accepted" | "declined";
export type SortBy = "newest" | "fit_score";

export interface ShortlistedAgent extends DeckAgent {
  status: ShortlistStatus;
  savedAt: string;
  leadStatus: LeadRequestStatus;
  fitScore: number;
}

export type FilterStatus = "all" | ShortlistStatus;

export interface ShortlistedState {
  agents: ShortlistedAgent[];
  loading: boolean;
  error: string | null;
  filterStatus: FilterStatus;
  sortBy: SortBy;
  editMode: boolean;
}

export function getEmptyContent() {
  return {
    title: "Nothing saved yet.",
    copy: "Swipe right on profiles you want to revisit later.",
    ctaLabel: "Go to Discover",
  };
}

export function getHeaderContent() {
  return {
    title: "Interested",
    footerNote: "Saved does not notify the professional unless product policy explicitly changes later.",
  };
}
