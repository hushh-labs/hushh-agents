#!/usr/bin/env python3
"""
Build a structured JSON file with consistent data model for all captured agents.
Reads from scrape_report.json and outputs to Downloads folder.
"""

import json
import os
from datetime import datetime

SCRAPE_REPORT = os.path.join(os.path.dirname(__file__), '..', 'captures', 'scrape_report.json')
OUTPUT_PATH = os.path.expanduser('~/Downloads/hushh_agents_structured.json')


def build_photo_url(photo_obj):
    """Build full photo URL from Yelp photo object."""
    if not photo_obj:
        return None
    prefix = photo_obj.get('url_prefix', '')
    suffix = photo_obj.get('url_suffix', '')
    return f"{prefix}o{suffix}" if prefix else None


def build_photo_list(photos_array):
    """Build list of photo objects with consistent structure."""
    if not photos_array:
        return []
    result = []
    for p in photos_array:
        result.append({
            "id": p.get("id"),
            "url": f"{p.get('url_prefix', '')}o{p.get('url_suffix', '')}",
            "thumbnail_url": f"{p.get('url_prefix', '')}258s{p.get('url_suffix', '')}",
            "width": p.get("width"),
            "height": p.get("height"),
            "caption": p.get("caption"),
        })
    return result


def extract_services(biz):
    """Extract services list from service_offering."""
    so = biz.get('service_offering')
    if not so:
        return []
    return [s.get('name') for s in so.get('business_services', [])]


def extract_categories(biz):
    """Extract category names."""
    return [c.get('name') for c in biz.get('categories', [])]


def normalize_agent(biz, async_data=None):
    """Normalize a business object into a consistent agent data model."""
    # Merge async data if available
    if async_data and async_data.get('business'):
        async_biz = async_data['business']
        # Merge missing fields from async
        for key in async_biz:
            if key not in biz or biz[key] is None:
                biz[key] = async_biz[key]
        # Prefer async hours, url, etc.
        if async_biz.get('hours'):
            biz['hours'] = async_biz['hours']
        if async_biz.get('url'):
            biz['url'] = async_biz['url']
        if async_biz.get('display_url'):
            biz['display_url'] = async_biz['display_url']
        if async_biz.get('localized_hours'):
            biz['localized_hours'] = async_biz['localized_hours']
        if async_biz.get('from_this_business'):
            biz['from_this_business'] = async_biz['from_this_business']
        if async_biz.get('message_the_business'):
            biz['message_the_business'] = async_biz['message_the_business']
        if async_biz.get('call_to_action'):
            biz['call_to_action'] = async_biz['call_to_action']

    # Extract from_this_business
    ftb = biz.get('from_this_business', {}) or {}
    rep = ftb.get('representative', {}) or {}

    # Extract message_the_business
    mtb = biz.get('message_the_business', {}) or {}

    # Extract annotations
    annotations_raw = (async_data or {}).get('annotations', [])
    annotations = []
    for a in annotations_raw:
        annotations.append({
            "type": a.get("identifier", a.get("type")),
            "title": a.get("title", "").replace("<b>", "").replace("</b>", ""),
        })

    # Build consistent agent object
    agent = {
        "id": biz.get("id"),
        "name": biz.get("name"),
        "alias": biz.get("alias"),

        # Location
        "location": {
            "address1": biz.get("address1", ""),
            "address2": biz.get("address2", ""),
            "address3": biz.get("address3", ""),
            "city": biz.get("city", ""),
            "state": biz.get("state", ""),
            "zip": biz.get("zip", ""),
            "country": biz.get("country", "US"),
            "latitude": biz.get("latitude"),
            "longitude": biz.get("longitude"),
            "formatted_address": (biz.get("addresses", {}) or {}).get("primary_language", {}).get("long_form", ""),
            "short_address": (biz.get("addresses", {}) or {}).get("primary_language", {}).get("short_form", ""),
        },

        # Contact
        "contact": {
            "phone": biz.get("phone", ""),
            "formatted_phone": biz.get("localized_phone", ""),
            "website_url": biz.get("display_url") or biz.get("url", ""),
        },

        # Ratings & Reviews
        "ratings": {
            "average_rating": biz.get("unrounded_avg_rating", 0),
            "rounded_rating": biz.get("avg_rating", 0),
            "review_count": biz.get("review_count", 0),
        },

        # Categories & Services
        "categories": extract_categories(biz),
        "services": extract_services(biz),

        # Photos
        "photos": {
            "primary_photo_url": biz.get("photo_url") or build_photo_url(biz.get("primary_photo")),
            "photo_count": biz.get("photo_count", 0),
            "photo_list": build_photo_list(biz.get("photos", [])),
        },

        # Business Details
        "business_details": {
            "is_closed": biz.get("is_closed", False),
            "is_chain": biz.get("is_chain_business", False),
            "is_yelp_guaranteed": biz.get("is_yelp_guaranteed", False),
            "hours": biz.get("localized_hours", []),
            "year_established": ftb.get("year_established"),
            "specialties": ftb.get("specialties", ""),
            "history": ftb.get("history", ""),
        },

        # Representative / Owner
        "representative": {
            "name": rep.get("name", ""),
            "bio": rep.get("bio", ""),
            "role": rep.get("role", ""),
            "photo_url": build_photo_url(rep.get("photo")) if rep.get("photo") else None,
        },

        # Messaging / Contact Preferences
        "messaging": {
            "is_enabled": bool(mtb),
            "type": mtb.get("type", ""),
            "display_text": mtb.get("display", ""),
            "response_time": mtb.get("response_time", ""),
            "reply_rate": mtb.get("reply_rate", ""),
        },

        # Annotations / Highlights
        "annotations": annotations,

        # Yelp URLs
        "yelp_urls": {
            "business_url": f"https://www.yelp.com/biz/{biz.get('alias', '')}",
            "share_url": biz.get("share_url", ""),
        },
    }

    return agent


def main():
    # Load scrape report
    with open(SCRAPE_REPORT, 'r') as f:
        report = json.load(f)

    yelp_data = report.get('yelp_data', {})
    search_results = yelp_data.get('search_results', [])

    if not search_results:
        print("No search results found!")
        return

    # Get the main search response
    main_search = search_results[0]
    response = main_search.get('response_body', {})

    # Get data maps
    data_map = response.get('data_map', {})
    biz_map = data_map.get('business_search_result_id_map', {})
    ad_biz_map = data_map.get('ad_business_search_result_id_map', {})

    # Get async data if available
    async_data_map = {}
    if len(search_results) > 1:
        async_response = search_results[1].get('response_body', {})
        for item in async_response.get('business_search_results', []):
            biz_id = item.get('business', {}).get('id')
            if biz_id:
                async_data_map[biz_id] = item

    # Process all organic agents
    agents = []
    seen_ids = set()

    # Organic results (in order)
    business_list = response.get('search_response_context', {}).get('search_result', {}).get('business_list', [])
    for biz_entry in business_list:
        biz_id = biz_entry.get('id')
        if biz_id in seen_ids:
            continue
        seen_ids.add(biz_id)

        biz_data = biz_map.get(biz_id, {}).get('business', {})
        if not biz_data:
            continue

        async_data = async_data_map.get(biz_id)
        agent = normalize_agent(biz_data, async_data)
        agent['source'] = 'organic'
        agents.append(agent)

    # Ad results
    for biz_id, ad_data in ad_biz_map.items():
        if biz_id in seen_ids:
            continue
        seen_ids.add(biz_id)

        biz_data = ad_data.get('business', {})
        if not biz_data:
            continue

        async_data = async_data_map.get(biz_id)
        agent = normalize_agent(biz_data, async_data)
        agent['source'] = 'sponsored'
        agents.append(agent)

    # Build final output
    output = {
        "metadata": {
            "generated_at": datetime.now().isoformat(),
            "source": "Yelp MITM Capture",
            "search_query": "Registered Investment Advisor",
            "search_location": "Kirkland, WA 98033",
            "total_yelp_results": response.get('total', 0),
            "agents_captured": len(agents),
            "data_model_version": "1.0",
        },
        "data_model_schema": {
            "id": "string - Yelp encrypted business ID",
            "name": "string - Business name",
            "alias": "string - URL-friendly slug",
            "location": {
                "address1": "string",
                "address2": "string",
                "address3": "string",
                "city": "string",
                "state": "string",
                "zip": "string",
                "country": "string",
                "latitude": "number | null",
                "longitude": "number | null",
                "formatted_address": "string",
                "short_address": "string"
            },
            "contact": {
                "phone": "string",
                "formatted_phone": "string",
                "website_url": "string"
            },
            "ratings": {
                "average_rating": "number (0-5)",
                "rounded_rating": "number (0-5, in 0.5 steps)",
                "review_count": "number"
            },
            "categories": "string[] - Category names",
            "services": "string[] - Services offered",
            "photos": {
                "primary_photo_url": "string | null",
                "photo_count": "number",
                "photo_list": [{
                    "id": "string",
                    "url": "string - Full size URL",
                    "thumbnail_url": "string - 258px thumbnail",
                    "width": "number | null",
                    "height": "number | null",
                    "caption": "string | null"
                }]
            },
            "business_details": {
                "is_closed": "boolean",
                "is_chain": "boolean",
                "is_yelp_guaranteed": "boolean",
                "hours": "string[] - Formatted hours",
                "year_established": "number | null",
                "specialties": "string",
                "history": "string"
            },
            "representative": {
                "name": "string",
                "bio": "string",
                "role": "string",
                "photo_url": "string | null"
            },
            "messaging": {
                "is_enabled": "boolean",
                "type": "string",
                "display_text": "string",
                "response_time": "string",
                "reply_rate": "string"
            },
            "annotations": [{
                "type": "string",
                "title": "string"
            }],
            "yelp_urls": {
                "business_url": "string",
                "share_url": "string"
            },
            "source": "string - 'organic' | 'sponsored'"
        },
        "agents": agents
    }

    # Write to Downloads folder
    os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)
    with open(OUTPUT_PATH, 'w', encoding='utf-8') as f:
        json.dump(output, f, indent=2, ensure_ascii=False)

    print(f"✅ Structured JSON created: {OUTPUT_PATH}")
    print(f"📊 Total agents: {len(agents)}")
    print(f"   Organic: {sum(1 for a in agents if a['source'] == 'organic')}")
    print(f"   Sponsored: {sum(1 for a in agents if a['source'] == 'sponsored')}")
    print(f"\n📋 Data model fields per agent:")
    if agents:
        def count_fields(obj, prefix=""):
            count = 0
            for k, v in obj.items():
                if isinstance(v, dict):
                    count += count_fields(v, f"{prefix}{k}.")
                else:
                    count += 1
            return count
        print(f"   {count_fields(agents[0])} fields (consistent across all agents)")


if __name__ == '__main__':
    main()
