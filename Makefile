.PHONY: build preview data clean

build:
	yarn build

preview:
	yarn preview

data:
	@mkdir -p data
	@echo "Searching for Data Desk mentions..."
	@scripts/search.sh
	@echo "Processing mentions with Claude..."
	@claude -p PROMPT.md --print --dangerously-skip-permissions > data/mentions.json.tmp
	@if jq empty data/mentions.json.tmp 2>/dev/null; then \
		mv data/mentions.json.tmp data/mentions.json; \
		echo "Updated mentions.json"; \
		cat data/mentions.json | duckdb data/data.duckdb "CREATE OR REPLACE TABLE mentions AS SELECT * FROM read_json('/dev/stdin')"; \
		echo "Updated DuckDB database"; \
	else \
		rm -f data/mentions.json.tmp; \
		echo "Failed: invalid JSON output"; \
		exit 1; \
	fi
	@rm -f data/search-results.json

clean:
	rm -rf docs/.observable/dist
