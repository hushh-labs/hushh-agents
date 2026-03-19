"""
🕵️ Hushh RIA Agents — MITM Interceptor Addon (Full Capture Mode)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Captures ALL HTTP/HTTPS traffic from the connected device.
Specifically highlights Yelp / Help app traffic and searches
for "RIagents" and "980033".

Usage:
  mitmweb -s addons/hushh_interceptor.py --listen-port 8080
"""

import json
import os
import time
from datetime import datetime, timezone
from pathlib import Path

from mitmproxy import http, ctx


# ── Config ──────────────────────────────────────────────
CAPTURES_DIR = Path(__file__).parent.parent / "captures"
CAPTURES_DIR.mkdir(exist_ok=True)

# CAPTURE_ALL mode — log every single request
CAPTURE_ALL = True

# Keywords to flag as HIGH PRIORITY
HIGH_PRIORITY_KEYWORDS = [
    "riagents",
    "ri agents",
    "ria agents",
    "980033",
    "yelp",
    "insurance",
    "agent",
    "hushh",
]

# Domains of special interest
HIGHLIGHT_DOMAINS = [
    "yelp.com",
    "yelp.co",
    "yelpcdn.com",
    "supabase.co",
    "supabase.in",
    "hushh",
    "localhost",
    "127.0.0.1",
]

# Output files
API_LOG_FILE = CAPTURES_DIR / "api_requests.jsonl"
AUTH_TOKENS_FILE = CAPTURES_DIR / "auth_tokens.json"
SUMMARY_FILE = CAPTURES_DIR / "session_summary.json"
YELP_TRAFFIC_FILE = CAPTURES_DIR / "yelp_traffic.jsonl"
SEARCH_HITS_FILE = CAPTURES_DIR / "search_hits.jsonl"

# ── Colors for terminal ──
class C:
    RED = "\033[91m"
    GREEN = "\033[92m"
    YELLOW = "\033[93m"
    BLUE = "\033[94m"
    MAGENTA = "\033[95m"
    CYAN = "\033[96m"
    BOLD = "\033[1m"
    DIM = "\033[2m"
    END = "\033[0m"


# ── State ──────────────────────────────────────────────
class HushhInterceptor:
    def __init__(self):
        self.request_count = 0
        self.captured_count = 0
        self.yelp_count = 0
        self.search_hit_count = 0
        self.auth_tokens: list[dict] = []
        self.captured_endpoints: dict[str, int] = {}
        self.domain_counts: dict[str, int] = {}
        self.start_time = datetime.now(timezone.utc).isoformat()
        
        # Load existing tokens if any
        if AUTH_TOKENS_FILE.exists():
            try:
                self.auth_tokens = json.loads(AUTH_TOKENS_FILE.read_text())
            except Exception:
                self.auth_tokens = []

        ctx.log.info(f"🕵️  Hushh Interceptor loaded (FULL CAPTURE MODE)! Captures → {CAPTURES_DIR}")

    def _is_highlight_traffic(self, flow: http.HTTPFlow) -> bool:
        """Check if this is traffic from a highlighted domain"""
        host = flow.request.pretty_host.lower()
        return any(d in host for d in HIGHLIGHT_DOMAINS)

    def _is_yelp_traffic(self, flow: http.HTTPFlow) -> bool:
        """Check if this is Yelp app traffic"""
        host = flow.request.pretty_host.lower()
        user_agent = flow.request.headers.get("user-agent", "").lower()
        return "yelp" in host or "yelp" in user_agent

    def _check_search_keywords(self, flow: http.HTTPFlow) -> list[str]:
        """Check if request/response contains our target search keywords"""
        hits = []
        
        # Check URL
        url_lower = flow.request.pretty_url.lower()
        for kw in HIGH_PRIORITY_KEYWORDS:
            if kw in url_lower:
                hits.append(f"url:{kw}")
        
        # Check request body
        req_body = self._get_request_body_raw(flow)
        if req_body:
            req_str = req_body.lower() if isinstance(req_body, str) else json.dumps(req_body).lower()
            for kw in HIGH_PRIORITY_KEYWORDS:
                if kw in req_str:
                    hits.append(f"req_body:{kw}")
        
        # Check response body
        res_body = self._get_response_body_raw(flow)
        if res_body:
            res_str = res_body.lower() if isinstance(res_body, str) else json.dumps(res_body).lower()
            for kw in HIGH_PRIORITY_KEYWORDS:
                if kw in res_str:
                    hits.append(f"res_body:{kw}")
        
        # Check request headers
        headers_str = json.dumps(dict(flow.request.headers)).lower()
        for kw in HIGH_PRIORITY_KEYWORDS:
            if kw in headers_str:
                hits.append(f"req_header:{kw}")
        
        return list(set(hits))

    def _extract_auth_token(self, flow: http.HTTPFlow) -> str | None:
        """Extract Bearer token from request"""
        auth_header = flow.request.headers.get("Authorization", "")
        if auth_header.startswith("Bearer "):
            return auth_header[7:]
        
        # Check apikey header (Supabase)
        apikey = flow.request.headers.get("apikey", "")
        if apikey:
            return apikey
        
        return None

    def _get_request_body_raw(self, flow: http.HTTPFlow) -> dict | str | None:
        """Safely parse request body"""
        if not flow.request.content:
            return None
        try:
            return json.loads(flow.request.content.decode("utf-8", errors="replace"))
        except (json.JSONDecodeError, UnicodeDecodeError):
            content = flow.request.content.decode("utf-8", errors="replace")
            return content[:5000] if len(content) > 5000 else content

    def _get_response_body_raw(self, flow: http.HTTPFlow) -> dict | str | None:
        """Safely parse response body"""
        if not flow.response or not flow.response.content:
            return None
        
        content_type = flow.response.headers.get("content-type", "")
        
        # Skip binary content
        if any(t in content_type for t in ["image/", "font/", "audio/", "video/", "octet-stream"]):
            return f"[binary: {content_type}, {len(flow.response.content)} bytes]"
        
        try:
            return json.loads(flow.response.content.decode("utf-8", errors="replace"))
        except (json.JSONDecodeError, UnicodeDecodeError):
            content = flow.response.content.decode("utf-8", errors="replace")
            return content[:10000] if len(content) > 10000 else content

    def _categorize_endpoint(self, flow: http.HTTPFlow) -> str:
        """Categorize the endpoint for summary"""
        host = flow.request.pretty_host.lower()
        path = flow.request.path.lower()
        
        if "yelp" in host:
            return "🔍 YELP"
        elif "supabase" in host:
            if "/auth/" in path:
                return "🔐 SUPABASE-AUTH"
            elif "/rest/" in path:
                return "🗄️  SUPABASE-DB"
            elif "/realtime/" in path:
                return "⚡ SUPABASE-RT"
            return "🟢 SUPABASE"
        elif "hushh" in host:
            return "🏠 HUSHH"
        elif "apple.com" in host:
            return "🍎 APPLE"
        elif "google" in host or "gstatic" in host:
            return "🔵 GOOGLE"
        elif "facebook" in host or "instagram" in host or "fbcdn" in host:
            return "📘 META"
        elif "analytics" in host or "tracking" in host or "telemetry" in host:
            return "📊 ANALYTICS"
        elif "cdn" in host or "static" in host or "assets" in host:
            return "📦 CDN"
        elif "/auth/" in path:
            return "🔐 AUTH"
        elif "/config/" in path:
            return "⚙️  CONFIG"
        else:
            return "📡 OTHER"

    def _print_flow(self, flow: http.HTTPFlow, category: str, keyword_hits: list[str]):
        """Pretty print the captured flow to terminal"""
        method = flow.request.method
        url = flow.request.pretty_url
        status = flow.response.status_code if flow.response else "???"
        
        # Color based on method
        method_color = {
            "GET": C.GREEN,
            "POST": C.YELLOW,
            "PUT": C.BLUE,
            "PATCH": C.MAGENTA,
            "DELETE": C.RED,
        }.get(method, C.CYAN)
        
        # Color based on status
        if flow.response:
            status_color = C.GREEN if flow.response.status_code < 400 else C.RED
        else:
            status_color = C.DIM

        # Highlight keyword hits
        if keyword_hits:
            print(f"\n{C.RED}{C.BOLD}{'🚨' * 35}{C.END}")
            print(f"  {C.RED}{C.BOLD}🎯 KEYWORD HIT: {', '.join(keyword_hits)}{C.END}")
        
        is_yelp = "YELP" in category
        separator = '🔥' if is_yelp else '━'
        sep_line = separator * 35 if is_yelp else f"{'━' * 70}"
        
        print(f"\n{C.BOLD}{sep_line}{C.END}")
        print(f"  {category}  {method_color}{C.BOLD}{method}{C.END} {url[:150]}")
        print(f"  {status_color}→ {status}{C.END}  {C.DIM}#{self.captured_count} (total: {self.request_count}){C.END}")
        
        # Show auth token (truncated)
        token = self._extract_auth_token(flow)
        if token:
            print(f"  {C.RED}🔑 Token: {token[:20]}...{token[-10:]}{C.END}")
        
        # Show request body (compact) — more for Yelp
        req_body = self._get_request_body_raw(flow)
        if req_body:
            body_str = json.dumps(req_body, ensure_ascii=False) if isinstance(req_body, dict) else str(req_body)
            max_len = 500 if (is_yelp or keyword_hits) else 200
            print(f"  {C.CYAN}📤 Body: {body_str[:max_len]}{C.END}")
        
        # Show response body (compact) — more for Yelp
        res_body = self._get_response_body_raw(flow)
        if res_body:
            body_str = json.dumps(res_body, ensure_ascii=False) if isinstance(res_body, dict) else str(res_body)
            max_len = 500 if (is_yelp or keyword_hits) else 200
            print(f"  {C.GREEN}📥 Response: {body_str[:max_len]}{C.END}")

    def response(self, flow: http.HTTPFlow):
        """Called when a response is received"""
        self.request_count += 1
        
        # Track domain counts
        host = flow.request.pretty_host.lower()
        base_domain = '.'.join(host.split('.')[-2:]) if '.' in host else host
        self.domain_counts[base_domain] = self.domain_counts.get(base_domain, 0) + 1
        
        # In CAPTURE_ALL mode, log everything; otherwise filter
        is_highlight = self._is_highlight_traffic(flow)
        is_yelp = self._is_yelp_traffic(flow)
        keyword_hits = self._check_search_keywords(flow)
        
        if not CAPTURE_ALL and not is_highlight and not is_yelp and not keyword_hits:
            return
        
        self.captured_count += 1
        category = self._categorize_endpoint(flow)
        
        # Track endpoint counts
        endpoint_key = f"{flow.request.method} {flow.request.path.split('?')[0]}"
        self.captured_endpoints[endpoint_key] = self.captured_endpoints.get(endpoint_key, 0) + 1
        
        # Extract and save auth tokens
        token = self._extract_auth_token(flow)
        if token:
            token_entry = {
                "token": token,
                "type": "apikey" if flow.request.headers.get("apikey") else "bearer",
                "host": flow.request.pretty_host,
                "path": flow.request.path,
                "timestamp": datetime.now(timezone.utc).isoformat(),
            }
            existing_tokens = {t["token"] for t in self.auth_tokens}
            if token not in existing_tokens:
                self.auth_tokens.append(token_entry)
                AUTH_TOKENS_FILE.write_text(json.dumps(self.auth_tokens, indent=2))
        
        # Build log entry
        log_entry = {
            "id": self.captured_count,
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "category": category,
            "is_yelp": is_yelp,
            "keyword_hits": keyword_hits,
            "method": flow.request.method,
            "url": flow.request.pretty_url,
            "host": flow.request.pretty_host,
            "path": flow.request.path,
            "request": {
                "headers": dict(flow.request.headers),
                "body": self._get_request_body_raw(flow),
            },
            "response": {
                "status_code": flow.response.status_code if flow.response else None,
                "headers": dict(flow.response.headers) if flow.response else None,
                "body": self._get_response_body_raw(flow),
            },
            "auth_token": token[:50] + "..." if token and len(token) > 50 else token,
        }
        
        # Append to main JSONL log
        with open(API_LOG_FILE, "a") as f:
            f.write(json.dumps(log_entry, ensure_ascii=False) + "\n")
        
        # Append to Yelp-specific log
        if is_yelp:
            self.yelp_count += 1
            with open(YELP_TRAFFIC_FILE, "a") as f:
                f.write(json.dumps(log_entry, ensure_ascii=False) + "\n")
        
        # Append to search hits log
        if keyword_hits:
            self.search_hit_count += 1
            with open(SEARCH_HITS_FILE, "a") as f:
                f.write(json.dumps(log_entry, ensure_ascii=False) + "\n")
        
        # Update session summary
        summary = {
            "session_start": self.start_time,
            "last_updated": datetime.now(timezone.utc).isoformat(),
            "total_requests": self.request_count,
            "captured_requests": self.captured_count,
            "yelp_requests": self.yelp_count,
            "search_keyword_hits": self.search_hit_count,
            "unique_tokens": len(self.auth_tokens),
            "domain_counts": dict(sorted(self.domain_counts.items(), key=lambda x: x[1], reverse=True)[:30]),
            "endpoint_counts": self.captured_endpoints,
        }
        SUMMARY_FILE.write_text(json.dumps(summary, indent=2))
        
        # Pretty print to terminal (only highlighted/yelp/keyword traffic to avoid flooding)
        if is_highlight or is_yelp or keyword_hits:
            self._print_flow(flow, category, keyword_hits)
        elif self.request_count % 50 == 0:
            # Periodic status update for non-highlighted traffic
            ctx.log.info(
                f"📊 Status: {self.request_count} total | "
                f"{self.captured_count} captured | "
                f"{self.yelp_count} yelp | "
                f"{self.search_hit_count} keyword hits"
            )


# ── Register addon ──
addons = [HushhInterceptor()]
