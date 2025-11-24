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
	@claude -p PROMPT.md --print --output-format json --dangerously-skip-permissions --setting-sources user > /dev/null
	@echo "Updated mentions.json"
	@cat data/mentions.json | duckdb data/data.duckdb "CREATE OR REPLACE TABLE mentions AS SELECT * FROM read_json('/dev/stdin')"
	@echo "Updated DuckDB database"
	@rm -f data/search-results.json

clean:
	rm -rf docs/.observable/dist
