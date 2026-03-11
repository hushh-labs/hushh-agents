/* ── Deck View ── Tinder-style swipe cards ── */

import { useDeckViewModel } from "./DeckViewModel";
import { useFiltersViewModel } from "./FiltersViewModel";
import FiltersSheet from "./FiltersSheet";
import HushhAgentHeading from "../../components/HushhAgentHeading";
import HushhAgentText from "../../components/HushhAgentText";

/* ── Inline SVG icons (duo-tone, matching onboarding screens) ── */
function FilterIcon({ className = "w-4 h-4" }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="none">
      <path d="M3 6h18M7 12h10M10 18h4" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
    </svg>
  );
}

function PassIcon({ className = "w-6 h-6" }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="none">
      <path d="M18 6L6 18M6 6l12 12" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
    </svg>
  );
}

function SaveIcon({ className = "w-6 h-6" }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="none">
      <path d="M20.84 4.61a5.5 5.5 0 00-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 00-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 000-7.78z" fill="currentColor" fillOpacity="0.15" stroke="currentColor" strokeWidth="1.5" />
    </svg>
  );
}

function InfoIcon({ className = "w-5 h-5" }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="none">
      <circle cx="12" cy="12" r="10" fill="currentColor" fillOpacity="0.1" stroke="currentColor" strokeWidth="1.5" />
      <path d="M12 16v-4M12 8h.01" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
    </svg>
  );
}

export default function DeckView() {
  const vm = useDeckViewModel();
  const filters = useFiltersViewModel(() => {
    console.log("[deck] filters applied, would reload deck");
  });

  /* ── loading state ── */
  if (vm.loading) {
    return (
      <div className="flex flex-col items-center justify-center min-h-screen px-6">
        <div className="w-12 h-12 rounded-full border-2 border-brand-primary/30 border-t-brand-primary animate-spin mb-4" />
        <HushhAgentText size="sm" muted>Loading your deck…</HushhAgentText>
      </div>
    );
  }

  /* ── error state ── */
  if (vm.error) {
    return (
      <div className="flex flex-col items-center justify-center min-h-screen px-6 text-center gap-3">
        <div className="w-14 h-14 rounded-full bg-brand-primary/10 flex items-center justify-center mb-2">
          <span className="text-2xl">⚠️</span>
        </div>
        <HushhAgentHeading level="h3">Something went wrong</HushhAgentHeading>
        <HushhAgentText size="sm" muted>{vm.error}</HushhAgentText>
        <button
          onClick={vm.onRetry}
          className="mt-4 px-6 py-2.5 bg-brand-primary text-white text-sm font-semibold rounded-custom active:scale-95 transition-transform shadow-lg shadow-brand-primary/25"
        >
          Try Again
        </button>
      </div>
    );
  }

  /* ── empty deck (swiped through all) ── */
  if (vm.deckExhausted) {
    return (
      <div className="flex flex-col items-center justify-center min-h-screen px-6 text-center gap-4">
        <div className="w-20 h-20 rounded-full bg-brand-primary/10 flex items-center justify-center mb-2">
          <span className="text-4xl">🎉</span>
        </div>
        <HushhAgentHeading level="h2">You've explored all agents!</HushhAgentHeading>
        <HushhAgentText size="sm" muted className="max-w-xs">
          Want to take another look? Tap below to shuffle and start fresh.
        </HushhAgentText>
        <button
          onClick={vm.onStartOver}
          className="mt-4 px-8 py-3 bg-brand-primary text-white text-sm font-bold rounded-custom active:scale-95 transition-transform shadow-lg shadow-brand-primary/25"
        >
          🔀 Shuffle & Discover Again
        </button>
      </div>
    );
  }

  const agent = vm.current!;
  const remaining = vm.agents.length - vm.currentIndex;

  /* ── card animation class ── */
  const animClass =
    vm.animatingDirection === "left"
      ? "animate-swipe-left"
      : vm.animatingDirection === "right"
        ? "animate-swipe-right"
        : "";

  return (
    <div className="flex flex-col min-h-screen pb-20">
      {/* ── header ── */}
      <div className="flex items-center justify-between px-4 sm:px-6 pt-6 pb-3">
        <HushhAgentHeading level="h3" className="text-xl">Discover</HushhAgentHeading>
        <div className="flex items-center gap-3">
          <button
            onClick={filters.onOpen}
            className={`flex items-center gap-1.5 text-xs font-medium px-3 py-1.5 rounded-custom border transition-all ${
              filters.hasActiveFilters
                ? "bg-brand-primary/15 border-brand-primary text-brand-primary"
                : "bg-white/5 border-white/10 text-white/40 hover:border-white/30 hover:text-white/60"
            }`}
          >
            <FilterIcon className="w-3.5 h-3.5" />
            Filters{filters.hasActiveFilters ? " ●" : ""}
          </button>
          <span className="text-xs text-white/30 font-medium">{remaining} left</span>
        </div>
      </div>

      {/* ── card stack area ── */}
      <div className="flex-1 flex items-center justify-center px-4 sm:px-6 relative">
        {/* background card (next) */}
        {vm.currentIndex + 1 < vm.agents.length && (
          <div className="absolute w-[calc(100%-56px)] max-w-sm sm:max-w-md lg:max-w-lg aspect-[3/4] rounded-custom bg-white/5 border border-white/10 scale-95 translate-y-2" />
        )}

        {/* active card */}
        <div
          key={agent.id}
          className={`relative w-full max-w-sm sm:max-w-md lg:max-w-lg aspect-[3/4] rounded-custom overflow-hidden shadow-2xl border border-white/10 ${animClass}`}
        >
          {/* photo */}
          <img
            src={agent.photoUrl}
            alt={agent.name}
            className="absolute inset-0 w-full h-full object-cover"
            onError={(e: React.SyntheticEvent<HTMLImageElement>) => {
              (e.target as HTMLImageElement).src =
                "https://via.placeholder.com/400x533?text=" + encodeURIComponent(agent.name);
            }}
          />

          {/* gradient overlay */}
          <div className="absolute inset-0 bg-gradient-to-t from-black/90 via-black/30 to-transparent" />

          {/* info */}
          <div className="absolute bottom-0 left-0 right-0 p-5 space-y-2">
            <div className="flex items-center gap-2">
              <span className="bg-brand-primary/20 text-brand-primary text-[10px] font-semibold px-2 py-0.5 rounded-custom uppercase tracking-wider">
                {agent.category}
              </span>
              {agent.rating > 0 && (
                <span className="text-yellow-400 text-xs">
                  ★ {agent.rating.toFixed(1)} ({agent.reviewCount})
                </span>
              )}
            </div>

            <h2 className="text-white text-xl font-bold leading-tight font-serif">{agent.name}</h2>

            <p className="text-white/60 text-xs leading-relaxed line-clamp-2">{agent.bio}</p>

            <div className="flex flex-wrap gap-1.5 pt-1">
              {agent.services.slice(0, 3).map((s: string) => (
                <span
                  key={s}
                  className="text-[10px] text-white/50 border border-white/20 rounded-custom px-2 py-0.5"
                >
                  {s}
                </span>
              ))}
              {agent.services.length > 3 && (
                <span className="text-[10px] text-white/30">
                  +{agent.services.length - 3} more
                </span>
              )}
            </div>

            <p className="text-white/40 text-[11px]">
              📍 {agent.city}, {agent.state}
            </p>
          </div>
        </div>
      </div>

      {/* ── action buttons ── */}
      <div className="flex items-center justify-center gap-5 pt-5 pb-4 px-5">
        {/* Pass */}
        <button
          onClick={vm.onPass}
          className="w-14 h-14 rounded-full bg-white/5 border border-white/10 flex items-center justify-center text-white/50 hover:text-white hover:border-white/30 active:scale-90 transition-all"
          aria-label="Pass"
        >
          <PassIcon />
        </button>

        {/* View profile */}
        <button
          onClick={vm.onViewProfile}
          className="w-11 h-11 rounded-full bg-white/5 border border-white/10 flex items-center justify-center text-white/40 hover:text-white hover:border-white/30 active:scale-90 transition-all"
          aria-label="View profile"
        >
          <InfoIcon />
        </button>

        {/* Save / Like */}
        <button
          onClick={vm.onSave}
          className="w-14 h-14 rounded-full bg-brand-primary flex items-center justify-center text-white active:scale-90 transition-all shadow-lg shadow-brand-primary/30"
          aria-label="Save"
        >
          <SaveIcon />
        </button>
      </div>

      {/* ── filters sheet ── */}
      <FiltersSheet vm={filters} />

      {/* ── inline keyframes ── */}
      <style>{`
        @keyframes swipeLeft {
          to { transform: translateX(-120%) rotate(-15deg); opacity: 0; }
        }
        @keyframes swipeRight {
          to { transform: translateX(120%) rotate(15deg); opacity: 0; }
        }
        .animate-swipe-left { animation: swipeLeft 0.3s ease-out forwards; }
        .animate-swipe-right { animation: swipeRight 0.3s ease-out forwards; }
      `}</style>
    </div>
  );
}
