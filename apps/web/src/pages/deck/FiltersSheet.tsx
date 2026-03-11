/* ── Filters Sheet ── Bottom sheet overlay ── */

import { availableCategories, sortOptions, ratingOptions, responseTimeOptions } from "./FiltersModel";
import type { useFiltersViewModel } from "./FiltersViewModel";
import HushhAgentCTA from "../../components/HushhAgentCTA";

type FiltersVM = ReturnType<typeof useFiltersViewModel>;

export default function FiltersSheet({ vm }: { vm: FiltersVM }) {
  if (!vm.open) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center">
      {/* backdrop */}
      <div className="absolute inset-0 bg-black/60 backdrop-blur-sm" onClick={vm.onClose} />

      {/* sheet */}
      <div className="relative w-full max-w-md bg-[#1a0533] border-t border-white/10 rounded-t-3xl max-h-[85vh] overflow-y-auto pb-safe">
        {/* handle */}
        <div className="flex justify-center pt-3 pb-2">
          <div className="w-10 h-1 rounded-full bg-white/20" />
        </div>

        {/* header */}
        <div className="flex items-center justify-between px-5 pb-4">
          <h2 className="text-lg font-bold text-white">Filters & Sorting</h2>
          <button onClick={vm.onReset} className="text-xs text-[#e6ff00] font-medium">
            Reset to recommended
          </button>
        </div>

        <div className="px-5 space-y-6 pb-6">
          {/* ── Category ── */}
          <section>
            <h3 className="text-xs font-semibold text-white/30 uppercase tracking-wider mb-3">Line of Business</h3>
            <div className="flex flex-wrap gap-2">
              {availableCategories.map(cat => {
                const active = vm.draft.categories.includes(cat);
                return (
                  <button
                    key={cat}
                    onClick={() => vm.onToggleCategory(cat)}
                    className={`text-xs px-3 py-1.5 rounded-full border transition-colors ${
                      active
                        ? "bg-[#e6ff00]/20 border-[#e6ff00]/40 text-[#e6ff00]"
                        : "border-white/15 text-white/50 hover:text-white/70"
                    }`}
                  >
                    {cat}
                  </button>
                );
              })}
            </div>
          </section>

          {/* ── Availability ── */}
          <section>
            <h3 className="text-xs font-semibold text-white/30 uppercase tracking-wider mb-3">Availability</h3>
            <div className="flex gap-3">
              <label className="flex items-center gap-2 cursor-pointer">
                <input
                  type="checkbox"
                  checked={vm.draft.remote_ok}
                  onChange={vm.onToggleRemote}
                  className="rounded bg-white/10 border-white/20 text-[#e6ff00] focus:ring-[#e6ff00]"
                />
                <span className="text-sm text-white/70">Remote / Virtual</span>
              </label>
              <label className="flex items-center gap-2 cursor-pointer">
                <input
                  type="checkbox"
                  checked={vm.draft.in_person_ok}
                  onChange={vm.onToggleInPerson}
                  className="rounded bg-white/10 border-white/20 text-[#e6ff00] focus:ring-[#e6ff00]"
                />
                <span className="text-sm text-white/70">In-person</span>
              </label>
            </div>
          </section>

          {/* ── Min Rating ── */}
          <section>
            <h3 className="text-xs font-semibold text-white/30 uppercase tracking-wider mb-3">Minimum Rating</h3>
            <div className="flex gap-2">
              {ratingOptions.map(r => (
                <button
                  key={r}
                  onClick={() => vm.onSetRating(r)}
                  className={`text-xs px-3 py-1.5 rounded-full border transition-colors ${
                    vm.draft.min_rating === r
                      ? "bg-yellow-500/20 border-yellow-500/40 text-yellow-300"
                      : "border-white/15 text-white/50 hover:text-white/70"
                  }`}
                >
                  {r === 0 ? "Any" : `★ ${r}+`}
                </button>
              ))}
            </div>
          </section>

          {/* ── Response Time ── */}
          <section>
            <h3 className="text-xs font-semibold text-white/30 uppercase tracking-wider mb-3">Response Time</h3>
            <div className="flex gap-2">
              {responseTimeOptions.map(opt => (
                <button
                  key={opt.label}
                  onClick={() => vm.onSetResponseTime(opt.value)}
                  className={`text-xs px-3 py-1.5 rounded-full border transition-colors ${
                    vm.draft.max_response_minutes === opt.value
                      ? "bg-blue-500/20 border-blue-500/40 text-blue-300"
                      : "border-white/15 text-white/50 hover:text-white/70"
                  }`}
                >
                  {opt.label}
                </button>
              ))}
            </div>
          </section>

          {/* ── Sort ── */}
          <section>
            <h3 className="text-xs font-semibold text-white/30 uppercase tracking-wider mb-3">Sort By</h3>
            <div className="flex flex-wrap gap-2">
              {sortOptions.map(s => (
                <button
                  key={s.value}
                  onClick={() => vm.onSetSort(s.value)}
                  className={`text-xs px-3 py-1.5 rounded-full border transition-colors ${
                    vm.draft.sort_by === s.value
                      ? "bg-white/15 border-white/30 text-white"
                      : "border-white/15 text-white/50 hover:text-white/70"
                  }`}
                >
                  {s.label}
                </button>
              ))}
            </div>
          </section>

          {/* ── Apply ── */}
          <HushhAgentCTA
            label={vm.saving ? "Applying…" : "Apply Filters"}
            onClick={vm.onApply}
            showArrow
            className="w-full"
          />
        </div>
      </div>
    </div>
  );
}
