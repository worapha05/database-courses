-- =============================================================================
-- 03-subqueries-cte / MySQL 8
-- =============================================================================
SET NAMES utf8mb4;


SET FOREIGN_KEY_CHECKS = 0;


DROP TABLE IF EXISTS enrollments;


DROP TABLE IF EXISTS courses;


DROP TABLE IF EXISTS students;


DROP TABLE IF EXISTS categories;


SET FOREIGN_KEY_CHECKS = 1;


CREATE TABLE categories (id BIGINT UNSIGNED NOT NULL PRIMARY KEY,
                                                     name VARCHAR(80) NOT NULL,
                                                                      parent_id BIGINT UNSIGNED NULL,
                                                                                                CONSTRAINT fk_cat_parent
                         FOREIGN KEY (parent_id) REFERENCES categories (id)) ENGINE = InnoDB;


CREATE TABLE students (id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
                                                                  full_name VARCHAR(120) NOT NULL) ENGINE = InnoDB;


CREATE TABLE courses (id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
                                                                 title VARCHAR(160) NOT NULL,
                                                                                    category_id BIGINT UNSIGNED NOT NULL,
                                                                                                                price DECIMAL(10, 2) NOT NULL,
                                                                                                                                     CONSTRAINT fk_course_cat
                      FOREIGN KEY (category_id) REFERENCES categories (id)) ENGINE = InnoDB;


CREATE TABLE enrollments (id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
                                                                     student_id BIGINT UNSIGNED NOT NULL,
                                                                                                course_id BIGINT UNSIGNED NOT NULL,
                                                                                                                          score DECIMAL(5, 2) NULL,
                                                                                                                                              enrolled_at DATE NOT NULL,
                                                                                                                                                               UNIQUE KEY uq_enroll_student_course (student_id, course_id),
                                                                                                                                                                          CONSTRAINT fk_enroll_student
                          FOREIGN KEY (student_id) REFERENCES students (id),
                                                              CONSTRAINT fk_enroll_course
                          FOREIGN KEY (course_id) REFERENCES courses (id)) ENGINE = InnoDB;


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


SELECT title,
       price
FROM courses
WHERE price >
    (SELECT AVG(price)
     FROM courses)
ORDER BY price DESC;


SELECT s.full_name
FROM students s
WHERE EXISTS
    (SELECT 1
     FROM enrollments e
     WHERE e.student_id = s.id);


SELECT s.full_name
FROM students s
WHERE NOT EXISTS
    (SELECT 1
     FROM enrollments e
     WHERE e.student_id = s.id);


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

WITH RECURSIVE cat_tree AS
  (SELECT id,
          parent_id,
          name,
          1 AS depth,
          CAST(name AS CHAR(255)) AS PATH
   FROM categories
   WHERE parent_id IS NULL
   UNION ALL SELECT c.id,
                    c.parent_id,
                    c.name,
                    t.depth + 1,
                    CONCAT(t.path, ' > ', c.name)
   FROM categories c
   JOIN cat_tree t ON c.parent_id = t.id)
SELECT depth,
       PATH
FROM cat_tree
ORDER BY PATH;
