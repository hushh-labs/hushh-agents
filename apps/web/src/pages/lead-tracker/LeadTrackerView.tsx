/* ── Lead / Quote Status Tracker — View ── */

import { useLeadTrackerViewModel } from "./LeadTrackerViewModel";
import { getEmptyContent, getHeaderContent, getStatusStep, statusSteps } from "./LeadTrackerModel";
import type { LeadRequest, LeadEvent } from "./LeadTrackerModel";
import HushhAgentHeading from "../../components/HushhAgentHeading";
import HushhAgentText from "../../components/HushhAgentText";
import HushhAgentCTA from "../../components/HushhAgentCTA";

export default function LeadTrackerView() {
  const vm = useLeadTrackerViewModel();
  const content = getHeaderContent();
  const emptyContent = getEmptyContent();

  if (vm.loading) {
    return (
      <div className="flex items-center justify-center min-h-screen bg-gradient-to-b from-[#1a0533] to-[#0d001a]">
        <div className="animate-pulse text-white/60 text-lg">Loading leads…</div>
      </div>
    );
  }

  if (vm.isEmpty) {
    return (
      <div className="flex flex-col items-center justify-center min-h-screen bg-gradient-to-b from-[#1a0533] to-[#0d001a] px-6 text-center gap-5">
        <div className="text-5xl">📊</div>
        <HushhAgentHeading>{emptyContent.title}</HushhAgentHeading>
        <HushhAgentText className="text-white/50">{emptyContent.copy}</HushhAgentText>
        <HushhAgentCTA label={emptyContent.ctaLabel} onClick={vm.onGoToDiscover} showArrow />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-b from-[#1a0533] to-[#0d001a] text-white pb-24">
      {/* header */}
      <div className="px-5 pt-12 pb-2">
        <HushhAgentHeading className="text-xl">{content.title}</HushhAgentHeading>
        <HushhAgentText className="text-white/40 text-xs mt-1">{content.subtitle}</HushhAgentText>
      </div>

      {/* lead list */}
      <div className="px-5 pt-3 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
        {vm.leads.map((lead: LeadRequest) => {
          const step = getStatusStep(lead.status);
          const isExpanded = vm.selectedLeadId === lead.id;

          return (
            <div key={lead.id} className="bg-white/5 border border-white/10 rounded-2xl overflow-hidden">
              {/* summary row */}
              <button
                onClick={() => vm.onSelectLead(lead.id)}
                className="w-full flex items-center gap-3.5 p-4 text-left active:bg-white/10"
              >
                {lead.agentPhotoUrl ? (
                  <img src={lead.agentPhotoUrl} alt="" className="w-12 h-12 rounded-xl object-cover bg-white/10 flex-shrink-0" />
                ) : (
                  <div className="w-12 h-12 rounded-xl bg-white/10 flex items-center justify-center text-white/30 flex-shrink-0">
                    {lead.agentName?.charAt(0) ?? "?"}
                  </div>
                )}
                <div className="flex-1 min-w-0">
                  <h3 className="text-sm font-semibold truncate">{lead.agentName}</h3>
                  <p className="text-white/40 text-xs truncate">{lead.agentCategory}</p>
                  <span className={`inline-block mt-1 text-[9px] font-semibold px-2 py-0.5 rounded-full uppercase tracking-wider ${step.color}`}>
                    {step.label}
                  </span>
                </div>
                <svg className={`w-4 h-4 text-white/20 transition-transform ${isExpanded ? "rotate-90" : ""}`} fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z" clipRule="evenodd" />
                </svg>
              </button>

              {/* expanded detail */}
              {isExpanded && (
                <div className="border-t border-white/10 px-4 py-4 space-y-4">
                  {/* status timeline */}
                  <div className="flex flex-wrap gap-1.5">
                    {statusSteps.slice(0, -1).map(s => {
                      const idx = statusSteps.findIndex(ss => ss.key === lead.status);
                      const sIdx = statusSteps.findIndex(ss => ss.key === s.key);
                      const done = sIdx <= idx;
                      return (
                        <div key={s.key} className={`text-[9px] px-2 py-1 rounded-full border ${done ? s.color + " border-transparent" : "border-white/10 text-white/20"}`}>
                          {s.label}
                        </div>
                      );
                    })}
                  </div>

                  {/* message preview */}
                  {lead.message && (
                    <div className="bg-white/5 rounded-xl px-3 py-2">
                      <p className="text-[10px] text-white/30 mb-1">Your message</p>
                      <p className="text-xs text-white/60">{lead.message}</p>
                    </div>
                  )}

                  {/* event timeline */}
                  {lead.events?.length > 0 && (
                    <div className="space-y-2">
                      <p className="text-[10px] text-white/30 uppercase tracking-wider">Timeline</p>
                      {lead.events.map((ev: LeadEvent) => (
                        <div key={ev.id} className="flex items-start gap-2">
                          <div className="w-1.5 h-1.5 rounded-full bg-white/20 mt-1.5 flex-shrink-0" />
                          <div>
                            <p className="text-xs text-white/50">{ev.event_type.replace(/_/g, " ")}</p>
                            <p className="text-[10px] text-white/25">{new Date(ev.created_at).toLocaleString()}</p>
                          </div>
                        </div>
                      ))}
                    </div>
                  )}

                  {/* actions */}
                  <div className="flex gap-2">
                    {lead.status === "need_more_info" && (
                      <button onClick={() => vm.onProvideInfo(lead.id)} className="flex-1 bg-[#e6ff00]/15 text-[#e6ff00] text-xs font-medium py-2.5 rounded-xl">
                        Upload info
                      </button>
                    )}
                    <button onClick={() => vm.onOpenChat(lead.agent_id)} className="flex-1 bg-white/5 text-white/60 text-xs font-medium py-2.5 rounded-xl hover:bg-white/10">
                      Open chat
                    </button>
                    {lead.status !== "archived" && lead.status !== "closed_won" && lead.status !== "closed_lost" && (
                      <button onClick={() => vm.onArchive(lead.id)} className="flex-1 bg-white/5 text-white/40 text-xs font-medium py-2.5 rounded-xl hover:bg-white/10">
                        Archive
                      </button>
                    )}
                  </div>
                </div>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}
