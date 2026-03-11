import HushhAgentHeading from "../../components/HushhAgentHeading";
import HushhAgentText from "../../components/HushhAgentText";
import HushhAgentCTA from "../../components/HushhAgentCTA";
import HushhAgentFooter from "../../components/HushhAgentFooter";
import HushhAgentLogo from "../../components/HushhAgentLogo";
import { useVerifyViewModel } from "./VerifyViewModel";

export default function VerifyView() {
  const {
    content,
    otp,
    error,
    loading,
    success,
    resendLabel,
    canResend,
    resending,
    inputRefs,
    onDigitChange,
    onKeyDown,
    onPaste,
    onVerify,
    onResend,
    onBack,
    onChangeEmail,
  } = useVerifyViewModel();

  /* ── Success State ── */
  if (success) {
    return (
      <div className="bg-brand-dark text-white font-sans antialiased min-h-screen flex flex-col items-center justify-center px-4">
        <div className="text-center">
          {/* Success icon */}
          <div className="w-20 h-20 bg-green-500/15 border border-green-500/20 rounded-full flex items-center justify-center mx-auto mb-6">
            <svg className="w-10 h-10 text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
            </svg>
          </div>
          <HushhAgentHeading level="h3">{content.successCopy}</HushhAgentHeading>
        </div>
      </div>
    );
  }

  /* ── Main Verify View ── */
  return (
    <div className="bg-brand-dark text-white font-sans antialiased overflow-x-hidden min-h-screen flex flex-col">
      {/* Header — Back arrow + "Verify email" center title */}
      <header className="fixed top-0 left-0 right-0 z-50 px-4 sm:px-6 py-3 sm:py-4 flex items-center justify-between bg-brand-dark/95 backdrop-blur-md border-b border-white/5">
        {/* Left: Back arrow */}
        <button
          onClick={onBack}
          className="flex items-center justify-center w-9 h-9 sm:w-10 sm:h-10 rounded-custom hover:bg-white/10 transition-colors border border-white/10"
          aria-label="Go back"
        >
          <svg className="w-4 h-4 sm:w-5 sm:h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
          </svg>
        </button>

        {/* Center: Title */}
        <span className="text-sm sm:text-base font-semibold text-white tracking-tight">
          {content.headerTitle}
        </span>

        {/* Right: Blank spacer */}
        <div className="w-9 h-9 sm:w-10 sm:h-10" />
      </header>

      {/* Main Content */}
      <main className="flex-1 relative flex flex-col items-center justify-center pt-24 pb-10 px-4 sm:px-6">
        <div className="w-full max-w-md">
          {/* Logo */}
          <div className="flex justify-center mb-8 sm:mb-10">
            <HushhAgentLogo size="lg" showGlow />
          </div>

          {/* Title */}
          <div className="text-center mb-3 sm:mb-4">
            <HushhAgentHeading level="h2">{content.title}</HushhAgentHeading>
          </div>

          {/* Support copy */}
          <div className="text-center mb-8 sm:mb-10">
            <HushhAgentText size="sm" muted>
              {content.supportCopy}
            </HushhAgentText>
          </div>

          {/* OTP Input — 6 cells */}
          <div className="flex justify-center gap-2.5 sm:gap-3 mb-6" onPaste={onPaste}>
            {otp.map((digit, i) => (
              <input
                key={i}
                ref={(el) => { inputRefs.current[i] = el; }}
                type="text"
                inputMode="numeric"
                maxLength={1}
                value={digit}
                onChange={(e) => onDigitChange(i, e.target.value)}
                onKeyDown={(e) => onKeyDown(i, e)}
                className={`w-11 h-14 sm:w-14 sm:h-16 text-center text-xl sm:text-2xl font-bold bg-white/5 border rounded-custom text-white focus:outline-none transition-all ${
                  digit
                    ? "border-brand-primary"
                    : error
                      ? "border-red-500/50"
                      : "border-white/10"
                } focus:border-brand-primary focus:ring-1 focus:ring-brand-primary`}
                disabled={loading}
                autoFocus={i === 0}
              />
            ))}
          </div>

          {/* Error */}
          {error && (
            <div className="text-center mb-4">
              <HushhAgentText size="xs" className="text-red-400">
                {error}
              </HushhAgentText>
            </div>
          )}

          {/* Primary CTA */}
          <HushhAgentCTA
            label={loading ? "Verifying…" : content.ctaLabel}
            onClick={onVerify}
            variant="primary"
            size="lg"
            showArrow={!loading}
            className={`w-full ${loading ? "opacity-80 cursor-wait" : ""}`}
          />

          {/* Secondary: Resend code */}
          <div className="mt-6 sm:mt-8 text-center">
            <button
              onClick={onResend}
              disabled={!canResend || resending}
              className={`text-sm transition-colors underline underline-offset-4 ${
                canResend
                  ? "text-brand-primary hover:text-brand-primary/80 decoration-brand-primary/30"
                  : "text-white/30 cursor-default decoration-white/10"
              }`}
            >
              {resendLabel}
            </button>
          </div>

          {/* Tertiary: Change email */}
          <div className="mt-3 text-center">
            <button
              onClick={onChangeEmail}
              className="text-sm text-white/40 hover:text-white/70 transition-colors underline underline-offset-4 decoration-white/20 hover:decoration-white/50"
            >
              {content.changeEmail}
            </button>
          </div>
        </div>
      </main>

      {/* Footer */}
      <HushhAgentFooter />
    </div>
  );
}
