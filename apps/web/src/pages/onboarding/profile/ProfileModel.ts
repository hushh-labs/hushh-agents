/** Profile Setup page data — pure functions, no React */

export interface RoleOption {
  value: string;
  label: string;
}

export interface ContactMethod {
  value: string;
  label: string;
  icon: string; // icon key
}

export interface ProfileFormData {
  firstName: string;
  lastName: string;
  role: string;
  zipCode: string;
  contactMethod: string;
  avatarUrl: string | null;
}

export function getProfileContent() {
  return {
    headerStep: "Step 2 of 5",
    title: "Set up your profile",
    supportCopy:
      "This helps us personalize the advisor deck and keep follow-ups relevant.",
    ctaLabel: "Save and continue",
    secondaryCta: "Skip avatar",
    footerNote: "You can edit these details later from My Profile.",
    fields: {
      firstName: { label: "First name", placeholder: "e.g. Ankit", required: true },
      lastName: { label: "Last name", placeholder: "e.g. Singh", required: false },
      role: { label: "I'm a…", required: true },
      zipCode: {
        label: "ZIP code",
        placeholder: "e.g. 98033",
        required: true,
        helper: "Used to prioritize nearby advisors and office locations.",
      },
      contactMethod: { label: "Preferred contact", required: false },
      avatar: { label: "Profile photo", required: false },
    },
    validation: {
      firstNameRequired: "First name is required.",
      zipRequired: "Enter your ZIP so we can localize your results.",
      zipInvalid: "Enter a valid ZIP code.",
      roleRequired: "Select a role to continue.",
    },
  };
}

export function getRoleOptions(): RoleOption[] {
  return [
    { value: "investor", label: "Investor" },
    { value: "family", label: "Family" },
    { value: "founder", label: "Founder" },
    { value: "executive", label: "Executive" },
    { value: "other", label: "Other" },
  ];
}

export function getContactMethods(): ContactMethod[] {
  return [
    { value: "email", label: "Email", icon: "email" },
    { value: "chat", label: "Chat", icon: "chat" },
    { value: "call", label: "Call", icon: "call" },
  ];
}

export function getInitialFormData(): ProfileFormData {
  return {
    firstName: "",
    lastName: "",
    role: "",
    zipCode: "",
    contactMethod: "email",
    avatarUrl: null,
  };
}

/** Validate profile form */
export function validateProfile(
  data: ProfileFormData
): { valid: boolean; errors: Record<string, string> } {
  const errors: Record<string, string> = {};
  const content = getProfileContent();

  if (!data.firstName.trim()) {
    errors.firstName = content.validation.firstNameRequired;
  }

  if (!data.role) {
    errors.role = content.validation.roleRequired;
  }

  if (!data.zipCode.trim()) {
    errors.zipCode = content.validation.zipRequired;
  } else if (!/^\d{5}(-\d{4})?$/.test(data.zipCode.trim())) {
    errors.zipCode = content.validation.zipInvalid;
  }

  return { valid: Object.keys(errors).length === 0, errors };
}
