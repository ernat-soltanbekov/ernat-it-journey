-- Day 4 SQL Basics

-- What I learn today:
-- AND = all conditions must be true
-- OR = at least one condition must be true
-- NOT = exclude condition

-- 1
SELECT * FROM users
WHERE city = 'Almaty' AND age > 25;

-- 2
SELECT * FROM users
WHERE city = 'Astana' OR city = 'Almaty';

-- 3
SELECT * FROM users
WHERE NOT city = 'Karaganda';

-- 4
SELECT * FROM users
WHERE age > 18 AND age < 30;

-- 5
SELECT name, email FROM users
WHERE email LIKE '%gmail.com' AND city = 'Astana';

-- 6
SELECT * FROM users
WHERE city = 'Astana' OR age > 40;

-- 7
SELECT * FROM users
WHERE (city = 'Astana' OR city = 'Almaty') AND age > 25;

-- 8
SELECT COUNT(*) FROM users
WHERE city = 'Almaty' AND age > 20;

-- 9
SELECT * FROM users
WHERE NOT age < 18;

-- 10
SELECT * FROM users
WHERE name LIKE 'A%' AND (city = 'Astana' OR city = 'Almaty');

-- Notes:
-- AND = stricter filter
-- OR = wider filter
-- NOT = exclusion
-- () = control logic priority
