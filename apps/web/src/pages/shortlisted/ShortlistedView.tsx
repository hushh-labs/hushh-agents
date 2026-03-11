/* ── Shortlisted View ── Enhanced with archive, sort, lead states ── */

import { useShortlistedViewModel } from "./ShortlistedViewModel";
import { getEmptyContent, getHeaderContent } from "./ShortlistedModel";
import type { ShortlistedAgent, FilterStatus, SortBy } from "./ShortlistedModel";
import HushhAgentHeading from "../../components/HushhAgentHeading";
import HushhAgentText from "../../components/HushhAgentText";
import HushhAgentCTA from "../../components/HushhAgentCTA";

const filters: { label: string; value: FilterStatus }[] = [
  { label: "All", value: "all" },
  { label: "Saved", value: "Saved" },
  { label: "Contacted", value: "Contacted" },
  { label: "Replied", value: "Replied" },
  { label: "Archived", value: "Archived" },
];

const statusColors: Record<string, string> = {
  Saved: "bg-brand-primary/20 text-brand-primary",
  Contacted: "bg-brand-primary/20 text-brand-primary",
  Replied: "bg-green-500/20 text-green-300",
  Archived: "bg-white/10 text-white/30",
};

const leadStatusLabels: Record<string, string> = {
  none: "",
  pending: "Lead pending",
  accepted: "Lead accepted ✓",
  declined: "Lead declined",
};

const leadStatusColors: Record<string, string> = {
  pending: "text-yellow-400/70",
  accepted: "text-green-400/70",
  declined: "text-red-400/70",
};

export default function ShortlistedView() {
  const vm = useShortlistedViewModel();
  const content = getHeaderContent();
  const emptyContent = getEmptyContent();

  if (vm.loading) {
    return (
      <div className="flex items-center justify-center min-h-screen bg-brand-dark">
        <div className="animate-pulse text-white/60 text-lg">Loading saved agents…</div>
      </div>
    );
  }

  if (vm.isEmpty) {
    return (
      <div className="flex flex-col items-center justify-center min-h-screen bg-brand-dark px-6 text-center gap-5">
        <div className="text-5xl">📋</div>
        <HushhAgentHeading>{emptyContent.title}</HushhAgentHeading>
        <HushhAgentText className="text-white/50">{emptyContent.copy}</HushhAgentText>
        <HushhAgentCTA label={emptyContent.ctaLabel} onClick={vm.onGoToDiscover} showArrow />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-brand-dark text-white pb-24">
      {/* header */}
      <div className="flex items-center justify-between px-5 pt-12 pb-2">
        <HushhAgentHeading className="text-xl">{content.title}</HushhAgentHeading>
        <div className="flex items-center gap-2">
          {/* sort toggle */}
          <button
            onClick={() => vm.onSetSort(vm.sortBy === "newest" ? "fit_score" : "newest")}
            className="text-[10px] text-white/40 border border-white/15 rounded-full px-2.5 py-1 hover:text-white/60"
          >
            {vm.sortBy === "newest" ? "↓ Newest" : "↓ Fit score"}
          </button>
          <button
            onClick={vm.onToggleEdit}
            className={`text-xs font-medium px-3 py-1.5 rounded-full transition-colors ${
              vm.editMode ? "bg-brand-primary/20 text-brand-primary" : "text-white/50 hover:text-white/80"
            }`}
          >
            {vm.editMode ? "Done" : "Edit"}
          </button>
        </div>
      </div>

      {/* filter chips */}
      <div className="flex gap-2 px-5 pb-4 overflow-x-auto no-scrollbar">
        {filters.map(f => (
          <button
            key={f.value}
            onClick={() => vm.onSetFilter(f.value)}
            className={`text-xs font-medium px-3.5 py-1.5 rounded-full whitespace-nowrap transition-colors ${
              vm.filterStatus === f.value
                ? "bg-white/15 text-white"
                : "bg-white/5 text-white/40 hover:text-white/60"
            }`}
          >
            {f.label}
          </button>
        ))}
      </div>

      {/* agent list */}
      <div className="px-5 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
        {vm.filteredAgents.map((agent: ShortlistedAgent) => (
          <div
            key={agent.id}
            className={`bg-white/5 border border-white/10 rounded-custom overflow-hidden transition-colors ${
              agent.status === "Archived" ? "opacity-50" : ""
            }`}
          >
            {/* row content */}
            <button
              onClick={() => vm.onOpenProfile(agent.id)}
              className="w-full flex items-center gap-3.5 p-4 text-left active:bg-white/10"
            >
              {/* thumbnail */}
              <div className="w-14 h-14 rounded-xl overflow-hidden flex-shrink-0 bg-white/10">
                {agent.photoUrl ? (
                  <img src={agent.photoUrl} alt={agent.name} className="w-full h-full object-cover"
                    onError={(e: React.SyntheticEvent<HTMLImageElement>) => {
                      (e.target as HTMLImageElement).style.display = "none";
                    }}
                  />
                ) : (
                  <div className="w-full h-full flex items-center justify-center text-white/30 text-lg">
                    {agent.name.charAt(0)}
                  </div>
                )}
              </div>

              {/* info */}
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2 mb-0.5">
                  <h3 className="text-white text-sm font-semibold truncate">{agent.name}</h3>
                  <span className={`text-[9px] font-semibold px-2 py-0.5 rounded-full uppercase tracking-wider flex-shrink-0 ${statusColors[agent.status] ?? statusColors.Saved}`}>
                    {agent.status}
                  </span>
                </div>
                <p className="text-white/50 text-xs truncate">{agent.category} · {agent.city}, {agent.state}</p>
                <div className="flex items-center gap-2 mt-0.5">
                  {agent.rating > 0 && (
                    <span className="text-yellow-400/80 text-[11px]">★ {agent.rating.toFixed(1)} ({agent.reviewCount})</span>
                  )}
                  {agent.fitScore > 0 && (
                    <span className="text-[10px] text-white/30">Fit: {agent.fitScore}%</span>
                  )}
                  {agent.leadStatus !== "none" && leadStatusLabels[agent.leadStatus] && (
                    <span className={`text-[10px] ${leadStatusColors[agent.leadStatus] ?? "text-white/30"}`}>
                      {leadStatusLabels[agent.leadStatus]}
                    </span>
                  )}
                </div>
              </div>

              {/* chevron */}
              <svg className="w-4 h-4 text-white/20 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
                <path fillRule="evenodd" d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z" clipRule="evenodd" />
              </svg>
            </button>

            {/* action buttons */}
            {vm.editMode && agent.status !== "Archived" && (
              <div className="flex border-t border-white/10">
                <button
                  onClick={() => vm.onConnect(agent.id)}
                  disabled={agent.status === "Contacted" || agent.leadStatus === "pending"}
                  className={`flex-1 py-2.5 text-xs font-medium transition-colors ${
                    agent.status === "Contacted" || agent.leadStatus === "pending"
                      ? "text-white/20"
                      : "text-brand-primary hover:bg-brand-primary/10"
                  }`}
                >
                  Connect
                </button>
                <div className="w-px bg-white/10" />
                <button
                  onClick={() => vm.onArchive(agent.id)}
                  className="flex-1 py-2.5 text-xs font-medium text-white/40 hover:bg-white/5 transition-colors"
                >
                  Archive
                </button>
                <div className="w-px bg-white/10" />
                <button
                  onClick={() => vm.onRemove(agent.id)}
                  className="flex-1 py-2.5 text-xs font-medium text-red-400 hover:bg-red-500/10 transition-colors"
                >
                  Remove
                </button>
              </div>
            )}
          </div>
        ))}

        {vm.filteredAgents.length === 0 && !vm.isEmpty && (
          <div className="text-center py-10">
            <HushhAgentText className="text-white/40">
              No agents with "{vm.filterStatus}" status.
            </HushhAgentText>
          </div>
        )}
      </div>

      {/* footer note */}
      <div className="px-5 pt-6">
        <p className="text-white/20 text-[10px] text-center leading-relaxed">{content.footerNote}</p>
      </div>
    </div>
  );
}
