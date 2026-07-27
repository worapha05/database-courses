-- =============================================================================
-- 03-subqueries-cte / PostgreSQL
-- =============================================================================

DROP TABLE IF EXISTS enrollments CASCADE;


DROP TABLE IF EXISTS courses CASCADE;


DROP TABLE IF EXISTS students CASCADE;


DROP TABLE IF EXISTS categories CASCADE;


CREATE TABLE categories (id BIGSERIAL PRIMARY KEY,
                                      name VARCHAR(80) NOT NULL,
                                                       parent_id BIGINT REFERENCES categories (id));


CREATE TABLE students (id BIGSERIAL PRIMARY KEY,
                                    full_name VARCHAR(120) NOT NULL);


CREATE TABLE courses (id BIGSERIAL PRIMARY KEY,
                                   title VARCHAR(160) NOT NULL,
                                                      category_id BIGINT NOT NULL REFERENCES categories (id),
                                                                                             price NUMERIC(10, 2) NOT NULL);


CREATE TABLE enrollments (id BIGSERIAL PRIMARY KEY,
                                       student_id BIGINT NOT NULL REFERENCES students (id),
                                                                             course_id BIGINT NOT NULL REFERENCES courses (id),
                                                                                                                  score NUMERIC(5, 2),
                                                                                                                        enrolled_at DATE NOT NULL,
                                                                                                                                         UNIQUE (student_id,
                                                                                                                                                 course_id));


INSERT INTO categories (id, name, parent_id)
VALUES (1, 'Technology', NULL),
       (2, 'Databases', 1),
       (3, 'PostgreSQL', 2),
       (4, 'MySQL', 2),
       (5, 'Business', NULL),
       (6, 'Analytics', 5);


INSERT INTO students (full_name)
VALUES ('Ann'),
       ('Ben'),
       ('Cara'),
       ('Dee');


INSERT INTO courses (title, category_id, price)
VALUES ('SQL Basics', 2, 1500),
       ('PG Advanced', 3, 2800),
       ('MySQL Ops', 4, 2500),
       ('BI Dashboards', 6, 2200);


INSERT INTO enrollments (student_id, course_id, score, enrolled_at)
VALUES (1, 1, 88, '2026-01-10'),
       (1, 2, 92, '2026-02-01'),
       (2, 1, 70, '2026-01-12'),
       (2, 3, 81, '2026-02-20'),
       (3, 4, 95, '2026-03-01');

-- Dee ยังไม่ลงทะเบียน
-- Scalar subquery: คอร์สที่แพงกว่าค่าเฉลี่ย

SELECT title,
       price
FROM courses
WHERE price >
    (SELECT AVG(price)
     FROM courses)
ORDER BY price DESC;

-- EXISTS: นักเรียนที่มี enrollment

SELECT s.full_name
FROM students s
WHERE EXISTS
    (SELECT 1
     FROM enrollments e
     WHERE e.student_id = s.id);

-- NOT EXISTS: นักเรียนที่ยังไม่ลงทะเบียน

SELECT s.full_name
FROM students s
WHERE NOT EXISTS
    (SELECT 1
     FROM enrollments e
     WHERE e.student_id = s.id);

-- Derived table + JOIN

SELECT s.full_name,
       x.course_count,
       x.avg_score
FROM students s
JOIN
  (SELECT student_id,
          COUNT(*) AS course_count,
          ROUND(AVG(score), 2) AS avg_score
   FROM enrollments
   GROUP BY student_id) x ON x.student_id = s.id
ORDER BY x.avg_score DESC;

-- CTE หลายขั้น
WITH paid_catalog AS
  (SELECT id,
          title,
          price
   FROM courses
   WHERE price >= 2000),
     top_scores AS
  (SELECT e.course_id,
          MAX(e.score) AS max_score
   FROM enrollments e
   GROUP BY e.course_id)
SELECT c.title,
       c.price,
       t.max_score
FROM paid_catalog c
LEFT JOIN top_scores t ON t.course_id = c.id
ORDER BY c.price DESC;

-- Recursive CTE: ต้นไม้หมวดหมู่
WITH RECURSIVE cat_tree AS
  (SELECT id,
          parent_id,
          name,
          1 AS depth,
          name::text AS PATH
   FROM categories
   WHERE parent_id IS NULL
   UNION ALL SELECT c.id,
                    c.parent_id,
                    c.name,
                    t.depth + 1,
                    t.path || ' > ' || c.name
   FROM categories c
   JOIN cat_tree t ON c.parent_id = t.id)
SELECT depth,
       PATH
FROM cat_tree
ORDER BY PATH;
