# Incident Analysis — Week 5 Day 1

## Scenario
Service `/api/orders` shows intermittent failures.

Log file:
`/var/log/orders.log`

---

## Log Sample

2026-04-18 09:12:01 INFO Request GET /api/orders 200  
2026-04-18 09:12:03 ERROR Database timeout on query orders  
2026-04-18 09:12:05 INFO Request GET /api/orders 200  
2026-04-18 09:12:07 ERROR Database timeout on query orders  
2026-04-18 09:12:09 ERROR Database timeout on query orders  
2026-04-18 09:12:12 INFO Request GET /api/orders 200  

---

## My Initial Thinking

- I identified that database issues are causing failures
- However, I lacked knowledge of how to work with logs in Linux
- I initially considered using Postman instead of logs/metrics

### Problem
- Did not know how to read logs using Linux tools
- Did not prioritize logs as primary debugging source
- Misidentified Postman as a verification tool for system-level issues

---

## Corrected Approach

### 1. What It Means

- System is partially degraded
- Some requests succeed (200)
- Some fail due to database timeout
- Issue is not total outage, but instability

---

### 2. First Step (Logs)

Use Linux tools:

- `tail -f /var/log/orders.log` → real-time monitoring  
- `grep ERROR /var/log/orders.log` → filter errors  
- `grep ERROR /var/log/orders.log | wc -l` → count errors  

---

### 3. Possible Cause

- Database is too slow or overloaded
- Queries to `orders` table are timing out
- Connection pool or DB performance issue

---

### 4. Actions

- Check database load (CPU, queries)
- Investigate slow queries
- Check connection pool limits
- Restart service if necessary
- Consider caching layer

---

### 5. Verification

- Monitor logs for repeated errors
- Check if error rate decreases
- Analyze metrics (latency, DB performance)

---

## Key Learning

- Logs are primary source of truth in system-level issues
- Postman is not useful for diagnosing backend performance problems
- Must use Linux tools to read and filter logs
- Partial failure indicates degradation, not full outage
