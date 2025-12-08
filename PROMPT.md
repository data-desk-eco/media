# Media Mentions Tracker

**BE FAST.** Target: under 60 seconds. No commentary.

## Context

Data Desk (data-desk-eco) investigates environmental/climate issues: oil/gas practices, fossil fuel supply chains, pollution, corporate accountability, green financing.

## Task

1. Read `data/mentions.json` (existing - PRESERVE ALL)
2. Read `data/search-results.json` (new Google News results)
3. Filter new results for relevance (see below)
4. Add ONLY relevant new entries (dedupe by URL)
5. Write to `data/mentions.json`

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
- Reference our oil/gas/fossil fuel investigations
- Are from outlets we work with (The Guardian, The Examination, etc.)

**When unsure, EXCLUDE.**

## Output Format

Valid JSON array:
```json
[{"title": "...", "url": "...", "source": "...", "published": "YYYY-MM-DD", "added": "ISO timestamp"}, ...]
```

Sort by published date descending. Max 50 entries. Clean titles (remove redundant source suffixes).
