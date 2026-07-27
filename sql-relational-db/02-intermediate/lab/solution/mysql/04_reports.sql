-- 04_reports.sql (MySQL) — LAB solution queries

SELECT c.title,
       COUNT(e.id) AS enrollment_count,
       COALESCE(SUM(e.amount_paid), 0) AS revenue
FROM courses c
INNER JOIN enrollments e ON e.course_id = c.id
GROUP BY c.id,
         c.title
ORDER BY enrollment_count DESC,
         revenue DESC
LIMIT 3;

WITH RECURSIVE cat_root AS
  (SELECT id,
          name,
          parent_id,
          id AS root_id,
          name AS root_name
   FROM categories
   WHERE parent_id IS NULL
   UNION ALL SELECT c.id,
                    c.name,
                    c.parent_id,
                    r.root_id,
                    r.root_name
   FROM categories c
   JOIN cat_root r ON c.parent_id = r.id),
               course_rev AS
  (SELECT course_id,
          SUM(amount_paid) AS revenue
   FROM enrollments
   GROUP BY course_id)
SELECT cr.root_name AS top_category,
       SUM(course_rev.revenue) AS revenue
FROM courses co
JOIN cat_root cr ON cr.id = co.category_id
LEFT JOIN course_rev ON course_rev.course_id = co.id
GROUP BY cr.root_id,
         cr.root_name
ORDER BY revenue DESC;


SELECT s.id,
       s.full_name,
       s.email
FROM students s
LEFT JOIN enrollments e ON e.student_id = s.id
WHERE e.id IS NULL;

WITH avg_price AS
  (SELECT AVG(price) AS v
   FROM courses)
SELECT c.title,
       c.price,
       ROUND(c.price - a.v, 2) AS above_avg_by
FROM courses c
CROSS JOIN avg_price a
WHERE c.price > a.v
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


SELECT VERSION,
       applied_at
FROM schema_migrations
ORDER BY VERSION;
