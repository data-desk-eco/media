#!/bin/bash
set -euo pipefail

# Search for "Data Desk" mentions using Google News RSS feed
# This is a free API that doesn't require authentication

SEARCH_QUERY="Data+Desk"
RSS_URL="https://news.google.com/rss/search?q=${SEARCH_QUERY}&hl=en-US&gl=US&ceid=US:en"

# Google News occasionally returns non-XML (rate-limit/consent HTML); retry a few
# times, and ask as a browser would — a bare curl agent gets blocked far sooner.
UA='Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0 Safari/537.36'
RSS_BODY=
for attempt in 1 2 3 4 5; do
  BODY=$(curl -s -A "$UA" "$RSS_URL")
  if [[ "${BODY:0:50}" == *"<?xml"* ]]; then
    RSS_BODY=$BODY
    break
  fi
  echo "search.sh: attempt $attempt returned non-XML, retrying..." >&2
  sleep $((attempt * 5))
done

if [ -z "$RSS_BODY" ]; then
  echo "search.sh: google news served no XML in 5 attempts — it rate-limits CI runner IPs." >&2
  echo "search.sh: leaving discoveries untouched; re-run the job to try again." >&2
  exit 1
fi

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
