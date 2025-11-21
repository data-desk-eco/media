#!/bin/bash
set -euo pipefail

# Search for "Data Desk" mentions using Google News RSS feed
# This is a free API that doesn't require authentication

SEARCH_QUERY="Data+Desk"
RSS_URL="https://news.google.com/rss/search?q=${SEARCH_QUERY}&hl=en-US&gl=US&ceid=US:en"

# Fetch RSS feed and convert to JSON
curl -s "$RSS_URL" | \
  python3 -c '
import sys
import xml.etree.ElementTree as ET
import json
from datetime import datetime, UTC

# Parse RSS XML
tree = ET.parse(sys.stdin)
root = tree.getroot()

articles = []
for item in root.findall(".//item"):
    title = item.find("title")
    link = item.find("link")
    pub_date = item.find("pubDate")
    source = item.find("source")

    articles.append({
        "title": title.text if title is not None else "",
        "url": link.text if link is not None else "",
        "published": pub_date.text if pub_date is not None else "",
        "source": source.text if source is not None else "",
        "fetched_at": datetime.now(UTC).isoformat()
    })

print(json.dumps(articles, indent=2))
' > data/search-results.json

echo "Found $(jq length data/search-results.json) articles" >&2
