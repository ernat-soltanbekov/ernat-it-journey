# Incident Analysis — Week 7 Day 1

## Scenario
User reports:
"External payment service sometimes slows down and causes API failures"

---

## Observations

- API waits up to 10 seconds for external service
- Multiple concurrent requests lead to worker exhaustion
- Users receive timeouts or 500 errors
- External dependency is unstable

---

## What Is Happening

- API makes synchronous call to external payment service
- Workers block while waiting for response
- Under load, worker pool becomes exhausted
- New requests are queued or fail

→ Result:
System becomes unresponsive due to blocked resources

---

## Core Problem

- Tight coupling with external dependency
- No isolation or protection mechanisms
- System does not degrade gracefully

---

## Solutions

### 1. Timeout + Fail-Fast (Critical)

- Set strict timeouts for external calls
- Separate connect timeout and read timeout

Result:
- Workers are freed quickly
- System remains responsive

---

### 2. Retry Strategy

- Implement limited retries with exponential backoff
- Avoid infinite or aggressive retry loops

Result:
- Handles transient failures without overload

---

### 3. Circuit Breaker

- Stop calling external service after repeated failures
- Allow recovery period before retrying

Result:
- Prevents cascading failures
- Protects system resources

---

### 4. Asynchronous Processing

- Move payment handling to background queue
- Respond to user immediately with processing status

Result:
- Decouples API response time from external service latency

---

## Key Learning

- External dependencies must be treated as unreliable
- Systems must fail fast to remain stable
- Protection mechanisms are essential for resilience
- Decoupling improves system robustness
