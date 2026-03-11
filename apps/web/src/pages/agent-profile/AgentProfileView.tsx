/* ── Agent Profile View ── Redesigned to match landing/onboarding design system ── */

import { useAgentProfileViewModel } from "./AgentProfileViewModel";
import HushhAgentHeading from "../../components/HushhAgentHeading";
import HushhAgentText from "../../components/HushhAgentText";
import HushhAgentCTA from "../../components/HushhAgentCTA";
import HushhAgentFooter from "../../components/HushhAgentFooter";

/* ── Duo-tone icons (matching onboarding style) ── */
function PhoneIcon() {
  return (
    <svg className="w-5 h-5" viewBox="0 0 24 24" fill="none">
      <path d="M22 16.92v3a2 2 0 01-2.18 2 19.79 19.79 0 01-8.63-3.07 19.5 19.5 0 01-6-6 19.79 19.79 0 01-3.07-8.67A2 2 0 014.11 2h3a2 2 0 012 1.72c.127.96.361 1.903.7 2.81a2 2 0 01-.45 2.11L8.09 9.91a16 16 0 006 6l1.27-1.27a2 2 0 012.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0122 16.92z" fill="currentColor" fillOpacity="0.2" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

function GlobeIcon() {
  return (
    <svg className="w-5 h-5" viewBox="0 0 24 24" fill="none">
      <circle cx="12" cy="12" r="10" fill="currentColor" fillOpacity="0.15" stroke="currentColor" strokeWidth="1.5" />
      <path d="M2 12h20M12 2a15.3 15.3 0 014 10 15.3 15.3 0 01-4 10 15.3 15.3 0 01-4-10 15.3 15.3 0 014-10z" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

function ClockIcon() {
  return (
    <svg className="w-5 h-5" viewBox="0 0 24 24" fill="none">
      <circle cx="12" cy="12" r="10" fill="currentColor" fillOpacity="0.15" stroke="currentColor" strokeWidth="1.5" />
      <path d="M12 6v6l4 2" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

function BuildingIcon() {
  return (
    <svg className="w-5 h-5" viewBox="0 0 24 24" fill="none">
      <rect x="3" y="3" width="18" height="18" rx="2" fill="currentColor" fillOpacity="0.15" stroke="currentColor" strokeWidth="1.5" />
      <path d="M9 21V9h6v12M9 9V3h6v6" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

function StarIcon() {
  return (
    <svg className="w-4 h-4" viewBox="0 0 24 24" fill="none">
      <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" fill="currentColor" fillOpacity="0.3" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

function LocationIcon() {
  return (
    <svg className="w-4 h-4" viewBox="0 0 24 24" fill="none">
      <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z" fill="currentColor" fillOpacity="0.15" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
      <circle cx="12" cy="10" r="3" stroke="currentColor" strokeWidth="1.5" />
    </svg>
  );
}

function MessageIcon() {
  return (
    <svg className="w-5 h-5" viewBox="0 0 24 24" fill="none">
      <path d="M21 11.5a8.38 8.38 0 01-.9 3.8 8.5 8.5 0 01-7.6 4.7 8.38 8.38 0 01-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 01-.9-3.8 8.5 8.5 0 014.7-7.6 8.38 8.38 0 013.8-.9h.5a8.48 8.48 0 018 8v.5z" fill="currentColor" fillOpacity="0.2" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

function UserIcon() {
  return (
    <svg className="w-5 h-5" viewBox="0 0 24 24" fill="none">
      <path d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2" fill="currentColor" fillOpacity="0.15" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
      <circle cx="12" cy="7" r="4" fill="currentColor" fillOpacity="0.15" stroke="currentColor" strokeWidth="1.5" />
    </svg>
  );
}

export default function AgentProfileView() {
  const vm = useAgentProfileViewModel();

  /* ── loading ── */
  if (vm.loading) {
    return (
      <div className="flex items-center justify-center min-h-screen bg-brand-dark">
        <div className="flex flex-col items-center gap-3">
          <div className="w-8 h-8 border-2 border-brand-primary/30 border-t-brand-primary rounded-full animate-spin" />
          <HushhAgentText size="sm" muted>Loading agent…</HushhAgentText>
        </div>
      </div>
    );
  }

  /* ── error / not found ── */
  if (vm.error || !vm.agent) {
    return (
      <div className="flex flex-col items-center justify-center min-h-screen bg-brand-dark px-6 text-center gap-5">
        <div className="w-16 h-16 rounded-full bg-white/5 border border-white/10 flex items-center justify-center text-white/30 text-2xl">?</div>
        <HushhAgentHeading level="h2">Agent not found</HushhAgentHeading>
        <HushhAgentText size="sm" muted>{vm.error ?? "No data available."}</HushhAgentText>
        <button
          onClick={vm.onBack}
          className="text-sm text-brand-primary hover:text-brand-primary/80 transition-colors underline underline-offset-4 decoration-brand-primary/30 hover:decoration-brand-primary/60"
        >
          ← Back to deck
        </button>
      </div>
    );
  }

  const a = vm.agent;

  return (
    <div className="bg-brand-dark text-white font-sans antialiased overflow-x-hidden min-h-screen flex flex-col">
      {/* ── Fixed Header ── */}
      <header className="fixed top-0 left-0 right-0 z-50 px-4 sm:px-6 py-3 sm:py-4 flex items-center justify-between bg-brand-dark/95 backdrop-blur-md border-b border-white/5">
        <button
          onClick={vm.onBack}
          className="flex items-center justify-center w-9 h-9 sm:w-10 sm:h-10 rounded-custom hover:bg-white/10 transition-colors border border-white/10"
          aria-label="Go back"
        >
          <svg className="w-4 h-4 sm:w-5 sm:h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
          </svg>
        </button>
        <span className="text-xs sm:text-sm font-medium text-white/50 tracking-widest uppercase">
          Agent Profile
        </span>
        <button
          onClick={vm.onSave}
          className={`flex items-center justify-center w-9 h-9 sm:w-10 sm:h-10 rounded-custom transition-colors border ${
            vm.saved
              ? "border-brand-primary/30 bg-brand-primary/10 text-brand-primary"
              : "border-white/10 text-white/50 hover:bg-white/10 hover:text-white"
          }`}
          aria-label={vm.saved ? "Saved" : "Save agent"}
        >
          <svg className="w-4 h-4 sm:w-5 sm:h-5" viewBox="0 0 24 24" fill={vm.saved ? "currentColor" : "none"} stroke="currentColor" strokeWidth="1.5">
            <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
        </button>
      </header>

      {/* ── Main Content ── */}
      <main className="flex-1 flex flex-col items-center pt-16 sm:pt-20 pb-10">
        <div className="w-full max-w-lg">
          {/* ── Hero Image ── */}
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
            {/* Gradient overlay */}
            <div className="absolute inset-0 bg-gradient-to-t from-brand-dark via-brand-dark/40 to-transparent" />

            {/* Floating badges */}
            <div className="absolute bottom-4 left-4 sm:left-5 flex flex-wrap items-center gap-2">
              <span className="inline-flex items-center gap-1.5 bg-white/10 backdrop-blur-md px-3 py-1.5 rounded-full border border-white/20 text-[10px] sm:text-xs font-semibold text-brand-primary uppercase tracking-wider">
                {a.category}
              </span>
              {a.certified && (
                <span className="inline-flex items-center gap-1.5 bg-white/10 backdrop-blur-md px-3 py-1.5 rounded-full border border-white/20 text-[10px] sm:text-xs font-semibold text-blue-300 uppercase tracking-wider">
                  ✓ Certified
                </span>
              )}
              {a.locallyOwned && (
                <span className="inline-flex items-center gap-1.5 bg-white/10 backdrop-blur-md px-3 py-1.5 rounded-full border border-white/20 text-[10px] sm:text-xs font-semibold text-green-300 uppercase tracking-wider">
                  Local
                </span>
              )}
            </div>
          </div>

          {/* ── Content Area ── */}
          <div className="px-4 sm:px-6 space-y-6 sm:space-y-8 -mt-2">

            {/* Name + Rating + Address */}
            <div className="space-y-2">
              <HushhAgentHeading level="h2">{a.name}</HushhAgentHeading>

              {a.rating > 0 && (
                <div className="flex items-center gap-2">
                  <div className="flex items-center gap-1 text-brand-primary">
                    <StarIcon />
                    <span className="text-sm font-semibold">{a.rating.toFixed(1)}</span>
                  </div>
                  <span className="text-white/40 text-sm">·</span>
                  <span className="text-white/50 text-sm">{a.reviewCount} reviews</span>
                </div>
              )}

              {a.address && (
                <div className="flex items-center gap-1.5 text-white/40">
                  <LocationIcon />
                  <HushhAgentText size="sm" muted>{a.address}</HushhAgentText>
                </div>
              )}
            </div>

            {/* About */}
            <section>
              <label className="block text-xs sm:text-sm font-semibold text-white/50 uppercase tracking-widest mb-2 sm:mb-3">
                About
              </label>
              <HushhAgentText size="sm" className="text-white/70 leading-relaxed">{a.bio}</HushhAgentText>
            </section>

            {/* Representative */}
            {a.representative && (
              <section className="bg-white/5 border border-white/10 rounded-custom p-4 sm:p-5">
                <div className="flex items-start gap-3">
                  <div className="w-10 h-10 sm:w-12 sm:h-12 rounded-full bg-white/10 border border-white/15 flex items-center justify-center text-white/40 flex-shrink-0">
                    <UserIcon />
                  </div>
                  <div className="flex-1 min-w-0">
                    <label className="block text-[10px] sm:text-xs font-semibold text-white/40 uppercase tracking-widest mb-1">
                      Your Agent
                    </label>
                    <p className="text-sm sm:text-base font-semibold text-white">{a.representative.name}</p>
                    <p className="text-xs text-white/40 mt-0.5">{a.representative.role}</p>
                    {a.representative.bio && (
                      <HushhAgentText size="xs" muted className="mt-2">{a.representative.bio}</HushhAgentText>
                    )}
                  </div>
                </div>
              </section>
            )}

            {/* Services */}
            {a.services.length > 0 && (
              <section>
                <label className="block text-xs sm:text-sm font-semibold text-white/50 uppercase tracking-widest mb-2 sm:mb-3">
                  Services
                </label>
                <div className="flex flex-wrap gap-2">
                  {a.services.map((s: string) => (
                    <span
                      key={s}
                      className="px-3.5 py-2 rounded-custom text-xs sm:text-sm font-medium bg-white/5 border border-white/10 text-white/60 hover:border-white/25 hover:text-white/80 transition-colors"
                    >
                      {s}
                    </span>
                  ))}
                </div>
              </section>
            )}

            {/* Specialties */}
            {a.specialties && (
              <section>
                <label className="block text-xs sm:text-sm font-semibold text-white/50 uppercase tracking-widest mb-2 sm:mb-3">
                  Specialties
                </label>
                <HushhAgentText size="sm" className="text-white/60">{a.specialties}</HushhAgentText>
              </section>
            )}

            {/* Contact Details */}
            <section className="bg-white/5 border border-white/10 rounded-custom p-4 sm:p-5 space-y-3.5">
              <label className="block text-xs sm:text-sm font-semibold text-white/50 uppercase tracking-widest">
                Contact
              </label>

              {a.phone && (
                <a href={`tel:${a.phone}`} className="flex items-center gap-3 text-sm text-white/70 hover:text-white transition-colors group">
                  <div className="w-9 h-9 rounded-custom bg-white/5 border border-white/10 flex items-center justify-center group-hover:border-white/25 transition-colors">
                    <PhoneIcon />
                  </div>
                  <span>{a.phone}</span>
                </a>
              )}

              {a.website && (
                <a href={a.website} target="_blank" rel="noreferrer" className="flex items-center gap-3 text-sm text-brand-primary/80 hover:text-brand-primary transition-colors group">
                  <div className="w-9 h-9 rounded-custom bg-white/5 border border-white/10 flex items-center justify-center group-hover:border-brand-primary/30 transition-colors">
                    <GlobeIcon />
                  </div>
                  <span>Visit website</span>
                </a>
              )}

              {a.hours && (
                <div className="flex items-center gap-3 text-sm text-white/50">
                  <div className="w-9 h-9 rounded-custom bg-white/5 border border-white/10 flex items-center justify-center">
                    <ClockIcon />
                  </div>
                  <span>{a.hours}</span>
                </div>
              )}

              {a.yearEstablished && (
                <div className="flex items-center gap-3 text-sm text-white/50">
                  <div className="w-9 h-9 rounded-custom bg-white/5 border border-white/10 flex items-center justify-center">
                    <BuildingIcon />
                  </div>
                  <span>Established {a.yearEstablished}</span>
                </div>
              )}
            </section>

            {/* Messaging availability */}
            {a.messagingEnabled && a.messagingText && (
              <section className="bg-brand-primary/10 border border-brand-primary/20 rounded-custom p-4 sm:p-5">
                <div className="flex items-start gap-3">
                  <div className="w-9 h-9 rounded-custom bg-brand-primary/15 border border-brand-primary/25 flex items-center justify-center text-brand-primary flex-shrink-0">
                    <MessageIcon />
                  </div>
                  <div>
                    <HushhAgentText size="sm" className="text-brand-primary/90">{a.messagingText}</HushhAgentText>
                    {a.responseTime && (
                      <HushhAgentText size="xs" muted className="mt-1">⏱ {a.responseTime}</HushhAgentText>
                    )}
                  </div>
                </div>
              </section>
            )}

            {/* ── Action Bar ── */}
            <div className="pt-2 pb-4 space-y-4">
              {/* Primary CTA */}
              <HushhAgentCTA
                label={vm.connectRequested ? "✓ Request Sent" : "Request Quote"}
                onClick={vm.onConnect}
                variant="primary"
                size="lg"
                showArrow={!vm.connectRequested}
                className={`w-full ${vm.connectRequested ? "opacity-60 pointer-events-none" : ""}`}
              />

              {/* Secondary actions */}
              <div className="flex gap-3">
                <button
                  onClick={vm.onSave}
                  className={`flex-1 flex items-center justify-center gap-2 py-3 sm:py-3.5 rounded-custom text-sm font-medium transition-all border ${
                    vm.saved
                      ? "bg-brand-primary/15 border-brand-primary text-brand-primary pointer-events-none"
                      : "bg-white/5 border-white/10 text-white/60 hover:border-white/30 hover:text-white"
                  }`}
                >
                  <svg className="w-4 h-4" viewBox="0 0 24 24" fill={vm.saved ? "currentColor" : "none"} stroke="currentColor" strokeWidth="1.5">
                    <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" strokeLinecap="round" strokeLinejoin="round" />
                  </svg>
                  {vm.saved ? "Saved" : "Save"}
                </button>

                <button
                  onClick={vm.onReport}
                  className={`px-5 py-3 sm:py-3.5 rounded-custom text-sm font-medium transition-all border ${
                    vm.reported
                      ? "border-red-500/30 text-red-400/50 pointer-events-none"
                      : "bg-white/5 border-white/10 text-white/40 hover:text-red-400 hover:border-red-400/30"
                  }`}
                >
                  {vm.reported ? "Reported" : "Report"}
                </button>
              </div>
            </div>
          </div>
        </div>
      </main>

      {/* ── Footer ── */}
      <HushhAgentFooter />
    </div>
  );
}
