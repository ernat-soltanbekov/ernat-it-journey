# Incident Analysis — Week 5 Day 3

## Scenario
Service `/api/orders` shows errors for specific users.

Two log sources:
- orders.log (API layer)
- db.log (database layer)

---

## Log Samples

### orders.log

2026-04-18 11:00:01 INFO Request GET /api/orders 200 user_id=201  
2026-04-18 11:00:02 ERROR Database timeout on query orders user_id=202  
2026-04-18 11:00:03 ERROR Database timeout on query orders user_id=202  

---

### db.log

2026-04-18 11:00:02 WARNING Slow query detected user_id=202 execution_time=5s  
2026-04-18 11:00:03 WARNING Slow query detected user_id=202 execution_time=6s  

---

## My Initial Thinking

- I identified that database is slow for user_id=202
- I understood there is a relationship between logs
- I suggested indexing as a solution

### Problem
- I did not explicitly confirm correlation between logs first
- My reasoning was not structured around cause-effect chain
- I did not fully specify how to validate slow queries

---

## Corrected Approach

### 1. What Is Happening

- Database logs show slow queries (5–6 seconds) for user_id=202
- API logs show timeouts at the same timestamps
- Strong correlation between DB delay and API failure

→ Slow query causes API timeout

---

### 2. First Step

Confirm correlation:

- `grep user_id=202 /var/log/orders.log`
- `grep user_id=202 /var/log/db.log`

Match timestamps and frequency

---

### 3. Root Cause

- Slow SQL queries for specific user
- Possible reasons:
  - missing indexes
  - large dataset
  - inefficient query design

---

### 4. Validation

- Analyze slow query logs
- Identify specific SQL query
- Check execution time patterns
- Compare with other users

---

### 5. Actions

- Optimize SQL query
- Add indexes where necessary
- Reduce data scope (limit/filter)
- Introduce caching if applicable

---

## Key Learning

- API errors can originate from database performance issues
- Must correlate logs across multiple layers
- Always confirm cause-effect relationship before acting
- Slow queries are a critical signal in system debugging
