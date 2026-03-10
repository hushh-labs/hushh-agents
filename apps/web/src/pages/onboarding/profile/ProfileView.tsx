import { useRef } from "react";
import HushhAgentHeading from "../../../components/HushhAgentHeading";
import HushhAgentText from "../../../components/HushhAgentText";
import HushhAgentCTA from "../../../components/HushhAgentCTA";
import HushhAgentFooter from "../../../components/HushhAgentFooter";
import { useProfileViewModel } from "./ProfileViewModel";

/** Duo-tone icons for contact methods */
function EmailIcon() {
  return (
    <svg className="w-4 h-4" viewBox="0 0 24 24" fill="none">
      <rect x="2" y="4" width="20" height="16" rx="3" fill="currentColor" fillOpacity="0.2" stroke="currentColor" strokeWidth="1.5" />
      <path d="M2 7l10 6 10-6" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
    </svg>
  );
}

function ChatIcon() {
  return (
    <svg className="w-4 h-4" viewBox="0 0 24 24" fill="none">
      <path d="M21 11.5a8.38 8.38 0 01-.9 3.8 8.5 8.5 0 01-7.6 4.7 8.38 8.38 0 01-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 01-.9-3.8 8.5 8.5 0 014.7-7.6 8.38 8.38 0 013.8-.9h.5a8.48 8.48 0 018 8v.5z" fill="currentColor" fillOpacity="0.2" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

function CallIcon() {
  return (
    <svg className="w-4 h-4" viewBox="0 0 24 24" fill="none">
      <path d="M22 16.92v3a2 2 0 01-2.18 2 19.79 19.79 0 01-8.63-3.07 19.5 19.5 0 01-6-6 19.79 19.79 0 01-3.07-8.67A2 2 0 014.11 2h3a2 2 0 012 1.72c.127.96.361 1.903.7 2.81a2 2 0 01-.45 2.11L8.09 9.91a16 16 0 006 6l1.27-1.27a2 2 0 012.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0122 16.92z" fill="currentColor" fillOpacity="0.2" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

function CameraIcon() {
  return (
    <svg className="w-6 h-6" viewBox="0 0 24 24" fill="none">
      <path d="M23 19a2 2 0 01-2 2H3a2 2 0 01-2-2V8a2 2 0 012-2h4l2-3h6l2 3h4a2 2 0 012 2z" fill="currentColor" fillOpacity="0.15" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
      <circle cx="12" cy="13" r="4" stroke="currentColor" strokeWidth="1.5" />
    </svg>
  );
}

const CONTACT_ICONS: Record<string, React.FC> = {
  email: EmailIcon,
  chat: ChatIcon,
  call: CallIcon,
};

export default function ProfileView() {
  const {
    content,
    roleOptions,
    contactMethods,
    form,
    errors,
    loading,
    updateField,
    onAvatarChange,
    onSkipAvatar,
    onSave,
    onBack,
  } = useProfileViewModel();

  const fileInputRef = useRef<HTMLInputElement>(null);

  const inputClass = (field: string) =>
    `w-full px-4 py-3.5 sm:py-4 bg-white/5 border rounded-custom text-white placeholder:text-white/25 focus:outline-none transition-all text-base font-medium ${
      errors[field]
        ? "border-red-500/50 focus:border-red-500 focus:ring-1 focus:ring-red-500"
        : "border-white/10 focus:border-brand-primary focus:ring-1 focus:ring-brand-primary"
    }`;

  return (
    <div className="bg-brand-dark text-white font-sans antialiased overflow-x-hidden min-h-screen flex flex-col">
      {/* Header — Step + Back */}
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

          {/* Avatar Upload */}
          <div className="flex justify-center mb-8">
            <button
              onClick={() => fileInputRef.current?.click()}
              className="relative w-20 h-20 sm:w-24 sm:h-24 rounded-full bg-white/5 border-2 border-dashed border-white/20 hover:border-brand-primary/50 transition-all flex items-center justify-center group overflow-hidden"
            >
              {form.avatarUrl ? (
                <img src={form.avatarUrl} alt="Avatar" className="w-full h-full object-cover rounded-full" />
              ) : (
                <div className="text-white/30 group-hover:text-brand-primary transition-colors">
                  <CameraIcon />
                </div>
              )}
              <div className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center rounded-full">
                <CameraIcon />
              </div>
            </button>
            <input
              ref={fileInputRef}
              type="file"
              accept="image/*"
              className="hidden"
              onChange={(e) => onAvatarChange(e.target.files?.[0] || null)}
            />
          </div>

          {/* Fields */}
          <div className="space-y-5">
            {/* First Name */}
            <div>
              <label className="block text-xs sm:text-sm font-semibold text-white/50 uppercase tracking-widest mb-2">
                {content.fields.firstName.label} <span className="text-brand-primary">*</span>
              </label>
              <input
                type="text"
                value={form.firstName}
                onChange={(e) => updateField("firstName", e.target.value)}
                placeholder={content.fields.firstName.placeholder}
                className={inputClass("firstName")}
                autoComplete="given-name"
              />
              {errors.firstName && (
                <p className="text-xs text-red-400 mt-1.5 px-1">{errors.firstName}</p>
              )}
            </div>

            {/* Last Name */}
            <div>
              <label className="block text-xs sm:text-sm font-semibold text-white/50 uppercase tracking-widest mb-2">
                {content.fields.lastName.label}
              </label>
              <input
                type="text"
                value={form.lastName}
                onChange={(e) => updateField("lastName", e.target.value)}
                placeholder={content.fields.lastName.placeholder}
                className={inputClass("lastName")}
                autoComplete="family-name"
              />
            </div>

            {/* Role / Persona */}
            <div>
              <label className="block text-xs sm:text-sm font-semibold text-white/50 uppercase tracking-widest mb-2">
                {content.fields.role.label} <span className="text-brand-primary">*</span>
              </label>
              <div className="flex flex-wrap gap-2">
                {roleOptions.map((opt) => (
                  <button
                    key={opt.value}
                    onClick={() => updateField("role", opt.value)}
                    className={`px-4 py-2.5 rounded-custom text-sm font-medium border transition-all ${
                      form.role === opt.value
                        ? "bg-brand-primary/15 border-brand-primary text-brand-primary"
                        : "bg-white/5 border-white/10 text-white/60 hover:border-white/30 hover:text-white"
                    }`}
                  >
                    {opt.label}
                  </button>
                ))}
              </div>
              {errors.role && (
                <p className="text-xs text-red-400 mt-1.5 px-1">{errors.role}</p>
              )}
            </div>

            {/* ZIP Code */}
            <div>
              <label className="block text-xs sm:text-sm font-semibold text-white/50 uppercase tracking-widest mb-2">
                {content.fields.zipCode.label} <span className="text-brand-primary">*</span>
              </label>
              <input
                type="text"
                inputMode="numeric"
                value={form.zipCode}
                onChange={(e) => updateField("zipCode", e.target.value.replace(/\D/g, "").slice(0, 5))}
                placeholder={content.fields.zipCode.placeholder}
                className={inputClass("zipCode")}
                autoComplete="postal-code"
                maxLength={5}
              />
              {errors.zipCode ? (
                <p className="text-xs text-red-400 mt-1.5 px-1">{errors.zipCode}</p>
              ) : (
                <HushhAgentText size="xs" muted className="mt-1.5 px-1">
                  {content.fields.zipCode.helper}
                </HushhAgentText>
              )}
            </div>

            {/* Preferred Contact Method */}
            <div>
              <label className="block text-xs sm:text-sm font-semibold text-white/50 uppercase tracking-widest mb-2">
                {content.fields.contactMethod.label}
              </label>
              <div className="flex gap-2 sm:gap-3">
                {contactMethods.map((method) => {
                  const IconComp = CONTACT_ICONS[method.icon] || EmailIcon;
                  return (
                    <button
                      key={method.value}
                      onClick={() => updateField("contactMethod", method.value)}
                      className={`flex-1 flex items-center justify-center gap-2 px-3 py-3 rounded-custom text-sm font-medium border transition-all ${
                        form.contactMethod === method.value
                          ? "bg-brand-primary/15 border-brand-primary text-brand-primary"
                          : "bg-white/5 border-white/10 text-white/60 hover:border-white/30 hover:text-white"
                      }`}
                    >
                      <IconComp />
                      <span>{method.label}</span>
                    </button>
                  );
                })}
              </div>
            </div>
          </div>

          {/* General Error */}
          {errors.general && (
            <div className="mt-4 text-center">
              <HushhAgentText size="xs" className="text-red-400">{errors.general}</HushhAgentText>
            </div>
          )}

          {/* Primary CTA */}
          <div className="mt-8">
            <HushhAgentCTA
              label={loading ? "Saving…" : content.ctaLabel}
              onClick={onSave}
              variant="primary"
              size="lg"
              showArrow={!loading}
              className={`w-full ${loading ? "opacity-80 cursor-wait" : ""}`}
            />
          </div>

          {/* Skip avatar */}
          {form.avatarUrl && (
            <div className="mt-4 text-center">
              <button
                onClick={onSkipAvatar}
                className="text-sm text-white/40 hover:text-white/70 transition-colors underline underline-offset-4 decoration-white/20 hover:decoration-white/50"
              >
                {content.secondaryCta}
              </button>
            </div>
          )}

          {/* Footer note */}
          <div className="mt-8 sm:mt-10 text-center">
            <HushhAgentText size="xs" muted className="italic">
              {content.footerNote}
            </HushhAgentText>
          </div>
        </div>
      </main>

      {/* Footer */}
      <HushhAgentFooter />
    </div>
  );
}
