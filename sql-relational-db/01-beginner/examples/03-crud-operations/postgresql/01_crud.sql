-- =============================================================================
-- 03-crud-operations / PostgreSQL
-- CRUD ที่รัดกุม: ระบุคอลัมน์, WHERE ชัด, soft delete, RETURNING
-- =============================================================================

DROP TABLE IF EXISTS articles CASCADE;


DROP TABLE IF EXISTS authors CASCADE;


CREATE TABLE authors (id BIGSERIAL PRIMARY KEY,
                                   display_name VARCHAR(120) NOT NULL,
                                                             email VARCHAR(255) NOT NULL UNIQUE);


CREATE TABLE articles (id BIGSERIAL PRIMARY KEY,
                                    author_id BIGINT NOT NULL REFERENCES authors (id),
                                                                         slug VARCHAR(160) NOT NULL,
                                                                                           title VARCHAR(200) NOT NULL,
                                                                                                              BODY TEXT NOT NULL DEFAULT '',
                                                                                                                                         status VARCHAR(20) NOT NULL DEFAULT 'draft',
                                                                                                                                                                             published_at TIMESTAMPTZ,
                                                                                                                                                                             deleted_at TIMESTAMPTZ, -- soft delete
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                                         updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                                                                                 CONSTRAINT uq_articles_slug UNIQUE (slug), CONSTRAINT ck_articles_status CHECK (status IN ('draft',
                                                                                                                                                                            'published',
                                                                                                                                                                            'archived')));

-- CREATE

INSERT INTO authors (display_name, email)
VALUES ('Kai Writer', 'kai@example.com') RETURNING id,
                                                   email;


INSERT INTO articles (author_id, slug, title, BODY, status, published_at)
VALUES (1, 'hello-sql', 'Hello SQL', 'Intro body', 'published', NOW()),
       (1, 'draft-notes', 'Draft Notes', 'WIP', 'draft', NULL) RETURNING id,
                                                                         slug,
                                                                         status;

-- READ — อย่าใช้ SELECT * ในแอปจริง

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

-- UPDATE — ทดสอบ WHERE ด้วย SELECT ก่อนเสมอ

UPDATE articles
SET title = 'Hello SQL (Revised)',
    BODY = 'Intro body — revised',
           updated_at = NOW()
WHERE slug = 'hello-sql'
  AND deleted_at IS NULL RETURNING id,
                                   title,
                                   updated_at;

-- Soft DELETE

UPDATE articles
SET deleted_at = NOW(),
    status = 'archived',
    updated_at = NOW()
WHERE slug = 'draft-notes' RETURNING id,
                                     slug,
                                     deleted_at;

-- Hard DELETE (ใช้เมื่อจำเป็น เช่น GDPR)
-- DELETE FROM articles WHERE id = ... AND deleted_at IS NOT NULL;
-- สรุปสถานะ

SELECT status,
       COUNT(*) AS cnt
FROM articles
WHERE deleted_at IS NULL
GROUP BY status;
