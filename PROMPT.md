# Media Mentions Tracker

**Your task:**
1. Read `data/mentions.json` - existing tracked mentions
2. Read `data/search-results.json` - new search results
3. Compare URLs to identify genuinely NEW mentions
4. Write the updated mentions list to `data/mentions.json` using the Write tool

**Output format for data/mentions.json:**
[
  {"title": "...", "url": "...", "source": "...", "published": "...", "added": "..."},
  ...
]

**Rules:**
- Only add genuinely new mentions (deduplicate by URL)
- Chronological order (newest first)
- Maximum 50 entries (trim oldest if needed)
- Each entry: title, url, source, published, added (ISO timestamp)
- Clean titles: Remove publication name from end of title if it duplicates the source field (e.g., "Article Title - Mongabay" → "Article Title" when source is "Mongabay")

**Exclusions:** Do not include mentions from the following URLs:
- https://news.google.com/rss/articles/CBMizgFBVV95cUxQdEt0bVVKU1cxVjZUb1E2NG1OTHU5YmRXbkxSb3BfcGVmanVKRTZYSEFsMzlaUEN6ZWZwWHQ2amhkT1JGNTNteWR0NTdRRmNlMUtKajFRR0lVN19GYkZ5ZXNGTVZVb2dQTU95dTduQ3Q0RWRXdVFBTFQzSTJRLWJiT20tWWpseDJZVV8xX1V3ZjNIT3p1OVFWSDZTR09tX3RKZGJadHFXc1kwbkNvMUI2Q1JHaER3OGZnR2NsOGhPYTNVTC0xNmJ6Y1JJR0xiZw?oc=5 (Africa Sustainability Matters - duplicate coverage)
