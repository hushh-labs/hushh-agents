import { useState, useCallback, useMemo, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import {
  getProfileContent,
  getRoleOptions,
  getContactMethods,
  getInitialFormData,
  validateProfile,
  type ProfileFormData,
} from "./ProfileModel";

/** Simple analytics stub */
function trackEvent(event: string, data?: Record<string, unknown>) {
  console.log(`[analytics] ${event}`, data ?? "");
}

export function useProfileViewModel() {
  const navigate = useNavigate();
  const content = useMemo(() => getProfileContent(), []);
  const roleOptions = useMemo(() => getRoleOptions(), []);
  const contactMethods = useMemo(() => getContactMethods(), []);

  const [form, setForm] = useState<ProfileFormData>(() => {
    // Restore from localStorage if user navigated back
    const saved = localStorage.getItem("hushh_profile_draft");
    return saved ? JSON.parse(saved) : getInitialFormData();
  });

  const [errors, setErrors] = useState<Record<string, string>>({});
  const [loading, setLoading] = useState(false);

  // Track screen view
  useEffect(() => {
    trackEvent("profile_started");
  }, []);

  // Persist draft to localStorage
  useEffect(() => {
    localStorage.setItem("hushh_profile_draft", JSON.stringify(form));
  }, [form]);

  /** Update a single field */
  const updateField = useCallback(
    <K extends keyof ProfileFormData>(field: K, value: ProfileFormData[K]) => {
      setForm((prev) => ({ ...prev, [field]: value }));
      // Clear field error on change
      setErrors((prev) => {
        const next = { ...prev };
        delete next[field];
        return next;
      });
    },
    []
  );

  /** Handle avatar upload */
  const onAvatarChange = useCallback((file: File | null) => {
    if (!file) {
      updateField("avatarUrl", null);
      return;
    }
    // Create local preview URL
    const url = URL.createObjectURL(file);
    updateField("avatarUrl", url);
  }, [updateField]);

  /** Skip avatar */
  const onSkipAvatar = useCallback(() => {
    updateField("avatarUrl", null);
  }, [updateField]);

  /** Save and continue */
  const onSave = useCallback(async () => {
    const validation = validateProfile(form);
    if (!validation.valid) {
      setErrors(validation.errors);
      return;
    }

    setLoading(true);
    setErrors({});

    try {
      // TODO: POST /me/profile API call
      // For now just simulate
      await new Promise((r) => setTimeout(r, 600));

      trackEvent("profile_saved", {
        role: form.role,
        hasAvatar: !!form.avatarUrl,
        contactMethod: form.contactMethod,
      });

      // Clear draft
      localStorage.removeItem("hushh_profile_draft");

      // Navigate to S6 Insurance Goals
      navigate("/onboarding/goals");
    } catch (err: unknown) {
      setErrors({ general: (err as Error).message || "Failed to save" });
    } finally {
      setLoading(false);
    }
  }, [form, navigate]);

  /** Go back to Welcome */
  const onBack = useCallback(() => {
    navigate("/onboarding/welcome");
  }, [navigate]);

  return {
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
  };
}
