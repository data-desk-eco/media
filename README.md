# Data Desk Media Mentions

Automated tracking of news mentions and media coverage of Data Desk research.

## Overview

This repository tracks media mentions of Data Desk's investigative research on the global oil and gas industry. A GitHub Action runs weekly to search for new mentions and update the list automatically.

## How It Works

**Weekly automated workflow:**
1. Searches Google News RSS for "Data Desk"
2. Claude reviews results against existing list
3. Updates `data/mentions.json` with new entries
4. Commits changes and deploys Observable notebook

**Schedule:** Every Monday at noon UTC

## Files

- `data/mentions.json` - List of all tracked media mentions
- `mentions.md` - Formatted list with descriptions and images
- `scripts/search.sh` - Google News RSS search script
- `Makefile` - Orchestration
- `.github/workflows/media-mentions.yml` - GitHub Action

## Local Development

```bash
make        # Search and update mentions
```

## Observable Notebook

The `docs/` directory contains an Observable notebook that displays all Data Desk research projects. The notebook automatically rebuilds when mentions are updated.
