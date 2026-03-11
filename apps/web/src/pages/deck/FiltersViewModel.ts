/* ── Filters ViewModel ── */

import { useState, useCallback } from "react";
import type { FilterPreferences, FiltersState, SortBy } from "./FiltersModel";
import { defaultFilters } from "./FiltersModel";
import { supabase } from "../../lib/supabase";

function trackEvent(event: string, data?: Record<string, unknown>) {
  console.log(`[analytics] ${event}`, data ?? "");
}

export function useFiltersViewModel(onApplied?: () => void) {
  const [state, setState] = useState<FiltersState>({
    draft: { ...defaultFilters },
    open: false,
    saving: false,
  });

  const onOpen = useCallback(() => {
    trackEvent("filters_opened");
    setState(s => ({ ...s, open: true }));
  }, []);

  const onClose = useCallback(() => {
    setState(s => ({ ...s, open: false }));
  }, []);

  const onToggleCategory = useCallback((cat: string) => {
    setState(s => {
      const cats = s.draft.categories.includes(cat)
        ? s.draft.categories.filter(c => c !== cat)
        : [...s.draft.categories, cat];
      return { ...s, draft: { ...s.draft, categories: cats } };
    });
  }, []);

  const onSetRating = useCallback((r: number) => {
    setState(s => ({ ...s, draft: { ...s.draft, min_rating: r } }));
  }, []);

  const onSetSort = useCallback((sort: SortBy) => {
    setState(s => ({ ...s, draft: { ...s.draft, sort_by: sort } }));
  }, []);

  const onToggleRemote = useCallback(() => {
    setState(s => ({ ...s, draft: { ...s.draft, remote_ok: !s.draft.remote_ok } }));
  }, []);

  const onToggleInPerson = useCallback(() => {
    setState(s => ({ ...s, draft: { ...s.draft, in_person_ok: !s.draft.in_person_ok } }));
  }, []);

  const onSetResponseTime = useCallback((mins: number | null) => {
    setState(s => ({ ...s, draft: { ...s.draft, max_response_minutes: mins } }));
  }, []);

  const onReset = useCallback(() => {
    trackEvent("filters_reset");
    setState(s => ({ ...s, draft: { ...defaultFilters } }));
  }, []);

  const onApply = useCallback(async () => {
    trackEvent("filters_applied", state.draft as unknown as Record<string, unknown>);
    setState(s => ({ ...s, saving: true }));
    try {
      await supabase.functions.invoke("save-filters", {
        body: state.draft,
        
      });
    } catch { /* silent */ }
    setState(s => ({ ...s, saving: false, open: false }));
    onApplied?.();
  }, [state.draft, onApplied]);

  const hasActiveFilters =
    state.draft.categories.length > 0 ||
    state.draft.min_rating > 0 ||
    !state.draft.remote_ok ||
    !state.draft.in_person_ok ||
    state.draft.max_response_minutes !== null ||
    state.draft.sort_by !== "recommended";

  return {
    ...state,
    hasActiveFilters,
    onOpen,
    onClose,
    onToggleCategory,
    onSetRating,
    onSetSort,
    onToggleRemote,
    onToggleInPerson,
    onSetResponseTime,
    onReset,
    onApply,
  };
}
