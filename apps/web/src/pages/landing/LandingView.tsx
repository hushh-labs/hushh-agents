import HushhAgentHeader from "../../components/HushhAgentHeader";
import HushhAgentFooter from "../../components/HushhAgentFooter";
import HushhAgentCTA from "../../components/HushhAgentCTA";
import { useLandingViewModel } from "./LandingViewModel";

export default function LandingView() {
  const { agentCards, heroContent, trustChips, onContinue, onLogin } =
    useLandingViewModel();

  return (
    <div className="bg-brand-dark text-white font-sans antialiased overflow-x-hidden min-h-screen">
      {/* Header */}
      <HushhAgentHeader onLogin={onLogin} />

      {/* Hero Section */}
      <main className="relative min-h-screen flex flex-col items-center justify-center pt-24 pb-20 px-4 sm:px-6">
        {/* Background Card Stack */}
        <div aria-hidden="true" className="absolute inset-0 z-0 hero-background-container">
          <div className="card-grid">
            {agentCards.map((card) => (
              <div key={card.id} className="agent-card-mock">
                <img
                  alt=""
                  className="w-full h-full object-cover"
                  src={card.imageUrl}
                  loading="lazy"
                />
              </div>
            ))}
          </div>
          {/* Overlay */}
          <div
            className="absolute inset-0"
            style={{
              background:
                "radial-gradient(circle at 50% 50%, rgba(255, 88, 100, 0.05) 0%, rgba(10, 10, 10, 0.95) 100%)",
            }}
          />
        </div>

        {/* Hero Content */}
        <div className="relative z-10 max-w-4xl w-full text-center flex flex-col items-center">
          {/* Eyebrow */}
          <div className="mb-6 sm:mb-8 inline-flex items-center gap-2 bg-white/10 backdrop-blur-md px-4 sm:px-5 py-1.5 sm:py-2 rounded-full border border-white/20 text-xs sm:text-sm font-medium text-white/80">
            {heroContent.eyebrow}
          </div>

          {/* Headline */}
          <h2 className="text-3xl sm:text-5xl md:text-7xl font-extrabold tracking-tight mb-4 sm:mb-6 leading-[1.1] font-serif">
            {heroContent.headline}
          </h2>

          {/* Subheadline */}
          <p className="text-base sm:text-lg md:text-xl text-white/70 max-w-2xl mb-8 sm:mb-10 leading-relaxed px-2 sm:px-0">
            {heroContent.subheadline}
          </p>

          {/* CTA */}
          <div className="flex flex-col items-center gap-4 w-full mb-8 sm:mb-12 px-4 sm:px-0">
            <HushhAgentCTA label={heroContent.ctaLabel} onClick={onContinue} />
            <button
              onClick={onLogin}
              className="text-sm text-white/50 hover:text-white transition-colors underline underline-offset-4"
            >
              {heroContent.secondaryCta}
            </button>
          </div>

          {/* Trust Chips */}
          <div className="flex flex-wrap justify-center items-center gap-2 sm:gap-3 opacity-80 px-2 sm:px-0">
            {trustChips.map((chip, i) => (
              <span
                key={chip.label}
                className="flex items-center gap-1.5 text-xs sm:text-sm text-white/60"
              >
                {chip.label}
                {i < trustChips.length - 1 && (
                  <span className="text-white/30 ml-1.5">•</span>
                )}
              </span>
            ))}
          </div>
        </div>
      </main>

      {/* Footer */}
      <HushhAgentFooter />
    </div>
  );
}
