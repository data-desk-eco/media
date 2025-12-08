.PHONY: build preview etl data clean

build: clean
	yarn build

preview:
	yarn preview

etl: data  # No heavy ETL step, just alias to data
data:
	@mkdir -p data
	@echo "Searching for Data Desk mentions..."
	@scripts/search.sh
	@echo "Processing mentions with Claude..."
	@cp data/mentions.json data/mentions.backup.json 2>/dev/null || true
	@claude -p PROMPT.md --print --output-format json --dangerously-skip-permissions --setting-sources user > /dev/null
	@echo "Updated mentions.json"
	@if ! python3 -c "import json; json.load(open('data/mentions.json'))"; then \
		echo "ERROR: Invalid JSON in mentions.json, restoring backup"; \
		cp data/mentions.backup.json data/mentions.json 2>/dev/null || true; \
	fi
	@cat data/mentions.json | duckdb data/data.duckdb "CREATE OR REPLACE TABLE mentions AS SELECT * FROM read_json('/dev/stdin')"
	@echo "Updated DuckDB database"
	@rm -f data/search-results.json data/mentions.backup.json

clean:
	rm -rf docs/.observable/dist
