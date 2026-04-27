# Incident Analysis — Week 6 Day 3

## Scenario
User reports: "API response takes 4–6 seconds"

---

## Observations

- CPU usage is normal
- Memory usage is normal
- API process is running correctly
- Measured response time: ~5.2 seconds

---

## API Logs

INFO Request started GET /api/orders  
INFO Calling external service: payment-service  
INFO Waiting for response...  
INFO Response received after 4.8s  
INFO Returning response  

---

## My Initial Thinking

- I correctly identified that the issue is not related to CPU or memory
- I suspected external dependency (payment-service)
- I initially focused on network latency tools (ping, mtr)

### Problem
- I did not prioritize direct measurement of external service
- I jumped too quickly into network diagnostics

---

## Corrected Approach

### 1. What Is Happening

- API sends request to external payment-service
- API blocks while waiting for response
- External service responds slowly (~4.8 seconds)

→ Total API response time is dominated by external dependency

---

### 2. First Step

Measure external service response directly:

Command:
curl -w "%{time_total}" -o /dev/null -s http://payment-service/endpoint

---

### 3. Root Cause

- External service (payment-service) is slow
- API is synchronously waiting for response

---

### 4. Validation

- Compare API response time vs direct external service response
- Measure consistency of delay
- Use tcpdump if deeper network inspection is required

---

### 5. Actions

#### Immediate
- Add request timeout
- Prevent long blocking calls

#### Short-term
- Implement retry mechanism with backoff
- Log slow external responses

#### Long-term
- Consider asynchronous processing
- Implement circuit breaker pattern
- Reduce dependency impact on user-facing response

---

## Key Learning

- External dependencies directly impact API performance
- System metrics (CPU, RAM) may appear normal while system is slow
- Must prioritize direct measurement before deep diagnostics
- Blocking calls can degrade overall system responsiveness
