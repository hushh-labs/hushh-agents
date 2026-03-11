import { Routes, Route } from "react-router-dom";
import LandingView from "./pages/landing/LandingView";
import ComponentLibraryView from "./pages/component-library/ComponentLibraryView";
import LoginView from "./pages/login/LoginView";
import VerifyView from "./pages/verify/VerifyView";
import WelcomeView from "./pages/onboarding/welcome/WelcomeView";
import ProfileView from "./pages/onboarding/profile/ProfileView";
import GoalsView from "./pages/onboarding/goals/GoalsView";
import LocationView from "./pages/onboarding/location/LocationView";
import NotificationsView from "./pages/onboarding/notifications/NotificationsView";
import ReadyView from "./pages/onboarding/ready/ReadyView";
import AppShell from "./components/AppShell";
import DeckView from "./pages/deck/DeckView";
import AgentProfileView from "./pages/agent-profile/AgentProfileView";
import ShortlistedView from "./pages/shortlisted/ShortlistedView";
import MessagesView from "./pages/messages/MessagesView";
import ChatView from "./pages/chat/ChatView";
import LeadTrackerView from "./pages/lead-tracker/LeadTrackerView";
import SettingsView from "./pages/settings/SettingsView";

export default function App() {
  return (
    <Routes>
      {/* ── Public / Auth / Onboarding (no bottom tabs) ── */}
      <Route path="/" element={<LandingView />} />
      <Route path="/login/email" element={<LoginView />} />
      <Route path="/login/verify" element={<VerifyView />} />
      <Route path="/onboarding/welcome" element={<WelcomeView />} />
      <Route path="/onboarding/profile" element={<ProfileView />} />
      <Route path="/onboarding/goals" element={<GoalsView />} />
      <Route path="/onboarding/location" element={<LocationView />} />
      <Route path="/onboarding/notifications" element={<NotificationsView />} />
      <Route path="/onboarding/ready" element={<ReadyView />} />
      <Route path="/components" element={<ComponentLibraryView />} />

      {/* ── Main App (with bottom tab navigation) ── */}
      <Route element={<AppShell />}>
        <Route path="/deck" element={<DeckView />} />
        <Route path="/agents/:agentId" element={<AgentProfileView />} />
        <Route path="/shortlisted" element={<ShortlistedView />} />
        <Route path="/messages" element={<MessagesView />} />
        <Route path="/messages/:conversationId" element={<ChatView />} />
        <Route path="/leads" element={<LeadTrackerView />} />
        <Route path="/me" element={<SettingsView />} />
      </Route>
    </Routes>
  );
}
