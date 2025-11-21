# Media Mentions Tracker

**CRITICAL OUTPUT REQUIREMENT:**
Your output will be redirected directly to a JSON file. Output ONLY raw JSON - no markdown, no code blocks, no explanations, no thinking, no commentary whatsoever. If you output anything other than valid JSON, the system will break.

**Your task:**
1. Read `data/mentions.json` - existing tracked mentions
2. Read `data/search-results.json` - new search results
3. Compare URLs to identify genuinely NEW mentions
4. Output updated JSON array with new entries at the top

**OUTPUT FORMAT:** Only output this exact structure - nothing else:
[
  {"title": "...", "url": "...", "source": "...", "published": "...", "added": "..."},
  ...
]

**Rules:**
- Only add genuinely new mentions (deduplicate by URL)
- Chronological order (newest first)
- Maximum 50 entries (trim oldest if needed)
- Each entry: title, url, source, published, added (ISO timestamp)
