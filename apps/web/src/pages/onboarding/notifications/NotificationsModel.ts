/** Notifications Preference — pure data */

export interface ValueBullet {
  icon: string;
  label: string;
}

export function getNotificationsContent() {
  return {
    headerStep: "Step 5 of 5",
    title: "Stay on top of replies",
    supportCopy:
      "Get notified when a professional responds, a request is accepted, or a conversation needs your attention.",
    ctaLabel: "Enable notifications",
    secondaryCta: "Maybe later",
    successCopy: "Thanks — we'll only send relevant updates.",
    errorBlocked:
      "Notifications are off in your browser settings. You can enable them later.",
    fallbackNote:
      "If browser notifications are skipped, keep email updates enabled for essential events.",
    footerNote: "Quiet hours and alert preferences are editable in settings.",
  };
}

export function getValueBullets(): ValueBullet[] {
  return [
    { icon: "reply", label: "Reply alerts" },
    { icon: "status", label: "Request status updates" },
    { icon: "reminder", label: "Follow-up reminders" },
  ];
}
