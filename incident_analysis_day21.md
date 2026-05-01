# Incident Analysis — Week 6 Day 7

## Scenario
User reports:
"API sometimes responds in ~200ms, sometimes in 6–10 seconds, worse under load"

---

## Observations

- CPU usage fluctuates but is not constantly maxed
- Database is generally fast but occasionally slows down (2–3 seconds)
- External service latency varies (100ms → 3 seconds)
- Cache hit rate is ~65% (below optimal)
- Under low load: ~200ms
- Under concurrency (20): 8–12 seconds

---

## What Is Happening

System experiences latency jitter that leads to cascading degradation under load.

- Occasional slow operations (DB / external service)
- Workers become blocked while waiting
- Incoming requests are queued
- Queueing delay grows with concurrency

→ Result:
Even fast operations are delayed due to waiting time

---

## Core Mechanism

Latency = Execution time + Queue wait time

Under load:
- Execution time stays similar
- Queue wait time grows rapidly

→ Queueing dominates total latency

---

## Contributing Factors

- Low cache hit rate (~65%) → frequent slow-path execution
- Unstable external dependency → blocking calls
- Occasional DB slowdowns → increased contention
- Lack of protective mechanisms (timeouts, fail-fast)

---

## Validation

- Compare response time at low vs high concurrency
- Analyze percentiles (p95, p99)
- Correlate API latency with DB and external service timing
- Inspect logs for slow requests (>500ms)

---

## Actions

### Priority 1 — Stabilization

- Add timeouts for external service calls
- Implement fail-fast behavior
- Introduce circuit breaker pattern

---

### Priority 2 — Load Reduction

- Improve cache hit rate (target 90%+)
- Implement cache warm-up
- Prevent cache stampede

---

### Priority 3 — Optimization

- Optimize DB queries and indexing
- Tune connection pool limits
- Monitor slow queries

---

## Key Learning

- System instability is often caused by multiple small issues
- Long-tail latency affects all users
- Queueing is the main driver of degradation under load
- Stabilization must come before optimization
