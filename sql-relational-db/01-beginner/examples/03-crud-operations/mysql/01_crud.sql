-- =============================================================================
-- 03-crud-operations / MySQL 8
-- CRUD ที่รัดกุม: ระบุคอลัมน์, WHERE ชัด, soft delete
-- หมายเหตุ: MySQL ไม่มี RETURNING — ใช้ last_insert_id() / SELECT ซ้ำ
-- =============================================================================
SET NAMES utf8mb4;


SET FOREIGN_KEY_CHECKS = 0;


DROP TABLE IF EXISTS articles;


DROP TABLE IF EXISTS authors;


SET FOREIGN_KEY_CHECKS = 1;


CREATE TABLE authors (id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
                                                  display_name VARCHAR(120) NOT NULL,
                                                                            email VARCHAR(255) NOT NULL,
                                                                                               PRIMARY KEY (id), CONSTRAINT uq_authors_email UNIQUE (email)) ENGINE = InnoDB DEFAULT
CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;


CREATE TABLE articles
  (id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
                               author_id BIGINT UNSIGNED NOT NULL,
                                                         slug VARCHAR(160) NOT NULL,
                                                                           title VARCHAR(200) NOT NULL,
                                                                                              BODY TEXT NOT NULL,
                                                                                                        status VARCHAR(20) NOT NULL DEFAULT 'draft',
                                                                                                                                            published_at DATETIME(6) NULL,
                                                                                                                                                                     deleted_at DATETIME(6) NULL,
                                                                                                                                                                                            created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
                                                                                                                                                                                                                                    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
                                                                                                                                                                                                                                                                                                           PRIMARY KEY (id), CONSTRAINT fk_articles_author
   FOREIGN KEY (author_id) REFERENCES authors (id),
                                      CONSTRAINT uq_articles_slug UNIQUE (slug), CONSTRAINT ck_articles_status CHECK (status IN ('draft',
                                                                                                                                 'published',
                                                                                                                                 'archived'))) ENGINE = InnoDB DEFAULT
CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;


INSERT INTO authors (display_name, email)
VALUES ('Kai Writer', 'kai@example.com');


SET @author_id = LAST_INSERT_ID();


SELECT @author_id AS author_id;


INSERT INTO articles (author_id, slug, title, BODY, status, published_at)
VALUES (@author_id, 'hello-sql', 'Hello SQL', 'Intro body', 'published', UTC_TIMESTAMP(6)),
       (@author_id, 'draft-notes', 'Draft Notes', 'WIP', 'draft', NULL);


SELECT a.id,
       a.slug,
       a.title,
       a.status,
       au.display_name AS author
FROM articles a
JOIN authors au ON au.id = a.author_id
WHERE a.deleted_at IS NULL
  AND a.status = 'published'
ORDER BY a.published_at DESC;


UPDATE articles
SET title = 'Hello SQL (Revised)',
    BODY = 'Intro body — revised'
WHERE slug = 'hello-sql'
  AND deleted_at IS NULL;


SELECT id,
       title,
       updated_at
FROM articles
WHERE slug = 'hello-sql';


UPDATE articles
SET deleted_at = UTC_TIMESTAMP(6),
    status = 'archived'
WHERE slug = 'draft-notes';


SELECT status,
       COUNT(*) AS cnt
FROM articles
WHERE deleted_at IS NULL
GROUP BY status;
