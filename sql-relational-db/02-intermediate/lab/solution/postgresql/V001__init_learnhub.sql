-- V001__init_learnhub.sql (PostgreSQL) — LAB solution

DROP TABLE IF EXISTS enrollments CASCADE;


DROP TABLE IF EXISTS courses CASCADE;


DROP TABLE IF EXISTS students CASCADE;


DROP TABLE IF EXISTS categories CASCADE;


DROP TABLE IF EXISTS schema_migrations CASCADE;


CREATE TABLE schema_migrations (VERSION VARCHAR(64) PRIMARY KEY,
                                                    applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW());


CREATE TABLE categories (id BIGSERIAL PRIMARY KEY,
                                      name VARCHAR(80) NOT NULL,
                                                       parent_id BIGINT REFERENCES categories (id));


CREATE TABLE students (id BIGSERIAL PRIMARY KEY,
                                    full_name VARCHAR(120) NOT NULL,
                                                           email VARCHAR(255) NOT NULL UNIQUE);


CREATE TABLE courses (id BIGSERIAL PRIMARY KEY,
                                   title VARCHAR(160) NOT NULL,
                                                      category_id BIGINT NOT NULL REFERENCES categories (id),
                                                                                             price NUMERIC(10, 2) NOT NULL CHECK (price >= 0));


CREATE TABLE enrollments (id BIGSERIAL PRIMARY KEY,
                                       student_id BIGINT NOT NULL REFERENCES students (id),
                                                                             course_id BIGINT NOT NULL REFERENCES courses (id),
                                                                                                                  amount_paid NUMERIC(10, 2) NOT NULL CHECK (amount_paid >= 0), enrolled_at DATE NOT NULL DEFAULT CURRENT_DATE,
                                                                                                                                                                                                                  UNIQUE (student_id,
                                                                                                                                                                                                                          course_id));


INSERT INTO schema_migrations (VERSION)
VALUES ('V001__init_learnhub');
