# Incident Analysis — Week 5 Day 7

## Scenario
Users report: "Sometimes orders load slowly, sometimes they do not appear immediately, sometimes everything works fine"

---

## Log Samples

### orders.log

2026-04-18 14:00:01 INFO Request GET /api/orders 200 response_time=120ms user_id=501  
2026-04-18 14:00:02 INFO Request GET /api/orders 200 response_time=5200ms user_id=502  
2026-04-18 14:00:03 INFO Request GET /api/orders 200 response_time=130ms user_id=503  
2026-04-18 14:00:04 INFO Request GET /api/orders 200 response_time=5400ms user_id=504  

---

### db.log

2026-04-18 14:00:02 WARNING Slow query detected user_id=502 execution_time=5s  
2026-04-18 14:00:04 WARNING Slow query detected user_id=504 execution_time=5.5s  

---

### cache.log

2026-04-18 14:00:02 INFO Cache miss user_id=502  
2026-04-18 14:00:04 INFO Cache miss user_id=504  

---

## My Initial Thinking

- I identified cache issues and slow database queries
- I suggested improving caching and indexing

### Problem
- I treated cache and DB as separate issues
- I did not fully connect them into a single chain
- My reasoning lacked structured correlation across logs

---

## Corrected Approach

### 1. What Is Happening

- Cache miss occurs for specific users
- Request falls back to database
- Database query is slow
- API response time increases significantly

→ Full chain:

Cache miss → DB slow query → API delay

---

### 2. First Step

Confirm correlation across all layers:
- Cache logs (miss)
- DB logs (slow query)
- API logs (response time)

---

### 3. Root Cause

Combined issue:

- Inefficient caching strategy (high cache miss rate)
- Slow database queries

→ Problem arises from interaction of both layers

---

### 4. Validation

- Extract all cache miss entries
- Match them with DB slow query logs
- Match both with API response_time spikes
- Identify repeating patterns

---

### 5. Actions

#### Improve Database Performance
- Optimize queries
- Add indexes

#### Improve Cache Efficiency
- Reduce cache miss rate
- Increase TTL if appropriate
- Implement cache warming

#### Improve System Behavior
- Update cache after write operations
- Reduce dependency on DB for frequent reads

---

## Key Learning

- Real-world issues often involve multiple system layers
- Must correlate logs across cache, DB, and API
- Cache inefficiency + slow DB = critical performance degradation
- Systems fail due to interaction of components, not isolated issues
