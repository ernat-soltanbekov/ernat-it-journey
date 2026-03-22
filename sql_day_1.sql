-- Day 1 SQL Basics

-- 1
SELECT * FROM users;

-- 2
SELECT name FROM users;

-- 3
SELECT name, email FROM users;

-- 4
SELECT * FROM users WHERE id = 1;

-- 5
SELECT * FROM users WHERE city = 'Astana';

-- 6
SELECT name, city FROM users WHERE city = 'Almaty';

-- 7
SELECT * FROM users ORDER BY name;

-- 8
SELECT * FROM users ORDER BY id DESC;

-- 9
SELECT name, email FROM users WHERE city = 'Astana' ORDER BY name;

-- 10
SELECT * FROM users WHERE age > 25 ORDER BY age;

-- Notes:
-- SELECT = what to show
-- FROM = from which table
-- WHERE = filter rows
-- ORDER BY = sort result
