import HushhAgentHeading from "../../../components/HushhAgentHeading";
import HushhAgentText from "../../../components/HushhAgentText";
import HushhAgentCTA from "../../../components/HushhAgentCTA";
import HushhAgentFooter from "../../../components/HushhAgentFooter";
import { useNotificationsViewModel } from "./NotificationsViewModel";

/** Duo-tone filled SVG icons */
function ReplyIcon({ className = "w-6 h-6" }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="none">
      <path d="M21 11.5a8.38 8.38 0 01-.9 3.8 8.5 8.5 0 01-7.6 4.7 8.38 8.38 0 01-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 01-.9-3.8 8.5 8.5 0 014.7-7.6 8.38 8.38 0 013.8-.9h.5a8.48 8.48 0 018 8v.5z" fill="currentColor" fillOpacity="0.2" stroke="currentColor" strokeWidth="1.5" />
      <path d="M8 10h8M8 14h5" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
    </svg>
  );
}

function StatusIcon({ className = "w-6 h-6" }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="none">
      <circle cx="12" cy="12" r="10" fill="currentColor" fillOpacity="0.15" stroke="currentColor" strokeWidth="1.5" />
      <path d="M8 12l3 3 5-5" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

function ReminderIcon({ className = "w-6 h-6" }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="none">
      <path d="M18 8A6 6 0 006 8c0 7-3 9-3 9h18s-3-2-3-9" fill="currentColor" fillOpacity="0.2" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
      <path d="M13.73 21a2 2 0 01-3.46 0" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
    </svg>
  );
}

function BellLargeIcon() {
  return (
    <svg className="w-16 h-16 sm:w-20 sm:h-20" viewBox="0 0 24 24" fill="none">
      <path d="M18 8A6 6 0 006 8c0 7-3 9-3 9h18s-3-2-3-9" fill="currentColor" fillOpacity="0.1" stroke="currentColor" strokeWidth="1" strokeLinecap="round" strokeLinejoin="round" />
      <path d="M13.73 21a2 2 0 01-3.46 0" stroke="currentColor" strokeWidth="1" strokeLinecap="round" />
      <circle cx="18" cy="4" r="3" fill="#ff5864" />
    </svg>
  );
}

function SuccessIcon() {
  return (
    <svg className="w-16 h-16 sm:w-20 sm:h-20 text-green-400" viewBox="0 0 24 24" fill="none">
      <circle cx="12" cy="12" r="10" fill="currentColor" fillOpacity="0.15" stroke="currentColor" strokeWidth="1.5" />
      <path d="M8 12l3 3 5-5" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

const BULLET_ICONS: Record<string, React.FC<{ className?: string }>> = {
  reply: ReplyIcon,
  status: StatusIcon,
  reminder: ReminderIcon,
};

export default function NotificationsView() {
  const {
    content,
    valueBullets,
    status,
    loading,
    onEnable,
    onSkip,
    onBack,
  } = useNotificationsViewModel();

  const isSuccess = status === "granted";
  const isDenied = status === "denied" || status === "unsupported";

  return (
    <div className="bg-brand-dark text-white font-sans antialiased overflow-x-hidden min-h-screen flex flex-col">
      {/* Header */}
      <header className="fixed top-0 left-0 right-0 z-50 px-4 sm:px-6 py-3 sm:py-4 flex items-center justify-between bg-transparent">
        <button onClick={onBack} className="flex items-center justify-center w-9 h-9 sm:w-10 sm:h-10 rounded-custom hover:bg-white/10 transition-colors border border-white/10" aria-label="Go back">
          <svg className="w-4 h-4 sm:w-5 sm:h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
          </svg>
        </button>
        <span className="text-xs sm:text-sm font-medium text-white/50 tracking-widest uppercase">{content.headerStep}</span>
        <div className="w-9 h-9 sm:w-10 sm:h-10" />
      </header>

      <main className="flex-1 flex flex-col items-center justify-center pt-20 sm:pt-24 pb-10 px-4 sm:px-6">
        <div className="w-full max-w-md text-center">
          {/* Hero Icon */}
          <div className="flex justify-center mb-8">
            {isSuccess ? (
              <SuccessIcon />
            ) : (
              <div className="text-brand-primary">
                <BellLargeIcon />
              </div>
            )}
          </div>

          {/* Title */}
          <div className="mb-3">
            <HushhAgentHeading level="h2">
              {isSuccess ? "You're all set!" : content.title}
            </HushhAgentHeading>
          </div>

          {/* Support copy / Success / Error */}
          <div className="mb-8">
            {isSuccess ? (
              <HushhAgentText size="sm" muted>{content.successCopy}</HushhAgentText>
            ) : isDenied ? (
              <HushhAgentText size="sm" className="text-amber-400/80">{content.errorBlocked}</HushhAgentText>
            ) : (
              <HushhAgentText size="sm" muted>{content.supportCopy}</HushhAgentText>
            )}
          </div>

          {/* Value Bullets — only show in idle state */}
          {status === "idle" && (
            <div className="space-y-4 mb-10 text-left max-w-sm mx-auto">
              {valueBullets.map((bullet) => {
                const IconComp = BULLET_ICONS[bullet.icon] || ReplyIcon;
                return (
                  <div key={bullet.icon} className="flex items-center gap-4">
                    <div className="flex-shrink-0 w-10 h-10 rounded-custom bg-brand-primary/10 flex items-center justify-center">
                      <IconComp className="w-5 h-5 text-brand-primary" />
                    </div>
                    <span className="text-sm font-medium text-white/80">{bullet.label}</span>
                  </div>
                );
              })}
            </div>
          )}

          {/* CTA — only show if not yet decided */}
          {!isSuccess && !isDenied && (
            <>
              <HushhAgentCTA
                label={loading ? "Requesting…" : content.ctaLabel}
                onClick={onEnable}
                variant="primary"
                size="lg"
                showArrow={false}
                className={`w-full ${loading ? "opacity-80 cursor-wait" : ""}`}
              />

              <div className="mt-4">
                <button
                  onClick={onSkip}
                  disabled={loading}
                  className="text-sm text-white/40 hover:text-white/70 transition-colors underline underline-offset-4 decoration-white/20 hover:decoration-white/50"
                >
                  {content.secondaryCta}
                </button>
              </div>
            </>
          )}

          {/* Fallback note */}
          {(isDenied || status === "idle") && (
            <div className="mt-8">
              <HushhAgentText size="xs" muted className="italic">{content.fallbackNote}</HushhAgentText>
            </div>
          )}

          {/* Footer note */}
          <div className="mt-6">
            <HushhAgentText size="xs" muted className="italic">{content.footerNote}</HushhAgentText>
          </div>
        </div>
      </main>

      <HushhAgentFooter />
    </div>
  );
}
