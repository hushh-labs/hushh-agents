/* ── Agent Profile View ── Full profile page ── */

import { useAgentProfileViewModel } from "./AgentProfileViewModel";
import HushhAgentHeading from "../../components/HushhAgentHeading";
import HushhAgentText from "../../components/HushhAgentText";
import HushhAgentCTA from "../../components/HushhAgentCTA";

export default function AgentProfileView() {
  const vm = useAgentProfileViewModel();

  /* ── loading ── */
  if (vm.loading) {
    return (
      <div className="flex items-center justify-center min-h-screen bg-gradient-to-b from-[#1a0533] to-[#0d001a]">
        <div className="animate-pulse text-white/60 text-lg">Loading agent…</div>
      </div>
    );
  }

  /* ── error / not found ── */
  if (vm.error || !vm.agent) {
    return (
      <div className="flex flex-col items-center justify-center min-h-screen bg-gradient-to-b from-[#1a0533] to-[#0d001a] px-6 text-center gap-4">
        <HushhAgentHeading>Agent not found</HushhAgentHeading>
        <HushhAgentText className="text-white/50">{vm.error ?? "No data available."}</HushhAgentText>
        <button onClick={vm.onBack} className="text-[#e6ff00] text-sm mt-4 underline">← Back to deck</button>
      </div>
    );
  }

  const a = vm.agent;

  return (
    <div className="min-h-screen bg-gradient-to-b from-[#1a0533] to-[#0d001a] text-white pb-10">
      {/* ── back button ── */}
      <div className="px-5 pt-12 pb-2">
        <button onClick={vm.onBack} className="text-white/60 text-sm flex items-center gap-1 hover:text-white transition-colors">
          <span>←</span> Back
        </button>
      </div>

      {/* ── hero image ── */}
      <div className="relative w-full aspect-[4/3] overflow-hidden">
        <img
          src={a.photoUrl}
          alt={a.name}
          className="w-full h-full object-cover"
          onError={(e: React.SyntheticEvent<HTMLImageElement>) => {
            (e.target as HTMLImageElement).src =
              "https://via.placeholder.com/600x450?text=" + encodeURIComponent(a.name);
          }}
        />
        <div className="absolute inset-0 bg-gradient-to-t from-[#0d001a] via-transparent to-transparent" />

        {/* ── floating badges ── */}
        <div className="absolute bottom-4 left-5 flex items-center gap-2">
          <span className="bg-[#e6ff00]/20 text-[#e6ff00] text-[10px] font-semibold px-2.5 py-1 rounded-full uppercase tracking-wider backdrop-blur-sm">
            {a.category}
          </span>
          {a.certified && (
            <span className="bg-blue-500/20 text-blue-300 text-[10px] font-semibold px-2.5 py-1 rounded-full uppercase tracking-wider backdrop-blur-sm">
              ✓ Certified
            </span>
          )}
          {a.locallyOwned && (
            <span className="bg-green-500/20 text-green-300 text-[10px] font-semibold px-2.5 py-1 rounded-full uppercase tracking-wider backdrop-blur-sm">
              Local
            </span>
          )}
        </div>
      </div>

      {/* ── content ── */}
      <div className="px-5 space-y-6 -mt-2">
        {/* name + rating */}
        <div>
          <h1 className="text-2xl font-bold">{a.name}</h1>
          {a.rating > 0 && (
            <p className="text-yellow-400 text-sm mt-1">
              ★ {a.rating.toFixed(1)} · {a.reviewCount} reviews
            </p>
          )}
          <p className="text-white/40 text-sm mt-1">📍 {a.address}</p>
        </div>

        {/* bio */}
        <div>
          <h3 className="text-xs font-semibold text-white/30 uppercase tracking-wider mb-2">About</h3>
          <p className="text-white/70 text-sm leading-relaxed">{a.bio}</p>
        </div>

        {/* representative */}
        {a.representative && (
          <div className="bg-white/5 border border-white/10 rounded-2xl p-4">
            <h3 className="text-xs font-semibold text-white/30 uppercase tracking-wider mb-2">Your Agent</h3>
            <p className="text-white font-semibold">{a.representative.name}</p>
            <p className="text-white/50 text-xs">{a.representative.role}</p>
            <p className="text-white/60 text-sm mt-2">{a.representative.bio}</p>
          </div>
        )}

        {/* services */}
        {a.services.length > 0 && (
          <div>
            <h3 className="text-xs font-semibold text-white/30 uppercase tracking-wider mb-2">Services</h3>
            <div className="flex flex-wrap gap-2">
              {a.services.map((s: string) => (
                <span key={s} className="text-xs text-white/60 border border-white/15 rounded-full px-3 py-1">
                  {s}
                </span>
              ))}
            </div>
          </div>
        )}

        {/* specialties */}
        {a.specialties && (
          <div>
            <h3 className="text-xs font-semibold text-white/30 uppercase tracking-wider mb-2">Specialties</h3>
            <p className="text-white/60 text-sm">{a.specialties}</p>
          </div>
        )}

        {/* contact details */}
        <div className="bg-white/5 border border-white/10 rounded-2xl p-4 space-y-3">
          <h3 className="text-xs font-semibold text-white/30 uppercase tracking-wider mb-1">Contact</h3>

          {a.phone && (
            <a href={`tel:${a.phone}`} className="flex items-center gap-3 text-sm text-white/70 hover:text-white transition-colors">
              <span className="text-lg">📞</span> {a.phone}
            </a>
          )}

          {a.website && (
            <a href={a.website} target="_blank" rel="noreferrer" className="flex items-center gap-3 text-sm text-[#e6ff00]/80 hover:text-[#e6ff00] transition-colors">
              <span className="text-lg">🌐</span> Website
            </a>
          )}

          {a.hours && (
            <div className="flex items-start gap-3 text-sm text-white/60">
              <span className="text-lg">🕐</span>
              <span>{a.hours}</span>
            </div>
          )}

          {a.yearEstablished && (
            <div className="flex items-center gap-3 text-sm text-white/50">
              <span className="text-lg">🏢</span> Est. {a.yearEstablished}
            </div>
          )}
        </div>

        {/* messaging */}
        {a.messagingEnabled && a.messagingText && (
          <div className="bg-[#e6ff00]/10 border border-[#e6ff00]/20 rounded-2xl p-4">
            <p className="text-sm text-[#e6ff00]/80">{a.messagingText}</p>
            {a.responseTime && (
              <p className="text-xs text-white/40 mt-1">⏱ {a.responseTime}</p>
            )}
          </div>
        )}

        {/* ── action bar: Save / Connect / Report ── */}
        <div className="pt-2 pb-4 space-y-3">
          {/* primary: Request Quote / Connect */}
          <HushhAgentCTA
            label={vm.connectRequested ? "✓ Request Sent" : "Request Quote"}
            onClick={vm.onConnect}
            showArrow={!vm.connectRequested}
            className={vm.connectRequested ? "opacity-60 pointer-events-none w-full" : "w-full"}
          />

          {/* secondary row: Save + Report */}
          <div className="flex gap-3">
            <button
              onClick={vm.onSave}
              className={`flex-1 py-3 rounded-xl text-sm font-semibold transition-all border ${
                vm.saved
                  ? "bg-[#e6ff00]/10 border-[#e6ff00]/30 text-[#e6ff00] pointer-events-none"
                  : "border-white/20 text-white hover:bg-white/10"
              }`}
            >
              {vm.saved ? "★ Saved" : "★ Save"}
            </button>

            <button
              onClick={vm.onReport}
              className={`px-5 py-3 rounded-xl text-sm font-medium transition-all border ${
                vm.reported
                  ? "border-red-500/30 text-red-400/50 pointer-events-none"
                  : "border-white/10 text-white/40 hover:text-red-400 hover:border-red-400/30"
              }`}
            >
              {vm.reported ? "Reported" : "⚑ Report"}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
