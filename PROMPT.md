# Media Mentions Tracker

Be fast. No commentary.

## Context

Data Desk investigates environmental/climate issues: oil/gas, fossil fuels, pollution, corporate accountability, green financing.

## Task

1. Read `data/curated.json` (never modify)
2. Read `data/discoveries.json` (your additions)
3. Read `data/search-results.json` (new Google News results)
4. Add relevant new articles to discoveries (dedupe by URL)
5. Write to `data/discoveries.json`

## Relevance

**Exclude:** "The Trade Desk", "Opportunity Desk", "CBA Data Desk", "Tiny Desk", hotel/service desks, trading desks, generic "data desk" mentions.

**Include:** Articles citing Data Desk environmental research or from outlets we work with (Guardian, Examination, Bloomberg, Reuters, etc).

When unsure, exclude.

## Output

```json
[{"title": "...", "url": "...", "source": "...", "published": "YYYY-MM-DD", "added": "ISO timestamp"}, ...]
```
