/* ── Settings / My Profile — View ── Bug 2+10 rewrite ── */

import { useSettingsViewModel } from "./SettingsViewModel";
import { getSettingsContent } from "./SettingsModel";

/* ── Inline SVG Icons (monotone/duotone, matching nav bar style) ── */
const UserIcon = () => (
  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
);
const MailIcon = () => (
  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><rect x="2" y="4" width="20" height="16" rx="2"/><path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"/></svg>
);
const MapPinIcon = () => (
  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z"/><circle cx="12" cy="10" r="3"/></svg>
);
const PhoneIcon = () => (
  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72c.127.96.361 1.903.7 2.81a2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0 1 22 16.92Z"/></svg>
);
const TargetIcon = () => (
  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10"/><circle cx="12" cy="12" r="6"/><circle cx="12" cy="12" r="2"/></svg>
);
const ClockIcon = () => (
  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
);
const UsersIcon = () => (
  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
);
const BellIcon = () => (
  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10.3 21a1.94 1.94 0 0 0 3.4 0"/></svg>
);
const ShieldIcon = () => (
  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10Z"/></svg>
);
const DownloadIcon = () => (
  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" x2="12" y1="15" y2="3"/></svg>
);
const LogOutIcon = () => (
  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1-2 2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" x2="9" y1="12" y2="12"/></svg>
);
const TrashIcon = () => (
  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/></svg>
);
const ChevronLeftIcon = () => (
  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="m15 18-6-6 6-6"/></svg>
);
const SaveIcon = () => (
  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1-2 2h11l4 4v11a2 2 0 0 1-2 2Z"/><polyline points="17 21 17 13 7 13 7 21"/><polyline points="7 3 7 8 15 8"/></svg>
);
const MessageIcon = () => (
  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2Z"/></svg>
);

/* ── Toggle component ── */
function Toggle({ on, onToggle, label }: { on: boolean; onToggle: () => void; label: string }) {
  return (
    <button onClick={onToggle} className="flex items-center justify-between w-full py-3">
      <span className="text-sm text-stone-700">{label}</span>
      <div className={`relative w-10 h-6 rounded-full transition-colors ${on ? "bg-stone-800" : "bg-stone-300"}`}>
        <div className={`absolute top-0.5 left-0.5 w-5 h-5 rounded-full bg-white shadow transition-transform ${on ? "translate-x-4" : ""}`} />
      </div>
    </button>
  );
}

/* ── Read-only info row ── */
function InfoRow({ icon, label, value }: { icon: React.ReactNode; label: string; value: string }) {
  if (!value) return null;
  return (
    <div className="flex items-start gap-3 py-2.5">
      <span className="text-stone-500 mt-0.5">{icon}</span>
      <div className="flex-1 min-w-0">
        <p className="text-xs text-stone-400 leading-none mb-0.5">{label}</p>
        <p className="text-sm text-stone-800 truncate">{value}</p>
      </div>
    </div>
  );
}

/* ── Editable input row ── */
function EditRow({ icon, label, value, onChange, placeholder }: {
  icon: React.ReactNode; label: string; value: string;
  onChange: (v: string) => void; placeholder?: string;
}) {
  return (
    <div className="flex items-start gap-3 py-2.5">
      <span className="text-stone-500 mt-3">{icon}</span>
      <div className="flex-1">
        <label className="text-xs text-stone-400 block mb-1">{label}</label>
        <input
          type="text"
          value={value}
          onChange={e => onChange(e.target.value)}
          placeholder={placeholder}
          className="w-full border border-stone-200 rounded-lg px-3 py-2 text-sm text-stone-800 focus:outline-none focus:ring-2 focus:ring-stone-400 bg-white"
        />
      </div>
    </div>
  );
}

/* ── Chip list (read-only) ── */
function ChipList({ items, label, icon }: { items: string[]; label: string; icon: React.ReactNode }) {
  if (!items.length) return null;
  return (
    <div className="flex items-start gap-3 py-2.5">
      <span className="text-stone-500 mt-0.5">{icon}</span>
      <div className="flex-1">
        <p className="text-xs text-stone-400 mb-1">{label}</p>
        <div className="flex flex-wrap gap-1.5">
          {items.map(item => (
            <span key={item} className="px-2.5 py-1 bg-stone-100 text-stone-700 text-xs rounded-full border border-stone-200">
              {item}
            </span>
          ))}
        </div>
      </div>
    </div>
  );
}

export default function SettingsView() {
  const vm = useSettingsViewModel();
  const content = getSettingsContent();

  if (vm.loading) {
    return (
      <div className="min-h-screen bg-stone-50 flex items-center justify-center">
        <div className="animate-spin w-8 h-8 border-2 border-stone-300 border-t-stone-800 rounded-full" />
      </div>
    );
  }

  const { profile } = vm.data;
  const initials = profile.fullName
    ? profile.fullName.split(" ").map(w => w[0]).join("").toUpperCase().slice(0, 2)
    : "?";

  return (
    <div className="min-h-screen bg-stone-50 pb-32">
      {/* ── Top Bar ── */}
      <div className="sticky top-0 z-20 bg-white/90 backdrop-blur-sm border-b border-stone-200">
        <div className="flex items-center justify-between px-4 py-3 max-w-lg mx-auto">
          <button onClick={vm.onBack} className="p-1 -ml-1 text-stone-600 hover:text-stone-900">
            <ChevronLeftIcon />
          </button>
          <h1 className="text-base font-semibold text-stone-900">{content.title}</h1>
          {vm.dirty ? (
            <button
              onClick={vm.onSave}
              disabled={vm.saving}
              className="flex items-center gap-1 px-3 py-1.5 bg-stone-900 text-white text-xs font-medium rounded-lg disabled:opacity-50"
            >
              <SaveIcon /> {vm.saving ? "Saving…" : "Save"}
            </button>
          ) : (
            <div className="w-16" />
          )}
        </div>
      </div>

      <div className="max-w-lg mx-auto px-4 py-6 space-y-6">
        {/* ── Status messages ── */}
        {vm.error && (
          <div className="bg-red-50 border border-red-200 text-red-700 text-sm px-4 py-2.5 rounded-lg">{vm.error}</div>
        )}
        {vm.successMsg && (
          <div className="bg-emerald-50 border border-emerald-200 text-emerald-700 text-sm px-4 py-2.5 rounded-lg">{vm.successMsg}</div>
        )}

        {/* ── Avatar + Name ── */}
        <div className="flex items-center gap-4">
          <div className="w-16 h-16 rounded-full bg-stone-200 flex items-center justify-center text-stone-600 text-xl font-semibold overflow-hidden flex-shrink-0">
            {profile.avatarUrl
              ? <img src={profile.avatarUrl} alt="" className="w-full h-full object-cover" />
              : initials}
          </div>
          <div className="flex-1 min-w-0">
            <h2 className="text-lg font-semibold text-stone-900 truncate">{profile.fullName || "Your Name"}</h2>
            <p className="text-sm text-stone-500 truncate">{profile.email}</p>
          </div>
        </div>

        {/* ── Section: Profile Details (editable) ── */}
        <section className="bg-white rounded-xl border border-stone-200 px-4 divide-y divide-stone-100">
          <h3 className="text-xs font-semibold text-stone-500 uppercase tracking-wide py-3">Profile</h3>
          <EditRow
            icon={<UserIcon />}
            label="Full Name"
            value={profile.fullName}
            onChange={v => vm.updateProfile("fullName", v)}
            placeholder="Enter your name"
          />
          <InfoRow icon={<MailIcon />} label="Email" value={profile.email} />
          <EditRow
            icon={<MapPinIcon />}
            label="ZIP Code"
            value={profile.zip}
            onChange={v => vm.updateProfile("zip", v)}
            placeholder="e.g. 94105"
          />
          <EditRow
            icon={<PhoneIcon />}
            label="Preferred Contact"
            value={profile.contactPref}
            onChange={v => vm.updateProfile("contactPref", v)}
            placeholder="email / chat / call"
          />
        </section>

        {/* ── Section: Goals & Preferences (from onboarding) ── */}
        {(vm.data.goals.length > 0 || vm.data.primaryGoal || vm.data.timeline) && (
          <section className="bg-white rounded-xl border border-stone-200 px-4 divide-y divide-stone-100">
            <h3 className="text-xs font-semibold text-stone-500 uppercase tracking-wide py-3">Goals & Preferences</h3>
            <ChipList items={vm.data.goals} label="Selected Goals" icon={<TargetIcon />} />
            <InfoRow icon={<TargetIcon />} label="Primary Goal" value={vm.data.primaryGoal} />
            <InfoRow icon={<ClockIcon />} label="Timeline" value={vm.data.timeline} />
            <InfoRow icon={<MessageIcon />} label="Communication Style" value={vm.data.communicationStyle} />
          </section>
        )}

        {/* ── Section: Location & Coverage (from onboarding) ── */}
        {(vm.data.connectPrefs.length > 0 || vm.data.coverageTimeline || vm.data.householdSize) && (
          <section className="bg-white rounded-xl border border-stone-200 px-4 divide-y divide-stone-100">
            <h3 className="text-xs font-semibold text-stone-500 uppercase tracking-wide py-3">Coverage Details</h3>
            <ChipList items={vm.data.connectPrefs} label="Connection Preferences" icon={<PhoneIcon />} />
            <InfoRow icon={<ClockIcon />} label="Coverage Timeline" value={vm.data.coverageTimeline} />
            <InfoRow icon={<ShieldIcon />} label="Currently Insured" value={vm.data.insuredStatus} />
            <InfoRow icon={<UsersIcon />} label="Household Size" value={vm.data.householdSize} />
          </section>
        )}

        {/* ── Section: Notifications ── */}
        <section className="bg-white rounded-xl border border-stone-200 px-4 divide-y divide-stone-100">
          <h3 className="text-xs font-semibold text-stone-500 uppercase tracking-wide py-3">Notifications</h3>
          <div className="flex items-center gap-3">
            <span className="text-stone-500"><BellIcon /></span>
            <div className="flex-1">
              <Toggle on={vm.data.notificationEmail} onToggle={vm.toggleNotifEmail} label="Email alerts" />
            </div>
          </div>
          <div className="flex items-center gap-3">
            <span className="text-stone-500"><BellIcon /></span>
            <div className="flex-1">
              <Toggle on={vm.data.notificationPush} onToggle={vm.toggleNotifPush} label="Push notifications" />
            </div>
          </div>
        </section>

        {/* ── Section: Privacy & Data ── */}
        <section className="bg-white rounded-xl border border-stone-200 px-4 divide-y divide-stone-100">
          <h3 className="text-xs font-semibold text-stone-500 uppercase tracking-wide py-3">Privacy & Data</h3>
          <div className="flex items-center gap-3">
            <span className="text-stone-500"><ShieldIcon /></span>
            <div className="flex-1">
              <Toggle on={vm.data.dataSharing} onToggle={vm.toggleDataSharing} label="Data sharing for better matches" />
            </div>
          </div>
          <button
            onClick={vm.onExportData}
            className="flex items-center gap-3 w-full py-3 text-left"
          >
            <span className="text-stone-500"><DownloadIcon /></span>
            <span className="text-sm text-stone-700 font-medium">{content.exportLabel}</span>
          </button>
          {vm.exportRequested && (
            <p className="text-xs text-emerald-600 py-2 pl-8">Export downloaded!</p>
          )}
        </section>

        {/* ── Section: Account Actions ── */}
        <section className="bg-white rounded-xl border border-stone-200 px-4 divide-y divide-stone-100">
          <button
            onClick={vm.onSignOut}
            className="flex items-center gap-3 w-full py-3.5 text-left"
          >
            <span className="text-stone-500"><LogOutIcon /></span>
            <span className="text-sm text-stone-700 font-medium">{content.signOutLabel}</span>
          </button>
          <button
            onClick={vm.onToggleDeleteConfirm}
            className="flex items-center gap-3 w-full py-3.5 text-left"
          >
            <span className="text-red-500"><TrashIcon /></span>
            <span className="text-sm text-red-600 font-medium">{content.deleteLabel}</span>
          </button>
        </section>

        {/* ── Delete Confirm Dialog ── */}
        {vm.deleteConfirmOpen && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-6">
            <div className="bg-white rounded-2xl p-6 max-w-sm w-full shadow-xl">
              <h3 className="text-lg font-semibold text-stone-900 mb-2">Delete account?</h3>
              <p className="text-sm text-stone-500 mb-6">
                This will permanently remove your profile, saved agents, conversations, and all data. This action cannot be undone.
              </p>
              <div className="flex gap-3">
                <button
                  onClick={vm.onToggleDeleteConfirm}
                  className="flex-1 py-2.5 text-sm font-medium text-stone-700 bg-stone-100 rounded-lg hover:bg-stone-200"
                >
                  Cancel
                </button>
                <button
                  onClick={() => { vm.onDeleteAccount(); vm.onToggleDeleteConfirm(); }}
                  className="flex-1 py-2.5 text-sm font-medium text-white bg-red-600 rounded-lg hover:bg-red-700"
                >
                  Delete
                </button>
              </div>
            </div>
          </div>
        )}

        {/* ── Footer ── */}
        <div className="text-center pt-4">
          <p className="text-xs text-stone-400">
            <a href="/terms" className="hover:underline">Terms of Service</a>
            {" · "}
            <a href="/privacy" className="hover:underline">Privacy Policy</a>
            {" · "}
            <a href="mailto:support@hushh.ai" className="hover:underline">Contact support</a>
          </p>
        </div>
      </div>
    </div>
  );
}
