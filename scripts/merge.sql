-- Merge curated.json and discoveries.json into mentions table
-- Curated entries take precedence (discoveries with same URL are excluded)

-- Load curated entries (always present)
CREATE OR REPLACE TABLE mentions AS
SELECT title, url, source, published, added
FROM read_json('data/curated.json');

-- Add discoveries if any exist (handle empty array gracefully)
INSERT INTO mentions
SELECT title, url, source, published, added
FROM read_json('data/discoveries.json',
    columns={title: 'VARCHAR', url: 'VARCHAR', source: 'VARCHAR', published: 'DATE', added: 'VARCHAR'})
WHERE url NOT IN (SELECT url FROM mentions);

-- Re-sort by date
CREATE OR REPLACE TABLE mentions AS
SELECT * FROM mentions ORDER BY published DESC;

SELECT count(*) || ' mentions in database' FROM mentions;
