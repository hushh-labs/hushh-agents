/* ── App Shell — Bottom Tab Navigation ── */

import { Outlet, useLocation, useNavigate } from "react-router-dom";

/* ── Duo-tone Filled SVG Icons ── */
function DiscoverIcon({ active }: { active: boolean }) {
  return (
    <svg className="w-6 h-6" viewBox="0 0 24 24" fill="none">
      <circle cx="11" cy="11" r="7" fill="currentColor" fillOpacity={active ? 0.25 : 0.1} stroke="currentColor" strokeWidth="1.5" />
      <path d="M21 21l-4.35-4.35" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
      {/* compass needle inside */}
      <path d="M14 8l-5 3 2 5 5-3-2-5z" fill="currentColor" fillOpacity={active ? 0.6 : 0.3} />
    </svg>
  );
}

function InterestedIcon({ active }: { active: boolean }) {
  return (
    <svg className="w-6 h-6" viewBox="0 0 24 24" fill="none">
      <path
        d="M20.84 4.61a5.5 5.5 0 00-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 00-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 000-7.78z"
        fill="currentColor"
        fillOpacity={active ? 0.35 : 0.15}
        stroke="currentColor"
        strokeWidth="1.5"
      />
    </svg>
  );
}

function MessagesIcon({ active }: { active: boolean }) {
  return (
    <svg className="w-6 h-6" viewBox="0 0 24 24" fill="none">
      <path
        d="M21 11.5a8.38 8.38 0 01-.9 3.8 8.5 8.5 0 01-7.6 4.7 8.38 8.38 0 01-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 01-.9-3.8 8.5 8.5 0 014.7-7.6 8.38 8.38 0 013.8-.9h.5a8.48 8.48 0 018 8v.5z"
        fill="currentColor"
        fillOpacity={active ? 0.35 : 0.15}
        stroke="currentColor"
        strokeWidth="1.5"
      />
      {/* message dots */}
      <circle cx="9" cy="12" r="1" fill="currentColor" fillOpacity={active ? 0.8 : 0.4} />
      <circle cx="12" cy="12" r="1" fill="currentColor" fillOpacity={active ? 0.8 : 0.4} />
      <circle cx="15" cy="12" r="1" fill="currentColor" fillOpacity={active ? 0.8 : 0.4} />
    </svg>
  );
}

function LeadsIcon({ active }: { active: boolean }) {
  return (
    <svg className="w-6 h-6" viewBox="0 0 24 24" fill="none">
      {/* chart background */}
      <rect x="3" y="3" width="18" height="18" rx="3" fill="currentColor" fillOpacity={active ? 0.2 : 0.08} stroke="currentColor" strokeWidth="1.5" />
      {/* bars */}
      <rect x="7" y="13" width="2.5" height="5" rx="0.5" fill="currentColor" fillOpacity={active ? 0.7 : 0.35} />
      <rect x="10.75" y="9" width="2.5" height="9" rx="0.5" fill="currentColor" fillOpacity={active ? 0.85 : 0.45} />
      <rect x="14.5" y="6" width="2.5" height="12" rx="0.5" fill="currentColor" fillOpacity={active ? 1 : 0.55} />
    </svg>
  );
}

function ProfileIcon({ active }: { active: boolean }) {
  return (
    <svg className="w-6 h-6" viewBox="0 0 24 24" fill="none">
      <circle cx="12" cy="8" r="4" fill="currentColor" fillOpacity={active ? 0.35 : 0.15} stroke="currentColor" strokeWidth="1.5" />
      <path
        d="M5.5 21c0-3.59 2.91-6.5 6.5-6.5s6.5 2.91 6.5 6.5"
        fill="currentColor"
        fillOpacity={active ? 0.25 : 0.1}
        stroke="currentColor"
        strokeWidth="1.5"
        strokeLinecap="round"
      />
    </svg>
  );
}

const TAB_ICONS: Record<string, React.FC<{ active: boolean }>> = {
  "/deck": DiscoverIcon,
  "/shortlisted": InterestedIcon,
  "/messages": MessagesIcon,
  "/leads": LeadsIcon,
  "/me": ProfileIcon,
};

const tabs = [
  { label: "Discover", path: "/deck" },
  { label: "Interested", path: "/shortlisted" },
  { label: "Messages", path: "/messages" },
  { label: "Leads", path: "/leads" },
  { label: "Profile", path: "/me" },
];

export default function AppShell() {
  const location = useLocation();
  const navigate = useNavigate();

  // Hide bottom tabs on full-screen pages (chat thread, agent profile)
  const hideTabPaths = ["/messages/", "/agents/"];
  const shouldHideTabs = hideTabPaths.some(p => location.pathname.startsWith(p) && location.pathname !== p.replace("/", ""));

  return (
    <div className="relative min-h-screen bg-brand-dark text-white font-sans antialiased">
      {/* Responsive container: full-width on all screens, max-w-6xl on desktop */}
      <div className="mx-auto w-full max-w-6xl min-h-screen px-4 sm:px-6 lg:px-8">
        <Outlet />
      </div>

      {/* ── Bottom Tab Bar ── */}
      {!shouldHideTabs && (
        <nav className="fixed bottom-0 inset-x-0 z-40 bg-brand-dark/95 backdrop-blur-lg border-t border-white/10 pb-safe">
          <div className="flex items-center justify-around max-w-lg mx-auto">
            {tabs.map(tab => {
              const isActive = location.pathname === tab.path || location.pathname.startsWith(tab.path + "/");
              const IconComp = TAB_ICONS[tab.path];
              return (
                <button
                  key={tab.path}
                  onClick={() => navigate(tab.path)}
                  className={`flex flex-col items-center py-2.5 px-3 min-w-[56px] transition-colors ${
                    isActive ? "text-brand-primary" : "text-white/30 hover:text-white/50"
                  }`}
                >
                  {IconComp && <IconComp active={isActive} />}
                  <span className="text-[9px] font-medium mt-1">{tab.label}</span>
                </button>
              );
            })}
          </div>
        </nav>
      )}
    </div>
  );
}
