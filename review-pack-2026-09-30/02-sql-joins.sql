-- Review: JOIN and GROUP BY. Based on ../sql_day_3.sql.
-- Exercise: count orders for every user, including users with no orders.
-- Two users share the name Aida: keep their identities separate.
WITH users(id, name) AS (
    VALUES (1, 'Aida'), (2, 'Arman'), (3, 'Aida')
), orders(id, user_id, amount) AS (
    VALUES (101, 1, 20), (102, 1, 30), (103, 3, 10)
)
SELECT u.id, u.name, COUNT(o.id) AS order_count
FROM users AS u
LEFT JOIN orders AS o ON o.user_id = u.id
GROUP BY u.id, u.name
ORDER BY u.id;
-- Expected: (1, Aida, 2), (2, Arman, 0), (3, Aida, 1).
-- LEFT JOIN preserves the user without orders. COUNT(o.id) excludes NULL.
-- COUNT(*) would count the preserved unmatched row as 1.
-- Grouping only by name would merge the two distinct Aida accounts.

-- Exercise: show only users with more than one order.
WITH users(id, name) AS (
    VALUES (1, 'Aida'), (2, 'Arman'), (3, 'Aida')
), orders(id, user_id, amount) AS (
    VALUES (101, 1, 20), (102, 1, 30), (103, 3, 10)
)
SELECT u.id, u.name, COUNT(o.id) AS order_count
FROM users AS u
LEFT JOIN orders AS o ON o.user_id = u.id
GROUP BY u.id, u.name
HAVING COUNT(o.id) > 1
ORDER BY u.id;
-- Expected: (1, Aida, 2). HAVING filters groups after aggregation.
-- References:
-- https://www.postgresql.org/docs/current/queries-table-expressions.html
-- https://www.postgresql.org/docs/current/functions-aggregate.html
