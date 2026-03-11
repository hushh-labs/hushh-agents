import HushhAgentHeading from "../../components/HushhAgentHeading";
import HushhAgentText from "../../components/HushhAgentText";
import HushhAgentCTA from "../../components/HushhAgentCTA";
import HushhAgentFooter from "../../components/HushhAgentFooter";
import HushhAgentLogo from "../../components/HushhAgentLogo";
import { useLoginViewModel } from "./LoginViewModel";

export default function LoginView() {
  const {
    content,
    email,
    error,
    isLoading,
    buttonLabel,
    onBack,
    onEmailChange,
    onSendCode,
    onNeedHelp,
  } = useLoginViewModel();

  return (
    <div className="bg-brand-dark text-white font-sans antialiased overflow-x-hidden min-h-screen flex flex-col">
      {/* Header — Back arrow + "Sign in" center title */}
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

          {/* Title — uses brand serif heading */}
          <div className="text-center mb-3 sm:mb-4">
            <HushhAgentHeading level="h2">{content.title}</HushhAgentHeading>
          </div>

          {/* Support copy */}
          <div className="text-center mb-8 sm:mb-10">
            <HushhAgentText size="sm" muted>
              {content.supportCopy}
            </HushhAgentText>
          </div>

          {/* Email Field */}
          <div className="mb-6">
            <label className="block text-xs sm:text-sm font-semibold text-white/50 uppercase tracking-widest mb-2">
              {content.fieldLabel}
            </label>
            <input
              type="email"
              value={email}
              onChange={(e) => onEmailChange(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && !isLoading && onSendCode()}
              placeholder={content.placeholder}
              className={`w-full px-4 py-3.5 sm:py-4 bg-white/5 border rounded-custom text-white placeholder:text-white/25 focus:outline-none transition-all text-base sm:text-lg font-medium ${
                error
                  ? "border-red-500/50 focus:border-red-500 focus:ring-1 focus:ring-red-500"
                  : "border-white/10 focus:border-brand-primary focus:ring-1 focus:ring-brand-primary"
              }`}
              disabled={isLoading}
              autoFocus
              autoComplete="email"
            />
            {/* Error or Helper text */}
            {error ? (
              <p className="text-xs sm:text-sm text-red-400 mt-2 px-1">{error}</p>
            ) : (
              <HushhAgentText size="xs" muted className="mt-2 px-1">
                {content.helperText}
              </HushhAgentText>
            )}
          </div>

          {/* Primary CTA — Send code */}
          <HushhAgentCTA
            label={buttonLabel}
            onClick={onSendCode}
            variant="primary"
            size="lg"
            showArrow={!isLoading}
            className={`w-full ${isLoading ? "opacity-80 cursor-wait" : ""}`}
          />

          {/* Secondary CTA */}
          <div className="mt-6 sm:mt-8 text-center">
            <button
              onClick={onNeedHelp}
              className="text-sm text-white/40 hover:text-white/70 transition-colors underline underline-offset-4 decoration-white/20 hover:decoration-white/50"
            >
              {content.secondaryCta}
            </button>
          </div>
        </div>
      </main>

      {/* Footer */}
      <HushhAgentFooter />
    </div>
  );
}
