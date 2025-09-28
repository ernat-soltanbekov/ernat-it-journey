-- Review: filters and NULL. Based on ../sql_day_1.sql and ../sql_day_4.sql.
-- Exercise: list users from Astana or Almaty who are older than 25.
-- Predict whether a row with unknown (NULL) age qualifies before running.
-- These SELECT statements use temporary CTE values; no table is changed.
WITH users(id, name, city, age) AS (
    VALUES (1, 'Aida', 'Astana', 28),
           (2, 'Arman', 'Almaty', 22),
           (3, 'Dana', 'Astana', NULL),
           (4, 'Murat', 'Karaganda', 41),
           (5, 'Aida', 'Almaty', 31)
)
SELECT id, name, city
FROM users
WHERE (city = 'Astana' OR city = 'Almaty') AND age > 25
ORDER BY id;
-- Expected: (1, Aida, Astana), (5, Aida, Almaty).
-- Parentheses make the intended OR group explicit. NULL > 25 is unknown,
-- so WHERE does not select that row.

-- Exercise: find the record that needs age clarification.
WITH users(id, name, city, age) AS (
    VALUES (1, 'Aida', 'Astana', 28),
           (2, 'Arman', 'Almaty', 22),
           (3, 'Dana', 'Astana', NULL),
           (4, 'Murat', 'Karaganda', 41),
           (5, 'Aida', 'Almaty', 31)
)
SELECT id, name FROM users WHERE age IS NULL ORDER BY id;
-- Expected: (3, Dana). Use IS NULL, not = NULL.
-- Extension: change the first filter to city IN ('Astana', 'Almaty').
-- Explain why its output stays the same for this fixture.
