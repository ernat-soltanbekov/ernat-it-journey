# Incident Analysis — Week 7 Day 2

## Scenario
User reports:
"After adding retry logic, API performance degraded significantly under load"

---

## Observations

- External service is slow or unstable
- Retry mechanism triggers multiple repeated requests
- Under load, system becomes unresponsive
- Increased number of outgoing requests to external service

---

## What Is Happening

- Each failed request triggers multiple retries
- Total number of external calls increases exponentially
- Workers remain occupied longer due to repeated attempts
- System experiences retry storm

→ Result:
System overloads itself while trying to recover from failures

---

## Core Problem

- Retry logic is uncontrolled
- No delay or spreading between retry attempts
- System amplifies load during external failure

---

## Solutions

### 1. Controlled Retry (Critical)

- Limit number of retries (e.g., max 2–3 attempts)
- Ensure total request time remains bounded

---

### 2. Exponential Backoff

- Increase delay between retries:
  - attempt 1 → immediate
  - attempt 2 → delay
  - attempt 3 → longer delay

Result:
- Reduces pressure on external service
- Gives time for recovery

---

### 3. Jitter

- Add randomness to retry delay

Result:
- Prevents synchronized retry bursts
- Smooths traffic spikes

---

### 4. Circuit Breaker

- Stop retrying after repeated failures
- Allow cooldown period before retrying

Result:
- Prevents cascading failures

---

### 5. Retry Budget (Advanced)

- Limit total number of retries across system

Result:
- Prevents retry from consuming all resources

---

## Key Learning

- Retry can amplify failures if uncontrolled
- Load must decrease during degradation, not increase
- Proper retry strategy requires delay, limits, and randomness
- Resilience patterns must work together, not independently
