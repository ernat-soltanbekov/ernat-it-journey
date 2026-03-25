-- Day 2 SQL Basics

-- What I learn today:
-- LIKE = search by pattern
-- IN = match one of several values
-- COUNT = count rows

-- 1
SELECT * FROM users WHERE name LIKE 'A%';

-- 2
SELECT * FROM users WHERE email LIKE '%gmail.com';

-- 3
SELECT * FROM users WHERE city IN ('Astana', 'Almaty');

-- 4
SELECT name, city FROM users WHERE city IN ('Astana', 'Karaganda');

-- 5
SELECT COUNT(*) FROM users;

-- 6
SELECT COUNT(*) FROM users WHERE city = 'Astana';

-- 7
SELECT COUNT(*) FROM users WHERE age > 25;

-- 8
SELECT * FROM users WHERE name LIKE '%an%';

-- 9
SELECT name, email FROM users WHERE email LIKE '%@mail.ru';

-- 10
SELECT COUNT(*) FROM users WHERE city IN ('Astana', 'Almaty');

-- Notes:
-- LIKE 'A%' = starts with A
-- LIKE '%an%' = contains an
-- IN (...) = one of these values
-- COUNT(*) = number of rows
