/* ── Filters Model ── Pure data types ── */

export type SortBy = "recommended" | "rating" | "distance" | "response_time";

export interface FilterPreferences {
  categories: string[];
  min_rating: number;
  remote_ok: boolean;
  in_person_ok: boolean;
  max_response_minutes: number | null;
  sort_by: SortBy;
}

export interface FiltersState {
  draft: FilterPreferences;
  open: boolean;
  saving: boolean;
}

export const defaultFilters: FilterPreferences = {
  categories: [],
  min_rating: 0,
  remote_ok: true,
  in_person_ok: true,
  max_response_minutes: null,
  sort_by: "recommended",
};

export const availableCategories = [
  "Financial Advising",
  "Investing",
  "Insurance",
  "Mortgage Brokers",
  "Accountants",
  "Tax Services",
];

export const sortOptions: { label: string; value: SortBy }[] = [
  { label: "Recommended", value: "recommended" },
  { label: "Highest rated", value: "rating" },
  { label: "Closest", value: "distance" },
  { label: "Fastest response", value: "response_time" },
];

export const ratingOptions = [0, 3, 3.5, 4, 4.5];

export const responseTimeOptions: { label: string; value: number | null }[] = [
  { label: "Any", value: null },
  { label: "< 30 min", value: 30 },
  { label: "< 1 hr", value: 60 },
  { label: "< 4 hrs", value: 240 },
];
