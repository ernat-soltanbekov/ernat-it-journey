# Incident Analysis — Week 6 Day 6

## Scenario
User reports:
"API sometimes responds in ~200ms, sometimes in 5–8 seconds, especially in the evening"

---

## Observations

- CPU usage fluctuates but is not maxed out
- Database is generally fast, but occasionally responds in 2–3 seconds
- External service is inconsistent (100ms to 2–3 seconds)
- Cache hit rate is ~60% (below optimal 90%+)
- Under load, response time varies significantly

---

## My Initial Thinking

- I recognized that there is no single bottleneck
- I identified instability caused by multiple small delays
- I considered long-tail latency and outlier impact

---

## What Is Happening

- Occasional slow responses from DB and external service
- These slow operations occupy workers and resources
- New requests are queued and delayed

→ Result:
Even fast requests are slowed down due to resource contention

---

## First Step

Find correlation between delays:

- Compare API response times with:
  - DB response times
  - External service latency
- Identify if slowdowns occur simultaneously

---

## Root Cause (Combined)

- Unstable external dependency
- Suboptimal cache hit rate
- Occasional DB slow queries
- Resource contention under load
- Possible cache stampede

---

## Validation

### 1. Analyze logs with timing

- Identify slow requests (>500ms)
- Track where time is spent (API / DB / external)

---

### 2. Measure percentiles

- p50 (median)
- p95 / p99 (tail latency)

---

### 3. Load testing

Command:
ab -n 100 -c 20 http://localhost:8000/api/orders

---

### 4. (Optional) Distributed tracing

- Visualize request flow across services

---

## Actions

### Priority 1 — Stabilization

- Add timeout for external service calls
- Implement fail-fast behavior
- Introduce circuit breaker

---

### Priority 2 — Load Reduction

- Improve cache hit rate (target: 90%+)
- Implement cache warm-up
- Prevent cache stampede

---

### Priority 3 — Optimization

- Optimize DB queries and indexing
- Tune connection pool sizes
- Monitor slow queries

---

## Key Learning

- System instability often comes from multiple small issues
- Long-tail latency affects overall performance
- Stability is more important than average speed
- Must prioritize protection before optimization
