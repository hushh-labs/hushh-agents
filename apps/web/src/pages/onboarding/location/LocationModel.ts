/** Location & Communication Preferences — pure data */

export interface CommPrefChip {
  value: string;
  label: string;
  icon: string;
}

export interface LocationFormData {
  locationSource: "gps" | "zip" | "none";
  latitude: number | null;
  longitude: number | null;
  zipCode: string;
  commPrefs: string[];
  // Context fields
  timeline: string;
  insuredStatus: string;
  householdSize: string;
  currentCarrier: string;
}

export function getLocationContent() {
  return {
    headerStep: "Step 4 of 5",
    title: "Make the results more relevant",
    supportCopy:
      "Use your current location or confirm your ZIP so we can rank nearby professionals higher.",
    locationCards: {
      gps: { label: "Use current location", sublabel: "Most accurate" },
      zip: { label: "Keep using ZIP", sublabel: "" },
    },
    sections: {
      commPrefs: "How do you prefer to connect?",
      timeline: "When do you need coverage?",
      insuredStatus: "Currently insured?",
      householdSize: "Household or business size",
      carrier: "Current carrier (optional)",
    },
    ctaUseLocation: "Use current location",
    ctaContinueZip: "Continue with ZIP",
    secondaryCta: "Not now",
    permissionExplainer:
      "We only use location to show nearby advisors and offices. You can change this later.",
    errorDenied: "No problem — we'll keep using your ZIP.",
    footerNote: "Location is optional. The product should never hard-block progress.",
  };
}

export function getCommPrefChips(): CommPrefChip[] {
  return [
    { value: "remote_only", label: "Remote only", icon: "remote" },
    { value: "in_person", label: "In-person welcome", icon: "person" },
    { value: "email_first", label: "Email first", icon: "email" },
    { value: "chat_first", label: "Chat first", icon: "chat" },
    { value: "call_okay", label: "Call okay", icon: "call" },
  ];
}

export function getTimelineOptions() {
  return [
    { value: "now", label: "Now" },
    { value: "this_week", label: "This week" },
    { value: "this_month", label: "This month" },
    { value: "researching", label: "Just researching" },
  ];
}

export function getInsuredOptions() {
  return [
    { value: "insured", label: "Yes, insured" },
    { value: "uninsured", label: "No" },
    { value: "switching", label: "Switching" },
    { value: "unsure", label: "Not sure" },
  ];
}

export function getHouseholdOptions() {
  return [
    { value: "individual", label: "Just me" },
    { value: "couple", label: "Couple" },
    { value: "family_small", label: "Small family" },
    { value: "family_large", label: "Large family" },
    { value: "business", label: "Business" },
  ];
}

export function getInitialLocationData(): LocationFormData {
  return {
    locationSource: "zip",
    latitude: null,
    longitude: null,
    zipCode: "",
    commPrefs: [],
    timeline: "",
    insuredStatus: "",
    householdSize: "",
    currentCarrier: "",
  };
}
