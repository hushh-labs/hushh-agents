/* ── Chat View ── Thread UI ── */

import { useChatViewModel } from "./ChatViewModel";
import { quickPrompts, getTrustBanner, getEmptyThreadContent } from "./ChatModel";
import type { ChatMessage } from "./ChatModel";
import HushhAgentText from "../../components/HushhAgentText";

const statusColors: Record<string, string> = {
  requested: "bg-yellow-500/20 text-yellow-300",
  replied: "bg-green-500/20 text-green-300",
  waiting_on_you: "bg-[#e6ff00]/20 text-[#e6ff00]",
  closed: "bg-white/10 text-white/40",
};

export default function ChatView() {
  const vm = useChatViewModel();

  if (vm.loading) {
    return (
      <div className="flex items-center justify-center min-h-screen bg-gradient-to-b from-[#1a0533] to-[#0d001a]">
        <div className="animate-pulse text-white/60 text-lg">Loading thread…</div>
      </div>
    );
  }

  return (
    <div className="flex flex-col min-h-screen bg-gradient-to-b from-[#1a0533] to-[#0d001a] text-white">
      {/* ── Header ── */}
      <div className="flex items-center gap-3 px-4 pt-12 pb-3 border-b border-white/10">
        <button onClick={vm.onBack} className="text-white/60 hover:text-white text-xl" aria-label="Back">
          ←
        </button>
        {vm.agentPhotoUrl && (
          <img src={vm.agentPhotoUrl} alt="" className="w-9 h-9 rounded-full object-cover bg-white/10" />
        )}
        <div className="flex-1 min-w-0">
          <h1 className="text-sm font-bold truncate">{vm.agentName || "Conversation"}</h1>
          {vm.status && (
            <span className={`text-[9px] font-semibold px-2 py-0.5 rounded-full uppercase tracking-wider ${statusColors[vm.status] ?? "bg-white/10 text-white/40"}`}>
              {vm.status.replace(/_/g, " ")}
            </span>
          )}
        </div>
        <div className="relative">
          <button onClick={vm.onToggleMenu} className="text-white/40 hover:text-white text-lg px-1" aria-label="Menu">⋯</button>
          {vm.menuOpen && (
            <div className="absolute right-0 top-8 bg-[#1a0533] border border-white/15 rounded-xl shadow-xl z-20 min-w-[180px] py-1">
              <button onClick={vm.onRequestCallback} className="w-full text-left px-4 py-2.5 text-sm text-white/70 hover:bg-white/5">
                Request callback
              </button>
              <button onClick={vm.onArchive} className="w-full text-left px-4 py-2.5 text-sm text-white/70 hover:bg-white/5">
                Archive conversation
              </button>
              <div className="border-t border-white/10 my-1" />
              <button onClick={vm.onReport} className="w-full text-left px-4 py-2.5 text-sm text-red-400 hover:bg-white/5">
                Block & Report
              </button>
            </div>
          )}
        </div>
      </div>

      {/* ── Trust banner ── */}
      <div className="mx-4 mt-3 bg-blue-500/10 border border-blue-500/20 rounded-xl px-4 py-2.5">
        <p className="text-[11px] text-blue-300/80 leading-relaxed">{getTrustBanner()}</p>
      </div>

      {/* ── Messages area ── */}
      <div className="flex-1 overflow-y-auto px-4 py-4 space-y-3">
        {vm.isEmpty && (
          <div className="text-center py-10">
            <HushhAgentText className="text-white/40">{getEmptyThreadContent().copy}</HushhAgentText>
          </div>
        )}

        {vm.messages.map((msg: ChatMessage) => (
          <div key={msg.id} className={`flex ${msg.sender_type === "user" ? "justify-end" : "justify-start"}`}>
            <div
              className={`max-w-[80%] px-4 py-2.5 rounded-2xl text-sm leading-relaxed ${
                msg.sender_type === "user"
                  ? "bg-[#e6ff00] text-black rounded-br-md"
                  : msg.sender_type === "system"
                    ? "bg-white/5 text-white/50 text-xs italic"
                    : "bg-white/10 text-white rounded-bl-md"
              } ${msg.sending ? "opacity-60" : ""}`}
            >
              {msg.body}
              {msg.sending && <span className="ml-2 text-[10px] opacity-50">Sending…</span>}
              {msg.failed && (
                <button
                  onClick={() => vm.onRetry(msg.id)}
                  className="block mt-1 text-[10px] text-red-400 underline"
                >
                  Message not sent. Tap to retry.
                </button>
              )}
            </div>
          </div>
        ))}

        <div ref={vm.bottomRef} />
      </div>

      {/* ── Quick prompts ── */}
      {vm.isEmpty && (
        <div className="px-4 pb-2 flex gap-2 overflow-x-auto">
          {quickPrompts.map(p => (
            <button
              key={p}
              onClick={() => vm.onQuickPrompt(p)}
              className="text-[11px] text-white/50 border border-white/15 rounded-full px-3 py-1.5 whitespace-nowrap hover:text-white/70 hover:border-white/25 transition-colors flex-shrink-0"
            >
              {p}
            </button>
          ))}
        </div>
      )}

      {/* ── Composer ── */}
      <div className="border-t border-white/10 px-4 py-3 pb-safe">
        <div className="flex items-end gap-2">
          {/* Attach file */}
          <button
            onClick={vm.onAttachFile}
            className="w-10 h-10 rounded-full bg-white/5 border border-white/15 flex items-center justify-center text-white/40 hover:text-white/60 active:scale-90 transition-transform flex-shrink-0"
            aria-label="Attach file"
          >
            📎
          </button>
          <input
            type="text"
            value={vm.draft}
            onChange={e => vm.onChangeDraft(e.target.value)}
            onKeyDown={e => e.key === "Enter" && !e.shiftKey && vm.onSend()}
            placeholder="Write a message…"
            className="flex-1 bg-white/5 border border-white/15 rounded-2xl px-4 py-2.5 text-sm text-white placeholder:text-white/30 focus:outline-none focus:border-[#e6ff00]/40"
          />
          <button
            onClick={vm.onSend}
            disabled={!vm.draft.trim() || vm.sending}
            className="w-10 h-10 rounded-full bg-[#e6ff00] flex items-center justify-center text-black disabled:opacity-30 active:scale-90 transition-transform flex-shrink-0"
            aria-label="Send"
          >
            ↑
          </button>
        </div>
      </div>
    </div>
  );
}
