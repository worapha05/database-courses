-- V003__add_courses_level.sql (MySQL)
SET @col_exists :=
  (SELECT COUNT(*)
   FROM information_schema.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'courses'
     AND COLUMN_NAME = 'level');


SET @sql := IF(@col_exists = 0, 'ALTER TABLE courses ADD COLUMN level VARCHAR(20) NULL', 'SELECT 1');

PREPARE stmt
FROM @sql;

EXECUTE stmt;

DEALLOCATE PREPARE stmt;

-- CHECK อาจมีอยู่แล้ว — เพิ่มแบบตรงไปตรงมาสำหรับ lab

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


INSERT
IGNORE INTO schema_migrations (VERSION)
VALUES ('V003__add_courses_level');
