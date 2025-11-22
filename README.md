# Data Desk Media Mentions

Automated tracking of news mentions and media coverage of Data Desk research.

## Overview

This repository tracks media mentions of Data Desk's investigative research on the global oil and gas industry. A GitHub Action runs weekly to search for new mentions and update the list automatically.

## How It Works

**Daily automated workflow:**
1. Downloads shared template files from main repo
2. Searches Google News RSS for "Data Desk"
3. Claude reviews results against existing list
4. Updates `data/mentions.json` with new entries
5. Commits changes and deploys Observable notebook

**Schedule:** Daily at 6am UTC

## Files

- `data/mentions.json` - List of all tracked media mentions
- `docs/index.html` - Observable notebook source
- `scripts/search.sh` - Google News RSS search script
- `PROMPT.md` - Instructions for Claude to process mentions
- `Makefile` - Build orchestration
- `.github/workflows/deploy.yml` - GitHub Action (self-updating)

## Local Development

```bash
make data      # Search and update mentions
make preview   # Preview notebook locally
make build     # Build notebook for deployment
```

## Observable Notebook

The `docs/` directory contains an Observable notebook that displays all Data Desk research projects. The notebook automatically rebuilds when mentions are updated.
