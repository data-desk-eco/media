CREATE OR REPLACE TABLE curated AS
SELECT title, url, source, published, added, image, description
FROM read_json('data/curated.json',
    columns={title: 'VARCHAR', url: 'VARCHAR', source: 'VARCHAR',
             published: 'DATE', added: 'VARCHAR',
             image: 'VARCHAR', description: 'VARCHAR'});

CREATE OR REPLACE TABLE discoveries AS
SELECT title, url, source, published, added
FROM read_json('data/discoveries.json',
    columns={title: 'VARCHAR', url: 'VARCHAR', source: 'VARCHAR',
             published: 'DATE', added: 'VARCHAR'})
WHERE url NOT IN (SELECT url FROM curated);

CREATE OR REPLACE TABLE metadata AS
SELECT url, og_title, og_description, og_image, og_site_name, final_url
FROM read_json('data/metadata.json',
    columns={url: 'VARCHAR', og_title: 'VARCHAR', og_description: 'VARCHAR',
             og_image: 'VARCHAR', og_site_name: 'VARCHAR',
             final_url: 'VARCHAR', error: 'VARCHAR', via: 'VARCHAR'});

CREATE OR REPLACE TABLE mentions AS
WITH combined AS (
    SELECT title, url, source, published, added, image, description FROM curated
    UNION ALL
    SELECT title, url, source, published, added, NULL AS image, NULL AS description
    FROM discoveries
)
SELECT
    c.title,
    c.url,
    c.source,
    c.published,
    c.added,
    COALESCE(c.image,       md.og_image)       AS image,
    COALESCE(c.description, md.og_description) AS description,
    COALESCE(md.og_title, c.title)             AS display_title
FROM combined c
LEFT JOIN metadata md ON c.url = md.url
ORDER BY c.published DESC;
