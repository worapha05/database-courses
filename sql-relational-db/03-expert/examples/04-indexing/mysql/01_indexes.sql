-- =============================================================================
-- 04-indexing / MySQL 8 — B-Tree, composite, covering-ish, FULLTEXT
-- =============================================================================
SET NAMES utf8mb4;


DROP TABLE IF EXISTS articles;


CREATE TABLE articles (id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
                                                                  author_id INT NOT NULL,
                                                                                title VARCHAR(200) NOT NULL,
                                                                                                   BODY TEXT NOT NULL,
                                                                                                             status VARCHAR(20) NOT NULL,
                                                                                                                                published_at DATETIME(6) NULL,
                                                                                                                                                         deleted_at DATETIME(6) NULL,
                                                                                                                                                                                FULLTEXT KEY ft_articles_title_body (title, BODY)) ENGINE = InnoDB DEFAULT
CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;


INSERT INTO articles (author_id, title, BODY, status, published_at, deleted_at)
VALUES (1, 'PostgreSQL Indexing', 'B-Tree GIN GiST and BRIN explained', 'published', DATE_SUB(NOW(6), INTERVAL 2 DAY), NULL),
       (1, 'Draft Notes', 'temporary thoughts', 'draft', NULL, NULL),
       (2, 'MySQL Fulltext', 'FULLTEXT indexes on InnoDB', 'published', DATE_SUB(NOW(6), INTERVAL 1 DAY), NULL),
       (2, 'Old Deleted', 'should not appear', 'published', DATE_SUB(NOW(6), INTERVAL 10 DAY), NOW(6));


CREATE INDEX ix_articles_author_published ON articles (author_id, published_at DESC);


CREATE INDEX ix_articles_status_published ON articles (status, published_at DESC);


CREATE INDEX ix_articles_status_title_published ON articles (status, published_at DESC, title);

EXPLAIN ANALYZE
SELECT id,
       title,
       published_at
FROM articles
WHERE deleted_at IS NULL
  AND status = 'published'
ORDER BY published_at DESC
LIMIT 20;

EXPLAIN ANALYZE
SELECT id,
       title,
       MATCH(title, BODY) AGAINST ('postgres index' IN NATURAL LANGUAGE MODE) AS score
FROM articles
WHERE MATCH(title, BODY) AGAINST ('postgres index' IN NATURAL LANGUAGE MODE)
  AND deleted_at IS NULL
ORDER BY score DESC;
