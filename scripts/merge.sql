CREATE OR REPLACE TABLE mentions AS
SELECT title, url, source, published, added FROM read_json('data/curated.json');

INSERT INTO mentions
SELECT title, url, source, published, added
FROM read_json('data/discoveries.json',
    columns={title: 'VARCHAR', url: 'VARCHAR', source: 'VARCHAR', published: 'DATE', added: 'VARCHAR'})
WHERE url NOT IN (SELECT url FROM mentions);

CREATE OR REPLACE TABLE mentions AS SELECT * FROM mentions ORDER BY published DESC;
