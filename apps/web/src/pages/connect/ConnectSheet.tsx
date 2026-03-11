/* ── Connect / Quote Request Sheet — View ── */

import { useConnectViewModel } from "./ConnectViewModel";
import { channelOptions, urgencyOptions, callbackSlots, getSheetContent } from "./ConnectModel";
import HushhAgentCTA from "../../components/HushhAgentCTA";
import HushhAgentHeading from "../../components/HushhAgentHeading";
import HushhAgentText from "../../components/HushhAgentText";
import { useRef } from "react";

interface ConnectSheetProps {
  vm: ReturnType<typeof useConnectViewModel>;
}

export default function ConnectSheet({ vm }: ConnectSheetProps) {
  const content = getSheetContent();
  const fileRef = useRef<HTMLInputElement>(null);

  if (!vm.open) return null;

  /* ── Success state ── */
  if (vm.success) {
    return (
      <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/60" onClick={vm.closeSheet}>
        <div className="w-full max-w-md bg-[#1a0533] rounded-t-3xl p-6 pb-safe text-center space-y-4" onClick={e => e.stopPropagation()}>
          <div className="text-4xl">✅</div>
          <HushhAgentHeading>{content.successTitle}</HushhAgentHeading>
          <HushhAgentText className="text-white/50">{content.successCopy}</HushhAgentText>
          <HushhAgentCTA label="Done" onClick={vm.closeSheet} />
        </div>
      </div>
    );
  }

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/60" onClick={vm.closeSheet}>
      <div
        className="w-full max-w-md bg-[#1a0533] border-t border-white/15 rounded-t-3xl overflow-y-auto max-h-[90vh] pb-safe"
        onClick={e => e.stopPropagation()}
      >
        {/* handle */}
        <div className="flex justify-center pt-3 pb-1">
          <div className="w-10 h-1 bg-white/20 rounded-full" />
        </div>

        <div className="px-5 pb-6 space-y-5">
          {/* title */}
          <HushhAgentHeading className="text-lg">
            {content.title} {vm.draft.agentName}
          </HushhAgentHeading>

          {/* message */}
          <div>
            <label className="text-xs text-white/50 mb-1 block">Your message</label>
            <textarea
              value={vm.draft.message}
              onChange={e => vm.onChangeMessage(e.target.value)}
              placeholder={content.messagePlaceholder}
              rows={3}
              className="w-full bg-white/5 border border-white/15 rounded-xl px-4 py-3 text-sm text-white placeholder:text-white/30 focus:outline-none focus:border-brand-primary/40 resize-none"
            />
          </div>

          {/* channel preference */}
          <div>
            <label className="text-xs text-white/50 mb-2 block">Preferred channel</label>
            <div className="flex gap-2">
              {channelOptions.map(ch => (
                <button
                  key={ch.value}
                  onClick={() => vm.onSetChannel(ch.value)}
                  className={`flex-1 text-xs py-2.5 rounded-xl border transition-colors ${
                    vm.draft.channelPref === ch.value
                      ? "bg-brand-primary/15 border-brand-primary/40 text-brand-primary"
                      : "bg-white/5 border-white/10 text-white/50 hover:text-white/70"
                  }`}
                >
                  {ch.label}
                </button>
              ))}
            </div>
          </div>

          {/* callback time */}
          <div>
            <label className="text-xs text-white/50 mb-2 block">Callback time preference</label>
            <div className="flex flex-wrap gap-2">
              {callbackSlots.map(slot => (
                <button
                  key={slot}
                  onClick={() => vm.onSetCallbackTime(slot)}
                  className={`text-xs px-3 py-2 rounded-xl border transition-colors ${
                    vm.draft.callbackTime === slot
                      ? "bg-white/15 border-white/30 text-white"
                      : "bg-white/5 border-white/10 text-white/40"
                  }`}
                >
                  {slot}
                </button>
              ))}
            </div>
          </div>

          {/* urgency */}
          <div>
            <label className="text-xs text-white/50 mb-2 block">Urgency</label>
            <div className="flex gap-2">
              {urgencyOptions.map(u => (
                <button
                  key={u.value}
                  onClick={() => vm.onSetUrgency(u.value)}
                  className={`flex-1 text-center py-2.5 rounded-xl border transition-colors ${
                    vm.draft.urgency === u.value
                      ? "bg-brand-primary/15 border-brand-primary/40 text-brand-primary"
                      : "bg-white/5 border-white/10 text-white/50"
                  }`}
                >
                  <div className="text-xs font-medium">{u.label}</div>
                  <div className="text-[10px] text-white/30 mt-0.5">{u.desc}</div>
                </button>
              ))}
            </div>
          </div>

          {/* file upload */}
          <div>
            <input
              ref={fileRef}
              type="file"
              className="hidden"
              onChange={e => vm.onAttachFile(e.target.files?.[0] ?? null)}
            />
            <button
              onClick={() => fileRef.current?.click()}
              className="w-full text-left bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-xs text-white/40 hover:text-white/60 transition-colors"
            >
              {vm.draft.attachmentFile
                ? `📎 ${vm.draft.attachmentFile.name}`
                : "📎 Attach a file (optional)"}
            </button>
          </div>

          {/* consent checkbox */}
          <label className="flex items-start gap-3 cursor-pointer">
            <input
              type="checkbox"
              checked={vm.draft.consentRevealContact}
              onChange={vm.onToggleConsent}
              className="mt-0.5 w-4 h-4 rounded border-white/30 bg-white/5 accent-[#e6ff00]"
            />
            <span className="text-xs text-white/60 leading-relaxed">{content.consentLabel}</span>
          </label>

          {/* multi-agent toggle */}
          <label className="flex items-start gap-3 cursor-pointer">
            <input
              type="checkbox"
              checked={vm.draft.multiAgent}
              onChange={vm.onToggleMultiAgent}
              className="mt-0.5 w-4 h-4 rounded border-white/30 bg-white/5 accent-[#e6ff00]"
            />
            <span className="text-xs text-white/60 leading-relaxed">{content.multiAgentLabel}</span>
          </label>

          {/* error */}
          {vm.error && (
            <p className="text-xs text-red-400 text-center">{vm.error}</p>
          )}

          {/* offline hint */}
          <p className="text-[10px] text-white/25 text-center">{content.offlineCopy}</p>

          {/* CTA */}
          <HushhAgentCTA
            label={vm.sending ? "Sending…" : content.ctaLabel}
            onClick={vm.onSubmit}
            disabled={vm.sending}
            showArrow
          />
        </div>
      </div>
    </div>
  );
}
