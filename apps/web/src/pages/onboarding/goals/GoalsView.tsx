import HushhAgentHeading from "../../../components/HushhAgentHeading";
import HushhAgentText from "../../../components/HushhAgentText";
import HushhAgentCTA from "../../../components/HushhAgentCTA";
import HushhAgentFooter from "../../../components/HushhAgentFooter";
import { useGoalsViewModel } from "./GoalsViewModel";

/** Duo-tone filled SVG icons for goals */
function RetirementIcon({ className = "w-6 h-6" }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="none">
      <circle cx="12" cy="12" r="10" fill="currentColor" fillOpacity="0.15" />
      <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2z" fill="currentColor" fillOpacity="0.2" />
      <path d="M15.5 11l-4-7L7 11h2v5h5v-5h1.5z" fill="currentColor" />
      <circle cx="11.5" cy="6" r="1.5" fill="currentColor" />
      <path d="M6 17h12v1.5H6z" fill="currentColor" fillOpacity="0.5" />
    </svg>
  );
}

function InvestmentIcon({ className = "w-6 h-6" }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="none">
      <rect x="2" y="3" width="20" height="18" rx="3" fill="currentColor" fillOpacity="0.15" />
      <path d="M4 18l4-5 3 3 5-7 4 4" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
      <path d="M15 7h5v5" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

function InsuranceIcon({ className = "w-6 h-6" }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="none">
      <path d="M12 2L4 5v6.09c0 5.05 3.41 9.76 8 10.91 4.59-1.15 8-5.86 8-10.91V5l-8-3z" fill="currentColor" fillOpacity="0.2" />
      <path d="M12 2L4 5v6.09c0 5.05 3.41 9.76 8 10.91 4.59-1.15 8-5.86 8-10.91V5l-8-3z" stroke="currentColor" strokeWidth="1.5" />
      <path d="M9 12l2 2 4-4" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

function EstateIcon({ className = "w-6 h-6" }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="none">
      <path d="M3 21V10l9-7 9 7v11H3z" fill="currentColor" fillOpacity="0.2" />
      <path d="M3 21V10l9-7 9 7v11" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
      <rect x="9" y="14" width="6" height="7" rx="0.5" fill="currentColor" fillOpacity="0.5" stroke="currentColor" strokeWidth="1" />
      <path d="M3 21h18" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
    </svg>
  );
}

function TaxIcon({ className = "w-6 h-6" }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="none">
      <rect x="4" y="2" width="16" height="20" rx="2" fill="currentColor" fillOpacity="0.15" />
      <rect x="4" y="2" width="16" height="20" rx="2" stroke="currentColor" strokeWidth="1.5" />
      <path d="M8 7h8M8 11h8M8 15h5" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
      <circle cx="16" cy="16" r="3" fill="currentColor" fillOpacity="0.3" stroke="currentColor" strokeWidth="1" />
      <path d="M16 14.5v3M14.5 16h3" stroke="currentColor" strokeWidth="1" strokeLinecap="round" />
    </svg>
  );
}

function BusinessIcon({ className = "w-6 h-6" }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="none">
      <rect x="2" y="7" width="20" height="14" rx="2" fill="currentColor" fillOpacity="0.2" />
      <rect x="2" y="7" width="20" height="14" rx="2" stroke="currentColor" strokeWidth="1.5" />
      <path d="M16 7V5a2 2 0 00-2-2h-4a2 2 0 00-2 2v2" stroke="currentColor" strokeWidth="1.5" />
      <path d="M2 12h20" stroke="currentColor" strokeWidth="1.5" />
      <rect x="10" y="10" width="4" height="4" rx="1" fill="currentColor" />
    </svg>
  );
}

const GOAL_ICON_COMPONENTS: Record<string, React.FC<{ className?: string }>> = {
  retirement: RetirementIcon,
  investment: InvestmentIcon,
  insurance: InsuranceIcon,
  estate: EstateIcon,
  tax: TaxIcon,
  business: BusinessIcon,
};

export default function GoalsView() {
  const {
    content,
    goalChips,
    timelineOptions,
    commStyleOptions,
    form,
    error,
    loading,
    toggleGoal,
    setPrimaryGoal,
    setTimeline,
    setCommStyle,
    onContinue,
    onNotSure,
    onBack,
  } = useGoalsViewModel();

  const hasGoals = form.selectedGoals.length > 0;

  return (
    <div className="bg-brand-dark text-white font-sans antialiased overflow-x-hidden min-h-screen flex flex-col">
      {/* Header */}
      <header className="fixed top-0 left-0 right-0 z-50 px-4 sm:px-6 py-3 sm:py-4 flex items-center justify-between bg-brand-dark/95 backdrop-blur-md border-b border-white/5">
        <button
          onClick={onBack}
          className="flex items-center justify-center w-9 h-9 sm:w-10 sm:h-10 rounded-custom hover:bg-white/10 transition-colors border border-white/10"
          aria-label="Go back"
        >
          <svg className="w-4 h-4 sm:w-5 sm:h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
          </svg>
        </button>
        <span className="text-xs sm:text-sm font-medium text-white/50 tracking-widest uppercase">
          {content.headerStep}
        </span>
        <div className="w-9 h-9 sm:w-10 sm:h-10" />
      </header>

      {/* Main Content */}
      <main className="flex-1 flex flex-col items-center pt-20 sm:pt-24 pb-10 px-4 sm:px-6">
        <div className="w-full max-w-lg">
          {/* Title */}
          <div className="text-center mb-2 sm:mb-3">
            <HushhAgentHeading level="h2">{content.title}</HushhAgentHeading>
          </div>
          <div className="text-center mb-8 sm:mb-10">
            <HushhAgentText size="sm" muted>{content.supportCopy}</HushhAgentText>
          </div>

          {/* Goal Chips */}
          <div className="mb-8">
            <label className="block text-xs sm:text-sm font-semibold text-white/50 uppercase tracking-widest mb-3">
              {content.sections.primary} <span className="text-brand-primary">*</span>
            </label>
            <div className="grid grid-cols-2 gap-2 sm:gap-3">
              {goalChips.map((chip) => {
                const selected = form.selectedGoals.includes(chip.value);
                const isPrimary = form.primaryGoal === chip.value;
                return (
                  <button
                    key={chip.value}
                    onClick={() => toggleGoal(chip.value)}
                    className={`relative flex items-center gap-3 px-4 py-3.5 rounded-custom text-sm font-medium border transition-all text-left ${
                      selected
                        ? "bg-brand-primary/15 border-brand-primary text-white"
                        : "bg-white/5 border-white/10 text-white/60 hover:border-white/30 hover:text-white"
                    }`}
                  >
                    {(() => {
                      const IconComp = GOAL_ICON_COMPONENTS[chip.icon];
                      return IconComp ? (
                        <IconComp className={`w-6 h-6 flex-shrink-0 ${selected ? "text-brand-primary" : "text-white/40"}`} />
                      ) : (
                        <span className="w-6 h-6 flex-shrink-0" />
                      );
                    })()}
                    <span className="flex-1">{chip.label}</span>
                    {selected && (
                      <svg className="w-4 h-4 text-brand-primary flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
                        <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                      </svg>
                    )}
                    {isPrimary && selected && (
                      <span className="absolute -top-2 -right-1 text-[10px] bg-brand-primary text-white px-1.5 py-0.5 rounded-full font-bold">
                        PRIMARY
                      </span>
                    )}
                  </button>
                );
              })}
            </div>

            {/* Primary selector (if multiple goals selected) */}
            {form.selectedGoals.length > 1 && (
              <div className="mt-4 p-3 bg-white/5 rounded-custom border border-white/10">
                <HushhAgentText size="xs" muted className="mb-2">
                  Tap to set primary goal:
                </HushhAgentText>
                <div className="flex flex-wrap gap-1.5">
                  {form.selectedGoals.map((g) => {
                    const chip = goalChips.find((c) => c.value === g);
                    return (
                      <button
                        key={g}
                        onClick={() => setPrimaryGoal(g)}
                        className={`px-3 py-1.5 rounded-full text-xs font-medium transition-all ${
                          form.primaryGoal === g
                            ? "bg-brand-primary text-white"
                            : "bg-white/10 text-white/60 hover:bg-white/20"
                        }`}
                      >
                        {chip?.label || g}
                      </button>
                    );
                  })}
                </div>
              </div>
            )}

            {error && (
              <p className="text-xs text-red-400 mt-2 px-1">{error}</p>
            )}
          </div>

          {/* Timeline */}
          <div className="mb-6">
            <label className="block text-xs sm:text-sm font-semibold text-white/50 uppercase tracking-widest mb-3">
              {content.sections.timeline}
            </label>
            <div className="flex gap-2 sm:gap-3">
              {timelineOptions.map((opt) => (
                <button
                  key={opt.value}
                  onClick={() => setTimeline(opt.value)}
                  className={`flex-1 px-3 py-3 rounded-custom text-sm font-medium border transition-all text-center ${
                    form.timeline === opt.value
                      ? "bg-brand-primary/15 border-brand-primary text-brand-primary"
                      : "bg-white/5 border-white/10 text-white/60 hover:border-white/30 hover:text-white"
                  }`}
                >
                  {opt.label}
                </button>
              ))}
            </div>
          </div>

          {/* Communication Style */}
          <div className="mb-6">
            <label className="block text-xs sm:text-sm font-semibold text-white/50 uppercase tracking-widest mb-3">
              {content.sections.commStyle}
            </label>
            <div className="flex flex-col sm:flex-row gap-2 sm:gap-3">
              {commStyleOptions.map((opt) => (
                <button
                  key={opt.value}
                  onClick={() => setCommStyle(opt.value)}
                  className={`flex-1 px-3 py-3 rounded-custom text-sm font-medium border transition-all text-center ${
                    form.communicationStyle === opt.value
                      ? "bg-brand-primary/15 border-brand-primary text-brand-primary"
                      : "bg-white/5 border-white/10 text-white/60 hover:border-white/30 hover:text-white"
                  }`}
                >
                  {opt.label}
                </button>
              ))}
            </div>
          </div>

          {/* Primary CTA */}
          <div className="mt-8">
            <HushhAgentCTA
              label={loading ? "Saving…" : content.ctaLabel}
              onClick={onContinue}
              variant="primary"
              size="lg"
              showArrow={!loading}
              className={`w-full ${loading ? "opacity-80 cursor-wait" : ""} ${!hasGoals ? "opacity-50" : ""}`}
            />
          </div>

          {/* Not sure yet */}
          <div className="mt-4 text-center">
            <button
              onClick={onNotSure}
              disabled={loading}
              className="text-sm text-white/40 hover:text-white/70 transition-colors underline underline-offset-4 decoration-white/20 hover:decoration-white/50"
            >
              {content.secondaryCta}
            </button>
          </div>

          {/* Footer note */}
          <div className="mt-8 sm:mt-10 text-center">
            <HushhAgentText size="xs" muted className="italic">
              {content.footerNote}
            </HushhAgentText>
          </div>
        </div>
      </main>

      <HushhAgentFooter />
    </div>
  );
}
