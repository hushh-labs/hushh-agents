export interface HushhAgentCTAProps {
  label: string;
  onClick?: () => void;
  variant?: "primary" | "outline";
  size?: "sm" | "md" | "lg";
  showArrow?: boolean;
  className?: string;
  type?: "button" | "submit";
  disabled?: boolean;
}

export default function HushhAgentCTA({
  label,
  onClick,
  variant = "primary",
  size = "lg",
  showArrow = true,
  className = "",
  type = "button",
  disabled = false,
}: HushhAgentCTAProps) {
  const baseClasses =
    "inline-flex items-center justify-center gap-2 font-bold transition-all rounded-custom";

  const variantClasses =
    variant === "primary"
      ? "bg-brand-primary text-white hover:bg-opacity-90 shadow-lg shadow-[#ff5864]/20"
      : "border border-white/20 text-white hover:bg-white/10";

  const sizeClasses =
    size === "lg"
      ? "px-10 py-4 text-lg"
      : size === "md"
        ? "px-6 py-3 text-base"
        : "px-4 py-2 text-sm";

  return (
    <button
      type={type}
      onClick={onClick}
      disabled={disabled}
      className={`${baseClasses} ${variantClasses} ${sizeClasses} ${disabled ? "opacity-40 cursor-not-allowed" : ""} ${className}`}
    >
      {label}
      {showArrow && (
        <svg
          className={size === "lg" ? "h-5 w-5" : size === "md" ? "h-4 w-4" : "h-3.5 w-3.5"}
          fill="currentColor"
          viewBox="0 0 20 20"
          xmlns="http://www.w3.org/2000/svg"
        >
          <path
            fillRule="evenodd"
            d="M10.293 3.293a1 1 0 011.414 0l6 6a1 1 0 010 1.414l-6 6a1 1 0 01-1.414-1.414L14.586 11H3a1 1 0 110-2h11.586l-4.293-4.293a1 1 0 010-1.414z"
            clipRule="evenodd"
          />
        </svg>
      )}
    </button>
  );
}
