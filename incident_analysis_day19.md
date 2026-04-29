# Incident Analysis — Week 6 Day 5

## Scenario
User reports:
"API works fast with low traffic, but slows down significantly under load (10–15 seconds)"

---

## Observations

- CPU usage is normal
- Memory usage is stable
- Database queries are fast
- External services respond quickly
- Low load response time: ~200ms
- Under load (concurrency 20): ~12 seconds

---

## My Initial Thinking

- I identified performance degradation only under load
- I recognized this as a saturation problem
- I considered resource limits and queueing behavior

---

## What Is Happening

- System reaches a resource limit under load
- Requests are queued due to limited capacity
- Waiting time increases non-linearly

→ Result: high latency despite normal system metrics

---

## First Step

Identify system and application limits:

- Number of workers
- Connection pool size
- OS-level limits (file descriptors)

---

## Root Cause (Possible)

- Database connection pool exhaustion
- Limited number of workers or threads
- OS file descriptor limits (ulimit)
- Lack of keep-alive causing connection overhead
- Internal locks or contention

---

## Validation

### 1. Check active connections

Command:
ss -s

---

### 2. Check OS limits

Command:
ulimit -n

---

### 3. Database activity

Query:
SELECT * FROM pg_stat_activity;

---

### 4. Load testing

Command:
ab -n 100 -c 20 http://localhost:8000/api/orders

---

### 5. Process state

Command:
htop

Observation:
- Many processes in waiting state → contention or queueing

---

## Actions

### Immediate

- Increase connection pool size
- Adjust number of workers
- Enable keep-alive

---

### Short-term

- Optimize blocking operations
- Reduce lock contention

---

### Long-term

- Horizontal scaling (multiple instances)
- Load balancing
- Improve architecture for concurrency

---

## Key Learning

- Systems can perform well under low load but fail under stress
- Saturation leads to queueing and latency spikes
- Identifying limits is critical for scalability
- Scaling should follow optimization, not replace it
