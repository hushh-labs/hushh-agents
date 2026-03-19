#!/usr/bin/env python3
"""
📊 Hushh RIA Agents — Captured Data Analyzer
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Captured MITM data ko parse karke organized reports banata hai.

Usage:
  python3 scripts/analyze_capture.py
"""

import json
import sys
from collections import defaultdict
from pathlib import Path

CAPTURES_DIR = Path(__file__).parent.parent / "captures"
API_LOG_FILE = CAPTURES_DIR / "api_requests.jsonl"
AUTH_TOKENS_FILE = CAPTURES_DIR / "auth_tokens.json"
SUMMARY_FILE = CAPTURES_DIR / "session_summary.json"

# Output files
AGENTS_DATA_FILE = CAPTURES_DIR / "extracted_agents.json"
USERS_DATA_FILE = CAPTURES_DIR / "extracted_users.json"
LEADS_DATA_FILE = CAPTURES_DIR / "extracted_leads.json"
MESSAGES_DATA_FILE = CAPTURES_DIR / "extracted_messages.json"
AUTH_DATA_FILE = CAPTURES_DIR / "extracted_auth.json"
FULL_REPORT_FILE = CAPTURES_DIR / "full_report.json"


def load_requests() -> list[dict]:
    """Load all captured requests from JSONL file"""
    if not API_LOG_FILE.exists():
        print("❌ No captured data found! Run the MITM proxy first.")
        print(f"   Expected file: {API_LOG_FILE}")
        sys.exit(1)

    requests = []
    with open(API_LOG_FILE) as f:
        for line in f:
            line = line.strip()
            if line:
                try:
                    requests.append(json.loads(line))
                except json.JSONDecodeError:
                    continue
    return requests


def extract_agents(requests: list[dict]) -> list[dict]:
    """Extract agent data from captured requests"""
    agents = []
    agent_profiles = {}

    for req in requests:
        path = req.get("path", "")
        response_body = req.get("response", {}).get("body")

        if not response_body or not isinstance(response_body, (dict, list)):
            continue

        # Agent deck responses
        if "/agents/deck" in path and req["method"] == "GET":
            if isinstance(response_body, list):
                for agent in response_body:
                    if isinstance(agent, dict) and "id" in agent:
                        agent_profiles[agent["id"]] = agent
            elif isinstance(response_body, dict):
                data = response_body.get("data", response_body.get("agents", []))
                if isinstance(data, list):
                    for agent in data:
                        if isinstance(agent, dict) and "id" in agent:
                            agent_profiles[agent["id"]] = agent

        # Individual agent profile
        elif "/agents/" in path and req["method"] == "GET" and "deck" not in path:
            if isinstance(response_body, dict) and "id" in response_body:
                agent_profiles[response_body["id"]] = response_body

    agents = list(agent_profiles.values())
    return agents


def extract_users(requests: list[dict]) -> list[dict]:
    """Extract user profile data"""
    users = []
    seen_users = set()

    for req in requests:
        path = req.get("path", "")
        response_body = req.get("response", {}).get("body")
        request_body = req.get("request", {}).get("body")

        if not isinstance(response_body, dict):
            continue

        # GET /users/me — user profile
        if "/users/me" in path and req["method"] == "GET":
            user_id = response_body.get("id", "unknown")
            if user_id not in seen_users:
                seen_users.add(user_id)
                users.append({
                    "source": "GET /users/me",
                    "data": response_body,
                    "timestamp": req.get("timestamp"),
                })

        # PATCH /users/me — profile updates
        elif "/users/me" in path and req["method"] == "PATCH":
            users.append({
                "source": "PATCH /users/me (update)",
                "update_data": request_body,
                "response": response_body,
                "timestamp": req.get("timestamp"),
            })

        # POST /users/me/preferences
        elif "/preferences" in path and req["method"] == "POST":
            users.append({
                "source": "POST preferences",
                "preferences": request_body,
                "timestamp": req.get("timestamp"),
            })

    return users


def extract_leads(requests: list[dict]) -> list[dict]:
    """Extract lead tracker data"""
    leads = []

    for req in requests:
        path = req.get("path", "")
        response_body = req.get("response", {}).get("body")
        request_body = req.get("request", {}).get("body")

        if "/leads" not in path:
            continue

        if req["method"] == "GET" and response_body:
            if isinstance(response_body, list):
                leads.extend(response_body)
            elif isinstance(response_body, dict):
                data = response_body.get("data", response_body.get("leads", []))
                if isinstance(data, list):
                    leads.extend(data)
                else:
                    leads.append(response_body)

        elif req["method"] == "PATCH" and request_body:
            leads.append({
                "type": "lead_update",
                "path": path,
                "update": request_body,
                "timestamp": req.get("timestamp"),
            })

    return leads


def extract_messages(requests: list[dict]) -> list[dict]:
    """Extract chat/message data"""
    messages = []

    for req in requests:
        path = req.get("path", "")
        response_body = req.get("response", {}).get("body")
        request_body = req.get("request", {}).get("body")

        if "/messages/" not in path:
            continue

        if req["method"] == "GET" and response_body:
            if isinstance(response_body, list):
                messages.append({
                    "type": "conversation_list" if "conversations" in path and "/" not in path.split("conversations/")[-1] else "messages",
                    "data": response_body,
                    "timestamp": req.get("timestamp"),
                })
            elif isinstance(response_body, dict):
                messages.append({
                    "type": "conversation_detail",
                    "data": response_body,
                    "timestamp": req.get("timestamp"),
                })

        elif req["method"] == "POST" and request_body:
            messages.append({
                "type": "sent_message",
                "path": path,
                "content": request_body,
                "timestamp": req.get("timestamp"),
            })

    return messages


def extract_auth(requests: list[dict]) -> list[dict]:
    """Extract authentication data"""
    auth_data = []

    for req in requests:
        path = req.get("path", "")
        category = req.get("category", "")
        request_body = req.get("request", {}).get("body")
        response_body = req.get("response", {}).get("body")

        if "AUTH" not in category and "/auth/" not in path:
            continue

        entry = {
            "method": req["method"],
            "path": path,
            "timestamp": req.get("timestamp"),
        }

        if request_body and isinstance(request_body, dict):
            # Capture phone/email used for OTP
            entry["request"] = request_body

        if response_body and isinstance(response_body, dict):
            entry["response"] = response_body
            # Extract tokens from auth responses
            if "access_token" in response_body:
                entry["access_token"] = response_body["access_token"]
            if "refresh_token" in response_body:
                entry["refresh_token"] = response_body["refresh_token"]

        if req.get("auth_token"):
            entry["bearer_token"] = req["auth_token"]

        auth_data.append(entry)

    return auth_data


def print_report(requests, agents, users, leads, messages, auth_data):
    """Print a nice summary report"""
    print()
    print("╔══════════════════════════════════════════════════════╗")
    print("║  📊  Hushh RIA Agents — MITM Capture Analysis       ║")
    print("╚══════════════════════════════════════════════════════╝")
    print()

    print(f"  📡 Total captured requests:  {len(requests)}")
    print(f"  👤 Agents found:             {len(agents)}")
    print(f"  👥 User data entries:        {len(users)}")
    print(f"  📊 Leads captured:           {len(leads)}")
    print(f"  💬 Message entries:          {len(messages)}")
    print(f"  🔐 Auth events:             {len(auth_data)}")
    print()

    # Auth tokens
    if AUTH_TOKENS_FILE.exists():
        tokens = json.loads(AUTH_TOKENS_FILE.read_text())
        print(f"  🔑 Unique auth tokens:       {len(tokens)}")
        for t in tokens:
            token_preview = t["token"][:30] + "..." if len(t["token"]) > 30 else t["token"]
            print(f"     • [{t['type']}] {token_preview}")
        print()

    # Endpoint breakdown
    print("  📋 Endpoint Breakdown:")
    category_counts = defaultdict(int)
    for req in requests:
        cat = req.get("category", "OTHER")
        category_counts[cat] += 1
    for cat, count in sorted(category_counts.items(), key=lambda x: -x[1]):
        print(f"     {cat}: {count}")
    print()

    # Agent details
    if agents:
        print("  👤 Captured Agents:")
        for a in agents[:10]:
            name = a.get("full_name", a.get("name", "Unknown"))
            agent_id = a.get("id", "?")
            print(f"     • {name} (ID: {agent_id})")
        if len(agents) > 10:
            print(f"     ... and {len(agents) - 10} more")
        print()

    print(f"  📁 Output files saved to: {CAPTURES_DIR}")
    print()


def main():
    print("\n🔍 Loading captured data...")
    requests = load_requests()
    print(f"   Found {len(requests)} captured requests")

    print("🔬 Extracting agents...")
    agents = extract_agents(requests)

    print("🔬 Extracting users...")
    users = extract_users(requests)

    print("🔬 Extracting leads...")
    leads = extract_leads(requests)

    print("🔬 Extracting messages...")
    messages = extract_messages(requests)

    print("🔬 Extracting auth data...")
    auth_data = extract_auth(requests)

    # Save extracted data
    print("💾 Saving extracted data...")

    if agents:
        AGENTS_DATA_FILE.write_text(json.dumps(agents, indent=2, ensure_ascii=False))
    if users:
        USERS_DATA_FILE.write_text(json.dumps(users, indent=2, ensure_ascii=False))
    if leads:
        LEADS_DATA_FILE.write_text(json.dumps(leads, indent=2, ensure_ascii=False))
    if messages:
        MESSAGES_DATA_FILE.write_text(json.dumps(messages, indent=2, ensure_ascii=False))
    if auth_data:
        AUTH_DATA_FILE.write_text(json.dumps(auth_data, indent=2, ensure_ascii=False))

    # Full report
    full_report = {
        "total_requests": len(requests),
        "agents_count": len(agents),
        "users_count": len(users),
        "leads_count": len(leads),
        "messages_count": len(messages),
        "auth_events_count": len(auth_data),
        "agents": agents,
        "users": users,
        "leads": leads,
        "messages": messages,
        "auth": auth_data,
    }
    FULL_REPORT_FILE.write_text(json.dumps(full_report, indent=2, ensure_ascii=False))

    # Print report
    print_report(requests, agents, users, leads, messages, auth_data)


if __name__ == "__main__":
    main()
