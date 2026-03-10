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

export default function App() {
  return (
    <Routes>
      <Route path="/" element={<LandingView />} />
      <Route path="/login/email" element={<LoginView />} />
      <Route path="/login/verify" element={<VerifyView />} />
      <Route path="/onboarding/welcome" element={<WelcomeView />} />
      <Route path="/onboarding/profile" element={<ProfileView />} />
      <Route path="/onboarding/goals" element={<GoalsView />} />
      <Route path="/onboarding/location" element={<LocationView />} />
      <Route path="/onboarding/notifications" element={<NotificationsView />} />
      <Route path="/components" element={<ComponentLibraryView />} />
    </Routes>
  );
}
