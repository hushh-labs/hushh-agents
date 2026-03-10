import HushhAgentHeading from "../../../components/HushhAgentHeading";
import HushhAgentText from "../../../components/HushhAgentText";
import HushhAgentCTA from "../../../components/HushhAgentCTA";
import HushhAgentFooter from "../../../components/HushhAgentFooter";
import { useGoalsViewModel } from "./GoalsViewModel";

/** Goal icons */
const GOAL_ICONS: Record<string, string> = {
  retirement: "🏖️",
  investment: "📈",
  insurance: "🛡️",
  estate: "🏠",
  tax: "📋",
  business: "💼",
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
      <header className="fixed top-0 left-0 right-0 z-50 px-4 sm:px-6 py-3 sm:py-4 flex items-center justify-between bg-transparent">
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
                    <span className="text-xl">{GOAL_ICONS[chip.icon] || "📌"}</span>
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
