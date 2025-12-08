.PHONY: build preview etl data clean

build: clean
	yarn build

preview:
	yarn preview

etl: data

data:
	@scripts/search.sh
	@claude -p PROMPT.md --print --output-format json --dangerously-skip-permissions --setting-sources user > /dev/null
	@duckdb data/data.duckdb < scripts/merge.sql
	@rm -f data/search-results.json

clean:
	rm -rf docs/.observable/dist
