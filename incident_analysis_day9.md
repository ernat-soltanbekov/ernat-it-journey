# Incident Analysis — Week 5 Day 2

## Scenario
Service `/api/orders` shows intermittent database timeouts.

Log sample includes user_id values.

---

## Log Sample

2026-04-18 10:01:01 INFO Request GET /api/orders 200 user_id=101  
2026-04-18 10:01:02 INFO Request GET /api/orders 200 user_id=102  
2026-04-18 10:01:03 ERROR Database timeout on query orders user_id=103  
2026-04-18 10:01:04 ERROR Database timeout on query orders user_id=104  
2026-04-18 10:01:05 INFO Request GET /api/orders 200 user_id=105  
2026-04-18 10:01:06 ERROR Database timeout on query orders user_id=103  
2026-04-18 10:01:07 ERROR Database timeout on query orders user_id=103  
2026-04-18 10:01:08 INFO Request GET /api/orders 200 user_id=106  

---

## My Initial Thinking

- I noticed that some users receive errors while others do not
- I incorrectly assumed the issue might be related to users (latency, behavior)
- I considered contacting affected users

### Problem
- Misinterpreted system issue as user-level issue
- Did not correctly analyze repeating patterns in logs
- Did not understand how to filter logs by user_id

---

## Corrected Approach

### 1. What I See

- Errors are not random
- user_id=103 appears multiple times with errors
- user_id=104 appears only once (likely not systemic)
- Indicates pattern, not random failure

---

### 2. First Step (Log Analysis)

Use Linux tools to isolate pattern:

- `grep user_id=103 /var/log/orders.log`
- `grep user_id=103 /var/log/orders.log | wc -l`

Compare with other users:

- `grep user_id=104 /var/log/orders.log | wc -l`

---

### 3. Key Insight

This is not a user issue:

→ Repeated failures for specific user_id  
→ Indicates data-related or query-related problem  

---

### 4. Possible Cause

- Heavy or complex data for user_id=103
- Slow database queries related to that user
- Database cannot process specific requests in time

---

### 5. Actions

- Analyze queries related to user_id=103
- Check database performance for those queries
- Investigate data volume or structure
- Optimize query or indexing if needed

---

## Key Learning

- Logs must be analyzed for patterns, not isolated errors
- Repeated errors for specific user_id indicate system/data issue
- Do not assume user-side problems without evidence
- Linux tools (grep, wc) are essential for log analysis
