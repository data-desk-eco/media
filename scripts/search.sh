#!/bin/bash
set -euo pipefail

# Search for "Data Desk" mentions using Google News RSS feed
# This is a free API that doesn't require authentication

SEARCH_QUERY="Data+Desk"
RSS_URL="https://news.google.com/rss/search?q=${SEARCH_QUERY}&hl=en-US&gl=US&ceid=US:en"

# Google News occasionally returns non-XML (rate-limit/consent HTML); retry a few times
for attempt in 1 2 3 4 5; do
  RSS_BODY=$(curl -s "$RSS_URL")
  if [[ "${RSS_BODY:0:50}" == *"<?xml"* ]]; then
    break
  fi
  echo "search.sh: attempt $attempt returned non-XML, retrying..." >&2
  sleep $((attempt * 3))
done

printf '%s' "$RSS_BODY" | \
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

if [ "$(jq length data/search-results.json)" -eq 0 ]; then
  echo "search.sh: zero articles parsed — refusing to overwrite curated discoveries" >&2
  exit 1
fi
