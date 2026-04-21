# Incident Analysis — Week 5 Day 4

## Scenario
Users report: "Orders are loading very slowly"

---

## Log Sample

2026-04-18 12:00:01 INFO Request GET /api/orders 200 response_time=120ms  
2026-04-18 12:00:02 INFO Request GET /api/orders 200 response_time=150ms  
2026-04-18 12:00:03 INFO Request GET /api/orders 200 response_time=4800ms  
2026-04-18 12:00:04 INFO Request GET /api/orders 200 response_time=5100ms  
2026-04-18 12:00:05 INFO Request GET /api/orders 200 response_time=130ms  

---

## My Initial Thinking

- I assumed database is the main cause
- I focused on backend/DB without confirming the bottleneck
- I suggested general actions like clearing cache and reducing load

### Problem
- Jumped to conclusions without evidence
- Did not analyze response_time patterns deeply
- Lacked structured performance debugging approach

---

## Corrected Approach

### 1. What I See

- All requests return 200 (no errors)
- Response time varies significantly
- Some requests are fast (~120ms)
- Some are extremely slow (~5000ms)

→ System is functional but unstable in performance

---

### 2. First Step

Identify pattern in slow requests:
- Are they random?
- Do they relate to specific users?
- Do they occur at specific times?

---

### 3. Possible Causes

- Slow database queries (not yet confirmed)
- Cache misses (cold cache)
- External service delays
- High system load
- Inefficient backend logic (e.g., multiple queries)

---

### 4. Verification

- Analyze response_time patterns in logs
- Check database slow query logs
- Identify repetition (same user/time)
- Compare fast vs slow requests
- Evaluate caching behavior

---

### 5. Actions

- Identify exact bottleneck (DB / cache / service)
- Optimize queries if DB-related
- Improve caching strategy
- Reduce unnecessary requests
- Monitor system load and adjust resources

---

## Key Learning

- 200 OK does not guarantee good performance
- Must analyze response_time, not just status codes
- Do not assume cause without evidence
- Performance issues require structured investigation
