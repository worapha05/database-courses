-- V003__add_courses_level.sql (PostgreSQL)

ALTER TABLE courses ADD COLUMN IF NOT EXISTS LEVEL VARCHAR(20);


ALTER TABLE courses
DROP CONSTRAINT IF EXISTS ck_courses_level;


ALTER TABLE courses ADD CONSTRAINT ck_courses_level CHECK (LEVEL IS NULL
                                                           OR LEVEL IN ('beginner',
                                                                        'intermediate',
                                                                        'advanced'));


UPDATE courses
SET LEVEL = 'beginner'
WHERE id = 1;


UPDATE courses
SET LEVEL = 'advanced'
WHERE id IN (2,
             3);


UPDATE courses
SET LEVEL = 'intermediate'
WHERE id = 4;


INSERT INTO schema_migrations (VERSION)
VALUES ('V003__add_courses_level') ON CONFLICT DO NOTHING;
