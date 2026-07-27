-- V001__init_learnhub.sql (MySQL) — LAB solution
SET NAMES utf8mb4;


SET FOREIGN_KEY_CHECKS = 0;


DROP TABLE IF EXISTS enrollments;


DROP TABLE IF EXISTS courses;


DROP TABLE IF EXISTS students;


DROP TABLE IF EXISTS categories;


DROP TABLE IF EXISTS schema_migrations;


SET FOREIGN_KEY_CHECKS = 1;


CREATE TABLE schema_migrations (VERSION VARCHAR(64) NOT NULL PRIMARY KEY,
                                                             applied_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)) ENGINE = InnoDB DEFAULT
CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;


CREATE TABLE categories (id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
                                                                    name VARCHAR(80) NOT NULL,
                                                                                     parent_id BIGINT UNSIGNED NULL,
                                                                                                               CONSTRAINT fk_cat_parent
                         FOREIGN KEY (parent_id) REFERENCES categories (id)) ENGINE = InnoDB DEFAULT
CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;


CREATE TABLE students (id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
                                                                  full_name VARCHAR(120) NOT NULL,
                                                                                         email VARCHAR(255) NOT NULL,
                                                                                                            UNIQUE KEY uq_students_email (email)) ENGINE = InnoDB DEFAULT
CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;


CREATE TABLE courses (id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
                                                                 title VARCHAR(160) NOT NULL,
                                                                                    category_id BIGINT UNSIGNED NOT NULL,
                                                                                                                price DECIMAL(10, 2) NOT NULL,
                                                                                                                                     CONSTRAINT fk_courses_cat
                      FOREIGN KEY (category_id) REFERENCES categories (id),
                                                           CONSTRAINT ck_courses_price CHECK (price >= 0)) ENGINE = InnoDB DEFAULT
CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;


CREATE TABLE enrollments (id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
                                                                     student_id BIGINT UNSIGNED NOT NULL,
                                                                                                course_id BIGINT UNSIGNED NOT NULL,
                                                                                                                          amount_paid DECIMAL(10, 2) NOT NULL,
                                                                                                                                                     enrolled_at DATE NOT NULL,
                                                                                                                                                                      UNIQUE KEY uq_enroll (student_id, course_id),
                                                                                                                                                                                 CONSTRAINT fk_enroll_student
                          FOREIGN KEY (student_id) REFERENCES students (id),
                                                              CONSTRAINT fk_enroll_course
                          FOREIGN KEY (course_id) REFERENCES courses (id),
                                                             CONSTRAINT ck_enroll_amount CHECK (amount_paid >= 0)) ENGINE = InnoDB DEFAULT
CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;


INSERT INTO schema_migrations (VERSION)
VALUES ('V001__init_learnhub');
