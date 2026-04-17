# Incident Analysis — Week 4 Day 7

## Scenario
Alert: "Error rate increased to 35% on /api/orders endpoint"

---

## My Initial Thinking

### Assumption
- Problem might be related to backend or database not responding
- Considered checking requests via DevTools

### Problem
- I approached this like a user-level issue
- I focused on frontend tools instead of system-level diagnostics
- I did not consider logs and metrics as primary sources

---

## Corrected Approach

### 1. What It Means

- System is partially degraded
- Some requests succeed, others fail
- Not a UI issue
- Likely related to system load, dependencies, or instability

---

### 2. First Step (System Level)

Check service logs for `/api/orders`:
- Identify error types (500, timeout, DB errors)
- Look for patterns

---

### 3. Diagnostic Flow

#### Step 1: Logs
- Analyze error messages
- Frequency and patterns

#### Step 2: Metrics
- CPU / RAM usage
- Request latency
- Error spikes

#### Step 3: Dependencies
- Database performance
- External services (payments, etc.)

#### Step 4: Pattern Detection
- Is failure random or specific?
- Does it affect certain requests/users?

---

### 4. Possible Causes

- Database slow queries or overload
- Service dependency failure
- Timeout between services
- High system load
- One instance in cluster malfunctioning
- Cache issues

---

### 5. Actions

- Restart affected service or instance
- Remove unhealthy instance from load balancer
- Rollback recent deployment
- Enable fallback (cache)
- Limit incoming traffic (if needed)

---

## Key Learning

- System issues require logs and metrics, not DevTools
- Partial failure indicates instability, not total outage
- Must think in terms of services, dependencies, and infrastructure
- Transition from user-level debugging to system-level analysis
