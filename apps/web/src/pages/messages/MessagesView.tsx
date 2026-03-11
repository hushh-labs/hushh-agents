/* ── Messages View ── Conversation list ── */

import { useMessagesViewModel } from "./MessagesViewModel";
import { getEmptyContent, statusLabels, statusColors } from "./MessagesModel";
import type { Conversation, MessageFilter, ConversationStatus } from "./MessagesModel";
import HushhAgentHeading from "../../components/HushhAgentHeading";
import HushhAgentText from "../../components/HushhAgentText";
import HushhAgentCTA from "../../components/HushhAgentCTA";

const filterTabs: { label: string; value: MessageFilter }[] = [
  { label: "All", value: "all" },
  { label: "Waiting", value: "waiting" },
  { label: "Unread", value: "unread" },
];

export default function MessagesView() {
  const vm = useMessagesViewModel();
  const emptyContent = getEmptyContent();

  if (vm.loading) {
    return (
      <div className="flex items-center justify-center min-h-screen bg-gradient-to-b from-[#1a0533] to-[#0d001a]">
        <div className="animate-pulse text-white/60 text-lg">Loading messages…</div>
      </div>
    );
  }

  if (vm.isEmpty) {
    return (
      <div className="flex flex-col items-center justify-center min-h-screen bg-gradient-to-b from-[#1a0533] to-[#0d001a] px-6 text-center gap-5">
        <div className="text-5xl">💬</div>
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
        <HushhAgentHeading className="text-xl">Messages</HushhAgentHeading>
      </div>

      {/* system banner */}
      {vm.waitingOnYou > 0 && (
        <div className="mx-5 mb-3 bg-[#e6ff00]/10 border border-[#e6ff00]/20 rounded-xl px-4 py-2.5">
          <p className="text-sm text-[#e6ff00]/90 font-medium">
            {vm.waitingOnYou} request{vm.waitingOnYou > 1 ? "s" : ""} need a response from you.
          </p>
        </div>
      )}

      {/* segmented control */}
      <div className="flex gap-2 px-5 pb-4">
        {filterTabs.map(t => (
          <button
            key={t.value}
            onClick={() => vm.onSetFilter(t.value)}
            className={`text-xs font-medium px-3.5 py-1.5 rounded-full transition-colors ${
              vm.filter === t.value
                ? "bg-white/15 text-white"
                : "bg-white/5 text-white/40 hover:text-white/60"
            }`}
          >
            {t.label}
            {t.value === "unread" && vm.totalUnread > 0 && (
              <span className="ml-1.5 bg-red-500 text-white text-[9px] font-bold px-1.5 py-0.5 rounded-full">
                {vm.totalUnread}
              </span>
            )}
          </button>
        ))}
      </div>

      {/* conversation list */}
      <div className="px-5 grid grid-cols-1 sm:grid-cols-2 gap-2">
        {vm.filtered.map((c: Conversation) => (
          <button
            key={c.id}
            onClick={() => vm.onOpenThread(c.id)}
            className="w-full flex items-center gap-3.5 p-4 bg-white/5 border border-white/10 rounded-2xl text-left active:bg-white/10 transition-colors"
            aria-label={`Conversation with ${c.agentName}`}
          >
            {/* thumbnail */}
            <div className="w-12 h-12 rounded-full overflow-hidden flex-shrink-0 bg-white/10">
              {c.agentPhotoUrl ? (
                <img src={c.agentPhotoUrl} alt="" className="w-full h-full object-cover"
                  onError={(e: React.SyntheticEvent<HTMLImageElement>) => {
                    (e.target as HTMLImageElement).style.display = "none";
                  }}
                />
              ) : (
                <div className="w-full h-full flex items-center justify-center text-white/30 text-sm font-bold">
                  {c.agentName.charAt(0)}
                </div>
              )}
            </div>

            {/* content */}
            <div className="flex-1 min-w-0">
              <div className="flex items-center justify-between mb-0.5">
                <h3 className={`text-sm font-semibold truncate ${c.unread_count > 0 ? "text-white" : "text-white/80"}`}>
                  {c.agentName}
                </h3>
                <span className="text-[10px] text-white/30 flex-shrink-0 ml-2">
                  {vm.formatTime(c.last_message_at)}
                </span>
              </div>

              <p className={`text-xs truncate ${c.unread_count > 0 ? "text-white/70 font-medium" : "text-white/40"}`}>
                {c.last_message_preview || "No messages yet"}
              </p>

              <div className="flex items-center gap-2 mt-1">
                <span className={`text-[9px] font-semibold px-2 py-0.5 rounded-full uppercase tracking-wider ${statusColors[c.status as ConversationStatus] ?? "bg-white/10 text-white/40"}`}>
                  {statusLabels[c.status as ConversationStatus] ?? c.status}
                </span>
                {c.unread_count > 0 && (
                  <span className="bg-red-500 text-white text-[9px] font-bold w-5 h-5 rounded-full flex items-center justify-center">
                    {c.unread_count}
                  </span>
                )}
              </div>
            </div>
          </button>
        ))}

        {vm.filtered.length === 0 && (
          <div className="text-center py-10">
            <HushhAgentText className="text-white/40">No conversations match this filter.</HushhAgentText>
          </div>
        )}
      </div>
    </div>
  );
}
