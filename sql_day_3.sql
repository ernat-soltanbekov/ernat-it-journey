-- Day 3 SQL Basics

-- What I learn today:
-- JOIN = combine tables
-- GROUP BY = group rows
-- COUNT = aggregate function

-- Imagine two tables:
-- users(id, name, city)
-- orders(id, user_id, amount)

-- 1
-- Get users with their orders
SELECT users.name, orders.amount
FROM users
JOIN orders ON users.id = orders.user_id;

-- 2
-- Get users and their cities with orders
SELECT users.name, users.city, orders.amount
FROM users
JOIN orders ON users.id = orders.user_id;

-- 3
-- Count how many orders each user has
SELECT users.name, COUNT(orders.id)
FROM users
JOIN orders ON users.id = orders.user_id
GROUP BY users.name;

-- 4
-- Count users per city
SELECT city, COUNT(*)
FROM users
GROUP BY city;

-- 5
-- Count orders per user and show only users with more than 1 order
SELECT users.name, COUNT(orders.id)
FROM users
JOIN orders ON users.id = orders.user_id
GROUP BY users.name
HAVING COUNT(orders.id) > 1;

-- Notes:
-- JOIN connects tables
-- ON defines how tables relate
-- GROUP BY groups rows
-- COUNT counts rows
-- HAVING filters groups
