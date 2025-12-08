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
	@cp data/discoveries.json data/discoveries.backup.json 2>/dev/null || echo "[]" > data/discoveries.backup.json
	@claude -p PROMPT.md --print --output-format json --dangerously-skip-permissions --setting-sources user > /dev/null
	@echo "Updated discoveries.json"
	@if ! python3 -c "import json; json.load(open('data/discoveries.json'))"; then \
		echo "ERROR: Invalid JSON in discoveries.json, restoring backup"; \
		cp data/discoveries.backup.json data/discoveries.json; \
	fi
	@echo "Merging curated + discoveries into database..."
	@duckdb data/data.duckdb < scripts/merge.sql
	@echo "Updated DuckDB database"
	@rm -f data/search-results.json data/discoveries.backup.json

clean:
	rm -rf docs/.observable/dist
