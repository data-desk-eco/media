# Media Mentions Tracker

**IMPORTANT:** Be FAST. Target: under 60 seconds. No commentary.

**Step 1:** Read `data/mentions.json` (existing entries - you MUST preserve ALL of these)
**Step 2:** Read `data/search-results.json` (new search results)
**Step 3:** Merge: Start with ALL existing entries, then add NEW entries from search results (skip duplicates by URL)
**Step 4:** Write merged list to `data/mentions.json`

**CRITICAL:** The output must contain every entry from the original mentions.json plus any new ones. Never drop existing entries.

**Output format:**
```json
[{"title": "...", "url": "...", "source": "...", "published": "YYYY-MM-DD", "added": "ISO timestamp"}, ...]
```

**Rules:**
- Keep all existing entries (some are manually added and won't appear in search)
- Add new entries from search results (dedupe by URL)
- Sort by published date descending
- Max 50 entries (trim oldest)
- Clean titles: remove trailing " - Source Name" if it duplicates source field

**Exclude these URLs:**
- https://news.google.com/rss/articles/CBMizgFBVV95cUxQdEt0bVVKU1cxVjZUb1E2NG1OTHU5YmRXbkxSb3BfcGVmanVKRTZYSEFsMzlaUEN6ZWZwWHQ2amhkT1JGNTNteWR0NTdRRmNlMUtKajFRR0lVN19GYkZ5ZXNGTVZVb2dQTU95dTduQ3Q0RWRXdVFBTFQzSTJRLWJiT20tWWpseDJZVV8xX1V3ZjNIT3p1OVFWSDZTR09tX3RKZGJadHFXc1kwbkNvMUI2Q1JHaER3OGZnR2NsOGhPYTNVTC0xNmJ6Y1JJR0xiZw?oc=5
