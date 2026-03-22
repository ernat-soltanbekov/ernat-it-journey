# SQL Cheat Sheet

## Core Words
- SELECT = what to show
- FROM = from which table
- WHERE = filter rows
- ORDER BY = sort result

## Basic Examples

### Show all columns
SELECT * FROM users;

### Show one column
SELECT name FROM users;

### Show two columns
SELECT name, email FROM users;

### Filter rows
SELECT * FROM users WHERE city = 'Astana';

### Sort rows
SELECT * FROM users ORDER BY name;

### Filter and sort
SELECT name, email FROM users WHERE city = 'Astana' ORDER BY name;

## My Reminder
SQL is about:
1. choosing data
2. choosing source
3. filtering rows
4. sorting result
