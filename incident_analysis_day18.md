# Incident Analysis — Week 6 Day 4

## Scenario
User reports: "API responds in 3–5 seconds"

---

## Observations

- CPU usage is low
- Memory usage is normal
- Database queries are fast
- External services respond quickly (~100ms)
- API response time: ~4.2 seconds

---

## Logs

INFO Request started  
INFO Processing request  
INFO Finished processing in 4.1s  

---

## My Initial Thinking

- I identified that system resources are not the bottleneck
- I suspected internal inefficiency in request handling
- I considered concurrency limitations and blocking behavior

### Problem
- I initially focused on system metrics instead of execution model
- Needed to explicitly analyze concurrency configuration

---

## Corrected Approach

### 1. What Is Happening

- Requests are not processed efficiently in parallel
- System resources are underutilized
- Requests are queued or blocked internally

→ Result: high response time despite low resource usage

---

### 2. First Step

Check service execution model:

- Number of workers
- Thread configuration
- Sync vs async behavior

Command:
ps aux | grep gunicorn

---

### 3. Root Cause

Possible causes:

- Limited number of workers
- Synchronous request handling
- Blocking operations
- Thread pool or connection pool limits

---

### 4. Validation

- Check process configuration (workers/threads)
- Run load test:

Command:
ab -n 50 -c 10 http://localhost:8000/api/orders

- Observe behavior:
  - Increasing response time with concurrency → queueing issue

- Check CPU distribution across cores using htop

---

### 5. Actions

#### Improve Parallelism
- Increase number of workers
- Adjust thread configuration

#### Improve Execution Model
- Replace blocking code with async alternatives
- Avoid long synchronous operations

#### Optimize Resource Pools
- Increase connection pool limits if necessary
- Reduce waiting time for shared resources

#### Deep Analysis
- Use profiling tools (e.g. py-spy) to detect bottlenecks

---

## Key Learning

- Low CPU usage does not mean system is efficient
- Concurrency limitations can create hidden bottlenecks
- Request queueing can significantly increase latency
- Must analyze execution model, not only resource usage
