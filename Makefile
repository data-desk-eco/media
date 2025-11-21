include .env

CLAUDE := claude

all: data/mentions.json

data/mentions.json: $(RAW_DATA) CLAUDE.md
	@cat CLAUDE.md | $(CLAUDE) --print --dangerously-skip-permissions > $@.tmp
	@if jq empty $@.tmp 2>/dev/null; then \
		mv $@.tmp $@; \
		echo "Updated mentions.json"; \
	else \
		rm -f $@.tmp; \
		echo "Failed: invalid JSON output"; \
	fi
	@rm -f $(RAW_DATA)

$(RAW_DATA): scripts/search.sh
	@./$<

.PHONY: all
