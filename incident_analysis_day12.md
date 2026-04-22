# Incident Analysis — Week 5 Day 5

## Scenario
Users report: "Sometimes orders do not open, but later everything works"

---

## Log Samples

### orders.log

2026-04-18 13:00:01 INFO Request GET /api/orders 200 response_time=120ms user_id=301  
2026-04-18 13:00:02 INFO Request GET /api/orders 200 response_time=130ms user_id=302  
2026-04-18 13:00:03 INFO Request GET /api/orders 200 response_time=6000ms user_id=303  
2026-04-18 13:00:04 INFO Request GET /api/orders 200 response_time=110ms user_id=304  
2026-04-18 13:00:05 INFO Request GET /api/orders 200 response_time=6200ms user_id=305  

---

### db.log

2026-04-18 13:00:03 INFO Connection pool limit reached  
2026-04-18 13:00:05 INFO Connection pool limit reached  

---

## My Initial Thinking

- I focused on specific users (303, 305)
- I assumed slow queries or cache issues
- I suggested general optimizations (indexing, cache)

### Problem
- Ignored clear signal in logs (connection pool limit)
- Focused on symptoms (slow response) instead of root cause
- Misidentified type of database issue

---

## Corrected Approach

### 1. What Is Happening

- API responses are successful (200), but slow
- Database logs indicate: connection pool limit reached
- Requests are delayed while waiting for available DB connections

→ This is not a query performance issue  
→ This is a resource limitation issue  

---

### 2. First Step

Check connection pool status:
- Maximum pool size
- Active connections
- Waiting requests

---

### 3. Root Cause

- Database connection pool is exhausted
- No free connections available
- Requests must wait → increased response time

---

### 4. Validation

- Monitor number of active DB connections
- Check if pool usage reaches maximum
- Identify long-lived or unclosed connections

---

### 5. Actions

- Increase connection pool size
- Fix connection leaks (ensure proper closing)
- Reduce connection holding time
- Optimize queries to release connections faster

---

## Key Learning

- Not all DB issues are slow queries
- Resource limits (connection pool) can cause delays
- Must pay attention to explicit log messages
- Always distinguish between performance and resource exhaustion
