/* ── Settings / My Profile — View ── */

import { useSettingsViewModel } from "./SettingsViewModel";
import { getSettingsContent } from "./SettingsModel";
import HushhAgentHeading from "../../components/HushhAgentHeading";
import HushhAgentCTA from "../../components/HushhAgentCTA";

export default function SettingsView() {
  const vm = useSettingsViewModel();
  const c = getSettingsContent();

  if (vm.loading) {
    return (
      <div className="flex items-center justify-center min-h-screen bg-gradient-to-b from-[#1a0533] to-[#0d001a]">
        <div className="animate-pulse text-white/60">Loading settings…</div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-b from-[#1a0533] to-[#0d001a] text-white pb-32">
      {/* header */}
      <div className="px-5 pt-12 pb-4">
        <HushhAgentHeading className="text-xl">{c.title}</HushhAgentHeading>
      </div>

      <div className="px-5 space-y-6">
        {/* ── Profile Card ── */}
        <section className="bg-white/5 border border-white/10 rounded-2xl p-4 space-y-3">
          <h2 className="text-xs text-white/40 uppercase tracking-wider">Profile</h2>
          <div className="flex items-center gap-4">
            <div className="w-14 h-14 rounded-full bg-white/10 flex items-center justify-center text-xl text-white/30 flex-shrink-0">
              {vm.data.profile.avatarUrl ? (
                <img src={vm.data.profile.avatarUrl} alt="" className="w-full h-full rounded-full object-cover" />
              ) : (vm.data.profile.fullName?.charAt(0) || "?")}
            </div>
            <div className="flex-1 space-y-2">
              <input value={vm.data.profile.fullName} onChange={e => vm.updateProfile("fullName", e.target.value)} placeholder="Full name" className="w-full bg-white/5 border border-white/10 rounded-xl px-3 py-2 text-sm text-white placeholder:text-white/20 focus:outline-none focus:border-[#e6ff00]/30" />
              <input value={vm.data.profile.email} disabled className="w-full bg-white/3 border border-white/5 rounded-xl px-3 py-2 text-sm text-white/40 cursor-not-allowed" />
            </div>
          </div>
          <div className="grid grid-cols-2 gap-2">
            <input value={vm.data.profile.zip} onChange={e => vm.updateProfile("zip", e.target.value)} placeholder="ZIP code" className="bg-white/5 border border-white/10 rounded-xl px-3 py-2 text-sm text-white placeholder:text-white/20 focus:outline-none focus:border-[#e6ff00]/30" />
            <select value={vm.data.profile.contactPref} onChange={e => vm.updateProfile("contactPref", e.target.value)} className="bg-white/5 border border-white/10 rounded-xl px-3 py-2 text-sm text-white focus:outline-none appearance-none">
              <option value="email">Email</option>
              <option value="phone">Phone</option>
              <option value="in_app">In-app</option>
            </select>
          </div>
        </section>

        {/* ── Notifications ── */}
        <section className="bg-white/5 border border-white/10 rounded-2xl p-4 space-y-3">
          <h2 className="text-xs text-white/40 uppercase tracking-wider">Notifications</h2>
          <label className="flex items-center justify-between">
            <span className="text-sm text-white/70">Email alerts</span>
            <input type="checkbox" checked={vm.data.notificationEmail} onChange={() => vm.updateField("notificationEmail", !vm.data.notificationEmail)} className="w-5 h-5 accent-[#e6ff00]" />
          </label>
          <label className="flex items-center justify-between">
            <span className="text-sm text-white/70">Browser push</span>
            <input type="checkbox" checked={vm.data.notificationPush} onChange={() => vm.updateField("notificationPush", !vm.data.notificationPush)} className="w-5 h-5 accent-[#e6ff00]" />
          </label>
          <div className="grid grid-cols-2 gap-2">
            <div>
              <label className="text-[10px] text-white/30 block mb-1">Quiet from</label>
              <input type="time" value={vm.data.quietHoursStart} onChange={e => vm.updateField("quietHoursStart", e.target.value)} className="w-full bg-white/5 border border-white/10 rounded-xl px-3 py-2 text-xs text-white focus:outline-none" />
            </div>
            <div>
              <label className="text-[10px] text-white/30 block mb-1">Until</label>
              <input type="time" value={vm.data.quietHoursEnd} onChange={e => vm.updateField("quietHoursEnd", e.target.value)} className="w-full bg-white/5 border border-white/10 rounded-xl px-3 py-2 text-xs text-white focus:outline-none" />
            </div>
          </div>
        </section>

        {/* ── Privacy ── */}
        <section className="bg-white/5 border border-white/10 rounded-2xl p-4 space-y-3">
          <h2 className="text-xs text-white/40 uppercase tracking-wider">Privacy & Trust</h2>
          <label className="flex items-center justify-between">
            <span className="text-sm text-white/70">Data sharing</span>
            <input type="checkbox" checked={vm.data.dataSharing} onChange={() => vm.updateField("dataSharing", !vm.data.dataSharing)} className="w-5 h-5 accent-[#e6ff00]" />
          </label>
          {vm.data.blockedAgents.length > 0 && (
            <div>
              <p className="text-xs text-white/40 mb-1">Blocked profiles</p>
              <div className="flex flex-wrap gap-2">
                {vm.data.blockedAgents.map(id => (
                  <button key={id} onClick={() => vm.onUnblock(id)} className="text-[10px] bg-white/5 border border-white/10 rounded-full px-2.5 py-1 text-white/40 hover:text-red-400">
                    {id.slice(0, 8)}… ✕
                  </button>
                ))}
              </div>
            </div>
          )}
          <button onClick={vm.onExportData} className="w-full text-left bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-xs text-white/50 hover:text-white/70">
            {vm.exportRequested ? "📦 Export queued — you'll receive an email." : `📦 ${c.exportLabel}`}
          </button>
        </section>

        {/* ── Danger Zone ── */}
        <section className="bg-red-500/5 border border-red-500/15 rounded-2xl p-4 space-y-3">
          <h2 className="text-xs text-red-400/60 uppercase tracking-wider">Danger Zone</h2>
          <button onClick={vm.onOpenDeleteConfirm} className="w-full text-left bg-red-500/10 border border-red-500/20 rounded-xl px-4 py-3 text-xs text-red-400 hover:bg-red-500/15">
            🗑 {c.deleteLabel}
          </button>
        </section>

        {/* success / error */}
        {vm.successMsg && <p className="text-center text-sm text-green-400">{vm.successMsg}</p>}
        {vm.error && <p className="text-center text-sm text-red-400">{vm.error}</p>}

        {/* save CTA */}
        {vm.dirty && (
          <div className="pt-2">
            <HushhAgentCTA label={vm.saving ? "Saving…" : c.saveLabel} onClick={vm.onSave} disabled={vm.saving} showArrow={false} />
          </div>
        )}
      </div>

      {/* ── Delete Confirmation Sheet ── */}
      {vm.deleteConfirmOpen && (
        <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/60" onClick={vm.onCancelDelete}>
          <div className="w-full max-w-md bg-[#1a0533] border-t border-red-500/20 rounded-t-3xl p-6 pb-safe text-center space-y-4" onClick={e => e.stopPropagation()}>
            <div className="text-3xl">⚠️</div>
            <HushhAgentHeading className="text-base">{c.deleteLabel}</HushhAgentHeading>
            <p className="text-xs text-white/50">{c.deleteWarning}</p>
            <button onClick={vm.onConfirmDelete} className="w-full bg-red-600 text-white text-sm font-bold py-3 rounded-xl">{c.deleteConfirmLabel}</button>
            <button onClick={vm.onCancelDelete} className="w-full text-white/40 text-sm py-2">{c.cancelLabel}</button>
          </div>
        </div>
      )}
    </div>
  );
}
