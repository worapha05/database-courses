-- =============================================================================
-- 04-indexing / PostgreSQL — B-Tree, composite, partial, covering, FTS
-- =============================================================================

DROP TABLE IF EXISTS articles CASCADE;


CREATE TABLE articles (id BIGSERIAL PRIMARY KEY,
                                    author_id INT NOT NULL,
                                                  title VARCHAR(200) NOT NULL,
                                                                     BODY TEXT NOT NULL,
                                                                               status VARCHAR(20) NOT NULL,
                                                                                                  published_at TIMESTAMPTZ,
                                                                                                  deleted_at TIMESTAMPTZ,
                                                                                                  search_vector
                       TSVECTOR);


INSERT INTO articles (author_id, title, BODY, status, published_at, deleted_at)
VALUES (1, 'PostgreSQL Indexing', 'B-Tree GIN GiST and BRIN explained', 'published', NOW() - INTERVAL '2 days', NULL),
       (1, 'Draft Notes', 'temporary thoughts', 'draft', NULL, NULL),
       (2, 'MySQL Fulltext', 'FULLTEXT indexes on InnoDB', 'published', NOW() - INTERVAL '1 day', NULL),
       (2, 'Old Deleted', 'should not appear', 'published', NOW() - INTERVAL '10 days', NOW());


UPDATE articles
SET search_vector = setweight(to_tsvector('english', coalesce(title, '')), 'A') || setweight(to_tsvector('english', coalesce(BODY, '')), 'B');

-- Composite B-Tree สำหรับลิสต์ตาม author + เวลา

CREATE INDEX ix_articles_author_published ON articles (author_id, published_at DESC);

-- Partial: เฉพาะแถวที่ยังไม่ลบและเผยแพร่แล้ว

CREATE INDEX ix_articles_published_active ON articles (published_at DESC)
WHERE deleted_at IS NULL
  AND status = 'published';

-- Covering / index-only friendly (PG 11+ INCLUDE)

CREATE INDEX ix_articles_status_covering ON articles (status) INCLUDE (title,
                                                                       published_at)
WHERE deleted_at IS NULL;

-- Full-text GIN

CREATE INDEX ix_articles_fts ON articles USING GIN (search_vector);

-- ตัวอย่าง query ที่ควรใช้ index เหล่านี้
EXPLAIN (ANALYZE,
         BUFFERS)
SELECT id,
       title,
       published_at
FROM articles
WHERE deleted_at IS NULL
  AND status = 'published'
ORDER BY published_at DESC
LIMIT 20;

EXPLAIN (ANALYZE,
         BUFFERS)
SELECT id,
       title,
       ts_rank(search_vector, query) AS rank
FROM articles,
     plainto_tsquery('english', 'postgres index') query
WHERE search_vector @@ query
  AND deleted_at IS NULL
ORDER BY rank DESC;
