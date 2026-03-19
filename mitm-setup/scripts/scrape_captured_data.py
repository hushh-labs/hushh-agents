#!/usr/bin/env python3
"""
🕵️ Scrape & Analyze ALL Captured MITM Traffic
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Extracts Yelp search results, business data, agent info,
and downloads all captured images.
"""

import json
import os
import re
import sys
import urllib.request
import urllib.error
from pathlib import Path
from datetime import datetime

CAPTURES_DIR = Path(__file__).parent.parent / "captures"
IMAGES_DIR = CAPTURES_DIR / "downloaded_images"
REPORT_FILE = CAPTURES_DIR / "scrape_report.json"
REPORT_MD = CAPTURES_DIR / "scrape_report.md"

API_LOG = CAPTURES_DIR / "api_requests.jsonl"
YELP_LOG = CAPTURES_DIR / "yelp_traffic.jsonl"
SEARCH_HITS_LOG = CAPTURES_DIR / "search_hits.jsonl"


def load_jsonl(filepath):
    """Load a JSONL file"""
    entries = []
    if not filepath.exists():
        return entries
    with open(filepath, "r") as f:
        for line in f:
            line = line.strip()
            if line:
                try:
                    entries.append(json.loads(line))
                except json.JSONDecodeError:
                    pass
    return entries


def extract_image_urls(entries):
    """Extract all image URLs from captured traffic"""
    image_urls = []
    image_extensions = ('.jpg', '.jpeg', '.png', '.gif', '.webp', '.svg', '.bmp')
    
    for entry in entries:
        url = entry.get("url", "")
        path = entry.get("path", "")
        host = entry.get("host", "")
        
        # Check if URL is an image request
        path_lower = path.lower().split("?")[0]
        if any(path_lower.endswith(ext) for ext in image_extensions):
            image_urls.append({
                "url": url,
                "host": host,
                "path": path,
                "category": entry.get("category", ""),
                "status": entry.get("response", {}).get("status_code", ""),
                "type": "direct_image"
            })
        
        # Check response bodies for image URLs
        res_body = entry.get("response", {}).get("body")
        if res_body and isinstance(res_body, (dict, list)):
            body_str = json.dumps(res_body)
            # Find Yelp CDN image URLs
            yelp_img_pattern = r'https?://[^\s"\']+?(?:\.jpg|\.jpeg|\.png|\.gif|\.webp)'
            found_urls = re.findall(yelp_img_pattern, body_str)
            for img_url in found_urls:
                img_url = img_url.replace("\\u002F", "/").replace("\\/", "/")
                image_urls.append({
                    "url": img_url,
                    "host": host,
                    "path": path,
                    "category": entry.get("category", ""),
                    "type": "embedded_in_response"
                })
    
    # Deduplicate
    seen = set()
    unique_images = []
    for img in image_urls:
        if img["url"] not in seen:
            seen.add(img["url"])
            unique_images.append(img)
    
    return unique_images


def extract_yelp_search_data(entries):
    """Extract Yelp search results and business data"""
    search_results = []
    business_data = []
    autocomplete_data = []
    graphql_data = []
    
    for entry in entries:
        path = entry.get("path", "")
        host = entry.get("host", "")
        method = entry.get("method", "")
        res_body = entry.get("response", {}).get("body")
        req_body = entry.get("request", {}).get("body")
        
        if "yelp" not in host.lower():
            continue
        
        # Search results
        if "/search" in path:
            search_results.append({
                "url": entry.get("url", ""),
                "method": method,
                "request_body": req_body,
                "response_body": res_body,
                "status": entry.get("response", {}).get("status_code"),
                "timestamp": entry.get("timestamp", "")
            })
        
        # Business presentation/profile
        elif "/business" in path:
            business_data.append({
                "url": entry.get("url", ""),
                "method": method,
                "request_body": req_body,
                "response_body": res_body,
                "status": entry.get("response", {}).get("status_code"),
                "timestamp": entry.get("timestamp", "")
            })
        
        # Autocomplete/Suggestions
        elif "/suggest" in path or "/autocomplete" in path:
            autocomplete_data.append({
                "url": entry.get("url", ""),
                "method": method,
                "response_body": res_body,
                "timestamp": entry.get("timestamp", "")
            })
        
        # GraphQL
        elif "/gql" in path:
            graphql_data.append({
                "url": entry.get("url", ""),
                "method": method,
                "request_body": req_body,
                "response_body": res_body,
                "status": entry.get("response", {}).get("status_code"),
                "timestamp": entry.get("timestamp", "")
            })
    
    return {
        "search_results": search_results,
        "business_data": business_data,
        "autocomplete_data": autocomplete_data,
        "graphql_data": graphql_data
    }


def extract_all_yelp_api_endpoints(entries):
    """Extract all unique Yelp API endpoints with details"""
    endpoints = {}
    for entry in entries:
        host = entry.get("host", "")
        if "yelp" not in host.lower():
            continue
        
        method = entry.get("method", "")
        path = entry.get("path", "").split("?")[0]
        key = f"{method} {path}"
        
        if key not in endpoints:
            endpoints[key] = {
                "method": method,
                "path": path,
                "full_url": entry.get("url", ""),
                "host": host,
                "count": 0,
                "statuses": [],
                "sample_request": entry.get("request", {}).get("body"),
                "sample_response": entry.get("response", {}).get("body"),
                "headers": entry.get("request", {}).get("headers", {}),
            }
        endpoints[key]["count"] += 1
        status = entry.get("response", {}).get("status_code")
        if status and status not in endpoints[key]["statuses"]:
            endpoints[key]["statuses"].append(status)
    
    return endpoints


def download_images(image_urls, max_images=100):
    """Download images to local directory"""
    IMAGES_DIR.mkdir(exist_ok=True)
    downloaded = []
    failed = []
    
    for i, img in enumerate(image_urls[:max_images]):
        url = img["url"]
        
        # Create filename from URL
        url_path = url.split("?")[0]
        ext = os.path.splitext(url_path)[1] or ".jpg"
        if ext not in ('.jpg', '.jpeg', '.png', '.gif', '.webp', '.svg', '.bmp'):
            ext = ".jpg"
        
        # Create descriptive filename
        if "bphoto" in url or "photo" in url:
            # Yelp business photo
            photo_id = url_path.split("/")[-2] if "/o.jpg" in url or "/258s.jpg" in url or "/60s.jpg" in url or "/ms.jpg" in url else url_path.split("/")[-1].split(".")[0]
            filename = f"yelp_biz_photo_{i:03d}_{photo_id[:20]}{ext}"
        elif "businessregularlogo" in url:
            filename = f"yelp_biz_logo_{i:03d}{ext}"
        elif "yelpcdn" in url:
            filename = f"yelp_cdn_{i:03d}{ext}"
        elif "googleapis" in url or "googleusercontent" in url:
            filename = f"google_{i:03d}{ext}"
        else:
            filename = f"image_{i:03d}{ext}"
        
        filepath = IMAGES_DIR / filename
        
        try:
            req = urllib.request.Request(url, headers={
                "User-Agent": "Yelp/26.9.0 CFNetwork/3860.400.51 Darwin/25.3.0",
                "Accept": "image/*,*/*"
            })
            with urllib.request.urlopen(req, timeout=10) as response:
                data = response.read()
                filepath.write_bytes(data)
                downloaded.append({
                    "filename": filename,
                    "url": url,
                    "size_bytes": len(data),
                    "type": img.get("type", ""),
                    "category": img.get("category", "")
                })
                print(f"  ✅ Downloaded: {filename} ({len(data)} bytes)")
        except Exception as e:
            failed.append({
                "filename": filename,
                "url": url,
                "error": str(e)
            })
            print(f"  ❌ Failed: {filename} — {e}")
    
    return downloaded, failed


def generate_markdown_report(summary, yelp_data, endpoints, images_downloaded, images_failed, all_entries, yelp_entries):
    """Generate a detailed markdown report"""
    md = []
    md.append("# 🕵️ MITM Capture Report — Yelp RIagents Search")
    md.append(f"\n**Generated:** {datetime.now().isoformat()}")
    md.append(f"\n**Session:** {summary.get('session_start', 'N/A')} → {summary.get('last_updated', 'N/A')}")
    md.append("")
    
    # Overview
    md.append("## 📊 Capture Overview")
    md.append(f"| Metric | Value |")
    md.append(f"|---|---|")
    md.append(f"| Total Requests | {summary.get('total_requests', 0)} |")
    md.append(f"| Yelp Requests | {summary.get('yelp_requests', 0)} |")
    md.append(f"| Search Keyword Hits | {summary.get('search_keyword_hits', 0)} |")
    md.append(f"| Unique Auth Tokens | {summary.get('unique_tokens', 0)} |")
    md.append(f"| Images Downloaded | {len(images_downloaded)} |")
    md.append(f"| Images Failed | {len(images_failed)} |")
    md.append("")
    
    # Domain breakdown
    md.append("## 🌐 Domain Breakdown")
    md.append("| Domain | Requests |")
    md.append("|---|---|")
    for domain, count in sorted(summary.get("domain_counts", {}).items(), key=lambda x: x[1], reverse=True):
        md.append(f"| {domain} | {count} |")
    md.append("")
    
    # Yelp API Endpoints
    md.append("## 🔍 Yelp API Endpoints Discovered")
    md.append("| Method | Path | Count | Status |")
    md.append("|---|---|---|---|")
    for key, ep in sorted(endpoints.items()):
        md.append(f"| {ep['method']} | `{ep['path']}` | {ep['count']} | {ep['statuses']} |")
    md.append("")
    
    # Search Results
    md.append("## 🔎 Search Results")
    for i, sr in enumerate(yelp_data["search_results"]):
        md.append(f"\n### Search #{i+1}")
        md.append(f"- **URL:** `{sr['url'][:200]}`")
        md.append(f"- **Method:** {sr['method']}")
        md.append(f"- **Status:** {sr['status']}")
        if sr.get("request_body"):
            md.append(f"- **Request Body:**")
            body_str = json.dumps(sr["request_body"], indent=2, ensure_ascii=False) if isinstance(sr["request_body"], dict) else str(sr["request_body"])
            md.append(f"```json\n{body_str[:3000]}\n```")
        if sr.get("response_body"):
            md.append(f"- **Response Body:**")
            body_str = json.dumps(sr["response_body"], indent=2, ensure_ascii=False) if isinstance(sr["response_body"], dict) else str(sr["response_body"])
            md.append(f"```json\n{body_str[:5000]}\n```")
    md.append("")
    
    # Business Data
    md.append("## 🏢 Business / Agent Data")
    for i, bd in enumerate(yelp_data["business_data"]):
        md.append(f"\n### Business #{i+1}")
        md.append(f"- **URL:** `{bd['url'][:200]}`")
        md.append(f"- **Method:** {bd['method']}")
        md.append(f"- **Status:** {bd['status']}")
        if bd.get("request_body"):
            body_str = json.dumps(bd["request_body"], indent=2, ensure_ascii=False) if isinstance(bd["request_body"], dict) else str(bd["request_body"])
            md.append(f"- **Request:**\n```json\n{body_str[:3000]}\n```")
        if bd.get("response_body"):
            body_str = json.dumps(bd["response_body"], indent=2, ensure_ascii=False) if isinstance(bd["response_body"], dict) else str(bd["response_body"])
            md.append(f"- **Response:**\n```json\n{body_str[:10000]}\n```")
    md.append("")
    
    # GraphQL Data
    md.append("## 📡 GraphQL Queries")
    for i, gql in enumerate(yelp_data["graphql_data"]):
        md.append(f"\n### GraphQL #{i+1}")
        md.append(f"- **URL:** `{gql['url'][:200]}`")
        if gql.get("request_body"):
            body_str = json.dumps(gql["request_body"], indent=2, ensure_ascii=False) if isinstance(gql["request_body"], dict) else str(gql["request_body"])
            md.append(f"- **Query:**\n```json\n{body_str[:5000]}\n```")
        if gql.get("response_body"):
            body_str = json.dumps(gql["response_body"], indent=2, ensure_ascii=False) if isinstance(gql["response_body"], dict) else str(gql["response_body"])
            md.append(f"- **Response:**\n```json\n{body_str[:10000]}\n```")
    md.append("")
    
    # Autocomplete
    md.append("## 🔤 Autocomplete / Suggestions")
    for i, ac in enumerate(yelp_data["autocomplete_data"]):
        md.append(f"\n### Suggestion #{i+1}")
        md.append(f"- **URL:** `{ac['url'][:200]}`")
        if ac.get("response_body"):
            body_str = json.dumps(ac["response_body"], indent=2, ensure_ascii=False) if isinstance(ac["response_body"], dict) else str(ac["response_body"])
            md.append(f"- **Response:**\n```json\n{body_str[:3000]}\n```")
    md.append("")
    
    # Downloaded Images
    md.append("## 🖼️ Downloaded Images")
    md.append(f"\nTotal: {len(images_downloaded)} images saved to `mitm-setup/captures/downloaded_images/`\n")
    md.append("| # | Filename | Size | Source |")
    md.append("|---|---|---|---|")
    for i, img in enumerate(images_downloaded):
        size_kb = img['size_bytes'] / 1024
        md.append(f"| {i+1} | `{img['filename']}` | {size_kb:.1f} KB | {img['category']} |")
    md.append("")
    
    return "\n".join(md)


def main():
    print("🕵️  Scraping all captured MITM traffic...")
    print(f"   Captures dir: {CAPTURES_DIR}")
    print()
    
    # Load data
    print("📂 Loading captured data...")
    all_entries = load_jsonl(API_LOG)
    yelp_entries = load_jsonl(YELP_LOG)
    search_hits = load_jsonl(SEARCH_HITS_LOG)
    
    summary = {}
    if (CAPTURES_DIR / "session_summary.json").exists():
        summary = json.loads((CAPTURES_DIR / "session_summary.json").read_text())
    
    print(f"   All entries: {len(all_entries)}")
    print(f"   Yelp entries: {len(yelp_entries)}")
    print(f"   Search hits: {len(search_hits)}")
    print()
    
    # Extract Yelp data
    print("🔍 Extracting Yelp search & business data...")
    yelp_data = extract_yelp_search_data(all_entries)
    print(f"   Search results: {len(yelp_data['search_results'])}")
    print(f"   Business data: {len(yelp_data['business_data'])}")
    print(f"   Autocomplete: {len(yelp_data['autocomplete_data'])}")
    print(f"   GraphQL: {len(yelp_data['graphql_data'])}")
    print()
    
    # Extract endpoints
    print("📡 Extracting Yelp API endpoints...")
    endpoints = extract_all_yelp_api_endpoints(all_entries)
    print(f"   Unique endpoints: {len(endpoints)}")
    print()
    
    # Extract image URLs
    print("🖼️  Extracting image URLs...")
    image_urls = extract_image_urls(all_entries)
    print(f"   Found {len(image_urls)} unique image URLs")
    print()
    
    # Download images
    print("⬇️  Downloading images...")
    downloaded, failed = download_images(image_urls, max_images=100)
    print(f"\n   Downloaded: {len(downloaded)}")
    print(f"   Failed: {len(failed)}")
    print()
    
    # Generate report
    print("📝 Generating report...")
    report_md = generate_markdown_report(
        summary, yelp_data, endpoints, 
        downloaded, failed, all_entries, yelp_entries
    )
    REPORT_MD.write_text(report_md)
    print(f"   Markdown report: {REPORT_MD}")
    
    # JSON report
    report_json = {
        "generated_at": datetime.now().isoformat(),
        "session_summary": summary,
        "yelp_data": yelp_data,
        "yelp_endpoints": {k: {**v, "sample_response": str(v.get("sample_response", ""))[:500]} for k, v in endpoints.items()},
        "images": {
            "total_found": len(image_urls),
            "downloaded": len(downloaded),
            "failed": len(failed),
            "downloaded_files": downloaded,
            "failed_files": failed,
            "all_urls": [img["url"] for img in image_urls]
        }
    }
    REPORT_FILE.write_text(json.dumps(report_json, indent=2, ensure_ascii=False, default=str))
    print(f"   JSON report: {REPORT_FILE}")
    print()
    print("✅ Done! All data scraped and saved.")


if __name__ == "__main__":
    main()
