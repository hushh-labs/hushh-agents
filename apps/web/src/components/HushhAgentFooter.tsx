export default function HushhAgentFooter() {
  return (
    <footer className="relative w-full px-4 sm:px-6 py-4 sm:py-6 border-t border-white/10 z-20">
      <div className="max-w-7xl mx-auto flex items-center justify-center gap-6 sm:gap-8">
        <a className="text-[10px] sm:text-xs text-white/40 hover:text-white transition-colors" href="#">
          Terms of Service
        </a>
        <span className="text-white/20 text-[10px]">•</span>
        <a className="text-[10px] sm:text-xs text-white/40 hover:text-white transition-colors" href="#">
          Privacy Policy
        </a>
        <span className="text-white/20 text-[10px]">•</span>
        <a className="text-[10px] sm:text-xs text-white/40 hover:text-white transition-colors" href="#">
          Contact support
        </a>
      </div>
    </footer>
  );
}
