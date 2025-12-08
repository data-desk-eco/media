# Media Mentions Tracker

**BE FAST.** Target: under 60 seconds. No commentary.

## Context

Data Desk (data-desk-eco) investigates environmental/climate issues: oil/gas practices, fossil fuel supply chains, pollution, corporate accountability, green financing.

## Task

1. Read `data/curated.json` (hand-curated entries - NEVER modify this file)
2. Read `data/discoveries.json` (previously discovered entries)
3. Read `data/search-results.json` (new Google News results)
4. Filter new results for relevance (see below)
5. Add ONLY relevant NEW entries to discoveries (dedupe by URL against both curated and discoveries)
6. Write updated list to `data/discoveries.json`

## Relevance Filter - CRITICAL

**EXCLUDE** (not about Data Desk research):
- "The Trade Desk" (ad tech company)
- "Opportunity Desk" (grants website)
- "CBA Data Desk" / Consumer Bankers
- NPR "Tiny Desk"
- Hotel/service/help desk mentions
- Financial trading desk references
- Any generic "data" + "desk" coincidence

**INCLUDE** only articles that:
- Cite Data Desk environmental research
- Reference our oil/gas/fossil fuel/environmental investigations
- Are from outlets we work with (The Guardian, The Examination, Bloomberg, Reuters, etc.)

**When unsure, EXCLUDE.** Better to miss one than add noise.

## Output Format

Write valid JSON array to `data/discoveries.json`:
```json
[{"title": "...", "url": "...", "source": "...", "published": "YYYY-MM-DD", "added": "ISO timestamp"}, ...]
```

Sort by published date descending.
