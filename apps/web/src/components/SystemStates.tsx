/* ── System State Content Pack — Shared state components ── */

import HushhAgentHeading from "./HushhAgentHeading";
import HushhAgentText from "./HushhAgentText";
import HushhAgentCTA from "./HushhAgentCTA";

interface StateProps {
  onAction?: () => void;
  onSecondary?: () => void;
}

/* ── Loading Deck ── */
export function LoadingDeck() {
  return (
    <div className="flex flex-col items-center justify-center min-h-screen bg-gradient-to-b from-[#1a0533] to-[#0d001a] px-6 text-center gap-4">
      <div className="w-16 h-16 rounded-full border-2 border-[#e6ff00]/30 border-t-[#e6ff00] animate-spin" />
      <HushhAgentHeading className="text-base">Finding the best matches for you</HushhAgentHeading>
      <HushhAgentText className="text-white/40 text-sm">
        We're ranking nearby professionals based on your goals and location.
      </HushhAgentText>
    </div>
  );
}

/* ── Network Failure ── */
export function NetworkFailure({ onAction, onSecondary }: StateProps) {
  return (
    <div className="flex flex-col items-center justify-center min-h-screen bg-gradient-to-b from-[#1a0533] to-[#0d001a] px-6 text-center gap-4">
      <div className="text-4xl">📡</div>
      <HushhAgentHeading className="text-base">We couldn't refresh right now</HushhAgentHeading>
      <HushhAgentCTA label="Retry" onClick={onAction} size="md" />
      {onSecondary && (
        <button onClick={onSecondary} className="text-xs text-white/40 hover:text-white/60 mt-1">
          Continue with cached results
        </button>
      )}
    </div>
  );
}

/* ── Unsupported Email ── */
export function UnsupportedEmail() {
  return (
    <div className="flex flex-col items-center justify-center min-h-screen bg-gradient-to-b from-[#1a0533] to-[#0d001a] px-6 text-center gap-4">
      <div className="text-4xl">✉️</div>
      <HushhAgentHeading className="text-base">This email isn't enabled yet</HushhAgentHeading>
      <HushhAgentText className="text-white/40 text-sm">
        Use another work email or contact your admin.
      </HushhAgentText>
    </div>
  );
}

/* ── Profile Unavailable ── */
export function ProfileUnavailable({ onAction }: StateProps) {
  return (
    <div className="flex flex-col items-center justify-center min-h-screen bg-gradient-to-b from-[#1a0533] to-[#0d001a] px-6 text-center gap-4">
      <div className="text-4xl">🚫</div>
      <HushhAgentHeading className="text-base">This profile is temporarily unavailable</HushhAgentHeading>
      <HushhAgentCTA label="Back to Discover" onClick={onAction} size="md" />
    </div>
  );
}

/* ── Permission Denied (location) ── */
export function LocationDenied() {
  return (
    <div className="mx-4 mt-3 bg-yellow-500/10 border border-yellow-500/20 rounded-xl px-4 py-2.5">
      <p className="text-[11px] text-yellow-300/80 leading-relaxed">
        📍 Location access denied. We'll continue with your ZIP code instead.
      </p>
    </div>
  );
}

/* ── Permission Denied (notifications) ── */
export function NotificationsDenied() {
  return (
    <div className="mx-4 mt-3 bg-blue-500/10 border border-blue-500/20 rounded-xl px-4 py-2.5">
      <p className="text-[11px] text-blue-300/80 leading-relaxed">
        🔔 Notifications denied. You can enable alerts later in settings.
      </p>
    </div>
  );
}

/* ── No Results After Filters ── */
export function NoFilterResults({ onAction, onSecondary }: StateProps) {
  return (
    <div className="flex flex-col items-center justify-center py-20 px-6 text-center gap-4">
      <div className="text-4xl">🔎</div>
      <HushhAgentHeading className="text-base">No results for these filters</HushhAgentHeading>
      <HushhAgentCTA label="Reset filters" onClick={onAction} size="md" />
      {onSecondary && (
        <button onClick={onSecondary} className="text-xs text-white/40 hover:text-white/60 mt-1">
          Expand radius
        </button>
      )}
    </div>
  );
}

/* ── Message Blocked / Archived ── */
export function ConversationInactive({ onAction, onSecondary }: StateProps) {
  return (
    <div className="mx-4 mt-3 bg-white/5 border border-white/10 rounded-xl px-4 py-3 flex items-center justify-between">
      <p className="text-[11px] text-white/40">This conversation is no longer active.</p>
      <div className="flex gap-2 flex-shrink-0">
        {onAction && (
          <button onClick={onAction} className="text-[10px] text-[#e6ff00] font-medium">View profile</button>
        )}
        {onSecondary && (
          <button onClick={onSecondary} className="text-[10px] text-white/40">Messages</button>
        )}
      </div>
    </div>
  );
}
