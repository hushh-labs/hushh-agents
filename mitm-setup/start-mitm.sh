#!/bin/bash
# ─────────────────────────────────────────────────────────
# 🕵️  MITM Proxy Launcher for Hushh RIA Agents
# ─────────────────────────────────────────────────────────

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CAPTURES_DIR="$SCRIPT_DIR/captures"
ADDON="$SCRIPT_DIR/addons/hushh_interceptor.py"
PROXY_PORT=8080
WEB_PORT=8081

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo ""
echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║  🕵️  MITM Proxy — Hushh RIA Agents Interceptor  ║${NC}"
echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════╝${NC}"
echo ""

# ── Step 1: Check mitmproxy installed ──
if ! command -v mitmweb &> /dev/null; then
    echo -e "${RED}❌ mitmproxy not installed!${NC}"
    echo -e "   Run: ${YELLOW}brew install mitmproxy${NC}"
    exit 1
fi
echo -e "${GREEN}✅ mitmproxy found:${NC} $(mitmproxy --version | head -1)"

# ── Step 2: Get Mac IP ──
MAC_IP=$(ipconfig getifaddr en0 2>/dev/null || echo "")
if [ -z "$MAC_IP" ]; then
    MAC_IP=$(ipconfig getifaddr en1 2>/dev/null || echo "NOT FOUND")
fi
echo -e "${GREEN}✅ MacBook WiFi IP:${NC} ${BOLD}${MAC_IP}${NC}"

# ── Step 3: Create captures directory ──
mkdir -p "$CAPTURES_DIR"
echo -e "${GREEN}✅ Captures directory:${NC} $CAPTURES_DIR"

# ── Step 4: Show iOS setup instructions ──
echo ""
echo -e "${BOLD}${YELLOW}📱 iPhone Setup Instructions:${NC}"
echo -e "${YELLOW}─────────────────────────────────────────────────${NC}"
echo -e "  1. Connect iPhone to ${BOLD}SAME WiFi${NC} as this Mac"
echo -e "  2. iPhone → Settings → Wi-Fi → (i) → Configure Proxy → Manual"
echo -e "     ${BOLD}Server:${NC} ${CYAN}${MAC_IP}${NC}"
echo -e "     ${BOLD}Port:${NC}   ${CYAN}${PROXY_PORT}${NC}"
echo -e "  3. Safari → ${CYAN}http://mitm.it${NC} → Download iOS certificate"
echo -e "  4. Settings → General → VPN & Device Management → Install mitmproxy cert"
echo -e "  5. Settings → General → About → Certificate Trust Settings → Enable mitmproxy"
echo -e "${YELLOW}─────────────────────────────────────────────────${NC}"
echo ""

# ── Step 5: Check addon exists ──
if [ -f "$ADDON" ]; then
    echo -e "${GREEN}✅ Addon loaded:${NC} hushh_interceptor.py"
    ADDON_FLAG="-s $ADDON"
else
    echo -e "${YELLOW}⚠️  No addon found, running without custom interceptor${NC}"
    ADDON_FLAG=""
fi

# ── Step 6: Start mitmweb ──
echo -e "${BOLD}${GREEN}🚀 Starting mitmweb...${NC}"
echo -e "   Proxy:     ${CYAN}http://${MAC_IP}:${PROXY_PORT}${NC}"
echo -e "   Dashboard: ${CYAN}http://localhost:${WEB_PORT}${NC}"
echo -e "   ${YELLOW}Press Ctrl+C to stop${NC}"
echo ""

mitmweb \
    --listen-port $PROXY_PORT \
    --web-port $WEB_PORT \
    --set console_eventlog_verbosity=info \
    --set flow_detail=2 \
    $ADDON_FLAG
