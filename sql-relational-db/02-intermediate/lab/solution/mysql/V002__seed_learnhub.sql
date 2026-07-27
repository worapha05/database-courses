-- V002__seed_learnhub.sql (MySQL)

INSERT INTO categories (id, name, parent_id)
VALUES (1, 'Technology', NULL),
       (2, 'Databases', 1),
       (3, 'PostgreSQL', 2),
       (4, 'MySQL', 2),
       (5, 'Career', NULL),
       (6, 'Soft Skills', 5);


INSERT INTO students (full_name, email)
VALUES ('Ann', 'ann@ex.com'),
       ('Ben', 'ben@ex.com'),
       ('Cara', 'cara@ex.com'),
       ('Dee', 'dee@ex.com'),
       ('Edd', 'edd@ex.com');


INSERT INTO courses (title, category_id, price)
VALUES ('SQL Fundamentals', 2, 1500),
       ('PostgreSQL DBA', 3, 3200),
       ('MySQL Performance', 4, 3000),
       ('Interview Prep', 6, 1800);


INSERT INTO enrollments (student_id, course_id, amount_paid, enrolled_at)
VALUES (1, 1, 1500, '2026-01-05'),
       (1, 2, 3200, '2026-01-20'),
       (2, 1, 1500, '2026-01-06'),
       (2, 3, 3000, '2026-02-01'),
       (3, 2, 3200, '2026-02-10'),
       (3, 4, 1800, '2026-02-11'),
       (4, 1, 1500, '2026-03-01'),
       (4, 3, 3000, '2026-03-02');


INSERT INTO schema_migrations (VERSION)
VALUES ('V002__seed_learnhub');
