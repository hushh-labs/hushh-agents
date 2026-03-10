/** Coverage Goals page data — pure functions, no React */

export interface GoalChip {
  value: string;
  label: string;
  icon: string;
}

export interface TimelineOption {
  value: string;
  label: string;
}

export interface CommStyleOption {
  value: string;
  label: string;
}

export interface GoalsFormData {
  selectedGoals: string[];
  primaryGoal: string;
  timeline: string;
  communicationStyle: string;
  languagePref: string;
}

export function getGoalsContent() {
  return {
    headerStep: "Step 3 of 5",
    title: "What are you looking for?",
    supportCopy:
      "Choose one primary goal and any secondary interests. This shapes the first deck you see.",
    ctaLabel: "Continue",
    secondaryCta: "I'm not sure yet",
    footerNote:
      "These preferences only shape recommendations; they do not limit which profiles you can view.",
    sections: {
      primary: "Primary goal",
      timeline: "Timeline",
      commStyle: "Communication style",
      language: "Language",
    },
    validation: {
      goalRequired: "Select at least one goal to continue.",
    },
  };
}

export function getGoalChips(): GoalChip[] {
  return [
    { value: "retirement", label: "Retirement planning", icon: "retirement" },
    { value: "investment", label: "Investment management", icon: "investment" },
    { value: "insurance", label: "Insurance planning", icon: "insurance" },
    { value: "estate", label: "Estate planning", icon: "estate" },
    { value: "tax", label: "Tax-forward advice", icon: "tax" },
    { value: "business", label: "Business planning", icon: "business" },
  ];
}

export function getTimelineOptions(): TimelineOption[] {
  return [
    { value: "now", label: "Now" },
    { value: "this_month", label: "This month" },
    { value: "researching", label: "Researching" },
  ];
}

export function getCommStyleOptions(): CommStyleOption[] {
  return [
    { value: "fast_answers", label: "Fast answers" },
    { value: "deep_planning", label: "Deep planning" },
    { value: "ongoing_relationship", label: "Ongoing relationship" },
  ];
}

export function getInitialGoalsData(): GoalsFormData {
  return {
    selectedGoals: [],
    primaryGoal: "",
    timeline: "",
    communicationStyle: "",
    languagePref: "en",
  };
}

export function validateGoals(data: GoalsFormData): { valid: boolean; error?: string } {
  if (data.selectedGoals.length === 0) {
    return { valid: false, error: getGoalsContent().validation.goalRequired };
  }
  return { valid: true };
}
