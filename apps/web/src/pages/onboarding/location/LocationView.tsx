import HushhAgentHeading from "../../../components/HushhAgentHeading";
import HushhAgentText from "../../../components/HushhAgentText";
import HushhAgentCTA from "../../../components/HushhAgentCTA";
import HushhAgentFooter from "../../../components/HushhAgentFooter";
import { useLocationViewModel } from "./LocationViewModel";

/** Duo-tone icons */
function GpsIcon({ className = "w-6 h-6" }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="none">
      <circle cx="12" cy="12" r="8" fill="currentColor" fillOpacity="0.15" stroke="currentColor" strokeWidth="1.5" />
      <circle cx="12" cy="12" r="3" fill="currentColor" />
      <path d="M12 2v4M12 18v4M2 12h4M18 12h4" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
    </svg>
  );
}

function ZipIcon({ className = "w-6 h-6" }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="none">
      <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z" fill="currentColor" fillOpacity="0.15" stroke="currentColor" strokeWidth="1.5" />
      <circle cx="12" cy="10" r="3" fill="currentColor" fillOpacity="0.5" stroke="currentColor" strokeWidth="1.5" />
    </svg>
  );
}

function RemoteIcon({ className = "w-4 h-4" }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="none">
      <rect x="2" y="3" width="20" height="14" rx="2" fill="currentColor" fillOpacity="0.2" stroke="currentColor" strokeWidth="1.5" />
      <path d="M8 21h8M12 17v4" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
    </svg>
  );
}

function PersonIcon({ className = "w-4 h-4" }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="none">
      <circle cx="12" cy="7" r="4" fill="currentColor" fillOpacity="0.2" stroke="currentColor" strokeWidth="1.5" />
      <path d="M5.5 21c0-3.59 2.91-6.5 6.5-6.5s6.5 2.91 6.5 6.5" fill="currentColor" fillOpacity="0.15" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
    </svg>
  );
}

function EmailIcon({ className = "w-4 h-4" }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="none">
      <rect x="2" y="4" width="20" height="16" rx="3" fill="currentColor" fillOpacity="0.2" stroke="currentColor" strokeWidth="1.5" />
      <path d="M2 7l10 6 10-6" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
    </svg>
  );
}

function ChatIcon({ className = "w-4 h-4" }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="none">
      <path d="M21 11.5a8.38 8.38 0 01-.9 3.8 8.5 8.5 0 01-7.6 4.7 8.38 8.38 0 01-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 01-.9-3.8 8.5 8.5 0 014.7-7.6 8.38 8.38 0 013.8-.9h.5a8.48 8.48 0 018 8v.5z" fill="currentColor" fillOpacity="0.2" stroke="currentColor" strokeWidth="1.5" />
    </svg>
  );
}

function CallIcon({ className = "w-4 h-4" }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="none">
      <path d="M22 16.92v3a2 2 0 01-2.18 2 19.79 19.79 0 01-8.63-3.07 19.5 19.5 0 01-6-6 19.79 19.79 0 01-3.07-8.67A2 2 0 014.11 2h3a2 2 0 012 1.72c.127.96.361 1.903.7 2.81a2 2 0 01-.45 2.11L8.09 9.91a16 16 0 006 6l1.27-1.27a2 2 0 012.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0122 16.92z" fill="currentColor" fillOpacity="0.2" stroke="currentColor" strokeWidth="1.5" />
    </svg>
  );
}

const COMM_ICONS: Record<string, React.FC<{ className?: string }>> = {
  remote: RemoteIcon,
  person: PersonIcon,
  email: EmailIcon,
  chat: ChatIcon,
  call: CallIcon,
};

export default function LocationView() {
  const {
    content,
    commPrefChips,
    timelineOptions,
    insuredOptions,
    householdOptions,
    form,
    loading,
    gpsError,
    gpsLoading,
    ctaLabel,
    requestGPS,
    useZip,
    toggleCommPref,
    setTimeline,
    setInsured,
    setHousehold,
    setCarrier,
    onContinue,
    onSkip,
    onBack,
  } = useLocationViewModel();

  const chipClass = (active: boolean) =>
    `flex-1 min-w-0 px-3 py-3 rounded-custom text-sm font-medium border transition-all text-center ${
      active
        ? "bg-brand-primary/15 border-brand-primary text-brand-primary"
        : "bg-white/5 border-white/10 text-white/60 hover:border-white/30 hover:text-white"
    }`;

  return (
    <div className="bg-brand-dark text-white font-sans antialiased overflow-x-hidden min-h-screen flex flex-col">
      {/* Header */}
      <header className="fixed top-0 left-0 right-0 z-50 px-4 sm:px-6 py-3 sm:py-4 flex items-center justify-between bg-brand-dark/95 backdrop-blur-md border-b border-white/5">
        <button onClick={onBack} className="flex items-center justify-center w-9 h-9 sm:w-10 sm:h-10 rounded-custom hover:bg-white/10 transition-colors border border-white/10" aria-label="Go back">
          <svg className="w-4 h-4 sm:w-5 sm:h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
          </svg>
        </button>
        <span className="text-xs sm:text-sm font-medium text-white/50 tracking-widest uppercase">{content.headerStep}</span>
        <div className="w-9 h-9 sm:w-10 sm:h-10" />
      </header>

      <main className="flex-1 flex flex-col items-center pt-20 sm:pt-24 pb-10 px-4 sm:px-6">
        <div className="w-full max-w-lg">
          <div className="text-center mb-2 sm:mb-3">
            <HushhAgentHeading level="h2">{content.title}</HushhAgentHeading>
          </div>
          <div className="text-center mb-8 sm:mb-10">
            <HushhAgentText size="sm" muted>{content.supportCopy}</HushhAgentText>
          </div>

          {/* Location Cards */}
          <div className="grid grid-cols-2 gap-3 mb-8">
            {/* GPS Card */}
            <button
              onClick={requestGPS}
              disabled={gpsLoading}
              className={`flex flex-col items-center gap-3 p-5 rounded-custom border-2 transition-all ${
                form.locationSource === "gps"
                  ? "bg-brand-primary/10 border-brand-primary"
                  : "bg-white/5 border-white/10 hover:border-white/30"
              }`}
            >
              <GpsIcon className={`w-8 h-8 ${form.locationSource === "gps" ? "text-brand-primary" : "text-white/40"}`} />
              <span className="text-sm font-medium text-center">{content.locationCards.gps.label}</span>
              <span className="text-xs text-white/40">{gpsLoading ? "Locating…" : content.locationCards.gps.sublabel}</span>
            </button>

            {/* ZIP Card */}
            <button
              onClick={useZip}
              className={`flex flex-col items-center gap-3 p-5 rounded-custom border-2 transition-all ${
                form.locationSource === "zip"
                  ? "bg-brand-primary/10 border-brand-primary"
                  : "bg-white/5 border-white/10 hover:border-white/30"
              }`}
            >
              <ZipIcon className={`w-8 h-8 ${form.locationSource === "zip" ? "text-brand-primary" : "text-white/40"}`} />
              <span className="text-sm font-medium text-center">
                {form.zipCode ? `Keep ZIP ${form.zipCode}` : content.locationCards.zip.label}
              </span>
              <span className="text-xs text-white/40">From your profile</span>
            </button>
          </div>

          {/* GPS Error */}
          {gpsError && (
            <div className="mb-6 p-3 bg-white/5 rounded-custom border border-white/10">
              <HushhAgentText size="xs" muted>{gpsError}</HushhAgentText>
            </div>
          )}

          {/* Permission explainer */}
          <div className="mb-8 text-center">
            <HushhAgentText size="xs" muted className="italic">{content.permissionExplainer}</HushhAgentText>
          </div>

          {/* Communication Preferences */}
          <div className="mb-6">
            <label className="block text-xs sm:text-sm font-semibold text-white/50 uppercase tracking-widest mb-3">
              {content.sections.commPrefs}
            </label>
            <div className="flex flex-wrap gap-2">
              {commPrefChips.map((chip) => {
                const active = form.commPrefs.includes(chip.value);
                const IconComp = COMM_ICONS[chip.icon];
                return (
                  <button
                    key={chip.value}
                    onClick={() => toggleCommPref(chip.value)}
                    className={`flex items-center gap-2 px-3.5 py-2.5 rounded-custom text-sm font-medium border transition-all ${
                      active
                        ? "bg-brand-primary/15 border-brand-primary text-brand-primary"
                        : "bg-white/5 border-white/10 text-white/60 hover:border-white/30 hover:text-white"
                    }`}
                  >
                    {IconComp && <IconComp className="w-4 h-4" />}
                    <span>{chip.label}</span>
                  </button>
                );
              })}
            </div>
          </div>

          {/* Timeline */}
          <div className="mb-6">
            <label className="block text-xs sm:text-sm font-semibold text-white/50 uppercase tracking-widest mb-3">
              {content.sections.timeline}
            </label>
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
              {timelineOptions.map((opt) => (
                <button key={opt.value} onClick={() => setTimeline(opt.value)} className={chipClass(form.timeline === opt.value)}>
                  {opt.label}
                </button>
              ))}
            </div>
          </div>

          {/* Insured Status */}
          <div className="mb-6">
            <label className="block text-xs sm:text-sm font-semibold text-white/50 uppercase tracking-widest mb-3">
              {content.sections.insuredStatus}
            </label>
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
              {insuredOptions.map((opt) => (
                <button key={opt.value} onClick={() => setInsured(opt.value)} className={chipClass(form.insuredStatus === opt.value)}>
                  {opt.label}
                </button>
              ))}
            </div>
          </div>

          {/* Household Size */}
          <div className="mb-6">
            <label className="block text-xs sm:text-sm font-semibold text-white/50 uppercase tracking-widest mb-3">
              {content.sections.householdSize}
            </label>
            <div className="flex flex-wrap gap-2">
              {householdOptions.map((opt) => (
                <button key={opt.value} onClick={() => setHousehold(opt.value)} className={chipClass(form.householdSize === opt.value)}>
                  {opt.label}
                </button>
              ))}
            </div>
          </div>

          {/* Current Carrier */}
          <div className="mb-8">
            <label className="block text-xs sm:text-sm font-semibold text-white/50 uppercase tracking-widest mb-2">
              {content.sections.carrier}
            </label>
            <input
              type="text"
              value={form.currentCarrier}
              onChange={(e) => setCarrier(e.target.value)}
              placeholder="e.g. State Farm, Allstate"
              className="w-full px-4 py-3.5 bg-white/5 border border-white/10 rounded-custom text-white placeholder:text-white/25 focus:outline-none focus:border-brand-primary focus:ring-1 focus:ring-brand-primary transition-all text-base font-medium"
            />
          </div>

          {/* Primary CTA */}
          <HushhAgentCTA
            label={ctaLabel}
            onClick={onContinue}
            variant="primary"
            size="lg"
            showArrow={!loading}
            className={`w-full ${loading ? "opacity-80 cursor-wait" : ""}`}
          />

          {/* Skip */}
          <div className="mt-4 text-center">
            <button onClick={onSkip} disabled={loading} className="text-sm text-white/40 hover:text-white/70 transition-colors underline underline-offset-4 decoration-white/20 hover:decoration-white/50">
              {content.secondaryCta}
            </button>
          </div>

          {/* Footer note */}
          <div className="mt-8 sm:mt-10 text-center">
            <HushhAgentText size="xs" muted className="italic">{content.footerNote}</HushhAgentText>
          </div>
        </div>
      </main>

      <HushhAgentFooter />
    </div>
  );
}
